using './main.bicep'

param workload = 'dostar'
param region = 'aue'
param instance = '001'
param location = readEnvironmentVariable('AZURE_LOCATION', 'australiaeast')
param repositoryUrl = 'https://github.com/piers-sinclair/Dostar'
param postgresAdminUsername = 'dostaradmin'
param postgresAdminPassword = readEnvironmentVariable('AZURE_POSTGRES_ADMIN_PASSWORD')
param env = readEnvironmentVariable('AZURE_ENV_NAME', 'dev')
