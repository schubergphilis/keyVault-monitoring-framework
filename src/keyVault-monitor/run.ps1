param($eventGridEvent, $TriggerMetadata)
Write-Verbose ('Event [{0}] has been detected.' -f $eventGridEvent.eventType) -Verbose
ConvertTo-Json $eventGridEvent -Depth 100
$ErrorActionPreference = 'Stop'
Import-Module 'helpers', 'AzTable'

switch -Wildcard ($eventGridEvent.eventType) {
    '*Expir*' {
        $expiryDate = ([system.datetimeoffset]::FromUnixTimeSeconds($eventGridEvent.data.EXP)).UtcDateTime
        $now = [datetime]::UtcNow
        [int]$timeMargin = (New-TimeSpan -Start $now -End $expiryDate).TotalHours
        if ($timeMargin -le 24) {
            $alertSplat = @{
                WebHook     = $env:OpsGenieWebHook
                ResourceId  = $eventGridEvent.topic
                SubjectData = $eventGridEvent.data
                EventType   = $eventGridEvent.eventType
                EventTime   = $eventGridEvent.eventTime
            }
            Write-Verbose ('Time margin is {0}, raising OpsGenie alert.' -f $timeMargin) -Verbose
            New-OpsGenieExpiryAlert @alertSplat
        }
        else {
            Write-Verbose ('Time margin is {0}, writting event to the storage table.' -f $timeMargin) -Verbose
            $storageTable = Test-AzStorageTableContext -ConnectionString $env:AzureWebJobsStorage  -TableName $env:StorageTableName
            Import-AzTableExpiryEvent -CloudTable $storageTable.CloudTable -PartitionKey $env:StorageTablePartitionKey -Data $eventGridEvent
        }
    }
    '*NewVersionCreated' {
        $storageTable = Test-AzStorageTableContext -ConnectionString $env:AzureWebJobsStorage  -TableName $env:StorageTableName
        $removeEventSplat = @{
            CloudTable   = $storageTable.CloudTable
            PartitionKey = $env:StorageTablePartitionKey
            RowKey       = '{0}-{1}-{2}-{3}' -f $eventGridEvent.topic.split('/')[2], $eventGridEvent.data.vaultName, $eventGridEvent.data.objectType, $eventGridEvent.data.objectName
        }
        Remove-AzTableExpiryEvent @removeEventSplat
    }
}