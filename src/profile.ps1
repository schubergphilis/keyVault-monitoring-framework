if ($env:MSI_SECRET -and (Get-Module -ListAvailable Az.Accounts)) {
    Connect-AzAccount -Identity
}
$storageContext = New-AzStorageContext -ConnectionString $env:AzureWebJobsStorage
try {
    Get-AzStorageTable -Name $env:StorageTableName -Context $storageContext -ErrorAction Stop
}
catch {
    [void](New-AzStorageTable -Name $env:StorageTableName -Context $storageContext)
}