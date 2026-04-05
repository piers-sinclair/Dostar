# Infrastructure

Dostar's cloud infrastructure is defined as code using [Bicep](https://learn.microsoft.com/azure/azure-resource-manager/bicep/overview) under the `infra/` directory.

## Overview

| Resource | Bicep module | Purpose |
|----------|-------------|---------|
| Resource Group | `main.bicep` | Container for all resources |
| Virtual Network | `modules/vnet.bicep` | Network isolation for backend services |
| Static Web App | `modules/staticwebapp.bicep` | Hosts the Vite-built React frontend |

## Naming convention

All resources follow the pattern `{abbrev}-{workload}-{env}-{region}-{instance}`, for example `stapp-dostar-prod-aue-001`. Abbreviations follow the [Azure Cloud Adoption Framework](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations) conventions and are listed in `infra/modules/abbreviations.bicep`.

## Azure Static Web Apps — preview environments

Azure Static Web Apps automatically creates a **preview environment per pull request** — 3 simultaneous preview environments on the Free tier and 10 on the Standard tier. No extra configuration is required beyond the `repositoryUrl` and `branch` parameters already set in the parameter files.

This means every pull request gets an ephemeral frontend environment at no additional cost, making it easy to review UI changes before merging.

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
