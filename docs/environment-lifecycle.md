# Dev Environment Lifecycle

The dev environment has three states. Pick the right one based on how long you'll be away.

---

## Environment states

| State | What's running | Approx. monthly cost | Resume time |
|-------|---------------|---------------------|-------------|
| **Running** | Container App (active) + PostgreSQL + Static Web App | ~$25–35 | — |
| **Paused** | PostgreSQL stopped; Container App idles to zero on inactivity | ~$8 (storage only) | ~3 min |
| **Torn down** | All resources deleted | $0 | ~15 min |

---

## Decision guide

| Scenario | Action |
|----------|--------|
| End of work day / overnight | Nothing needed — Container App already scales to zero |
| Weekend / short break | **Pause** — stops PostgreSQL billing, data preserved |
| Holiday / extended break (1+ weeks) | **Tear down** — zero cost, full reprovision on return |

---

## Operations

### Spin up (provision from scratch)

Use after a full teardown, or for first-time setup as an alternative to running `infra-deploy-dev` + `bootstrap-rbac` manually.

**Prerequisites** — the following GitHub secrets must be set (see [deploy-setup.md](deploy-setup.md)):

| Secret | Value |
|--------|-------|
| `AZURE_CLIENT_ID` | Service principal app ID |
| `AZURE_TENANT_ID` | Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Subscription ID |

**Steps:**

1. Go to **GitHub Actions** → **Dev — spin up** → **Run workflow**
2. Wait ~15 minutes for all steps to complete
3. Verify the backend is up:
   ```bash
   az containerapp show \
     --name ca-dostar-dev-aue-001 \
     --resource-group rg-dostar-dev-aue-001 \
     --query properties.configuration.ingress.fqdn -o tsv
   # then: curl https://<FQDN>/healthz/live  → 200 OK
   ```

The spinup workflow:
- Deploys Bicep (all Azure resources)
- Bootstraps RBAC role assignments (AcrPush, AcrPull, Key Vault Secrets User)
- Refreshes the `AZURE_STATIC_WEB_APPS_API_TOKEN_DEV` GitHub secret (it changes each reprovision)
- Triggers backend and frontend deploy workflows

---

### Pause

Stops the PostgreSQL server to eliminate compute billing. The Container App already scales to zero when idle; no action is needed for it.

**Prerequisites** — in addition to the three OIDC secrets:

| Secret | Value |
|--------|-------|
| `POSTGRES_SERVER_NAME` | `psql-dostar-dev-aue-001` |
| `RESOURCE_GROUP` | `rg-dostar-dev-aue-001` |

**Steps:**

1. Go to **GitHub Actions** → **Dev — pause** → **Run workflow**
2. Enter `pause` in the confirmation field
3. PostgreSQL will stop within ~1 minute

---

### Resume

Starts PostgreSQL and redeploys the application.

**Prerequisites** — same as Pause (`POSTGRES_SERVER_NAME` + `RESOURCE_GROUP`).

**Steps:**

1. Go to **GitHub Actions** → **Dev — resume** → **Run workflow**
2. The workflow polls until PostgreSQL is `Ready` (~3 minutes), then triggers backend and frontend deploys automatically

---

### Tear down

Deletes the entire resource group and all resources inside it. Cost drops to $0 immediately.

**Prerequisites** — in addition to the three OIDC secrets:

| Secret | Value |
|--------|-------|
| `RESOURCE_GROUP` | `rg-dostar-dev-aue-001` |

**Steps:**

1. Go to **GitHub Actions** → **Dev — tear down** → **Run workflow**
2. Enter `teardown` in the confirmation field
3. The resource group deletion runs in the background; the workflow exits immediately

To bring the environment back, run **Dev — spin up** (see above).

---

## Required GitHub secrets summary

| Secret | Used by | Notes |
|--------|---------|-------|
| `AZURE_CLIENT_ID` | All lifecycle workflows | Service principal app ID |
| `AZURE_TENANT_ID` | All lifecycle workflows | Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | All lifecycle workflows | Subscription ID |
| `POSTGRES_SERVER_NAME` | Pause, Resume | `psql-dostar-dev-aue-001` |
| `RESOURCE_GROUP` | Pause, Resume, Tear down | `rg-dostar-dev-aue-001` |
| `AZURE_STATIC_WEB_APPS_API_TOKEN_DEV` | Frontend CD | Auto-refreshed by spin up; set manually after first deploy (see [deploy-setup.md](deploy-setup.md)) |

See [deploy-setup.md](deploy-setup.md) for instructions on creating the service principal and adding these secrets.
