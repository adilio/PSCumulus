function Get-CloudDisk {
    <#
        .SYNOPSIS
            Gets managed disks from a selected cloud provider.

        .DESCRIPTION
            Routes disk inventory requests to the matching provider backend and
            returns normalized cloud record objects for the disk surface.

        .EXAMPLE
            Get-CloudDisk -Provider Azure -ResourceGroup 'prod-rg'

            Gets Azure managed disks in a resource group.

        .EXAMPLE
            Get-CloudDisk -Provider AWS -Region 'us-east-1'

            Gets AWS EBS volumes in a region.

        .EXAMPLE
            Get-CloudDisk -Provider GCP -Project 'my-project'

            Gets GCP persistent disks for a project.
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

        # The Azure resource group containing the target disks.
        [Parameter(Mandatory, ParameterSetName = 'Azure')]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroup,

        # The AWS region to query for EBS volumes.
        [Parameter(Mandatory, ParameterSetName = 'AWS')]
        [ValidateNotNullOrEmpty()]
        [string]$Region,

        # The GCP project to query for persistent disks.
        [Parameter(Mandatory, ParameterSetName = 'GCP')]
        [ValidateNotNullOrEmpty()]
        [string]$Project
    )

    process {
        Assert-ProviderParameterSet -Provider $Provider -ParameterSetName $PSCmdlet.ParameterSetName

        $commandMap = @{
            Azure = 'Get-AzureDiskData'
            AWS   = 'Get-AWSDiskData'
            GCP   = 'Get-GCPDiskData'
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
