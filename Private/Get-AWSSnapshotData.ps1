function Get-AWSSnapshotData {
    [CmdletBinding()]
    [OutputType([AWSSnapshotRecord])]
    param(
        [string]$Region
    )

    Assert-CommandAvailable `
        -CommandName 'Get-EC2Snapshot' `
        -InstallHint "Install the AWS.Tools.EC2 module with: Install-Module AWS.Tools.EC2 -Scope CurrentUser"

    # -OwnerId self keeps the listing to the caller's own snapshots; without it
    # EC2 returns every public snapshot in the region.
    $snapshots = if ([string]::IsNullOrWhiteSpace($Region)) {
        Get-EC2Snapshot -OwnerId self -ErrorAction Stop
    } else {
        Get-EC2Snapshot -OwnerId self -Region $Region -ErrorAction Stop
    }

    foreach ($snapshot in $snapshots) {
        [AWSSnapshotRecord]::FromEC2Snapshot($snapshot)
    }
}
