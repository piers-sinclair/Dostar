targetScope = 'resourceGroup'

@description('Azure region used for this resource.')
param location string

@description('Resource ID of the Application Insights component this workbook is pinned to.')
param appInsightsId string

var workbookContent = '''
{
  "version": "Notebook/1.0",
  "items": [
    {
      "type": 1,
      "content": {
        "json": "## API Observability Dashboard\n\nKey production metrics: request rate, error rate, P95/P99 latency, and database query duration. All charts show the last hour."
      },
      "name": "text-header"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "requests\n| where timestamp > ago(1h)\n| summarize RequestsPerMinute = count() by bin(timestamp, 1m)\n| render timechart",
        "queryType": 0,
        "resourceType": "microsoft.insights/components",
        "visualization": "timechart",
        "title": "Request Rate (per minute)"
      },
      "customWidth": "50",
      "name": "query-request-rate"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "requests\n| where timestamp > ago(1h)\n| summarize Total = count(), Failed = countif(success == false) by bin(timestamp, 1m)\n| extend ErrorRatePct = iff(Total > 0, Failed * 100.0 / Total, 0.0)\n| project timestamp, ErrorRatePct\n| render timechart",
        "queryType": 0,
        "resourceType": "microsoft.insights/components",
        "visualization": "timechart",
        "title": "Error Rate (%)"
      },
      "customWidth": "50",
      "name": "query-error-rate"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "requests\n| where timestamp > ago(1h)\n| summarize P95 = percentile(duration, 95), P99 = percentile(duration, 99) by bin(timestamp, 5m)\n| render timechart",
        "queryType": 0,
        "resourceType": "microsoft.insights/components",
        "visualization": "timechart",
        "title": "Request Latency P95/P99 (ms)"
      },
      "customWidth": "50",
      "name": "query-latency"
    },
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "dependencies\n| where timestamp > ago(1h)\n| where type == \"SQL\"\n| summarize AvgDuration = avg(duration), P95Duration = percentile(duration, 95) by bin(timestamp, 5m)\n| render timechart",
        "queryType": 0,
        "resourceType": "microsoft.insights/components",
        "visualization": "timechart",
        "title": "Database Query Duration (ms)"
      },
      "customWidth": "50",
      "name": "query-db-duration"
    }
  ],
  "$schema": "https://github.com/Microsoft/Application-Insights-Workbooks/blob/master/schema/workbook.json"
}
'''

resource workbook 'microsoft.insights/workbooks@2023-06-01' = {
  name: guid(resourceGroup().id, 'api-observability-dashboard')
  location: location
  kind: 'shared'
  properties: {
    displayName: 'API Observability'
    category: 'workbook'
    sourceId: appInsightsId
    serializedData: workbookContent
  }
}
