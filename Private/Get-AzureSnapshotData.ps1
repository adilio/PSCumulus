function Get-AzureSnapshotData {
    [CmdletBinding()]
    [OutputType([AzureSnapshotRecord])]
    param(
        [string]$ResourceGroup
    )

    Assert-CommandAvailable `
        -CommandName 'Get-AzSnapshot' `
        -InstallHint "Install the Az.Compute module with: Install-Module Az.Compute -Scope CurrentUser"

    $snapshots = if ([string]::IsNullOrWhiteSpace($ResourceGroup)) {
        Get-AzSnapshot -ErrorAction Stop
    } else {
        Get-AzSnapshot -ResourceGroupName $ResourceGroup -ErrorAction Stop
    }

    foreach ($snapshot in $snapshots) {
        [AzureSnapshotRecord]::FromAzSnapshot($snapshot)
    }
}
