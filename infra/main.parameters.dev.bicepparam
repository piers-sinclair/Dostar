using './main.bicep'

param workload = 'dostar'
param env = 'dev'
param region = 'aue'
param instance = '001'
param location = 'australiaeast'
param repositoryUrl = 'https://github.com/piers-sinclair/Dostar'
param postgresAdminUsername = 'dostaradmin'
// postgresAdminPassword: set to a placeholder for local what-if validation only.
// CI overrides this with the real secret from Key Vault. Never use this value in production.
param postgresAdminPassword = 'Placeholder123!'
