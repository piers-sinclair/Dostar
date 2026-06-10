using './main.bicep'

param workload = 'dostar'
param env = 'prod'
param region = 'aue'
param instance = '001'
param location = 'australiaeast'
param repositoryUrl = 'https://github.com/piers-sinclair/Dostar'
param postgresAdminUsername = 'dostaradmin'
param postgresAdminPassword = readEnvironmentVariable('AZURE_POSTGRES_ADMIN_PASSWORD')

// Container App — scale up from dev defaults for production load
param containerCpu = '1.0'
param containerMemory = '2Gi'
param containerMinReplicas = 1
param containerMaxReplicas = 10

// PostgreSQL — larger SKU and storage for production
param postgresSkuName = 'Standard_B2ms'
param postgresStorageSizeGB = 64
