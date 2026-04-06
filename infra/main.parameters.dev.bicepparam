using './main.bicep'

param workload = 'dostar'
param env = 'dev'
param region = 'aue'
param instance = '001'
param location = 'australiaeast'
param repositoryUrl = 'https://github.com/piers-sinclair/Dostar'
param postgresAdminUsername = 'dostaradmin'
// postgresAdminPassword: placeholder for local what-if validation ONLY.
// NEVER run `az deployment sub create` with this file — use infra/scripts/predeploy.sh instead.
param postgresAdminPassword = 'Placeholder123!'
