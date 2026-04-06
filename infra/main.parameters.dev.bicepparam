using './main.bicep'

param workload = 'dostar'
param env = 'dev'
param region = 'aue'
param instance = '001'
param location = 'australiaeast'
param repositoryUrl = 'https://github.com/piers-sinclair/Dostar'
param postgresAdminUsername = 'dostaradmin'
// postgresAdminPassword: reads from the POSTGRES_ADMIN_PASSWORD env var at compile time.
// CI sets this to the real secret fetched from Key Vault before running az deployment.
// Locally (what-if validation only) it falls back to the placeholder — never deploy with the placeholder.
param postgresAdminPassword = readEnvironmentVariable('POSTGRES_ADMIN_PASSWORD', 'Placeholder123!')
