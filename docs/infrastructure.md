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
```

---

## Naming convention

All resources follow the pattern:

```
{abbrev}-{workload}-{env}-{region}-{instance}
```

| Segment    | Description                              | Example   |
|------------|------------------------------------------|-----------|
| `abbrev`   | Resource type abbreviation (see below)   | `app`     |
| `workload` | Short identifier for the product/project | `dostar`  |
| `env`      | Deployment environment                   | `prod`    |
| `region`   | Short Azure region code (see below)      | `aue`     |
| `instance` | Three-digit instance number              | `001`     |

**Full example:** `app-dostar-prod-aue-001`

The convention is implemented as a user-defined function in `infra/main.bicep`:

```bicep
func resourceName(abbrev string, workloadName string, environment string, regionCode string, instanceNumber string) string =>
  '${abbrev}-${workloadName}-${environment}-${regionCode}-${instanceNumber}'
```

---

## Resource type abbreviations

Abbreviations are defined in `infra/modules/abbreviations.bicep` following the
[Azure CAF naming conventions](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations).

| Resource type                | Abbreviation |
|------------------------------|--------------|
| Resource group               | `rg`         |
| App Service plan             | `asp`        |
| App Service (web app)        | `app`        |
| Static Web App               | `stapp`      |
| PostgreSQL Flexible Server   | `psql`       |
| Key Vault                    | `kv`         |
| Storage account              | `st`         |
| Log Analytics workspace      | `log`        |
| Application Insights         | `appi`       |
| Container registry           | `cr`         |
| Managed identity             | `id`         |
| Virtual network              | `vnet`       |
| Subnet                       | `snet`       |

---

## Region codes

| Azure region     | Short code |
|------------------|------------|
| Australia East   | `aue`      |
| East US          | `eus`      |
| West Europe      | `weu`      |
| Southeast Asia   | `sea`      |

Add entries here as new regions are used.

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

```bash
az bicep build --file infra/main.bicep
```
