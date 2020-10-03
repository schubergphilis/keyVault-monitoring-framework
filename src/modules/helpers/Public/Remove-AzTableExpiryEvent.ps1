function Remove-AzTableExpiryEvent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [object]$CloudTable,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$PartitionKey,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RowKey
    )
    process {
        $ErrorActionPreference = 'Stop'
        Import-Module 'AzTable' -Force
        $rowLookup = Get-AzTableRow -Table $CloudTable -PartitionKey $PartitionKey -RowKey $RowKey
        if ($false -eq [string]::IsNullOrWhiteSpace($rowLookup)) {
            [void](Remove-AzTableRow -Table $CloudTable -entity $rowLookup)
            Write-Verbose ('Successfully removed the expiry event which matches the PartitionKey: [{0}] and RowKey: [{1}].' -f $PartitionKey, $RowKey) -Verbose
        }
        else {
            Write-Verbose ('Cannot find the table row matching the PartitionKey: [{0}] and RowKey: [{1}].' -f $PartitionKey, $RowKey) -Verbose
        }
    }
}