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

### 2.5 Create GitHub OIDC trust (MAIN BRANCH)

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

### 2.6 (Optional) Allow Pull Request deployments

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

### 2.7 Retrieve values for GitHub Secrets

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

### 2.8 Add GitHub Secrets

In GitHub:

**Settings → Secrets and variables → Actions**

Add:

| Secret                | Value           |
| --------------------- | --------------- |
| AZURE_CLIENT_ID       | App ID          |
| AZURE_TENANT_ID       | Tenant ID       |
| AZURE_SUBSCRIPTION_ID | Subscription ID |

---

### Done

GitHub Actions can now authenticate to Azure using OIDC.

No passwords required.
