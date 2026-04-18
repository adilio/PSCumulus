function Get-CloudTag {
    <#
        .SYNOPSIS
            Gets resource tags or labels from a selected cloud provider.

        .DESCRIPTION
            Routes resource metadata requests to the matching provider backend for
            Azure, AWS, or GCP.

            Use -All to query every provider that has an established session context,
            returning tags/labels from all connected clouds in one pipeline.

        .EXAMPLE
            Get-CloudTag -Provider Azure -ResourceId '/subscriptions/.../virtualMachines/vm01'

            Gets Azure tags for a resource identifier.

        .EXAMPLE
            Get-CloudTag -Provider AWS -ResourceId 'i-0123456789abcdef0'

            Gets AWS tags for a resource identifier.

        .EXAMPLE
            Get-CloudTag -Provider GCP -Project 'my-project' -Resource 'instances/vm-01'

            Gets GCP labels for a project-scoped resource.

        .EXAMPLE
            Get-CloudTag -All

            Gets tags/labels from all providers with an established session context.
            Note: This returns a representative sample of tags per provider based on
            stored context (region for AWS, resource group for Azure, project for GCP).
            Use after Connect-Cloud -Provider AWS, Azure, GCP.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        # The cloud provider to query.
        [Parameter()]
        [string]$Provider,

        # The provider resource identifier for Azure or AWS.
        [string]$ResourceId,

        # The GCP project containing the target resource.
        [string]$Project,

        # The GCP resource path used to resolve labels.
        [string]$Resource,

        # Query all providers with an established session context.
        [Parameter(ParameterSetName = 'All')]
        [switch]$All
    )

    process {
        $commandMap = @{
            Azure = 'Get-AzureTagData'
            AWS   = 'Get-AWSTagData'
            GCP   = 'Get-GCPTagData'
        }

        if ($PSCmdlet.ParameterSetName -eq 'All') {
            $skippedProviders = New-Object System.Collections.Generic.List[string]
            $providers = @('Azure', 'AWS', 'GCP')
            $providerIndex = 0

            foreach ($providerName in $providers) {
                $providerIndex++
                $percentComplete = [int] (($providerIndex / $providers.Count) * 100)

                Write-Progress -Activity "Get-CloudTag -All" -Status "Querying $providerName..." -PercentComplete $percentComplete -CurrentOperation "Fetching tags from $providerName"

                $ctx = $script:PSCumulusContext.Providers[$providerName]
                if ($null -eq $ctx) {
                    $skippedProviders.Add("$providerName (no active session context)")
                    continue
                }

                $argumentMap = @{}

                if ($providerName -eq 'Azure') {
                    if ($null -eq $ctx.Scope) {
                        $skippedProviders.Add("$providerName (no stored resource group)")
                        continue
                    }
                    $argumentMap.ResourceId = $ctx.Scope
                }

                if ($providerName -eq 'AWS') {
                    if ($null -eq $ctx.Region) {
                        $skippedProviders.Add("$providerName (no stored region)")
                        continue
                    }
                    $argumentMap.ResourceId = $ctx.Region
                }

                if ($providerName -eq 'GCP') {
                    if ($null -eq $ctx.Scope) {
                        $skippedProviders.Add("$providerName (no stored project)")
                        continue
                    }
                    $argumentMap.Project = $ctx.Scope
                    $argumentMap.Resource = 'projects/' + $ctx.Scope
                }

                Invoke-CloudProvider -Provider $providerName -CommandMap $commandMap -ArgumentMap $argumentMap
            }

            Write-Progress -Activity "Get-CloudTag -All" -Completed

            if ($skippedProviders.Count -gt 0) {
                Write-Verbose ("Get-CloudTag -All skipped: " + ($skippedProviders -join '; ') + '.')
            }

            return
        }

        $resolvedProvider = Resolve-CloudTagProvider -Provider $Provider -Project $Project -Resource $Resource

        Assert-CloudTagArgument -Provider $resolvedProvider -ResourceId $ResourceId -Project $Project -Resource $Resource

        $argumentMap = @{}

        if ($resolvedProvider -eq 'Azure' -and $PSBoundParameters.ContainsKey('ResourceId')) {
            $argumentMap.ResourceId = $ResourceId
        }

        if ($resolvedProvider -eq 'AWS' -and $PSBoundParameters.ContainsKey('ResourceId')) {
            $argumentMap.ResourceId = $ResourceId
        }

        if ($resolvedProvider -eq 'GCP') {
            if ($PSBoundParameters.ContainsKey('Project')) {
                $argumentMap.Project = $Project
            }

            if ($PSBoundParameters.ContainsKey('Resource')) {
                $argumentMap.Resource = $Resource
            }
        }

        Invoke-CloudProvider -Provider $resolvedProvider -CommandMap $commandMap -ArgumentMap $argumentMap
    }
}
