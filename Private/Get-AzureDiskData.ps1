function Get-AzureDiskData {
    [CmdletBinding()]
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
        $status = if ($disk.DiskState) { $disk.DiskState.ToString() } else { $null }

        $params = @{
            Name     = $disk.Name
            Provider = 'Azure'
            Region   = $disk.Location
            Size     = "$($disk.DiskSizeGB) GB"
            Metadata = @{
                ResourceGroup = $disk.ResourceGroupName
                DiskSizeGB    = $disk.DiskSizeGB
                OsType        = if ($disk.OsType) { $disk.OsType.ToString() } else { $null }
                Sku           = $disk.Sku.Name
            }
        }

        if ($status) { $params.Status = $status }
        if ($disk.TimeCreated) { $params.CreatedAt = $disk.TimeCreated }

        ConvertTo-CloudRecord @params
    }
}
