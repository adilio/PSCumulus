$script:AzureRegions = @(
    'australiaeast', 'australiasoutheast', 'brazilsouth', 'brazilsoutheast',
    'canadacentral', 'canadaeast', 'centralindia', 'centralus',
    'centraluseuap', 'eastasia', 'eastus', 'eastus2',
    'eastus2euap', 'francecentral', 'francesouth', 'germanynorth',
    'germanywestcentral', 'japaneast', 'japanwest', 'jioindiacentral',
    'jioindiawest', 'koreacentral', 'koreasouth', 'northcentralus',
    'northeurope', 'norwayeast', 'norwaywest', 'qatarcentral',
    'southafricanorth', 'southafricawest', 'southcentralus', 'southeastasia',
    'southindia', 'swedencentral', 'switzerlandnorth', 'switzerlandwest',
    'uaecentral', 'uaenorth', 'uksouth', 'ukwest',
    'westcentralus', 'westeurope', 'westindia', 'westus',
    'westus2', 'westus3'
)

$script:AWSRegions = @(
    'af-south-1', 'ap-east-1', 'ap-northeast-1', 'ap-northeast-2',
    'ap-northeast-3', 'ap-south-1', 'ap-south-2', 'ap-southeast-1',
    'ap-southeast-2', 'ap-southeast-3', 'ap-southeast-4', 'ca-central-1',
    'ca-west-1', 'eu-central-1', 'eu-central-2', 'eu-north-1',
    'eu-south-1', 'eu-south-2', 'eu-west-1', 'eu-west-2',
    'eu-west-3', 'il-central-1', 'me-central-1', 'me-south-1',
    'sa-east-1', 'us-east-1', 'us-east-2', 'us-gov-east-1',
    'us-gov-west-1', 'us-west-1', 'us-west-2'
)

$script:GCPRegions = @(
    'asia-east1', 'asia-east2', 'asia-northeast1', 'asia-northeast2',
    'asia-northeast3', 'asia-south1', 'asia-south2', 'asia-southeast1',
    'asia-southeast2', 'australia-southeast1', 'australia-southeast2',
    'europe-central2', 'europe-north1', 'europe-southwest1',
    'europe-west1', 'europe-west10', 'europe-west12', 'europe-west2',
    'europe-west3', 'europe-west4', 'europe-west6', 'europe-west8',
    'europe-west9', 'me-central1', 'me-central2', 'me-west1',
    'northamerica-northeast1', 'northamerica-northeast2', 'southamerica-east1',
    'southamerica-west1', 'us-central1', 'us-east1', 'us-east4',
    'us-east5', 'us-south1', 'us-west1', 'us-west2', 'us-west3', 'us-west4'
)

# Cache for ResourceGroup completion (60-second TTL)
$script:__PSCumulusRgCache = @{}
$script:__PSCumulusRgCacheLastUpdate = $null

Register-ArgumentCompleter -ParameterName Region -ScriptBlock {
    param($commandName, $wordToComplete)

    $regions = switch ($commandName) {
        { $_ -match 'Azure|Get-Az' } { $script:AzureRegions }
        { $_ -match 'AWS|Get-EC2|Get-S3' } { $script:AWSRegions }
        { $_ -match 'GCP|gcloud' } { $script:GCPRegions }
        default { @($script:AzureRegions; $script:AWSRegions; $script:GCPRegions) | Sort-Object -Unique }
    }

    $regions | Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object { [CompletionResult]::new($_, $_, 'ParameterValue', $_) }
}

Register-ArgumentCompleter -ParameterName ResourceGroup -ScriptBlock {
    param($commandName, $wordToComplete)

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
