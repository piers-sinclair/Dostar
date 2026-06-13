---
description: Audit Azure infrastructure and CI/CD configuration for cost optimisation against early-stage startup principles.
argument-hint: [--env dev|prod|all] [--live]
allowed-tools: Bash(az *) Bash(git *) Read Glob
---

# audit-azure-costs

Audit the Azure infrastructure and CI/CD configuration for cost optimisation, benchmarked against
early-stage startup principles: keep the app live and reliable for customers while minimising spend.

## Usage

```
/audit-azure-costs [--env <dev|prod|all>] [--live]
```

- `--env` — limit the audit to one environment. Defaults to `all` (both dev and prod).
- `--live` — attempt to query live Azure cost and metric data via the `az` CLI in addition to the
  static config analysis. Skipped automatically if `az account show` fails.

## What this skill does

### 1. Read infrastructure config

Read every file under `infra/`:

- `infra/main.bicep` — parameters, resource wiring, naming
- `infra/modules/*.bicep` — per-resource settings (SKUs, tiers, scaling, retention, redundancy)
- `infra/main.parameters.dev.bicepparam` and `infra/main.parameters.prod.bicepparam` — env-specific
  overrides

Extract and record the following for each environment:

| Resource | What to capture |
|----------|----------------|
| Container App | `minReplicas`, `maxReplicas`, CPU, memory |
| PostgreSQL Flexible Server | SKU name & tier, `storageSizeGB`, `backupRetentionDays`, `geoRedundantBackup`, `highAvailabilityMode` |
| Static Web App | `sku.name` |
| Container Registry | `sku.name` |
| App Insights | `IngestionMode`, daily cap (if set) |
| Log Analytics | `retentionInDays` |
| Key Vault | `sku.name`, `softDeleteRetentionInDays` |

### 2. Read CI/CD workflows

Read all files under `.github/workflows/`. For each workflow note:

- Trigger type and path filters (or lack thereof)
- Whether Testcontainers-based integration tests run on every PR (expensive GitHub-hosted minutes)
- Job timeouts and whether they are set
- Any always-on polling loops or scheduled triggers

### 3. Check live Azure data (only if `--live` is passed or auto-detected)

Run `az account show` — if it fails, skip this step and note it in the report.

If authenticated, collect:

```bash
# Check for existing cost budgets
az consumption budget list --output table

# Check current Container App replica count for each environment
az containerapp show --name <app-name> --resource-group <rg-name> \
  --query "properties.template.scale.{min:minReplicas,max:maxReplicas}" --output table

# Check PostgreSQL storage utilisation
az postgres flexible-server show --name <server-name> --resource-group <rg-name> \
  --query "storage" --output table
```

Resource names follow the `<workload>-<env>-<region>-<instance>` naming convention from
`infra/main.bicep`. Derive them from the parameter values in the `.bicepparam` files.

### 4. Evaluate each resource category

Apply the following checks. Flag each finding at one of three levels:

- 🔴 **High impact** — change is straightforward and saves meaningful money with no reliability risk
- 🟡 **Medium impact** — worthwhile saving but involves a tradeoff the team must consciously accept
- 🟢 **Already optimised** — no action needed; call it out so the team has confidence

#### Container Apps

