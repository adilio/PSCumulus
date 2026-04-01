function Connect-Cloud {
    <#
        .SYNOPSIS
            Connects to a cloud provider using the PSCumulus abstraction.

        .DESCRIPTION
            Routes a provider-specific connection request to the matching backend
            implementation for Azure, AWS, or GCP.

        .EXAMPLE
            Connect-Cloud -Provider Azure

            Connects to Azure using the Azure backend.

        .EXAMPLE
            Connect-Cloud -Provider AWS -Region 'us-east-1'

            Connects to AWS using the region-aware backend path.

        .EXAMPLE
            Connect-Cloud -Provider GCP -Project 'my-project'

            Connects to GCP using the project-aware backend path.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Azure')]
    [OutputType([pscustomobject])]
    param(
        # The cloud provider to connect to.
        [Parameter(Mandatory, ParameterSetName = 'Azure')]
        [Parameter(Mandatory, ParameterSetName = 'AWS')]
        [Parameter(Mandatory, ParameterSetName = 'GCP')]
        [ValidateSet('Azure', 'AWS', 'GCP')]
        [string]$Provider,

        # The AWS region to target for the connection context.
        [Parameter(Mandatory, ParameterSetName = 'AWS')]
        [ValidateNotNullOrEmpty()]
        [string]$Region,

        # The GCP project to target for the connection context.
        [Parameter(Mandatory, ParameterSetName = 'GCP')]
        [ValidateNotNullOrEmpty()]
        [string]$Project
    )

    process {
        Assert-ProviderParameterSet -Provider $Provider -ParameterSetName $PSCmdlet.ParameterSetName

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
}
