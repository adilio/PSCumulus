function Get-AzureDiskData {
    [CmdletBinding()]
    [OutputType([AzureDiskRecord])]
    param(
        [string]$ResourceGroup
    )

    Assert-CommandAvailable `
        -CommandName 'Get-AzDisk' `
        -InstallHint "Install the Az.Compute module with: Install-Module Az.Compute -Scope CurrentUser"

    $disks = if ([string]::IsNullOrWhiteSpace($ResourceGroup)) {
        Get-AzDisk -ErrorAction Stop
    } else {
        Get-AzDisk -ResourceGroupName $ResourceGroup -ErrorAction Stop
    }

    foreach ($disk in $disks) {
        [AzureDiskRecord]::FromAzDisk($disk)
    }
}
