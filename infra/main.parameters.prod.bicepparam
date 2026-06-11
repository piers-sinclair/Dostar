using './main.bicep'

param workload = 'dostar'
param env = 'prod'
param region = 'aue'
param instance = '001'
param location = 'australiaeast'
param postgresAdminUsername = readEnvironmentVariable('AZURE_POSTGRES_ADMIN_USERNAME')
param postgresAdminPassword = readEnvironmentVariable('AZURE_POSTGRES_ADMIN_PASSWORD')

// Container App — scale up from dev defaults for production load
param containerCpu = '1.0'
param containerMemory = '2Gi'
param containerMinReplicas = 1
param containerMaxReplicas = 10

// PostgreSQL — Burstable B2ms keeps costs low (~$65/month) at launch.
// Upgrade to Standard_D* and set postgresEnableHa = true when uptime SLAs require it.
param postgresSkuName = 'Standard_B2ms'

// Alerting — set ALERT_EMAIL_ADDRESS in your CI environment to receive P1 notifications (comma/semicolon-separated for multiple)
param alertEmailAddress = readEnvironmentVariable('ALERT_EMAIL_ADDRESS', '')