| Check | Pass condition | Finding level |
|-------|---------------|---------------|
| Dev min-replicas | `minReplicas == 0` (scale-to-zero in dev) | 🔴 if non-zero |
| Prod min-replicas | `minReplicas >= 1` is expected — but document the ~$30–50/mo baseline cost and the cold-start tradeoff so it is a conscious choice | 🟡 always (inform, don't flag as wrong) |
| Prod max-replicas | Is `maxReplicas > 5` without documented traffic justification? | 🟡 if > 5 |
| CPU/memory | 0.5 vCPU / 1 GiB is the smallest billable unit — flag if higher | 🔴 if oversized |

#### PostgreSQL Flexible Server

| Check | Pass condition | Finding level |
|-------|---------------|---------------|
| Dev SKU | `Standard_B1ms` or smaller | 🔴 if larger |
| Prod SKU | `Standard_B2ms` (burstable) rather than General Purpose | 🟡 if GP tier |
| Storage size | `storageSizeGB <= 32` for early stage | 🟡 if > 32 |
| Geo-redundant backup | `Disabled` — saves ~50% on backup costs | 🔴 if Enabled in dev |
| Dev backup retention | `<= 7 days` | 🟡 if > 7 |
| Prod backup retention | `<= 14 days` for early stage | 🟡 if > 14 |
| HA mode | `Disabled` — SameZone HA doubles DB cost | 🔴 if Enabled in dev; 🟡 if Enabled in prod |

#### Static Web Apps

| Check | Pass condition | Finding level |
|-------|---------------|---------------|
| Dev tier | `Free` | 🔴 if `Standard` |
| Prod tier | `Standard` adds custom domains + auth — flag if unused features justify Free instead | 🟡 always (explain cost) |

#### Container Registry

| Check | Pass condition | Finding level |
|-------|---------------|---------------|
| Dev SKU | `Basic` | 🔴 if `Standard` or `Premium` |
| Prod SKU | `Basic` is sufficient until image pull volume warrants `Standard` | 🟡 if `Standard` with low pull volume |

#### Application Insights

| Check | Pass condition | Finding level |
|-------|---------------|---------------|
| Daily data cap | A cap is configured (`dailyQuotaGb` is set) | 🔴 if no cap — ingestion can spike unexpectedly |
| Sampling | Adaptive sampling is enabled by default in the SDK — note this as 🟢 |

#### Log Analytics

| Check | Pass condition | Finding level |
|-------|---------------|---------------|
| Dev retention | `<= 30 days` | 🟡 if > 30 |
| Prod retention | `<= 90 days` for early stage | 🟡 if > 90 |

#### Cost governance

| Check | Pass condition | Finding level |
|-------|---------------|---------------|
| Azure Budget alerts | At least one budget with email/action-group alert per subscription/env | 🔴 if absent |
| Resource tagging | Resources tagged with `env` and `workload` for cost-centre filtering | 🟡 if absent |

#### CI/CD (GitHub Actions minutes)

| Check | Pass condition | Finding level |
|-------|---------------|---------------|
| Path filters on all workflows | All push/PR triggers have `paths:` filters | 🟡 if absent — avoids rebuilding everything on docs changes |
| Integration test triggers | Integration tests run on PR to `main` only (not on every branch push) | 🟡 if too broad |
| Explicit job timeouts | `timeout-minutes:` set on expensive jobs | 🟡 if absent — runaway jobs burn minutes |

### 5. Produce the report

Output a structured Markdown report with three sections:

---

**Section A — Monthly cost estimate**

Build a table of estimated monthly costs using these Azure pricing constants (australiaeast, pay-as-you-go, mid-2025 baseline):

| Resource | Dev estimate | Prod estimate |
|----------|-------------|---------------|
| PostgreSQL B1ms | ~$12/mo | — |
| PostgreSQL B2ms | — | ~$45/mo |
| Container App (1 replica, 0.5 vCPU/1 GiB, 730 hrs) | ~$30/mo | ~$30/mo |
| Container App (scale-to-zero dev, low traffic) | ~$2–5/mo | — |
| Container Registry Basic | ~$5/mo | ~$5/mo |
| Container Registry Standard | — | ~$20/mo |
| Static Web App Free | $0 | — |
| Static Web App Standard | — | ~$9/mo |
| Key Vault Standard (< 10k ops) | ~$0.10/mo | ~$0.10/mo |
| App Insights + Log Analytics (low ingestion, < 1 GB/mo) | ~$0–5/mo | ~$5–20/mo |
| VNet + subnets | ~$0 | ~$0 |
| **Total (approx.)** | **$20–50/mo** | **$110–130/mo** |

Adjust the table values based on what is actually configured (e.g. if dev min-replicas > 0, adjust upward).

---

**Section B — Findings**

List each finding grouped under its level (🔴 / 🟡 / 🟢). For every 🔴 and 🟡 finding include:

- **Resource**: which Bicep module/file the setting lives in
- **Current value**: what the config says today
- **Recommended value**: the cost-optimised setting
- **Tradeoff**: one sentence on what you give up (reliability, features, dev experience)
- **Estimated saving**: rough monthly $ saved if changed

---

**Section C — Recommended actions**

List only 🔴 and 🟡 findings that have a concrete fix. For each, provide the exact Bicep change or
`az` command needed. Group by priority:

**Do now (🔴 — no reliability tradeoff):**
- Add Azure Budget alert (no Bicep change; `az consumption budget create` command)
- Add App Insights daily cap (Bicep change in `infra/modules/appinsights.bicep`)
- Verify dev Container App min-replicas is 0

**Review with the team (🟡 — startup tradeoffs):**
- Prod Container App min-replicas: document the decision (0 = cold starts, 1 = ~$30/mo baseline)
- Prod ACR tier: downgrade to Basic if image pull volume is low
- Prod Static Web App tier: stay on Standard only if you use custom domains or auth

---

## Startup framing

Every finding must respect two constraints:

1. **The app must remain live for customers.** Never recommend scale-to-zero in prod without
   explicitly noting the cold-start latency impact (typically 5–30 s for a .NET app on Container
   Apps). If recommending it, suggest pairing with a warmup ping or Azure Front Door health probe.

2. **Cost savings compound.** Flag small wins (e.g. ACR Basic vs Standard = $15/mo) — they matter
   when multiplied across months and copied across customer deployments of the template.
