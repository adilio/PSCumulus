function Connect-Cloud {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Azure', 'AWS', 'GCP')]
        [string]$Provider,

        [string]$Region,
        [string]$Project
    )

    $commandMap = @{
        Azure = 'Connect-AzureBackend'
        AWS   = 'Connect-AWSBackend'
        GCP   = 'Connect-GCPBackend'
    }

    $argumentMap = @{}

    if ($Provider -eq 'AWS' -and $PSBoundParameters.ContainsKey('Region')) {
        $argumentMap.Region = $Region
    }

    if ($Provider -eq 'GCP' -and $PSBoundParameters.ContainsKey('Project')) {
        $argumentMap.Project = $Project
    }

    Invoke-CloudProvider -Provider $Provider -CommandMap $commandMap -ArgumentMap $argumentMap
}
