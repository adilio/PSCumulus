function Get-GCPSnapshotData {
    [CmdletBinding()]
    [OutputType([GCPSnapshotRecord])]
    param(
        [string]$Project
    )

    $null = Assert-GCloudAuthenticated
    $resolvedProject = Get-GCloudProject -Project $Project
    $snapshots = Invoke-GCloudJson -Arguments @('compute', 'snapshots', 'list', "--project=$resolvedProject")

    foreach ($snapshot in $snapshots) {
        [GCPSnapshotRecord]::FromGCloudJson($snapshot, $resolvedProject)
    }
}
