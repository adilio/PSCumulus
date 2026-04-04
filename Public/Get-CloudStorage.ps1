function Get-CloudStorage {
    <#
        .SYNOPSIS
            Gets storage resources from a selected cloud provider.

        .DESCRIPTION
            Routes storage inventory requests to the matching provider backend and
            returns normalized cloud record objects for the storage surface.

        .EXAMPLE
            Get-CloudStorage -Provider Azure -ResourceGroup 'prod-rg'

            Gets Azure storage resources in a resource group.

        .EXAMPLE
            Get-CloudStorage -Provider AWS -Region 'us-east-1'

            Gets AWS storage resources in a region.

        .EXAMPLE
            Get-CloudStorage -Provider GCP -Project 'my-project'

            Gets GCP storage resources for a project.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Azure')]
    [OutputType([pscustomobject])]
    param(
        # The cloud provider to query.
        [Parameter(ParameterSetName = 'Azure')]
        [Parameter(ParameterSetName = 'AWS')]
        [Parameter(ParameterSetName = 'GCP')]
        [string]$Provider,

        # The Azure resource group containing the target storage resources.
        [Parameter(Mandatory, ParameterSetName = 'Azure')]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroup,

        # The AWS region to query for storage resources.
        [Parameter(Mandatory, ParameterSetName = 'AWS')]
        [ValidateNotNullOrEmpty()]
        [string]$Region,

        # The GCP project to query for storage resources.
        [Parameter(Mandatory, ParameterSetName = 'GCP')]
        [ValidateNotNullOrEmpty()]
        [string]$Project
    )

    process {
        $resolvedProvider = Resolve-CloudProvider -Provider $Provider -ParameterSetName $PSCmdlet.ParameterSetName

        $commandMap = @{
            Azure = 'Get-AzureStorageData'
            AWS   = 'Get-AWSStorageData'
            GCP   = 'Get-GCPStorageData'
        }

        $argumentMap = @{}

        if ($resolvedProvider -eq 'Azure' -and $PSBoundParameters.ContainsKey('ResourceGroup')) {
            $argumentMap.ResourceGroup = $ResourceGroup
        }

        if ($resolvedProvider -eq 'AWS' -and $PSBoundParameters.ContainsKey('Region')) {
            $argumentMap.Region = $Region
        }

        if ($resolvedProvider -eq 'GCP' -and $PSBoundParameters.ContainsKey('Project')) {
            $argumentMap.Project = $Project
        }

        Invoke-CloudProvider -Provider $resolvedProvider -CommandMap $commandMap -ArgumentMap $argumentMap
    }
}
