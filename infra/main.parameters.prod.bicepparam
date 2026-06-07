using './main.bicep'

param workload = 'dostar'
// env is omitted — main.bicep defaults to readEnvironmentVariable('AZURE_ENV_NAME', 'dev');
// for prod, set AZURE_ENV_NAME=prod in the azd environment before deploying.
param region = 'aue'
param instance = '001'
param location = 'australiaeast'
param repositoryUrl = 'https://github.com/piers-sinclair/Dostar'
param postgresAdminUsername = 'dostaradmin'
// postgresAdminPassword: fetched directly from Key Vault by Azure at deploy time — never touches the CI runner.
// Fill in the Key Vault details below (or let `dostar new-project` do it via token replacement).
// On first deploy (no Key Vault yet): the CI deploy workflow generates and stores the password (see #23, #157).
param postgresAdminPassword = getSecret('<subscriptionId>', 'rg-dostar-prod-aue-001', 'kv-dostar-prod-aue-001', 'postgres-admin-password')
