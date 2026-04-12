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

        .EXAMPLE
            Get-CloudInstance -ResourceGroup 'prod-rg' -Name 'web-server-01' | Stop-CloudInstance

            Stops the Azure VM using piped PSCumulus instance output.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Azure', SupportsShouldProcess)]
    [OutputType([pscustomobject])]
    param(
        # A PSCumulus cloud record piped from Get-CloudInstance.
        [Parameter(Mandatory, ParameterSetName = 'Piped', ValueFromPipeline)]
        [psobject]$InputObject,

        # The cloud provider to target.
        [Parameter(ParameterSetName = 'Azure', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'AWS', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'GCP', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Piped', ValueFromPipelineByPropertyName)]
        [string]$Provider,

        # The instance name (Azure and GCP).
        [Parameter(Mandatory, ParameterSetName = 'Azure', ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName = 'GCP', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Piped', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        # The Azure resource group containing the target VM.
        [Parameter(Mandatory, ParameterSetName = 'Azure', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Piped', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroup,

        # The AWS EC2 instance identifier.
        [Parameter(Mandatory, ParameterSetName = 'AWS', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Piped', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$InstanceId,

        # The AWS region where the instance resides.
        [Parameter(ParameterSetName = 'AWS', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Piped', ValueFromPipelineByPropertyName)]
        [string]$Region,

        # The GCP project containing the target instance.
        [Parameter(Mandatory, ParameterSetName = 'GCP', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Piped', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Project,

        # The GCP zone where the instance resides.
        [Parameter(Mandatory, ParameterSetName = 'GCP', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Piped', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Zone
    )

    process {
        $resolvedInput = Resolve-CloudInstanceInput `
            -InputObject $InputObject `
            -Provider $Provider `
            -Name $Name `
            -ResourceGroup $ResourceGroup `
            -InstanceId $InstanceId `
            -Region $Region `
            -Project $Project `
            -Zone $Zone

        $resolvedProvider = if ($PSCmdlet.ParameterSetName -eq 'Piped') {
            Resolve-CloudProvider -Provider $resolvedInput.Provider
        } else {
            Resolve-CloudProvider -Provider $resolvedInput.Provider -ParameterSetName $PSCmdlet.ParameterSetName
        }

        $commandMap = @{
            Azure = 'Stop-AzureInstance'
            AWS   = 'Stop-AWSInstance'
            GCP   = 'Stop-GCPInstance'
        }

        $argumentMap = @{}

        switch ($resolvedProvider) {
            'Azure' {
                $argumentMap.Name          = $resolvedInput.Name
                $argumentMap.ResourceGroup = $resolvedInput.ResourceGroup
            }
            'AWS' {
                $argumentMap.InstanceId = $resolvedInput.InstanceId
                if (-not [string]::IsNullOrWhiteSpace($resolvedInput.Region)) {
                    $argumentMap.Region = $resolvedInput.Region
                }
            }
            'GCP' {
                $argumentMap.Name    = $resolvedInput.Name
                $argumentMap.Zone    = $resolvedInput.Zone
                $argumentMap.Project = $resolvedInput.Project
            }
        }

        $target = switch ($resolvedProvider) {
            'Azure' { "$($resolvedInput.Name) in resource group $($resolvedInput.ResourceGroup)" }
            'AWS'   { $resolvedInput.InstanceId }
            'GCP'   { "$($resolvedInput.Name) in zone $($resolvedInput.Zone) ($($resolvedInput.Project))" }
        }

        if ($PSCmdlet.ShouldProcess($target, 'Stop-CloudInstance')) {
            Invoke-CloudProvider -Provider $resolvedProvider -CommandMap $commandMap -ArgumentMap $argumentMap
        }
    }
}
