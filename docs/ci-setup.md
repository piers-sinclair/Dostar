# CI/CD Setup

This guide walks through setting up Azure credentials and GitHub secrets so the CI/CD workflows in `.github/workflows/` can authenticate with Azure using OIDC (no long-lived secrets).

---

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed and signed in (`az login`)
- [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd) installed
- Owner or Contributor + User Access Administrator role on the target Azure subscription
- Admin access to the GitHub repository

---

## Step 1 — Authenticate with Azure

```bash
azd auth login
```

This opens a browser for interactive login. If running in a headless environment, use `azd auth login --use-device-code`.

---

## Step 2 — Create an azd environment

```bash
azd env new <env-name>
```

Use `dev` for a development environment. azd stores this environment's config locally in `.azure/<env-name>/`.

---

## Step 3 — Pre-set your Azure location

Set the location before running the pipeline config so azd stores the value and can pass it to GitHub without prompting:

```bash
azd env set AZURE_LOCATION australiaeast
```

> **Deploying outside Australia?** Replace `australiaeast` with your Azure region identifier (no spaces or hyphens, e.g. `eastus`, `westeurope`, `southeastasia`). Also update `location` and `region` in `infra/main.parameters.dev.bicepparam` to match.

---

## Step 4 — Configure the pipeline (OIDC + GitHub secrets)

```bash
azd pipeline config --provider github
```

The command prompts for only two values:

| Prompt | Value | Notes |
|--------|-------|-------|
| `env` | `dev` or `prod` | Must be explicit — controls which environment tier is provisioned |
| `postgresAdminPassword` | A strong password of your choice | Stored as a GitHub secret; used to create the PostgreSQL server |

When prompted for auth type, select **Federated service principal** (OIDC — no long-lived secrets).

This command:

1. Creates an Azure AD app registration and service principal
2. Configures OIDC federated credentials for the `main` branch and pull requests
3. Adds the following secrets to your GitHub repository automatically:
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`
   - `AZURE_ENV_NAME`
   - `AZURE_LOCATION`
   - `AZURE_POSTGRESADMINPASSWORD` (the password you entered above)

After this step the `infra-whatif.yml` workflow will authenticate successfully and `deploy-dev.yml` will be able to provision and deploy.

---

## Step 5 — Add deployment secrets (manual)

`azd pipeline config` does not set the following secrets — add them manually under **Settings → Secrets and variables → Actions** in your GitHub repository.

### Dev environment

| Secret | Description | Where to find it |
|--------|-------------|------------------|
| `RESOURCE_GROUP` | Dev resource group name (e.g. `rg-dostar-dev-aue-001`) | `az group list` after first deploy |
| `POSTGRES_SERVER_NAME` | PostgreSQL server name (e.g. `psql-dostar-dev-aue-001`) | `az postgres flexible-server list` after first deploy |

### Production environment

| Secret | Description | Where to find it |
|--------|-------------|------------------|
| `RESOURCE_GROUP_PROD` | Prod resource group name (e.g. `rg-dostar-prod-aue-001`) | `az group list` after first prod deploy |
| `CONTAINER_APP_NAME_PROD` | Container App name (e.g. `ca-dostar-prod-aue-001`) | `az containerapp list` after first prod deploy |
| `ACR_LOGIN_SERVER` | ACR login server (e.g. `crDostarProdAue001.azurecr.io`) | `az acr list --query "[].loginServer"` |

---

## Step 6 — Configure the production GitHub Environment

The `deploy-production.yml` workflow uses a GitHub Environment called `production` to enforce a manual approval gate before deploying.

1. Go to **Settings → Environments** in your GitHub repository
2. Click **New environment** and name it `production`
3. Under **Deployment protection rules**, add required reviewers (at least one person who must approve production deploys)
4. Under **Deployment branches and tags**, restrict to `main` only

---

## Verifying the setup

Open a PR that touches a file under `infra/` — the `infra-whatif.yml` workflow should trigger and post a Bicep what-if summary as a PR comment.

---

## Rotating credentials

OIDC federated credentials do not expire. If you need to rotate for any reason:

1. Delete the existing app registration in Azure AD
2. Re-run `azd pipeline config --provider github`

---

## Troubleshooting

### "Missing required secrets: AZURE_CLIENT_ID ..."

One or more OIDC secrets are not configured. Return to Step 4 and run `azd pipeline config`.

### "azure/login failed"

The OIDC federated credential may not trust the current branch or pull request context. Verify that `azd pipeline config` created federated credentials for both branch pushes and pull requests:

```bash
az ad app federated-credential list --id <app-id>
```

### Service principal lacks permissions

Check that the service principal has Contributor role at the subscription scope:

```bash
az role assignment list --assignee <client-id> --scope /subscriptions/<subscription-id>
```
