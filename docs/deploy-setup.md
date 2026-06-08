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

### 2.8 Retrieve values for GitHub Secrets

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

### 2.9 Add GitHub Secrets

In GitHub:

**Settings → Secrets and variables → Actions**

Add:

| Secret                | Value           |
| --------------------- | --------------- |
| AZURE_CLIENT_ID       | App ID          |
| AZURE_TENANT_ID       | Tenant ID       |
| AZURE_SUBSCRIPTION_ID | Subscription ID |

---

## 3. RBAC Bootstrap (REQUIRED after first deploy)

After first infra deployment:

1. Go to GitHub Actions
2. Run: Bootstrap RBAC (dev)

This assigns required runtime permissions

#### Why this exists?

Azure RBAC permissions like:

- ACR pull
- Key Vault access
- Storage access

Require elevated permissions that should NOT be in Bicep or CI/CD core pipelines.

### Done

GitHub Actions can now authenticate to Azure using OIDC.

No passwords required.

---

## 4. Verifying the deployment

After a successful CD run, confirm the app is up before calling it done.

### 4.1 Backend (Container App)

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

> Note: Scalar (`/scalar/v1`) is dev-only and returns 404 in deployed environments. Use the endpoints above instead.

Tail logs if something is wrong:

```bash
az containerapp logs show \
  --name ca-dostar-dev-aue-001 \
  --resource-group rg-dostar-dev-aue-001 \
  --follow
```

---

### 4.2 Frontend (Static Web App)

Get the hostname:

```bash
az staticwebapp list \
  --resource-group rg-dostar-dev-aue-001 \
  --query "[0].defaultHostname" -o tsv
```

Current dev URL (for reference): `https://zealous-ground-0c1d90b0f.7.azurestaticapps.net`
