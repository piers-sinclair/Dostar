using './main.bicep'

param workload = 'dostar'
param env = 'prod'
param region = 'aue'
param instance = '001'
param location = 'australiaeast'
param repositoryUrl = 'https://github.com/piers-sinclair/Dostar'
param postgresAdminUsername = 'dostaradmin'
// postgresAdminPassword is intentionally omitted — it is supplied by the CI workflow.
// The deploy workflow reads the existing password from Key Vault on subsequent deploys,
// or generates a new one on first deploy. Never hardcode this value here.
