function Get-CloudTag {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Azure', 'AWS', 'GCP')]
        [string]$Provider,

        [string]$ResourceId,
        [string]$Project,
        [string]$Resource
    )

    $commandMap = @{
        Azure = 'Get-AzureTagData'
        AWS   = 'Get-AWSTagData'
        GCP   = 'Get-GCPTagData'
    }

    $argumentMap = @{}

    if ($Provider -eq 'Azure' -and $PSBoundParameters.ContainsKey('ResourceId')) {
        $argumentMap.ResourceId = $ResourceId
    }

    if ($Provider -eq 'AWS' -and $PSBoundParameters.ContainsKey('ResourceId')) {
        $argumentMap.ResourceId = $ResourceId
    }

    if ($Provider -eq 'GCP') {
        if ($PSBoundParameters.ContainsKey('Project')) {
            $argumentMap.Project = $Project
        }

        if ($PSBoundParameters.ContainsKey('Resource')) {
            $argumentMap.Resource = $Resource
        }
    }

    Invoke-CloudProvider -Provider $Provider -CommandMap $commandMap -ArgumentMap $argumentMap
}
