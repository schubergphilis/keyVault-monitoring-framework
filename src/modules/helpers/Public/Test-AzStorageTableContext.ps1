function Test-AzStorageTableContext {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ConnectionString,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$TableName
    )
    process {
        $ErrorActionPreference = 'Stop'
        $storageContext = New-AzStorageContext -ConnectionString $ConnectionString
        try {
            $storageTable = Get-AzStorageTable -Name $TableName -Context $storageContext
        }
        catch {
            Write-Error $_
            throw ('Cannot find the storage account table with the name {0}' -f $env:StorageTableName)
        }
        Write-Verbose ('Table context tested and created successfully.') -Verbose
        return($storageTable)
    }
}