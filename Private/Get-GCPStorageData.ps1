function Get-GCPStorageData {
    [CmdletBinding()]
    [OutputType([GCPStorageRecord])]
    param(
        [string]$Project
    )

    $null = Assert-GCloudAuthenticated
    $resolvedProject = Get-GCloudProject -Project $Project
    $buckets = Invoke-GCloudJson -Arguments @('storage', 'buckets', 'list', "--project=$resolvedProject")

    foreach ($bucket in $buckets) {
        [GCPStorageRecord]::FromGCloudJson($bucket, $resolvedProject)
    }
}
