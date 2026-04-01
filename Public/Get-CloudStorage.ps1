function Get-CloudStorage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Azure', 'AWS', 'GCP')]
        [string]$Provider,

        [string]$ResourceGroup,
        [string]$Region,
        [string]$Project
    )

    $commandMap = @{
        Azure = 'Get-AzureStorageData'
        AWS   = 'Get-AWSStorageData'
        GCP   = 'Get-GCPStorageData'
    }

    $argumentMap = @{}

    if ($Provider -eq 'Azure' -and $PSBoundParameters.ContainsKey('ResourceGroup')) {
        $argumentMap.ResourceGroup = $ResourceGroup
    }

    if ($Provider -eq 'AWS' -and $PSBoundParameters.ContainsKey('Region')) {
        $argumentMap.Region = $Region
    }

    if ($Provider -eq 'GCP' -and $PSBoundParameters.ContainsKey('Project')) {
        $argumentMap.Project = $Project
    }

    Invoke-CloudProvider -Provider $Provider -CommandMap $commandMap -ArgumentMap $argumentMap
}
