using './main.bicep'

param workload = 'dostar'
// env and location use readEnvironmentVariable so azd pipeline config can map them to CI variables without prompting.
// AZURE_APP_ENV avoids the AZURE_ENV_NAME reserved name; AZURE_LOCATION is set via azd env set.
param env = readEnvironmentVariable('AZURE_APP_ENV', 'dev')
param region = 'aue'
param instance = '001'
param location = readEnvironmentVariable('AZURE_LOCATION', 'australiaeast')
param repositoryUrl = 'https://github.com/piers-sinclair/Dostar'
param postgresAdminUsername = 'dostaradmin'
// postgresAdminPassword: set by infra/scripts/predeploy.sh (reads Key Vault, generates on first deploy).
// Placeholder fallback is used for local `az deployment sub what-if` validation only.
param postgresAdminPassword = readEnvironmentVariable('AZURE_POSTGRES_ADMIN_PASSWORD', 'Placeholder123!')
