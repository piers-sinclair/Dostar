# CI/CD Setup (GitHub Actions + Bicep + OIDC)

This repository uses **GitHub Actions + Azure OIDC (no secrets passwords)** to automatically:

- Deploy infrastructure (Bicep)
- Deploy applications (API + Web)
- Run Bicep what-if on pull requests
- Automatically deploy changes when infra or app code changes

---

# 1. Prerequisites

You must have:

## Azure
- Azure Subscription
- Owner or User Access Administrator (first-time setup only)
- Ability to create App Registrations + RBAC roles

## GitHub
- Admin access to repository
- Ability to create:
  - Repository Secrets
  - Repository Variables (optional)
  - Environments (recommended)

## Local tools (for initial setup only)
- Azure CLI
- GitHub CLI (`gh`)
- Logged in:
  ```bash
  az login
  gh auth login

2. One-time Azure OIDC Setup (IMPORTANT)

Run this once to create the GitHub → Azure trust relationship:

az ad sp create-for-rbac \
  --name "dostar-github-actions" \
  --role Contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID>

Then configure federated credentials (recommended approach is via Azure Portal OR az cli + manifest).

You need:

AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID

3. Add GitHub Secrets

Go to:

GitHub Repo → Settings → Secrets and variables → Actions

Add:

Required Secrets
Name	Value
AZURE_CLIENT_ID	from service principal
AZURE_TENANT_ID	from Azure tenant
AZURE_SUBSCRIPTION_ID	from Azure subscription

4. Add GitHub Variables (optional but recommended)

Go to:

Settings → Secrets and variables → Actions → Variables

Name	Value
AZURE_ENV_NAME	dev
AZURE_LOCATION	australiaeast

5. Repository Structure (Required)
/infra
  main.bicep
  main.parameters.dev.bicepparam

/backend
/frontend

.github/workflows
  infra-whatif.yml
  infra-deploy.yml
  deploy-dev.yml
6. Infrastructure Pipeline (WHAT-IF)

Runs on every PR affecting infra:

on:
  pull_request:
    paths:
      - infra/**
Behaviour
Runs az deployment sub what-if
Posts results to PR
No changes applied

7. Infrastructure Deployment Pipeline (AUTO APPLY)

This is the key automation piece.

Create: .github/workflows/infra-deploy.yml

name: Infra — deploy

on:
  push:
    branches: [main]
    paths:
      - infra/**

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Azure login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Deploy Bicep
        run: |
          az deployment sub create \
            --location australiaeast \
            --template-file infra/main.bicep \
            --parameters infra/main.parameters.dev.bicepparam

8. Application Deployment Pipeline

Create: .github/workflows/app-deploy.yml

name: App — deploy

on:
  push:
    branches: [main]
    paths:
      - backend/**
      - frontend/**

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Azure login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Deploy API
        run: |
          az containerapp up ...

      - name: Deploy Web
        run: |
          az staticwebapp deploy ...

(Replace with your actual deployment commands.)

9. Recommended Production Promotion Strategy

Use GitHub Environments:

Create environment

GitHub → Settings → Environments → production

Add:

Required reviewers
Restrict to main

Then modify infra/app workflows:

environment: production

This forces manual approval for production deploys.

10. Infra + App Flow (FINAL BEHAVIOUR)
Pull Request
Runs:
infra what-if
optional build/test
Merge to main

Triggers:

1. infra deploy
applies Bicep changes
2. app deploy
deploys API + web

Order is important:

Infra first, then app

11. Common Issues
Missing secrets
Missing required secrets: AZURE_CLIENT_ID

→ Add GitHub secrets

OIDC login fails
Federated credential not created correctly
Wrong repo or branch subject
Deployment fails with missing parameters
Ensure Bicep defaults exist OR parameters file is complete
Permission denied on scripts
/bin/sh: permission denied

Fix:

chmod +x infra/scripts/*.sh
git update-index --chmod=+x infra/scripts/predeploy.sh
12. Design Philosophy

This template is intentionally:

No Azure DevOps
No azd pipeline dependency
No long-lived secrets
GitHub Actions only
Fully declarative infra (Bicep)
Event-driven deployments

13. Summary

To onboard a new team:

Add Azure OIDC credentials
Add GitHub secrets
Push to main
Infra + app deploy automatically
PRs show infra diff (what-if)

That’s it.
