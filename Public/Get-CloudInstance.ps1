function Get-CloudInstance {
    <#
        .SYNOPSIS
            Gets compute instances from a selected cloud provider.

        .DESCRIPTION
            Routes instance inventory requests to the matching provider backend and
            returns normalized cloud record objects.

            Use -All to query every provider that has an established session context,
            returning instances from all connected clouds in one pipeline.

        .EXAMPLE
            Get-CloudInstance -Provider Azure -ResourceGroup 'prod-rg'

            Gets Azure instances scoped to a resource group.

        .EXAMPLE
            Get-CloudInstance -Provider Azure -ResourceGroup 'prod-rg' -Name 'web-server-01'

            Gets the Azure instance named web-server-01 within the resource group.

        .EXAMPLE
            Get-CloudInstance -Provider AWS -Region 'us-east-1'

            Gets AWS instances for a region.

        .EXAMPLE
            Get-CloudInstance -Provider AWS -Region 'us-east-1' -Name 'app-server-01'

            Gets the AWS instance with the matching Name tag or InstanceId.

        .EXAMPLE
            Get-CloudInstance -Provider GCP -Project 'my-project'

            Gets GCP instances for a project.

        .EXAMPLE
            Get-CloudInstance -Provider GCP -Project 'my-project' -Name 'gcp-vm-01'

            Gets the GCP instance with the matching instance name.

        .EXAMPLE
            Get-CloudInstance -Provider Azure -ResourceGroup 'prod-rg' -Name 'web-server-01' -Detailed

            Gets the Azure instance with a richer, detail-focused view.

        .EXAMPLE
            Get-CloudInstance -All

            Gets instances from all providers with an established session context.
            Use after Connect-Cloud -Provider AWS, Azure, GCP.

        .EXAMPLE
            Get-CloudInstance -All | Where-Object { $_.Tags['environment'] -eq 'prod' }

            Gets all prod-tagged instances across every connected cloud.

        .EXAMPLE
            Get-CloudInstance -All -Status Running -Tag @{ environment = 'production' }

            Gets all running instances with the production environment tag across all connected clouds.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Azure')]
    [OutputType([pscustomobject])]
    param(
        # The cloud provider to query.
        [Parameter(ParameterSetName = 'Azure')]
        [Parameter(ParameterSetName = 'AWS')]
        [Parameter(ParameterSetName = 'GCP')]
        [string]$Provider,

        # The Azure resource group containing the target instances.
        [Parameter(Mandatory, ParameterSetName = 'Azure')]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroup,

        # The instance name to filter within the selected scope.
        [Parameter(ParameterSetName = 'Azure')]
        [Parameter(ParameterSetName = 'AWS')]
        [Parameter(ParameterSetName = 'GCP')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        # The AWS region to query for instances.
        [Parameter(Mandatory, ParameterSetName = 'AWS')]
        [ValidateNotNullOrEmpty()]
        [string]$Region,

        # The GCP project to query for instances.
        [Parameter(Mandatory, ParameterSetName = 'GCP')]
        [ValidateNotNullOrEmpty()]
        [string]$Project,

        # Query all providers with an established session context.
        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch]$All,

        # Returns a richer display-oriented view of cloud records.
        [Parameter(ParameterSetName = 'Azure')]
        [Parameter(ParameterSetName = 'AWS')]
        [Parameter(ParameterSetName = 'GCP')]
        [Parameter(ParameterSetName = 'All')]
        [switch]$Detailed,

        # Filter results by instance status.
        [Parameter(ParameterSetName = 'Azure')]
        [Parameter(ParameterSetName = 'AWS')]
        [Parameter(ParameterSetName = 'GCP')]
        [Parameter(ParameterSetName = 'All')]
        [CloudInstanceStatus]$Status,

        # Filter results by tag key-value pairs. All specified tags must match.
        [Parameter(ParameterSetName = 'Azure')]
        [Parameter(ParameterSetName = 'AWS')]
        [Parameter(ParameterSetName = 'GCP')]
        [Parameter(ParameterSetName = 'All')]
        [hashtable]$Tag
    )

    process {
        $commandMap = @{
            Azure = 'Get-AzureInstanceData'
            AWS   = 'Get-AWSInstanceData'
            GCP   = 'Get-GCPInstanceData'
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

                Write-Progress -Activity "Get-CloudInstance -All" -Status "Querying $providerName..." -PercentComplete $percentComplete -CurrentOperation "Fetching instances from $providerName"

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

                $providerResults = & $decorateRecord (Invoke-CloudProvider -Provider $providerName -CommandMap $commandMap -ArgumentMap $argumentMap)
                foreach ($result in $providerResults) {
                    $allResults.Add($result)
                }
            }

            Write-Progress -Activity "Get-CloudInstance -All" -Completed

            if ($skippedProviders.Count -gt 0) {
                Write-Verbose ("Get-CloudInstance -All skipped: " + ($skippedProviders -join '; ') + '.')
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

        if ($resolvedProvider -eq 'Azure' -and $PSBoundParameters.ContainsKey('Name')) {
            $argumentMap.Name = $Name
        }

        if ($resolvedProvider -eq 'AWS' -and $PSBoundParameters.ContainsKey('Region')) {
            $argumentMap.Region = $Region
        }

        if ($resolvedProvider -eq 'AWS' -and $PSBoundParameters.ContainsKey('Name')) {
            $argumentMap.Name = $Name
        }

        if ($resolvedProvider -eq 'GCP' -and $PSBoundParameters.ContainsKey('Project')) {
            $argumentMap.Project = $Project
        }

        if ($resolvedProvider -eq 'GCP' -and $PSBoundParameters.ContainsKey('Name')) {
            $argumentMap.Name = $Name
        }

        $results = & $decorateRecord (Invoke-CloudProvider -Provider $resolvedProvider -CommandMap $commandMap -ArgumentMap $argumentMap)

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
