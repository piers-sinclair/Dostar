# Infrastructure

Dostar uses [Bicep](https://learn.microsoft.com/azure/azure-resource-manager/bicep/overview) to define all Azure infrastructure as code.

---

## Folder structure

```
infra/
  main.bicep                      ← subscription-scoped entry point; orchestrates all modules
  main.parameters.dev.bicepparam  ← dev environment parameter values
  main.parameters.prod.bicepparam ← prod environment parameter values
  modules/
    abbreviations.bicep           ← resource type abbreviation map (CAF conventions)
    keyvault.bicep                ← Key Vault with RBAC and managed identity integration
    staticwebapp.bicep            ← Azure Static Web Apps for the React frontend
    vnet.bicep                    ← VNet and subnets for network isolation
```

---

## Overview

| Resource        | Bicep module                 | Purpose                                |
| --------------- | ---------------------------- | -------------------------------------- |
| Resource Group  | `main.bicep`                 | Container for all resources            |
| Key Vault       | `modules/keyvault.bicep`     | Secret management with RBAC            |
| Virtual Network | `modules/vnet.bicep`         | Network isolation for backend services |
| Static Web App  | `modules/staticwebapp.bicep` | Hosts the Vite-built React frontend    |

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

The convention is implemented as a user-defined function in `infra/main.bicep`:

```bicep
func resourceName(abbr string, workloadName string, environment string, regionCode string, instanceNumber string) string =>
  '${abbr}-${workloadName}-${environment}-${regionCode}-${instanceNumber}'
```

---

## Resource type abbreviations

Abbreviations are defined in `infra/modules/abbreviations.bicep` following the
[Azure CAF naming conventions](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations).

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
