function Get-CloudNetwork {
    <#
        .SYNOPSIS
            Gets virtual networks from a selected cloud provider.

        .DESCRIPTION
            Routes network inventory requests to the matching provider backend and
            returns normalized cloud record objects for the network surface.

            Use -All to query every provider that has an established session context,
            returning networks from all connected clouds in one pipeline.

        .EXAMPLE
            Get-CloudNetwork -Provider Azure -ResourceGroup 'prod-rg'

            Gets Azure virtual networks in a resource group.

        .EXAMPLE
            Get-CloudNetwork -Provider AWS -Region 'us-east-1'

            Gets AWS VPCs in a region.

        .EXAMPLE
            Get-CloudNetwork -Provider GCP -Project 'my-project'

            Gets GCP networks for a project.

        .EXAMPLE
            Get-CloudNetwork -All

            Gets networks from all providers with an established session context.
            Use after Connect-Cloud -Provider AWS, Azure, GCP.
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
        [string]$Project,

        # Query all providers with an established session context.
        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch]$All
    )

    process {
        $commandMap = @{
            Azure = 'Get-AzureNetworkData'
            AWS   = 'Get-AWSNetworkData'
            GCP   = 'Get-GCPNetworkData'
        }

        if ($PSCmdlet.ParameterSetName -eq 'All') {
            $skippedProviders = New-Object System.Collections.Generic.List[string]
            $providers = @('Azure', 'AWS', 'GCP')
            $providerIndex = 0

            foreach ($providerName in $providers) {
                $providerIndex++
                $percentComplete = [int] (($providerIndex / $providers.Count) * 100)

                Write-Progress -Activity "Get-CloudNetwork -All" -Status "Querying $providerName..." -PercentComplete $percentComplete -CurrentOperation "Fetching networks from $providerName"

                $ctx = $script:PSCumulusContext.Providers[$providerName]
                if ($null -eq $ctx) {
                    $skippedProviders.Add("$providerName (no active session context)")
                    continue
                }

                $argumentMap = @{}

                if ($providerName -eq 'AWS' -and -not [string]::IsNullOrWhiteSpace($ctx.Region)) {
                    $argumentMap.Region = $ctx.Region
                }

                if ($providerName -eq 'AWS' -and [string]::IsNullOrWhiteSpace($ctx.Region)) {
                    $skippedProviders.Add("$providerName (no stored region)")
                    continue
                }

                if ($providerName -eq 'GCP' -and -not [string]::IsNullOrWhiteSpace($ctx.Scope)) {
                    $argumentMap.Project = $ctx.Scope
                }

                if ($providerName -eq 'GCP' -and [string]::IsNullOrWhiteSpace($ctx.Scope)) {
                    $skippedProviders.Add("$providerName (no stored project)")
                    continue
                }

                Invoke-CloudProvider -Provider $providerName -CommandMap $commandMap -ArgumentMap $argumentMap
            }

            Write-Progress -Activity "Get-CloudNetwork -All" -Completed

            if ($skippedProviders.Count -gt 0) {
                Write-Verbose ("Get-CloudNetwork -All skipped: " + ($skippedProviders -join '; ') + '.')
            }

            return
        }

        $resolvedProvider = Resolve-CloudProvider -Provider $Provider -ParameterSetName $PSCmdlet.ParameterSetName

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
