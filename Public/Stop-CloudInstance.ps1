function Stop-CloudInstance {
    <#
        .SYNOPSIS
            Stops a compute instance on a selected cloud provider.

        .DESCRIPTION
            Routes instance stop requests to the matching provider backend and
            returns a normalized cloud record confirming the stop operation.

        .EXAMPLE
            Stop-CloudInstance -Provider Azure -Name 'web-server-01' -ResourceGroup 'prod-rg'

            Stops an Azure VM.

        .EXAMPLE
            Stop-CloudInstance -Provider AWS -InstanceId 'i-0123456789abcdef0' -Region 'us-east-1'

            Stops an AWS EC2 instance.

        .EXAMPLE
            Stop-CloudInstance -Provider GCP -Name 'gcp-vm-01' -Zone 'us-central1-a' -Project 'my-project'

            Stops a GCP compute instance.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Azure')]
    [OutputType([pscustomobject])]
    param(
        # The cloud provider to target.
        [Parameter(Mandatory, ParameterSetName = 'Azure')]
        [Parameter(Mandatory, ParameterSetName = 'AWS')]
        [Parameter(Mandatory, ParameterSetName = 'GCP')]
        [ValidateSet('Azure', 'AWS', 'GCP')]
        [string]$Provider,

        # The instance name (Azure and GCP).
        [Parameter(Mandatory, ParameterSetName = 'Azure')]
        [Parameter(Mandatory, ParameterSetName = 'GCP')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        # The Azure resource group containing the target VM.
        [Parameter(Mandatory, ParameterSetName = 'Azure')]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroup,

        # The AWS EC2 instance identifier.
        [Parameter(Mandatory, ParameterSetName = 'AWS')]
        [ValidateNotNullOrEmpty()]
        [string]$InstanceId,

        # The AWS region where the instance resides.
        [Parameter(ParameterSetName = 'AWS')]
        [string]$Region,

        # The GCP project containing the target instance.
        [Parameter(Mandatory, ParameterSetName = 'GCP')]
        [ValidateNotNullOrEmpty()]
        [string]$Project,

        # The GCP zone where the instance resides.
        [Parameter(Mandatory, ParameterSetName = 'GCP')]
        [ValidateNotNullOrEmpty()]
        [string]$Zone
    )

    process {
        Assert-ProviderParameterSet -Provider $Provider -ParameterSetName $PSCmdlet.ParameterSetName

        $commandMap = @{
            Azure = 'Stop-AzureInstance'
            AWS   = 'Stop-AWSInstance'
            GCP   = 'Stop-GCPInstance'
        }

        $argumentMap = @{}

        switch ($Provider) {
            'Azure' {
                $argumentMap.Name          = $Name
                $argumentMap.ResourceGroup = $ResourceGroup
            }
            'AWS' {
                $argumentMap.InstanceId = $InstanceId
                if ($PSBoundParameters.ContainsKey('Region')) {
                    $argumentMap.Region = $Region
                }
            }
            'GCP' {
                $argumentMap.Name    = $Name
                $argumentMap.Zone    = $Zone
                $argumentMap.Project = $Project
            }
        }

        Invoke-CloudProvider -Provider $Provider -CommandMap $commandMap -ArgumentMap $argumentMap
    }
}
