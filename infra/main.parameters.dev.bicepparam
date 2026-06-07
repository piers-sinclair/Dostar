using './main.bicep'

param workload = 'dostar'
param env = 'dev'
param region = 'aue'
param instance = '001'
param location = 'australiaeast'
param repositoryUrl = 'https://github.com/piers-sinclair/Dostar'
param postgresAdminUsername = 'dostaradmin'
// postgresAdminPassword: read from AZURE_POSTGRES_ADMIN_PASSWORD env var (set by infra/scripts/predeploy.sh hook).
// Falls back to a placeholder for local `az deployment sub what-if` validation only — never used in real deploys.
param postgresAdminPassword = readEnvironmentVariable('AZURE_POSTGRES_ADMIN_PASSWORD', 'Placeholder123!')
