# Architecture

## High-level overview

```mermaid
graph LR
    Browser -->|HTTPS| SWA[Azure Static Web Apps\nReact + Vite]
    SWA -->|/api proxy| API[Azure Container App\n.NET 10 Minimal API]
    ACR[Azure Container Registry] -->|AcrPull\nmanaged identity| API
    API -->|EF Core\nprivate VNet| DB[(PostgreSQL\nFlexible Server)]
    API -.-|Key Vault Secrets User\nmanaged identity| KV[Azure Key Vault]
    API -->|OpenTelemetry| APPI[Application Insights]
```

The browser talks only to Static Web Apps. SWA proxies `/api` requests to the Container App — the API is never exposed to the browser directly. The API pulls secrets from Key Vault at runtime via managed identity (no credentials in config). All PostgreSQL traffic stays inside the VNet. GitHub Actions authenticates to Azure via OIDC — no long-lived credentials.

---

## Key security decisions

| Decision | Implementation |
|---|---|
| No long-lived Azure credentials | GitHub Actions authenticates via OIDC federated credentials; no client secrets |
| No secrets in config or env vars | All secrets in Key Vault; app pulls at runtime via managed identity |
| PostgreSQL not publicly accessible | VNet-integrated via delegated subnet; private DNS zone; no public endpoint |
| Image supply chain | CI SP has AcrPush; Container App has AcrPull via managed identity; migration job uses a 1-hour TTL ACR token |
| Infra changes reviewed before merge | `infra/**` path trigger on PRs runs Bicep what-if and posts the diff as a PR comment |

---

## CI/CD pipeline

```mermaid
flowchart TD
    PR[Pull Request] --> CI

    subgraph CI[CI — every PR]
        PT[PR title\nconventional commits]
        TV[Trivy scan\nCVEs in deps + images]
        OG[OpenGrep SAST\ncode patterns]
        WI[Bicep what-if\nif infra/** changed]
        BCI[Backend build & test\nif backend/** changed]
        FCI[Frontend build, lint & UI tests\nif frontend/** changed]
    end

    CI --> Merge[Merge to main]

    Merge -->|every push| RP[release-please]
    Merge --> PathFilter{Changed paths}

    PathFilter -->|backend/** or Dockerfile| CDB[CD — backend\ndeploy to dev]
    PathFilter -->|frontend/**| CDF[CD — frontend\ndeploy to dev]
    PathFilter -->|infra/**| IDeploy[Infra — deploy\nto dev]

    CDB --> MJ2[Run migration job\nephemeral Container Apps Job]
    MJ2 --> BuildPush[Build + push API image\nto ACR]
    BuildPush --> Deploy[Update Container App\nimage]

    RP -.->|if feat or fix commits| ReleasePR[Release PR\nauto-created]
    ReleasePR -->|manual merge| ProdDeploy[CD — deploy to prod]
```

Release-please runs on every push to `main` regardless of which paths changed. It opens or updates a Release PR when `feat:` or `fix:` commits have accumulated since the last release. Prod deploys require manually merging that Release PR. To deploy to prod on demand, go to **Actions → CD — release to prod → Run workflow**.

---

## Spin up / tear down

```mermaid
flowchart LR
    SpinUp[Infra — spin up\nworkflow dispatch] --> ID[infra-deploy\nBicep sub deployment]
    ID --> RBAC[infra-bootstrap-rbac\nAcrPush + AcrPull + KV roles]
    RBAC --> CDB2[cd-backend\nmigrate + build + deploy]
    CDB2 --> CDF2[cd-frontend\nbuild + deploy to SWA]
    CDF2 --> URLs[Print live URLs\nto workflow summary]

    TearDown[Infra — tear down\ntype 'teardown' to confirm] --> RGDelete[az group delete\ncascades all resources]
    RGDelete --> ReSpinUp[Re-run spin up\nto recreate from scratch]
```

Spin up sequences four reusable workflows in order. Tear down deletes the resource group; every resource inside it (Container App, PostgreSQL, Key Vault, Application Insights) is removed automatically. GitHub secrets and the repo are unaffected.

See [environment-lifecycle.md](environment-lifecycle.md) for step-by-step instructions and cost estimates.
