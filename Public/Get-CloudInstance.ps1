function Get-CloudInstance {
    <#
        .SYNOPSIS
            Gets compute instances from a selected cloud provider.

        .DESCRIPTION
            Routes instance inventory requests to the matching provider backend and
            returns normalized cloud record objects.

        .EXAMPLE
            Get-CloudInstance -Provider Azure -ResourceGroup 'prod-rg'

            Gets Azure instances scoped to a resource group.

        .EXAMPLE
            Get-CloudInstance -Provider AWS -Region 'us-east-1'

            Gets AWS instances for a region.

        .EXAMPLE
            Get-CloudInstance -Provider GCP -Project 'my-project'

            Gets GCP instances for a project.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Azure')]
    [OutputType([pscustomobject])]
    param(
        # The cloud provider to query.
        [Parameter(Mandatory, ParameterSetName = 'Azure')]
        [Parameter(Mandatory, ParameterSetName = 'AWS')]
        [Parameter(Mandatory, ParameterSetName = 'GCP')]
        [ValidateSet('Azure', 'AWS', 'GCP')]
        [string]$Provider,

        # The Azure resource group containing the target instances.
        [Parameter(Mandatory, ParameterSetName = 'Azure')]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroup,

        # The AWS region to query for instances.
        [Parameter(Mandatory, ParameterSetName = 'AWS')]
        [ValidateNotNullOrEmpty()]
        [string]$Region,

        # The GCP project to query for instances.
        [Parameter(Mandatory, ParameterSetName = 'GCP')]
        [ValidateNotNullOrEmpty()]
        [string]$Project
    )

    process {
        Assert-ProviderParameterSet -Provider $Provider -ParameterSetName $PSCmdlet.ParameterSetName

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
}
