Param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$VariableName,

    [Parameter(Mandatory = $false)]
    [ValidateNotNull()]
    [String]$ResourceName,

    [Boolean]$IsSecret = $False,

    [ValidateSet("Json", "None")]
    [String]
    $Formatter = "Json"
)

$Value = ''
if (-not([string]::IsNullOrEmpty($ResourceName))) {
    $AzResourceId = (Get-AzResource -Name $ResourceName -ErrorAction SilentlyContinue).ResourceId
    if ([string]::IsNullOrEmpty($AzResourceId)) {
        Write-Warning "Cannot find or access Azure Resource $ResourceName!"
        $Value = ''
    } else { $Value = $AzResourceId }
}

if ($Formatter -eq "Json") {
    $OutValue = ConvertTo-Json -Compress -InputObject $Value
} else {
    $OutValue = $Value
}

$SetVariable = ("vso[task.setvariable variable={0};]{1}" -f $VariableName, $OutValue)

If ($IsSecret) {
    Write-Host ("Skipped output preview because variable '{0}' is a secret" -f $VariableName)
} Else {
    Write-Host $SetVariable
}

Write-Host "##$SetVariable"
