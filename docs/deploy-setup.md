# CI/CD Setup (GitHub Actions + Bicep + OIDC)

This repository deploys:

- Infrastructure via Bicep
- Application (API + Web)
- Using GitHub Actions + Azure OIDC (no passwords / no client secrets)

---

# 0. What you get

After setup:

- Push to `main` → infra + app deploy automatically
- PR → infra what-if runs
- No long-lived Azure secrets
- Fully automated deployments

---

# 1. Prerequisites

## Required access

- Azure Subscription Owner (first time only)
- GitHub repo admin access

## Required tools (local machine once only)

- Azure CLI
- GitHub CLI

Login:

```bash
az login
gh auth login
```

---

## 2. Create Azure Identity (ONE-TIME SETUP)

This step creates the Azure identity that GitHub Actions will use via OIDC (no passwords).

---

### 2.1 Set variables

export these before running:

```bash
export SUBSCRIPTION_ID="<your-subscription-id>"
export REPO="<YOUR_GITHUB_ORG/YOUR_REPO>"
export APP_NAME="<YOUR_APP_NAME>"

```

---

### 2.2 Create App Registration

```bash
APP_ID=$(az ad app create \
  --display-name "$APP_NAME" \
  --query appId -o tsv)

echo "APP_ID=$APP_ID"
```

---

### 2.3 Create Service Principal

```bash
az ad sp create --id "$APP_ID"
```

---

### 2.4 Assign Azure RBAC permissions

This allows deployments to your subscription.

```bash
az role assignment create \
  --assignee "$APP_ID" \
  --role Contributor \
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

---

### 2.5 Grant role-assignment permissions

This allows the GitHub Actions identity to create Azure RBAC role assignments (required by the Bootstrap RBAC workflow). Can be scoped to a resource group instead for least-privilege.

```bash
az role assignment create \
  --assignee "$APP_ID" \
  --role "User Access Administrator" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

---

### 2.6 Create GitHub OIDC trust (MAIN BRANCH)

This allows GitHub Actions to authenticate securely.

```bash
az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters "{
    \"name\": \"github-main\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:$REPO:ref:refs/heads/main\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"
```

---

### 2.7 Allow Pull Request deployments

```bash
az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters "{
    \"name\": \"github-pr\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:$REPO:pull_request\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"
```

---

### 2.8 Allow environment deployments

CD and infra jobs use `environment: dev` / `environment: prod`, which changes the OIDC subject from `ref:refs/heads/main` to `environment:<name>`. A separate federated credential is required for each environment name.

```bash
az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters "{
    \"name\": \"github-environment-dev\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:$REPO:environment:dev\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"

az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters "{
    \"name\": \"github-environment-prod\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:$REPO:environment:prod\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"
```

These are one-time manual steps. The credentials live on the Azure AD app registration and persist across all teardown/spinup cycles — you will not need to repeat them. If you add more GitHub environments in future, add a matching federated credential here.

---

### 2.9 Retrieve values for GitHub Secrets

Run:

```bash
az account show --query tenantId -o tsv
az account show --query id -o tsv
```

And use:

- APP_ID → `AZURE_CLIENT_ID`
- tenantId → `AZURE_TENANT_ID`
- subscriptionId → `AZURE_SUBSCRIPTION_ID`

---

### 2.10 Generate a Postgres password

Generate a strong random password and add it as a GitHub secret. You will never need to type it manually.

```bash
POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d '/+=')
gh secret set AZURE_POSTGRES_ADMIN_PASSWORD --body "$POSTGRES_PASSWORD"
```

---

### 2.11 Add remaining GitHub secrets

```bash
gh secret set AZURE_CLIENT_ID       --body "$APP_ID"
gh secret set AZURE_TENANT_ID       --body "$(az account show --query tenantId -o tsv)"
gh secret set AZURE_SUBSCRIPTION_ID --body "$(az account show --query id -o tsv)"
```

Or via the GitHub UI (**Settings → Secrets and variables → Actions**):

| Secret | Value | Required by |
| ------ | ----- | ----------- |
| `AZURE_CLIENT_ID` | App ID from step 2.2 | All workflows |
| `AZURE_TENANT_ID` | Tenant ID | All workflows |
| `AZURE_SUBSCRIPTION_ID` | Subscription ID | All workflows |
| `AZURE_POSTGRES_ADMIN_PASSWORD` | Generated in step 2.10 | Infra workflows |

---

## 3. Enable GitHub Actions PR creation (ONE-TIME SETUP)

Release Please needs permission to open pull requests from the Actions bot. GitHub disables this by default.

1. Go to **Settings → Actions → General** in your GitHub repo.
2. Under **Workflow permissions**, check **"Allow GitHub Actions to create and approve pull requests"**.
3. Save.

Without this, the `release-please` workflow will fail with _"GitHub Actions is not permitted to create or approve pull requests"_ when it tries to open a release PR.

---

## 4. Post-infra setup (REQUIRED after first deploy)

Run the infra deploy workflow first (`infra-deploy`), then complete these steps.

### 4.1 Run Bootstrap RBAC

Go to GitHub Actions → run **Bootstrap RBAC (dev)**.

This grants the Container App managed identity `AcrPull` and `Key Vault Secrets User` so it can pull images and read the database connection string, and grants the CI service principal `Key Vault Secrets User` so the frontend deploy workflow reads the SWA deployment token directly from Key Vault.

#### Why this exists?

Role assignments (ACR pull, Key Vault access) require elevated permissions that should not be embedded in Bicep or the core CI/CD pipelines.

### Done

GitHub Actions can now authenticate to Azure using OIDC. The frontend deploy workflow reads the SWA deployment token directly from Key Vault — no manual secret management required.

No passwords or manually-managed tokens required.

---

## 5. Verifying the deployment

After a successful CD run, confirm the app is up before calling it done.

### 5.1 Backend (Container App)

Get the FQDN:

```bash
az containerapp show \
  --name ca-dostar-dev-aue-001 \
  --resource-group rg-dostar-dev-aue-001 \
  --query properties.configuration.ingress.fqdn -o tsv
```

Check the health endpoint (HTTP 200 = app is up):

```bash
curl https://<FQDN>/healthz/live
```

Smoke-test the API (empty array `[]` = app + DB healthy; HTTP 500 = DB connection problem):

```bash
curl https://<FQDN>/api/v1/todos
```

> The deployed dev environment runs with `ASPNETCORE_ENVIRONMENT=Development`, so Scalar is available at `https://<FQDN>/scalar/v1`. Browse it in a browser. It is not available in prod.

Tail logs if something is wrong:

```bash
az containerapp logs show \
  --name ca-dostar-dev-aue-001 \
  --resource-group rg-dostar-dev-aue-001 \
  --follow
```

---

### 5.2 Frontend (Static Web App)

The `cd-frontend` workflow deploys automatically on pushes to `main` that touch `frontend/**`. To trigger an initial deploy manually, go to GitHub Actions → **CD — deploy frontend** → Run workflow.

Get the hostname:

```bash
az staticwebapp list \
  --resource-group rg-dostar-dev-aue-001 \
  --query "[0].defaultHostname" -o tsv
```

Open the URL in a browser — it should show the React app. If it shows the Azure placeholder page, the frontend workflow has not run yet.

---

## 6. Managing the dev environment lifecycle

Once the environment is running, see [environment-lifecycle.md](environment-lifecycle.md) for how to pause, resume, or tear down the dev environment to manage running costs.
