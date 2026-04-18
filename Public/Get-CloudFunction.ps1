function Get-CloudFunction {
    <#
        .SYNOPSIS
            Gets serverless functions from a selected cloud provider.

        .DESCRIPTION
            Routes function inventory requests to the matching provider backend and
            returns normalized cloud record objects for the serverless compute surface.

            Use -All to query every provider that has an established session context,
            returning functions from all connected clouds in one pipeline.

        .EXAMPLE
            Get-CloudFunction -Provider Azure -ResourceGroup 'prod-rg'

            Gets Azure Function Apps in a resource group.

        .EXAMPLE
            Get-CloudFunction -Provider AWS -Region 'us-east-1'

            Gets AWS Lambda functions in a region.

        .EXAMPLE
            Get-CloudFunction -Provider GCP -Project 'my-project'

            Gets GCP Cloud Functions for a project.

        .EXAMPLE
            Get-CloudFunction -All

            Gets functions from all providers with an established session context.
            Use after Connect-Cloud -Provider AWS, Azure, GCP.

        .EXAMPLE
            Get-CloudFunction -All -Status Active -Tag @{ environment = 'production' }

            Gets all active functions with the production environment tag across all connected clouds.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Azure')]
    [OutputType([pscustomobject])]
    param(
        # The cloud provider to query.
        [Parameter(ParameterSetName = 'Azure')]
        [Parameter(ParameterSetName = 'AWS')]
        [Parameter(ParameterSetName = 'GCP')]
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
        [string]$Project,

        # Query all providers with an established session context.
        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch]$All,

        # Filter results by function status.
        [Parameter(ParameterSetName = 'Azure')]
        [Parameter(ParameterSetName = 'AWS')]
        [Parameter(ParameterSetName = 'GCP')]
        [Parameter(ParameterSetName = 'All')]
        [CloudFunctionStatus]$Status,

        # Filter results by tag key-value pairs. All specified tags must match.
        [Parameter(ParameterSetName = 'Azure')]
        [Parameter(ParameterSetName = 'AWS')]
        [Parameter(ParameterSetName = 'GCP')]
        [Parameter(ParameterSetName = 'All')]
        [hashtable]$Tag
    )

    process {
        $commandMap = @{
            Azure = 'Get-AzureFunctionData'
            AWS   = 'Get-AWSFunctionData'
            GCP   = 'Get-GCPFunctionData'
        }

        if ($PSCmdlet.ParameterSetName -eq 'All') {
            $skippedProviders = New-Object System.Collections.Generic.List[string]
            $providers = @('Azure', 'AWS', 'GCP')
            $providerIndex = 0
            $allResults = [System.Collections.Generic.List[psobject]]::new()

            foreach ($providerName in $providers) {
                $providerIndex++
                $percentComplete = [int] (($providerIndex / $providers.Count) * 100)

                Write-Progress -Activity "Get-CloudFunction -All" -Status "Querying $providerName..." -PercentComplete $percentComplete -CurrentOperation "Fetching functions from $providerName"

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

                $providerResults = Invoke-CloudProvider -Provider $providerName -CommandMap $commandMap -ArgumentMap $argumentMap
                foreach ($result in $providerResults) {
                    $allResults.Add($result)
                }
            }

            Write-Progress -Activity "Get-CloudFunction -All" -Completed

            if ($skippedProviders.Count -gt 0) {
                Write-Verbose ("Get-CloudFunction -All skipped: " + ($skippedProviders -join '; ') + '.')
            }

            $results = $allResults

            if ($PSBoundParameters.ContainsKey('Status')) {
                $results = $results | Where-Object { $_.Status -eq $Status.ToString() }
            }

            if ($PSBoundParameters.ContainsKey('Tag')) {
                $results = $results | Where-Object {
                    $recordTags = $_.Tags
                    if ($null -eq $recordTags) { return $false }
                    foreach ($key in $Tag.Keys) {
                        if (-not $recordTags.ContainsKey($key)) { return $false }
                        if ($recordTags[$key] -ne $Tag[$key]) { return $false }
                    }
                    return $true
                }
            }

            $results

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

        $results = Invoke-CloudProvider -Provider $resolvedProvider -CommandMap $commandMap -ArgumentMap $argumentMap

        if ($PSBoundParameters.ContainsKey('Status')) {
            $results = $results | Where-Object { $_.Status -eq $Status.ToString() }
        }

        if ($PSBoundParameters.ContainsKey('Tag')) {
            $results = $results | Where-Object {
                $recordTags = $_.Tags
                if ($null -eq $recordTags) { return $false }
                foreach ($key in $Tag.Keys) {
                    if (-not $recordTags.ContainsKey($key)) { return $false }
                    if ($recordTags[$key] -ne $Tag[$key]) { return $false }
                }
                return $true
            }
        }

        $results
    }
}
