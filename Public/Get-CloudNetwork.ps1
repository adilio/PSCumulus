function Get-CloudNetwork {
    <#
        .SYNOPSIS
            Gets virtual networks from a selected cloud provider.

        .DESCRIPTION
            Routes network inventory requests to the matching provider backend and
            returns normalized cloud record objects for the network surface.

        .EXAMPLE
            Get-CloudNetwork -Provider Azure -ResourceGroup 'prod-rg'

            Gets Azure virtual networks in a resource group.

        .EXAMPLE
            Get-CloudNetwork -Provider AWS -Region 'us-east-1'

            Gets AWS VPCs in a region.

        .EXAMPLE
            Get-CloudNetwork -Provider GCP -Project 'my-project'

            Gets GCP networks for a project.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Azure')]
    [OutputType([pscustomobject])]
    param(
        # The cloud provider to query.
        [Parameter(ParameterSetName = 'Azure')]
        [Parameter(ParameterSetName = 'AWS')]
        [Parameter(ParameterSetName = 'GCP')]
        [string]$Provider,

        # The Azure resource group containing the target virtual networks.
        [Parameter(Mandatory, ParameterSetName = 'Azure')]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroup,

        # The AWS region to query for VPCs.
        [Parameter(Mandatory, ParameterSetName = 'AWS')]
        [ValidateNotNullOrEmpty()]
        [string]$Region,

        # The GCP project to query for networks.
        [Parameter(Mandatory, ParameterSetName = 'GCP')]
        [ValidateNotNullOrEmpty()]
        [string]$Project
    )

    process {
        $resolvedProvider = Resolve-CloudProvider -Provider $Provider -ParameterSetName $PSCmdlet.ParameterSetName

        $commandMap = @{
            Azure = 'Get-AzureNetworkData'
            AWS   = 'Get-AWSNetworkData'
            GCP   = 'Get-GCPNetworkData'
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
