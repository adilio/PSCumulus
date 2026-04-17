function Get-AWSStorageData {
    [CmdletBinding()]
    [OutputType([AWSStorageRecord])]
    param(
        [string]$Region
    )

    Assert-CommandAvailable `
        -CommandName 'Get-S3Bucket' `
        -InstallHint "Install the AWS.Tools.S3 module with: Install-Module AWS.Tools.S3 -Scope CurrentUser"

    Assert-CommandAvailable `
        -CommandName 'Get-S3BucketLocation' `
        -InstallHint "Install the AWS.Tools.S3 module with: Install-Module AWS.Tools.S3 -Scope CurrentUser"

    $buckets = Get-S3Bucket -ErrorAction Stop

    foreach ($bucket in $buckets) {
        $locationResponse = Get-S3BucketLocation -BucketName $bucket.BucketName -ErrorAction Stop
        $bucketRegion = if ([string]::IsNullOrWhiteSpace($locationResponse.Value)) {
            'us-east-1'
        } else {
            $locationResponse.Value
        }

        if (-not [string]::IsNullOrWhiteSpace($Region) -and $bucketRegion -ne $Region) {
            continue
        }

        [AWSStorageRecord]::FromS3Bucket($bucket, $bucketRegion)
    }
}
