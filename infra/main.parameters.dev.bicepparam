using './main.bicep'

param workload = 'dostar'
param region = 'aue'
param instance = '001'
param location = readEnvironmentVariable('AZURE_LOCATION', 'australiaeast')
param repositoryUrl = 'https://github.com/piers-sinclair/Dostar'
param postgresAdminUsername = readEnvironmentVariable('AZURE_POSTGRES_ADMIN_USERNAME', 'dostaradmin')
param postgresAdminPassword = readEnvironmentVariable('AZURE_POSTGRES_ADMIN_PASSWORD')
param env = readEnvironmentVariable('AZURE_ENV_NAME', 'dev')

// Container App — minimal resources; scale-to-zero keeps dev cost near zero
param containerCpu = '0.5'
param containerMemory = '1Gi'
param containerMinReplicas = 0
param containerMaxReplicas = 1

// PostgreSQL — cheapest burstable SKU and minimum storage for dev
param postgresSkuName = 'Standard_B1ms'
param postgresStorageSizeGB = 32

// Alerting — set ALERT_EMAIL_ADDRESS in your CI environment to receive P1 notifications (comma/semicolon-separated for multiple)
param alertEmailAddress = readEnvironmentVariable('ALERT_EMAIL_ADDRESS', '')
