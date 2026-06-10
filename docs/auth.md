# Authentication

This template ships **without authentication**. The API is open by default. Add your own auth before going to production.

Auth is intentionally left out — the right choice depends on your product, user base, and how much control you want. The table below covers the main options.

| Option | Best for | Setup effort | Cost | Tradeoffs |
|--------|----------|-------------|------|-----------|
| **Azure Entra ID Easy Auth + MSAL** | Internal tools, enterprise apps, Microsoft 365 orgs | Medium — requires an Entra app registration and MSAL wiring in the frontend | Free (Entra included in Azure) | Locks you to Microsoft identity; poor UX for external/consumer users |
| **Auth0** | Consumer or B2B apps needing social login, MFA, passwordless out of the box | Low — managed UI and SDKs for React + .NET | Free tier up to 25k MAU; paid beyond | Adds a third-party dependency and monthly cost at scale |
| **Clerk** | Developer-focused apps wanting a polished pre-built UI | Low — drop-in React components | Free tier up to 10k MAU; paid beyond | Similar to Auth0; less enterprise-focused |
| **ASP.NET Core Identity + JWT** | Full control, no external dependencies | High — implement login, token issuance, refresh yourself | Free | Most work; most flexibility; no SaaS dependency |
