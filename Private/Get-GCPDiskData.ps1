function Get-GCPDiskData {
    [CmdletBinding()]
    [OutputType([GCPDiskRecord])]
    param(
        [string]$Project
    )

    $null = Assert-GCloudAuthenticated
    $resolvedProject = Get-GCloudProject -Project $Project
    $disks = Invoke-GCloudJson -Arguments @('compute', 'disks', 'list', "--project=$resolvedProject")

    foreach ($disk in $disks) {
        [GCPDiskRecord]::FromGCloudJson($disk, $resolvedProject)
    }
}
