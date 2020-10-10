param($Timer)
$ErrorActionPreference = 'Stop'
Import-Module 'helpers', 'AzTable'

$now = [datetime]::UtcNow
$storageTable = Test-AzStorageTableContext -ConnectionString $env:AzureWebJobsStorage  -TableName $env:StorageTableName
$eventList = Get-AzTableRow -Table $storageTable.CloudTable
foreach ($event in $eventList) {
    $eventExpiry = ([System.DateTimeOffset]::FromUnixTimeSeconds($event.EXP)).UtcDateTime
    if ($eventExpiry -lt $now) {
        Remove-AzTableExpiryEvent -CloudTable $storageTable.CloudTable -PartitionKey $event.PartitionKey -Rowkey $event.RowKey
    }
    else {
        $alertSplat = @{
            WebHook     = $env:OpsGenieWebHook
            ResourceId  = $event.topic
            SubjectData = @{
                ObjectType = $event.ObjectType
                ObjectName = $event.ObjectName
                Version    = $event.Version
                VaultName  = $event.VaultName
                EXP        = $event.EXP
            }
            EventType   = $event.eventType
            EventTime   = $event.eventTime
        }
        New-OpsGenieExpiryAlert @alertSplat
    }
}