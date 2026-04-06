using './main.bicep'

param workload = 'dostar'
param env = 'prod'
param region = 'aue'
param instance = '001'
param location = 'australiaeast'
param repositoryUrl = 'https://github.com/piers-sinclair/Dostar'
param postgresAdminUsername = 'dostaradmin'
// postgresAdminPassword: fetched directly from Key Vault by Azure at deploy time — never touches the CI runner.
// Fill in the Key Vault details below (or let `dostar new-project` do it via token replacement).
// On first deploy (no Key Vault yet): use infra/scripts/predeploy.sh — it generates and stores the password.
param postgresAdminPassword = getSecret('<subscriptionId>', 'rg-dostar-prod-aue-001', 'kv-dostar-prod-aue-001', 'postgres-admin-password')
