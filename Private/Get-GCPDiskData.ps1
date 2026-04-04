function Get-GCPDiskData {
    [CmdletBinding()]
    param(
        [string]$Project
    )

    $null = Assert-GCloudAuthenticated
    $resolvedProject = Get-GCloudProject -Project $Project
    $disks = Invoke-GCloudJson -Arguments @('compute', 'disks', 'list', "--project=$resolvedProject")

    foreach ($disk in $disks) {
        $zoneName = if ($disk.zone) {
            ($disk.zone -split '/')[-1]
        } else {
            $null
        }

        $diskType = if ($disk.type) {
            ($disk.type -split '/')[-1]
        } else {
            $null
        }

        $status = if ($disk.status) {
            (Get-Culture).TextInfo.ToTitleCase($disk.status.ToLower())
        } else {
            $null
        }

        $params = @{
            Name     = $disk.name
            Provider = 'GCP'
            Region   = $zoneName
            Size     = "$($disk.sizeGb) GB"
            Metadata = @{
                Project  = $resolvedProject
                Zone     = $zoneName
                DiskType = $diskType
                SizeGb   = $disk.sizeGb
            }
        }

        if ($status) { $params.Status = $status }

        if (-not [string]::IsNullOrWhiteSpace($disk.creationTimestamp)) {
            $params.CreatedAt = [datetime]::Parse($disk.creationTimestamp)
        }

        ConvertTo-CloudRecord @params
    }
}
