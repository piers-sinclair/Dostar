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

CD jobs use `environment: dev`, which changes the OIDC subject from `ref:refs/heads/main` to `environment:dev`. A separate federated credential is required.

```bash
az ad app federated-credential create \
  --id "$APP_ID" \
  --parameters "{
    \"name\": \"github-environment-dev\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:$REPO:environment:dev\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"
```

This is a one-time manual step. The credential lives on the Azure AD app registration and persists across all teardown/spinup cycles — you will not need to repeat this.

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
| `AZURE_ENTRA_CLIENT_ID` | API app client ID (step 3 below) | Infra workflows |

`AZURE_ENTRA_CLIENT_ID` is set in step 3 — complete that section first.

---

## 3. Create API app registration (ONE-TIME SETUP)

Easy Auth is always enabled on the Container App — every API request must carry a valid Entra Bearer token. This step creates a separate app registration that represents your API (distinct from the CI service principal in section 2).

### 3.1 Create the app registration

```bash
API_APP_ID=$(az ad app create \
  --display-name "$APP_NAME-api" \
  --query appId -o tsv)

API_OBJECT_ID=$(az ad app show --id "$API_APP_ID" --query id -o tsv)
echo "API_APP_ID=$API_APP_ID"
```

### 3.2 Set the Application ID URI

```bash
az ad app update \
  --id "$API_APP_ID" \
  --identifier-uris "api://$API_APP_ID"
```

This is the audience that Easy Auth validates Bearer tokens against.

### 3.3 Expose the `access_as_user` scope

The frontend acquires tokens scoped to `api://<clientId>/access_as_user`. This scope must be declared on the app registration.

```bash
SCOPE_ID=$(openssl rand -hex 16)

az rest --method PATCH \
  --uri "https://graph.microsoft.com/v1.0/applications/$API_OBJECT_ID" \
  --headers "Content-Type=application/json" \
  --body "{
    \"api\": {
      \"oauth2PermissionScopes\": [
        {
          \"id\": \"$SCOPE_ID\",
          \"adminConsentDescription\": \"Allow the frontend to call the API on behalf of the signed-in user.\",
          \"adminConsentDisplayName\": \"Access API as user\",
          \"isEnabled\": true,
          \"type\": \"User\",
          \"userConsentDescription\": \"Allow this app to access the API on your behalf.\",
          \"userConsentDisplayName\": \"Access API\",
          \"value\": \"access_as_user\"
        }
      ]
    }
  }"
```

### 3.4 Add SPA redirect URI for local development

MSAL uses redirect URIs to return auth codes to the frontend. Add `localhost` here for local development — the deployed SWA hostname is set automatically on every spinup by the `infra-spinup` workflow.

```bash
az rest --method PATCH \
  --uri "https://graph.microsoft.com/v1.0/applications/$API_OBJECT_ID" \
  --headers "Content-Type=application/json" \
  --body '{
    "spa": {
      "redirectUris": [
        "http://localhost:5173"
      ]
    }
  }'
```

### 3.5 Grant CI service principal permission to update this app registration

The `infra-spinup` workflow automatically updates the SPA redirect URI after each deploy (since the Azure Static Web App hostname changes on every recreate). For this to work, the CI service principal must be an **owner** of the API app registration and have the `Application.ReadWrite.OwnedBy` Microsoft Graph permission.

```bash
# Get the CI service principal's object ID (the SP created in section 2)
CI_SP_OBJECT_ID=$(az ad sp show --id "$APP_ID" --query id -o tsv)

# Make the CI service principal an owner of the API app registration
az ad app owner add \
  --id "$API_APP_ID" \
  --owner-object-id "$CI_SP_OBJECT_ID"

# Grant Application.ReadWrite.OwnedBy to the CI service principal
# (allows it to update only app registrations it owns)
GRAPH_SP_ID=$(az ad sp show --id 00000003-0000-0000-c000-000000000000 --query id -o tsv)

az rest --method POST \
  --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$CI_SP_OBJECT_ID/appRoleAssignments" \
  --headers "Content-Type=application/json" \
  --body "{
    \"principalId\": \"$CI_SP_OBJECT_ID\",
    \"resourceId\": \"$GRAPH_SP_ID\",
    \"appRoleId\": \"18a4783c-866b-4cc7-a460-3d5e5662c884\"
  }"
```

> `18a4783c-866b-4cc7-a460-3d5e5662c884` is the well-known GUID for the `Application.ReadWrite.OwnedBy` app role in Microsoft Graph. This is a one-time setup — the permission persists and does not need to be re-applied after teardown.

### 3.6 Add GitHub secret

```bash
gh secret set AZURE_ENTRA_CLIENT_ID --body "$API_APP_ID"
```

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
FQDN=$(az containerapp show \
  --name ca-dostar-dev-aue-001 \
  --resource-group rg-dostar-dev-aue-001 \
  --query properties.configuration.ingress.fqdn -o tsv)
```

Check the health endpoint — no token needed (excluded from Easy Auth):

```bash
curl https://$FQDN/healthz/live
```

Call the API — requires a Bearer token:

```bash
TOKEN=$(az account get-access-token \
  --resource "api://$API_APP_ID" \
  --query accessToken -o tsv)

curl -H "Authorization: Bearer $TOKEN" https://$FQDN/api/v1/todos
```

> `[]` = app and DB are healthy. `401` = token missing or invalid. `500` = DB connection problem.
>
> The deployed dev environment runs with `ASPNETCORE_ENVIRONMENT=Development`, so Scalar is available at `https://$FQDN/scalar/v1`. Browse it in a browser after acquiring a Bearer token (Easy Auth applies; see above). It is not available in prod.

Tail logs if something is wrong:

```bash
az containerapp logs show \
  --name ca-dostar-dev-aue-001 \
  --resource-group rg-dostar-dev-aue-001 \
  --follow
```

---

### 4.2 Frontend (Static Web App)

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
