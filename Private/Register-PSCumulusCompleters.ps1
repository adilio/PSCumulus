# Cache for ResourceGroup completion (60-second TTL)
$script:__PSCumulusRgCache = @{}
$script:__PSCumulusRgCacheLastUpdate = $null

Register-ArgumentCompleter -ParameterName Region -ScriptBlock {
    param($commandName, $wordToComplete)

    $module = Get-Module PSCumulus
    if (-not $module) {
        return
    }

    $providers = switch ($commandName) {
        { $_ -match 'Azure|Get-Az' } { @('Azure') }
        { $_ -match 'AWS|Get-EC2|Get-S3' } { @('AWS') }
        { $_ -match 'GCP|gcloud' } { @('GCP') }
        default { @('Azure', 'AWS', 'GCP') }
    }

    $regions = foreach ($providerName in $providers) {
        & $module { param($p) Get-CloudRegionData -Provider $p } $providerName
    }

    $regions = $regions | Sort-Object -Unique
    $regions | Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object { [CompletionResult]::new($_, $_, 'ParameterValue', $_) }
}

Register-ArgumentCompleter -ParameterName ResourceGroup -ScriptBlock {
    param($commandName, $wordToComplete)

    # $commandName is required by the completer signature but not used for ResourceGroup
    $null = $commandName

    # Get-AzResourceGroup may not be available; guard against it
    if (-not (Get-Command Get-AzResourceGroup -ErrorAction SilentlyContinue)) {
        return
    }

    # Read context directly from module scope
    $ctx = & (Get-Module PSCumulus) { $script:PSCumulusContext }
    if (-not $ctx -or -not $ctx.Providers.Azure) {
        return
    }

    # Use cache if fresh (within 60 seconds)
    $now = [DateTime]::UtcNow
    $cacheKey = $ctx.Providers.Azure.SubscriptionId
    if ($script:__PSCumulusRgCacheLastUpdate -and
        ($now - $script:__PSCumulusRgCacheLastUpdate).TotalSeconds -lt 60 -and
        $script:__PSCumulusRgCache.ContainsKey($cacheKey)) {
        $rgs = $script:__PSCumulusRgCache[$cacheKey]
    } else {
        # Fetch from Azure
        $rgs = Get-AzResourceGroup -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty ResourceGroupName

        # Update cache
        $script:__PSCumulusRgCache[$cacheKey] = $rgs
        $script:__PSCumulusRgCacheLastUpdate = $now
    }

    $rgs | Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object { [CompletionResult]::new($_, $_, 'ParameterValue', $_) }
}

Register-ArgumentCompleter -ParameterName Project -ScriptBlock {
    param($commandName, $wordToComplete)

    # $commandName is required by the completer signature but not used for Project
    $null = $commandName

    # Read context directly from module scope
    $ctx = & (Get-Module PSCumulus) { $script:PSCumulusContext }
    if (-not $ctx -or -not $ctx.Providers.GCP) {
        return
    }

    $project = $ctx.Providers.GCP.Project
    if ($project -and $project -like "$wordToComplete*") {
        [CompletionResult]::new($project, $project, 'ParameterValue', $project)
    }
}
