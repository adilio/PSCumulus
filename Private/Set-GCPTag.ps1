function Set-GCPTag {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'This internal helper is invoked only by Set-CloudTag, which implements ShouldProcess.'
    )]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Project,

        [Parameter(Mandatory)]
        [string]$Resource,

        [Parameter(Mandatory)]
        [hashtable]$Tags,

        [switch]$Merge
    )

    Assert-CommandAvailable `
        -CommandName 'gcloud' `
        -InstallHint "Install the Google Cloud SDK: https://cloud.google.com/sdk/docs/install"

    if ($Merge) {
        $existingLabels = Invoke-GCloudJson -Arguments @('resource-manager', 'tags', 'list', '--filter', "resource:$Resource", '--format=json') -ErrorAction SilentlyContinue

        if ($existingLabels) {
            foreach ($binding in $existingLabels) {
                if ($binding.names) {
                    foreach ($name in $binding.names) {
                        if ($binding.shortValue -and -not $Tags.ContainsKey($name)) {
                            $Tags[$name] = $binding.shortValue
                        }
                    }
                }
            }
        }
    }

    $tagList = foreach ($key in $Tags.Keys) {
        "$key=$($Tags[$key])"
    }

    $joinedTags = $tagList -join ','
    $null = Invoke-GCloudJson -Arguments @('resource-manager', 'tags', 'create', '--tag', $joinedTags, '--parent', $Resource, '--project', $Project) -ErrorAction Stop
}
