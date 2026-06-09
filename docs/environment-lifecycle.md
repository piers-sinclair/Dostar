# Dev Environment Lifecycle

The dev environment has two states. Tear it down when you won't need it for a while.

---

## Environment states

| State | What's running | Approx. monthly cost | Resume time |
|-------|---------------|---------------------|-------------|
| **Running** | Container App (scales to zero on idle) + PostgreSQL + Static Web App | ~$15–25 | — |
| **Paused** | PostgreSQL stopped; Container App scales to zero | ~$3–5 (SWA + storage) | ~3–5 min |
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

### Pause (preserve data)

Use pause when you need a short break but want to keep the dev database and its data. Pause stops the PostgreSQL Flexible Server (~$12/month compute savings) while preserving all data. The Container App scales to zero automatically.

**Additional secrets required** (add in repo Settings → Secrets and variables → Actions):

| Secret | Example value |
|--------|---------------|
| `POSTGRES_SERVER_NAME` | `psql-dostar-dev-aue-001` |
| `RESOURCE_GROUP` | `rg-dostar-dev-aue-001` |

**Steps:**

1. Go to **GitHub Actions** → **Dev — pause** → **Run workflow**
2. Set `confirm` to `yes`
3. PostgreSQL stops; database state is preserved

To bring the environment back, see **Resume** below.

---

### Resume

Starts a paused environment — starts PostgreSQL, waits until ready, then redeploys the latest backend and frontend.

**Steps:**

1. Go to **GitHub Actions** → **Dev — resume** → **Run workflow**
2. Set `confirm` to `yes`
3. Wait ~3–5 minutes for PostgreSQL to reach Ready state and apps to redeploy

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
| `POSTGRES_SERVER_NAME` | Pause / Resume | PostgreSQL Flexible Server name (e.g. `psql-dostar-dev-aue-001`) |
| `RESOURCE_GROUP` | Pause / Resume | Resource group name (e.g. `rg-dostar-dev-aue-001`) |

See [deploy-setup.md](deploy-setup.md) for instructions on creating the service principal and adding these secrets.
