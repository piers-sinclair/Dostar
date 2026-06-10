# Authentication

This template ships **without authentication**. The API is open by default. Add your own auth before going to production.

Auth is intentionally left out of the template because the right choice depends on your product:

| If you need... | Consider |
|---------------|---------|
| Microsoft / Entra-only users (internal tooling, enterprise) | Azure Entra ID Easy Auth + MSAL |
| Social login, passwordless, MFA out of the box | [Auth0](https://auth0.com), [Clerk](https://clerk.com) |
| Auth as part of your Supabase stack | [Supabase Auth](https://supabase.com/docs/guides/auth) |
| Full control, self-hosted | Roll your own JWT with ASP.NET Core Identity |

---

## Option A: Azure Entra ID Easy Auth + MSAL (Azure-native)

This is the best fit if your app is Azure-hosted and your users are in an Entra tenant (e.g. Microsoft 365 orgs, internal tools).

### How it works

- **Easy Auth** runs at the Container App ingress layer — every request without a valid Bearer token gets a `401` before reaching your .NET code. No backend code changes required.
- **MSAL** (`@azure/msal-browser` + `@azure/msal-react`) runs in the React SPA and handles the Entra login redirect and token acquisition.

### Backend (infra)

Add a `Microsoft.App/containerApps/authConfigs` resource to `infra/modules/containerapp.bicep`:

```bicep
resource authConfig 'Microsoft.App/containerApps/authConfigs@2024-03-01' = {
  parent: containerApp
  name: 'current'
  properties: {
    platform: { enabled: true }
    globalValidation: {
      unauthenticatedClientAction: 'Return401'
      excludedPaths: ['/healthz/live', '/healthz/ready', '/scalar', '/scalar/*']
    }
    identityProviders: {
      azureActiveDirectory: {
        enabled: true
        registration: {
          clientId: entraClientId
          openIdIssuer: 'https://sts.windows.net/${subscription().tenantId}/'
        }
        validation: {
          allowedAudiences: ['api://${entraClientId}']
        }
      }
    }
    httpSettings: { requireHttps: true }
  }
}
```

Add a `param entraClientId string` to `containerapp.bicep` and thread it through `main.bicep` + `main.parameters.dev.bicepparam` (reading from an `AZURE_ENTRA_CLIENT_ID` environment variable / GitHub secret).

### Entra app registration (one-time)

```bash
# 1. Create the app registration
API_APP_ID=$(az ad app create --display-name "$APP_NAME-api" --query appId -o tsv)
API_OBJECT_ID=$(az ad app show --id "$API_APP_ID" --query id -o tsv)

# 2. Set the Application ID URI (the audience Easy Auth validates tokens against)
az ad app update --id "$API_APP_ID" --identifier-uris "api://$API_APP_ID"

# 3. Expose the access_as_user scope
SCOPE_ID=$(openssl rand -hex 16)
az rest --method PATCH \
  --uri "https://graph.microsoft.com/v1.0/applications/$API_OBJECT_ID" \
  --headers "Content-Type=application/json" \
  --body "{
    \"api\": {
      \"oauth2PermissionScopes\": [{
        \"id\": \"$SCOPE_ID\",
        \"adminConsentDescription\": \"Allow the frontend to call the API on behalf of the signed-in user.\",
        \"adminConsentDisplayName\": \"Access API as user\",
        \"isEnabled\": true,
        \"type\": \"User\",
        \"value\": \"access_as_user\"
      }]
    }
  }"

# 4. Add SPA redirect URI for local dev
az rest --method PATCH \
  --uri "https://graph.microsoft.com/v1.0/applications/$API_OBJECT_ID" \
  --headers "Content-Type=application/json" \
  --body '{"spa": {"redirectUris": ["http://localhost:5173"]}}'

# 5. Add the deployed SWA hostname as a redirect URI after each spinup
#    (automate this in infra-spinup.yml — see below)

# 6. Store client ID as a GitHub secret
gh secret set AZURE_ENTRA_CLIENT_ID --body "$API_APP_ID"
```

Because the Azure Static Web App hostname changes on every teardown/spinup, automate the redirect URI update in `infra-spinup.yml`:

```yaml
- name: Update Entra SPA redirect URI
  env:
    AZURE_ENTRA_CLIENT_ID: ${{ secrets.AZURE_ENTRA_CLIENT_ID }}
  run: |
    SWA_HOSTNAME=$(az staticwebapp show \
      --name stapp-dostar-dev-aue-001 \
      --resource-group rg-dostar-dev-aue-001 \
      --query defaultHostname -o tsv)
    API_OBJECT_ID=$(az ad app show --id "$AZURE_ENTRA_CLIENT_ID" --query id -o tsv)
    az rest --method PATCH \
      --uri "https://graph.microsoft.com/v1.0/applications/$API_OBJECT_ID" \
      --headers "Content-Type=application/json" \
      --body "{\"spa\": {\"redirectUris\": [\"http://localhost:5173\", \"https://$SWA_HOSTNAME\"]}}"
```

> For this to work, the CI service principal needs `Application.ReadWrite.OwnedBy` and must be an owner of the API app registration. See the Microsoft Graph docs for the `appRoleAssignment` needed.

### Frontend

Install the MSAL packages:

```bash
pnpm add @azure/msal-browser @azure/msal-react
```

Add `VITE_AZURE_CLIENT_ID` and `VITE_AZURE_TENANT_ID` to `frontend/src/vite-env.d.ts`, `.env.example`, and pass them at build time in `cd-frontend.yml`.

Create `frontend/src/lib/auth.ts` to configure `PublicClientApplication` and export a `getAccessToken()` helper. Wrap `main.tsx` with `<MsalProvider>`, add a login redirect in `App.tsx`, and inject `Authorization: Bearer <token>` in `frontend/src/api/client.ts`.

---

## Option B: Third-party auth (Auth0, Clerk, etc.)

These providers handle the login UI, token issuance, and social login out of the box. The general pattern:

1. **Backend**: validate the JWT in your .NET middleware using the provider's JWKS endpoint. Use `Microsoft.AspNetCore.Authentication.JwtBearer` with the provider's authority and audience.
2. **Frontend**: use the provider's React SDK to wrap the app and acquire tokens, then inject them into API requests in `client.ts`.

Refer to each provider's "React + .NET" quickstart for the specifics.
