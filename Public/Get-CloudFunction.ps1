function Get-CloudFunction {
    <#
        .SYNOPSIS
            Gets serverless functions from a selected cloud provider.

        .DESCRIPTION
            Routes function inventory requests to the matching provider backend and
            returns normalized cloud record objects for the serverless compute surface.

        .EXAMPLE
            Get-CloudFunction -Provider Azure -ResourceGroup 'prod-rg'

            Gets Azure Function Apps in a resource group.

        .EXAMPLE
            Get-CloudFunction -Provider AWS -Region 'us-east-1'

            Gets AWS Lambda functions in a region.

        .EXAMPLE
            Get-CloudFunction -Provider GCP -Project 'my-project'

            Gets GCP Cloud Functions for a project.
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

        # The Azure resource group containing the target Function Apps.
        [Parameter(Mandatory, ParameterSetName = 'Azure')]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroup,

        # The AWS region to query for Lambda functions.
        [Parameter(Mandatory, ParameterSetName = 'AWS')]
        [ValidateNotNullOrEmpty()]
        [string]$Region,

        # The GCP project to query for Cloud Functions.
        [Parameter(Mandatory, ParameterSetName = 'GCP')]
        [ValidateNotNullOrEmpty()]
        [string]$Project
    )

    process {
        Assert-ProviderParameterSet -Provider $Provider -ParameterSetName $PSCmdlet.ParameterSetName

        $commandMap = @{
            Azure = 'Get-AzureFunctionData'
            AWS   = 'Get-AWSFunctionData'
            GCP   = 'Get-GCPFunctionData'
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
