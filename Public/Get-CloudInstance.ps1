function Get-CloudInstance {
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
        Azure = 'Get-AzureInstanceData'
        AWS   = 'Get-AWSInstanceData'
        GCP   = 'Get-GCPInstanceData'
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
