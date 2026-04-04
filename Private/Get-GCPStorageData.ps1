function Get-GCPStorageData {
    [CmdletBinding()]
    param(
        [string]$Project
    )

    $null = Assert-GCloudAuthenticated
    $resolvedProject = Get-GCloudProject -Project $Project
    $buckets = Invoke-GCloudJson -Arguments @('storage', 'buckets', 'list', "--project=$resolvedProject")

    foreach ($bucket in $buckets) {
        # Bucket names may be prefixed with "gs://" in some output formats
        $name = $bucket.name -replace '^gs://', ''

        $params = @{
            Name     = $name
            Provider = 'GCP'
            Region   = $bucket.location
            Status   = 'Available'
            Size     = $bucket.storageClass
            Metadata = @{
                Project      = $resolvedProject
                StorageClass = $bucket.storageClass
                Location     = $bucket.location
            }
        }

        if (-not [string]::IsNullOrWhiteSpace($bucket.timeCreated)) {
            $params.CreatedAt = [datetime]::Parse($bucket.timeCreated)
        }

        ConvertTo-CloudRecord @params
    }
}
