# Infrastructure

Dostar uses [Bicep](https://learn.microsoft.com/azure/azure-resource-manager/bicep/overview) to define all Azure infrastructure as code.

---

## Folder structure

```
infra/
  main.bicep                         ← subscription-scoped orchestrator; module calls only
  main.parameters.dev.bicepparam     ← dev environment parameter values
  main.parameters.prod.bicepparam    ← prod environment parameter values
  modules/
    resource-group.bicep             ← resource group
    acr.bicep                        ← Azure Container Registry
    appinsights.bicep                ← Application Insights + Log Analytics Workspace + workbook
    alerting.bicep                   ← alerting orchestrator (prod only)
    alerting/
      action-group.bicep             ← email action group for P1 notifications
      error-rate.bicep               ← KQL alert: API error rate
      latency.bicep                  ← KQL alert: P99 request latency
      db-connectivity.bicep          ← KQL alert: PostgreSQL connectivity failures
      container-restarts.bicep       ← metric alert: container restart count
    container-environment.bicep      ← Container Apps managed environment + diagnostics
    containerapp.bicep               ← Container App (identity, ingress, env vars, probes)
    keyvault.bicep                   ← Key Vault with RBAC
    postgres.bicep                   ← PostgreSQL Flexible Server + private DNS zone
    staticwebapp.bicep               ← Azure Static Web Apps for the React frontend
    vnet.bicep                       ← VNet, subnets, and NSGs for network isolation
```

---

## Overview

| Resource                        | Bicep module                              | Purpose                                            |
| ------------------------------- | ----------------------------------------- | -------------------------------------------------- |
| Resource Group                  | `modules/resource-group.bicep`            | Container for all resources                        |
| Key Vault                       | `modules/keyvault.bicep`                  | Secret management with RBAC                        |
| Virtual Network                 | `modules/vnet.bicep`                      | Network isolation for backend and database         |
| Container Apps Environment      | `modules/container-environment.bicep`     | Managed environment with VNet and diagnostics      |
| Container App                   | `modules/containerapp.bicep`              | Backend API with ingress, identity, and probes     |
| Azure Container Registry        | `modules/acr.bicep`                       | Docker image registry                              |
| PostgreSQL Flexible Server      | `modules/postgres.bicep`                  | Managed PostgreSQL with private networking         |
| Application Insights            | `modules/appinsights.bicep`               | Observability: traces, metrics, workbook dashboard |
| Static Web App                  | `modules/staticwebapp.bicep`              | Hosts the Vite-built React frontend                |
| Alerting (prod only)            | `modules/alerting.bicep`                  | Orchestrates all P1 alert rules                    |

---

## Naming convention

All resources follow the pattern:

```
{abbrev}-{workload}-{env}-{region}-{instance}
```

| Segment    | Description                              | Example  |
| ---------- | ---------------------------------------- | -------- |
| `abbrev`   | Resource type abbreviation (see below)   | `app`    |
| `workload` | Short identifier for the product/project | `dostar` |
| `env`      | Deployment environment                   | `prod`   |
| `region`   | Short Azure region code (see below)      | `aue`    |
| `instance` | Three-digit instance number              | `001`    |

**Full example:** `app-dostar-prod-aue-001`

Each module constructs its own resource names using this pattern as a string interpolation — for example `'ca-${workload}-${env}-${region}-${instance}'` in `containerapp.bicep`.

---

## Resource type abbreviations

Abbreviations follow the [Azure CAF naming conventions](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations).

| Resource type              | Abbreviation |
| -------------------------- | ------------ |
| Resource group             | `rg`         |
| Static Web App             | `stapp`      |
| PostgreSQL Flexible Server | `psql`       |
| Key Vault                  | `kv`         |
| Storage account            | `st`         |
| Log Analytics workspace    | `log`        |
| Application Insights       | `appi`       |
| Container Apps Environment | `cae`        |
| Container App              | `ca`         |
| Container registry         | `cr`         |
| Managed identity           | `id`         |
| Virtual network            | `vnet`       |
| Subnet                     | `snet`       |

---

## Region codes

| Azure region   | Short code |
| -------------- | ---------- |
| Australia East | `aue`      |
| East US        | `eus`      |
| West Europe    | `weu`      |
| Southeast Asia | `sea`      |

Add entries here as new regions are used.

---

## Key Vault

Key Vault is provisioned via `infra/modules/keyvault.bicep`. It uses RBAC authorization (not access policies) and is integrated with managed identity.

**Example name:** `kv-dostar-prod-aue-001`

### Secret naming convention

Secrets stored in Key Vault follow this naming pattern:

```
{env}--{component}--{key}
```

**Full example:** `prod--postgres--admin-password`

### Referencing secrets in Container App settings

Use the Key Vault reference syntax in application settings:

```
@Microsoft.KeyVault(SecretUri=https://kv-dostar-prod-aue-001.vault.azure.net/secrets/prod--postgres--admin-password/)
```

The Container App must have a system-assigned managed identity with the **Key Vault Secrets User** role on the vault.

### RBAC roles

| Role                                                            | Who gets it                    | Purpose                 |
| --------------------------------------------------------------- | ------------------------------ | ----------------------- |
| Key Vault Secrets User (`4633458b-17de-408a-b874-0445c86b69e0`) | Container App managed identity | Read secrets at runtime |

No identity is granted **Key Vault Administrator** or **Key Vault Secrets Officer** by default.

### Environment differences

| Setting                     | dev     | prod                                                     |
| --------------------------- | ------- | -------------------------------------------------------- |
| `enablePurgeProtection`     | `false` | `true`                                                   |
| `softDeleteRetentionInDays` | 90      | 90                                                       |
| `publicNetworkAccess`       | Enabled | Enabled (private endpoint deferred to VNet module — #32) |

---

## Azure Static Web Apps — preview environments

Azure Static Web Apps automatically creates a **preview environment per pull request** — 3 simultaneous preview environments on the Free tier and 10 on the Standard tier. No extra configuration is required beyond the `repositoryUrl` and `branch` parameters already set in the parameter files.

This means every pull request gets an ephemeral frontend environment at no additional cost, making it easy to review UI changes before merging.

---

## Container Apps — scaling

### Default configuration

The `containerapp.bicep` module sets replica limits based on environment:

| Environment | `minReplicas` | `maxReplicas` | Effect                                    |
| ----------- | ------------- | ------------- | ----------------------------------------- |
| dev         | 0             | 3             | Scales to zero when idle — no charge      |
| prod        | 1             | 10            | Always 1 warm replica; scales out on load |

Each replica is allocated **0.5 vCPU / 1 GiB memory** (Consumption plan).

### Changing replica limits

To increase max replicas without redeploying infrastructure:

```bash
az containerapp update \
  --name ca-dostar-prod-aue-001 \
  --resource-group rg-dostar-prod-aue-001 \
  --max-replicas 20
```

### HTTP scaling rule (default, built-in)

ACA's built-in HTTP scaler triggers scale-out at **10 concurrent requests per replica** by default — no explicit rule is needed in the Bicep. To override this threshold, add a `rules` block to the `scale` section in `infra/modules/containerapp.bicep`:

```bicep
scale: {
  minReplicas: 1
  maxReplicas: 10
  rules: [
    {
      name: 'http-scaling'
      http: { metadata: { concurrentRequests: '20' } }
    }
  ]
}
```

### Cost reference

| Scenario                               | Estimated monthly cost                                                     |
| -------------------------------------- | -------------------------------------------------------------------------- |
| Dev (scale-to-zero, Consumption plan)  | $0 when idle; free monthly grants cover light usage                        |
| Prod (min 1 replica, 0.5 vCPU / 1 GiB) | ~$8–12 at low traffic                                                      |
| Each additional replica (scale-out)    | ~$8–12 per replica                                                         |
| Zone-redundant HA (Dedicated plan)     | Significantly higher — evaluate when P99 latency or uptime SLAs require it |

Costs are approximate and vary by region and usage. See [Azure Container Apps pricing](https://azure.microsoft.com/pricing/details/container-apps/) for current rates.

### ASP.NET Core environment and Scalar

`containerapp.bicep` sets `ASPNETCORE_ENVIRONMENT` based on the deployment environment:

| `env` param | `ASPNETCORE_ENVIRONMENT` | Scalar at `/scalar/v1` | Error detail |
|-------------|--------------------------|------------------------|--------------|
| `dev`       | `Development`            | ✓ enabled              | Full stack traces |
| `prod`      | `Production`             | ✗ disabled             | Generic messages |

**Why `Development` in dev?** It enables Scalar at the deployed URL — useful for exploring the live API without running the app locally. It also surfaces full error detail in responses, which speeds up debugging.

**To disable Scalar in the dev environment** (e.g. to test prod-like behaviour), change the value in `infra/modules/containerapp.bicep`:

```bicep
{
  name: 'ASPNETCORE_ENVIRONMENT'
  value: 'Production'   // was: env == 'prod' ? 'Production' : 'Development'
}
```

Or override without redeploying infrastructure:

```bash
az containerapp update \
  --name ca-dostar-dev-aue-001 \
  --resource-group rg-dostar-dev-aue-001 \
  --set-env-vars ASPNETCORE_ENVIRONMENT=Production
```

> Scalar is available in the deployed environment in both modes.

---

### KEDA scalers (advanced)

For queue-driven workloads (e.g. Azure Service Bus, Storage Queue), KEDA scalers let you scale on message backlog rather than HTTP traffic. See the [KEDA scalers documentation](https://keda.sh/docs/scalers/) for available trigger types.

---

### Deploying

```bash
# Generate a postgres password (first deploy only — store it securely afterwards)
PASSWORD=$(openssl rand -base64 32 | tr -d '/+=' | head -c 32)

# Deploy to dev
az deployment sub create \
  --location australiaeast \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.dev.bicepparam \
  --parameters postgresAdminPassword="$PASSWORD"

# Deploy to prod
az deployment sub create \
  --location australiaeast \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.prod.bicepparam \
  --parameters postgresAdminPassword="$PASSWORD"

# Tear down (dev)
az group delete --name rg-dostar-dev-aue-001 --yes
```

---

## PostgreSQL high availability

### Default configuration

| Environment | HA mode  | Protection                                                                        |
| ----------- | -------- | --------------------------------------------------------------------------------- |
| dev         | Disabled | No HA — lowest cost                                                               |
| prod        | SameZone | Standby replica in the same availability zone; automatic failover on node failure |

**Same-zone HA** (prod default) protects against individual node failure within a zone. The standby replica is kept in sync and promoted automatically if the primary fails — no data loss, short failover window (~30–120 seconds).

### Zone-redundant HA upgrade path

**Zone-redundant HA** spreads the primary and standby across separate availability zones, protecting against a full zone outage. It is available on the same Burstable and General Purpose SKUs and is enabled by setting `highAvailability.mode = 'ZoneRedundant'` in `infra/modules/postgres.bicep`.

Roughly doubles the database cost (two servers billed instead of one). Evaluate when:

- Your uptime SLA requires surviving an availability zone failure (e.g. 99.99% SLO)
- RPO/RTO requirements cannot tolerate the risk of same-zone failure

To enable, change the `highAvailability` block in `infra/modules/postgres.bicep`:

```bicep
highAvailability: {
  mode: 'ZoneRedundant'
}
```

---

## Observability

### Application Insights and Log Analytics

Application Insights and a Log Analytics Workspace are provisioned by `infra/modules/appinsights.bicep` in every environment. The backend receives the connection string via the `APPLICATIONINSIGHTS_CONNECTION_STRING` environment variable; when the variable is absent (local dev), all telemetry is silently no-op.

The workbook dashboard at **Application Insights → Workbooks → API Observability** charts request rate, error rate, P95/P99 latency, and database query duration.

Smart Detection (anomaly-based failure detection) is enabled automatically by Application Insights at no extra cost and requires no configuration.

---

### Health check endpoints

The API exposes two health endpoints, both handled by ASP.NET Core's built-in health check middleware:

| Endpoint | Purpose | What runs |
| -------- | ------- | --------- |
| `GET /healthz/live` | Liveness — is the process up? | No checks (always 200 if the app is running) |
| `GET /healthz/ready` | Readiness — is the app ready for traffic? | All registered `IHealthCheck` implementations |

Azure Container Apps is configured with startup, liveness, and readiness probes pointing at these endpoints (`infra/modules/containerapp.bicep`):

| Probe | Path | Period | Failure threshold | Effect on breach |
| ----- | ---- | ------ | ----------------- | ---------------- |
| Startup | `/healthz/live` | 10s | 18 (= 180s max) | Prevents liveness/readiness probes from running during startup |
| Liveness | `/healthz/live` | 30s | 3 (= 90s) | Container is restarted |
| Readiness | `/healthz/ready` | 10s | 3 (= 30s) | Replica removed from load balancer until healthy |

A liveness probe failure (container restart) triggers the **[P1] Container Restart** alert within 5 minutes.

---

### Alerts

All alerts are scoped to **prod only** — dev uses scale-to-zero and is not customer-facing, so alert noise outweighs the signal. Alerts are orchestrated by `infra/modules/alerting.bicep`, with each alert rule in its own module under `infra/modules/alerting/`.

| Alert | Mechanism | Condition | Severity | Action |
| ----- | --------- | --------- | -------- | ------ |
| [P1] High Error Rate | Scheduled query rule (KQL) | Error rate > 10% over 5 min | Critical (0) | Email action group |
| [P1] High P99 Latency | Scheduled query rule (KQL) | P99 > 2000ms over 5 min | Critical (0) | Email action group |
| [P1] Database Connectivity Failure | Scheduled query rule (KQL) | Any failed PostgreSQL dependency in 5 min | Critical (0) | Email action group |
| [P1] Container Restart | Metric alert (native ACA metric) | RestartCount > 0 over 5 min | Critical (0) | Email action group |

Metric alerts (container restart) use `Microsoft.Insights/metricAlerts` — they are lower-latency and simpler than KQL-based `scheduledQueryRules`. KQL rules are used only where no equivalent native metric exists (error rate ratio, P99 percentile, DB dependency filter).

To enable alerting, set the `ALERT_EMAIL_ADDRESS` environment variable in your CI workflow (comma or semicolon-separated for multiple addresses). Leaving it empty skips all alert resources.

#### CPU and memory alerts

CPU and memory metric thresholds depend on the container allocation (`containerCpu` / `containerMemory`) and vary between deployments. Recommended approach: after your first prod deployment, create metric alerts in the Azure Portal targeting `CpuUsageNanoCores` and `MemoryWorkingSetBytes` on the Container App, set to 80% of your allocated values. These are straightforward to add in `infra/modules/alerting.bicep` once you have settled on a fixed resource allocation.

---

### Uptime monitoring

External availability testing (pinging the API from outside Azure) is not provisioned by Bicep. The previous Application Insights multi-region webtest was removed because it generated false positives from distant Azure test nodes.

For external uptime monitoring, [UptimeRobot](https://uptimerobot.com/) (free tier) is a reliable alternative — configure an HTTP monitor against `https://<your-container-app-fqdn>/healthz/live` with a 5-minute check interval.

---

### Alert runbook

**[P1] High Error Rate**
1. Check `AppRequests | where Success == false` in Log Analytics — identify which endpoints are failing and at what rate.
2. Check recent deployments — roll back if a new image was pushed recently.
3. Check `AppExceptions` for stack traces.

**[P1] High P99 Latency**
1. Check `AppRequests | summarize percentile(DurationMs, 99) by Name` — identify slow endpoints.
2. Check `AppDependencies | where Type =~ "postgresql"` for slow queries.
3. Check PostgreSQL metrics in Azure Portal for CPU or I/O saturation.

**[P1] Database Connectivity Failure**
1. Open the PostgreSQL Flexible Server in Azure Portal — check server status and recent metrics.
2. Verify the connection string secret in Key Vault (`prod--postgres--connection-string`) is correct and the Key Vault firewall allows the Container App's managed identity.
3. Check `AppDependencies | where Success == false` for exception details.

**[P1] Container Restart**
1. Open the Container App in Azure Portal → **Revision management** → click the active revision → **Console logs**.
2. Look for OOM kills (`exit code 137`) or application panics.
3. Check recent image pushes — a bad deploy that crashes on startup will produce restart loops.
4. If restarts are ongoing, scale to zero and back (`az containerapp update --min-replicas 0`, then restore).

---

## Validating the template

Use `what-if` to confirm what a deployment would create or change, without actually deploying anything. This is the recommended way to validate Bicep changes before merging a PR.

```bash
# Validate against dev
az deployment sub what-if \
  --location australiaeast \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.dev.bicepparam

# Validate against prod
az deployment sub what-if \
  --location australiaeast \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.prod.bicepparam
```

`az bicep build --file infra/main.bicep` is a local syntax check only — it does not prove the template is deployable against Azure.
