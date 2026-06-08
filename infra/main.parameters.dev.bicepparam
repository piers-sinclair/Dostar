using './main.bicep'

param workload = 'dostar'
// env is omitted — main.bicep defaults it to readEnvironmentVariable('AZURE_ENV_NAME', 'dev'),
// which azd always provides. Explicit value is only needed to override (e.g. testing prod locally).
param region = 'aue'
param instance = '001'
param location = readEnvironmentVariable('AZURE_LOCATION', 'australiaeast')
param repositoryUrl = 'https://github.com/piers-sinclair/Dostar'
param postgresAdminUsername = 'dostaradmin'
param postgresAdminPassword = readEnvironmentVariable('AZURE_POSTGRES_ADMIN_PASSWORD', 'Placeholder123!')
param env = readEnvironmentVariable('AZURE_ENV_NAME', 'dev')
