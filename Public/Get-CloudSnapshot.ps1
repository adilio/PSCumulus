function Get-CloudSnapshot {
    <#
        .SYNOPSIS
            Gets disk snapshots from a selected cloud provider.

        .DESCRIPTION
            Routes snapshot inventory requests to the matching provider backend and
            returns normalized cloud record objects: Azure managed-disk snapshots,
            AWS EBS snapshots (owned by the caller), and GCP disk snapshots. Every
            record carries the source disk, size, and creation date.

            Use -All to query every provider that has an established session context,
            returning snapshots from all connected clouds in one pipeline.

        .EXAMPLE
            Get-CloudSnapshot -Provider Azure -ResourceGroup 'prod-rg'

            Gets Azure managed-disk snapshots in a resource group.

        .EXAMPLE
            Get-CloudSnapshot -Provider AWS -Region 'us-east-1'

            Gets the caller's EBS snapshots in a region.

        .EXAMPLE
            Get-CloudSnapshot -Provider GCP -Project 'my-project'

            Gets GCP disk snapshots for a project.

        .EXAMPLE
            Get-CloudSnapshot -All

            Gets snapshots from all providers with an established session context.
            Use after Connect-Cloud -Provider AWS, Azure, GCP.

        .EXAMPLE
            Get-CloudSnapshot -Provider Azure -ResourceGroup 'prod-rg' -Name 'nightly-data-01'

            Gets Azure snapshots matching the specified name.

        .EXAMPLE
            Get-CloudSnapshot -Provider AWS -Region 'us-east-1' -Detailed

            Gets AWS EBS snapshots with detailed view enabled.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Azure')]
    [OutputType([pscustomobject])]
    param(
        # The cloud provider to query.
        [Parameter(ParameterSetName = 'Azure')]
        [Parameter(ParameterSetName = 'AWS')]
        [Parameter(ParameterSetName = 'GCP')]
        [string]$Provider,

        # The Azure resource group containing the target snapshots.
        [Parameter(Mandatory, ParameterSetName = 'Azure')]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroup,

        # The AWS region to query for snapshots.
        [Parameter(Mandatory, ParameterSetName = 'AWS')]
        [ValidateNotNullOrEmpty()]
        [string]$Region,

        # The GCP project to query for snapshots.
        [Parameter(Mandatory, ParameterSetName = 'GCP')]
        [ValidateNotNullOrEmpty()]
        [string]$Project,

        # Query all providers with an established session context.
        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch]$All,

        # Filter results by name.
        [Parameter(ParameterSetName = 'Azure')]
        [Parameter(ParameterSetName = 'AWS')]
        [Parameter(ParameterSetName = 'GCP')]
        [Parameter(ParameterSetName = 'All')]
        [string]$Name,

        # Filter results by tag key-value pairs. All specified tags must match.
        [Parameter(ParameterSetName = 'Azure')]
        [Parameter(ParameterSetName = 'AWS')]
        [Parameter(ParameterSetName = 'GCP')]
        [Parameter(ParameterSetName = 'All')]
        [hashtable]$Tag,

        # Emit detailed view records.
        [Parameter(ParameterSetName = 'Azure')]
        [Parameter(ParameterSetName = 'AWS')]
        [Parameter(ParameterSetName = 'GCP')]
        [Parameter(ParameterSetName = 'All')]
        [switch]$Detailed
    )

    process {
        $commandMap = @{
            Azure = 'Get-AzureSnapshotData'
            AWS   = 'Get-AWSSnapshotData'
            GCP   = 'Get-GCPSnapshotData'
        }

        $decorateRecord = {
            param($Records)

            foreach ($record in @($Records)) {
                if ($Detailed -and $record) {
                    if ($record.PSObject.TypeNames[0] -ne 'PSCumulus.CloudRecord.Detailed') {
                        $record.PSObject.TypeNames.Insert(0, 'PSCumulus.CloudRecord.Detailed')
                    }
                }

                $record
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'All') {
            $skippedProviders = New-Object System.Collections.Generic.List[string]
            $providers = @('Azure', 'AWS', 'GCP')
            $providerIndex = 0
            $allResults = [System.Collections.Generic.List[psobject]]::new()

            foreach ($providerName in $providers) {
                $providerIndex++
                $percentComplete = [int] (($providerIndex / $providers.Count) * 100)

                Write-Progress -Activity "Get-CloudSnapshot -All" -Status "Querying $providerName..." -PercentComplete $percentComplete -CurrentOperation "Fetching snapshots from $providerName"

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

            Write-Progress -Activity "Get-CloudSnapshot -All" -Completed

            if ($skippedProviders.Count -gt 0) {
                Write-Verbose ("Get-CloudSnapshot -All skipped: " + ($skippedProviders -join '; ') + '.')
            }

            $results = $allResults

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

            if ($PSBoundParameters.ContainsKey('Name')) {
                $results = $results | Where-Object { [string]::IsNullOrWhiteSpace($Name) -or $_.Name -eq $Name }
            }

            & $decorateRecord $results

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

        if ($PSBoundParameters.ContainsKey('Name')) {
            $results = $results | Where-Object { [string]::IsNullOrWhiteSpace($Name) -or $_.Name -eq $Name }
        }

        & $decorateRecord $results
    }
}
