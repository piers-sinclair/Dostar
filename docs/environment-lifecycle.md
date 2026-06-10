# Dev Environment Lifecycle

The dev environment has two states. Tear it down when you won't need it for a while.

---

## Environment states

| State | What's running | Approx. monthly cost | Resume time |
|-------|---------------|---------------------|-------------|
| **Running** | Container App (scales to zero on idle) + PostgreSQL + Static Web App | ~$15–25 | — |
| **Torn down** | All resources deleted | $0 | ~15 min |

> The Container App automatically scales to zero replicas when there is no traffic — no action needed for day-to-day idle time. PostgreSQL continues to run when the environment is up.

---

## Operations

### Spin up (provision from scratch)

Use after a full teardown, or for first-time setup as an alternative to running `infra-deploy`, `infra-bootstrap-rbac`, and the CD workflows manually.

**Prerequisites** — the following GitHub secrets must be set (see [deploy-setup.md](deploy-setup.md)):

| Secret | Value |
|--------|-------|
| `AZURE_CLIENT_ID` | Service principal app ID |
| `AZURE_TENANT_ID` | Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Subscription ID |
| `AZURE_POSTGRES_ADMIN_PASSWORD` | Strong random password for PostgreSQL |

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
- Stores the SWA deployment token in Key Vault (automatically retrieved by the frontend CD workflow)
- Triggers backend and frontend deploy workflows

---

### Tear down

Deletes the entire resource group and all resources inside it. Cost drops to $0 immediately.

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
| `AZURE_POSTGRES_ADMIN_PASSWORD` | Infra deploy/what-if | Strong random password for PostgreSQL |

See [deploy-setup.md](deploy-setup.md) for instructions on creating the service principal and adding these secrets.
