function New-OpsGenieExpiryAlert {
    <#
    .SYNOPSIS
    Creates an Ops Genie Key Vault expiry alert.
    
    .DESCRIPTION
    Creates an Ops Genie Key Vault expiry alert based on the Event Grid event(s).
    
    .PARAMETER WebHook
    WebHook of the OpsGenie Azure integration.
    
    .PARAMETER ResourceId
    Event Grid powershell object topic property.
    
    .PARAMETER SubjectData
    Event Grid powershell object data property.
    
    .PARAMETER EventType
    Event Grid powershell object eventType property.
    
    .PARAMETER EventTime
    Event Grid powershell object eventTime property.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$WebHook,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceId,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [object]$SubjectData,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$EventType,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$EventTime
    )
    process {
        $now = [datetime]::UtcNow
        $eventExpiry = [System.DateTimeOffset]::FromUnixTimeSeconds($SubjectData.EXP).UtcDateTime
        $universalDateTimeFormat = Get-Date -Date $EventTime -Format 'FileDateTimeUniversal'
        $resourceName = $ResourceId.Split('/')[-1]
        $resourceGroup = $ResourceId.Split('/')[4]
        $subscriptionId = $ResourceId.Split('/')[2]
        switch -Wildcard ($EventType) {
            '*NearExpiry' {
                $severity = 3
            }
            '*Expired' {
                $severity = 1
            }
        }
        $alertObject = @{
            schemaId = 'AzureMonitorMetricAlert'
            data     = @{
                version    = '2.0'
                properties = $null
                status     = 'Activated'
                context    = @{
                    timestamp         = $universalDateTimeFormat
                    id                = '{0}/metricalerts/{1}/{2}-{3}' -f $ResourceId, $EventType.Replace('.', '-'), $SubjectData.ObjectName, $SubjectData.Version
                    name              = $resourceName
                    description       = 'The {0} [{1} version: {2}] in the KeyVault [{3}] has produced an event of the type [{4}]' -f $SubjectData.ObjectType, $SubjectData.ObjectName, $SubjectData.Version, $SubjectData.VaultName, $EventType.Split('.')[2]
                    conditionType     = 'SingleResourceMultipleMetricCriteria'
                    severity          = $severity
                    condition         = @{
                        windowSize = 'PT5M'
                        allOf      = @(
                            @{
                                metricName      = 'Expires'
                                metricNameSpace = 'Microsoft.KeyVault/vaults/{0}' -f $SubjectData.ObjectType
                                operator        = 'at'
                                threshold       = Get-Date $eventExpiry -f yyyy-MM-dd
                                timeAggregation = 'Average'
                                dimensions      = @(
                                    @{
                                        name  = 'ResourceId'
                                        value = $ResourceId
                                    }
                                )
                                metricValue     = '{0} days left' -f [math]::round((New-TimeSpan -Start $now -End $eventExpiry).TotalDays,3)
                                webTestName     = $null
                            }
                        )
                    }
                    subscriptionId    = $subscriptionId
                    resourceGroupName = $resourceGroup
                    resourceName      = '{0}-{1}' -f $SubjectData.VaultName, $SubjectData.ObjectName
                    resourceType      = 'Microsoft.KeyVault/vaults/{0}' -f $SubjectData.ObjectType
                    resourceId        = $ResourceId
                    portalLink        = 'https://portal.azure.com/#resource/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.KeyVault/vaults/{2}' -f $subscriptionId, $resourceGroup, $resourceName
                }
            }
        }
        try {
            Invoke-RestMethod -Uri $WebHook -Body (ConvertTo-Json $alertObject -Depth 100) -Method Post
            Write-Verbose ('Successfully raised OpsGenie alert.') -Verbose
        }
        catch {
            Write-Error $_
        }
    }
}