targetScope = 'resourceGroup'

@description('Short workload identifier (e.g. dostar).')
param workload string

@description('Deployment environment.')
@allowed(['dev', 'prod'])
param env string

@description('Resource ID of the Container App to monitor.')
param containerAppId string

@description('Resource ID of the action group to notify on alert.')
param actionGroupId string

// 2018-03-01 is the current stable GA API version for metricAlerts — no newer GA version exists.
resource restartAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-restart-${workload}-${env}'
  location: 'global'
  properties: {
    description: '[P1] Container Restart — one or more container restarts detected in 5 minutes. Indicates a crash loop, OOM kill, or failed liveness probe. Check Container App system logs and recent deployments.'
    severity: 0
    enabled: true
    scopes: [containerAppId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          name: 'RestartCount'
          metricName: 'RestartCount'
          metricNamespace: 'Microsoft.App/containerApps'
          operator: 'GreaterThan'
          threshold: 0
          timeAggregation: 'Total'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroupId
      }
    ]
    autoMitigate: true
  }
}
