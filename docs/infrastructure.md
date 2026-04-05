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

| Resource | Bicep module | Purpose |
|----------|-------------|---------|
| Resource Group | `main.bicep` | Container for all resources |
| Key Vault | `modules/keyvault.bicep` | Secret management with RBAC |
| Virtual Network | `modules/vnet.bicep` | Network isolation for backend services |
| Static Web App | `modules/staticwebapp.bicep` | Hosts the Vite-built React frontend |

---

## Naming convention

All resources follow the pattern:

```
{abbrev}-{workload}-{env}-{region}-{instance}
```

| Segment | Description | Example |
|---------|-------------|---------|
| `abbrev` | Resource type abbreviation (see below) | `app` |
| `workload` | Short identifier for the product/project | `dostar` |
| `env` | Deployment environment | `prod` |
| `region` | Short Azure region code (see below) | `aue` |
| `instance` | Three-digit instance number | `001` |

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

| Resource type | Abbreviation |
|---------------|--------------|
| Resource group | `rg` |
| Static Web App | `stapp` |
| PostgreSQL Flexible Server | `psql` |
| Key Vault | `kv` |
| Storage account | `st` |
| Log Analytics workspace | `log` |
| Application Insights | `appi` |
| Container Apps Environment | `cae` |
| Container App | `ca` |
| Container registry | `cr` |
| Managed identity | `id` |
| Virtual network | `vnet` |
| Subnet | `snet` |

---

## Region codes

| Azure region | Short code |
|--------------|------------|
| Australia East | `aue` |
| East US | `eus` |
| West Europe | `weu` |
| Southeast Asia | `sea` |

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

| Role | Who gets it | Purpose |
|------|-------------|---------|
| Key Vault Secrets User (`4633458b-17de-408a-b874-0445c86b69e0`) | Container App managed identity | Read secrets at runtime |

No identity is granted **Key Vault Administrator** or **Key Vault Secrets Officer** by default.

### Environment differences

| Setting | dev | prod |
|---------|-----|------|
| `enablePurgeProtection` | `false` | `true` |
| `softDeleteRetentionInDays` | 90 | 90 |
| `publicNetworkAccess` | Enabled | Enabled (private endpoint deferred to VNet module — #32) |

---

## Azure Static Web Apps — preview environments

Azure Static Web Apps automatically creates a **preview environment per pull request** — 3 simultaneous preview environments on the Free tier and 10 on the Standard tier. No extra configuration is required beyond the `repositoryUrl` and `branch` parameters already set in the parameter files.

This means every pull request gets an ephemeral frontend environment at no additional cost, making it easy to review UI changes before merging.

---

## Deploying

```bash
# Deploy to dev
az deployment sub create \
  --location australiaeast \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.dev.bicepparam

# Deploy to prod
az deployment sub create \
  --location australiaeast \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.prod.bicepparam
```

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
