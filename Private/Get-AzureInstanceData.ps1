function Get-AzureInstanceData {
    [CmdletBinding()]
    param(
        [string]$ResourceGroup,
        [string]$Name
    )

    Assert-CommandAvailable `
        -CommandName 'Get-AzVM' `
        -InstallHint "Install the Az.Compute module with: Install-Module Az.Compute -Scope CurrentUser"

    $virtualMachines = if ([string]::IsNullOrWhiteSpace($ResourceGroup)) {
        Get-AzVM -Status -ErrorAction Stop
    } else {
        Get-AzVM -ResourceGroupName $ResourceGroup -Status -ErrorAction Stop
    }

    if (-not [string]::IsNullOrWhiteSpace($Name)) {
        $virtualMachines = @(
            $virtualMachines | Where-Object { $_.Name -eq $Name }
        )
    }

    foreach ($virtualMachine in $virtualMachines) {
        $powerStatus = $virtualMachine.Statuses |
            Where-Object { $_.Code -like 'PowerState/*' } |
            Select-Object -First 1 -ExpandProperty DisplayStatus

        $normalizedStatus = ConvertFrom-AzurePowerState -PowerState $powerStatus
        if ([string]::IsNullOrWhiteSpace($normalizedStatus)) {
            $normalizedStatus = 'Ready'
        }

        $tagHashtable = [CloudTagHelper]::FromAzureTags($virtualMachine.Tags)

        $addressData = Get-AzureInstanceAddressData -VirtualMachine $virtualMachine

        ConvertTo-CloudRecord `
            -Name $virtualMachine.Name `
            -Provider Azure `
            -Region $virtualMachine.Location `
            -Status $normalizedStatus `
            -Size $virtualMachine.HardwareProfile.VmSize `
            -PrivateIpAddress $addressData.PrivateIpAddress `
            -PublicIpAddress $addressData.PublicIpAddress `
            -Tags $tagHashtable `
            -Metadata @{
                ResourceGroup = $virtualMachine.ResourceGroupName
                VmId          = $virtualMachine.VmId
                OsType        = $virtualMachine.StorageProfile.OsDisk.OsType.ToString()
                PowerState    = $powerStatus
                NativeStatus  = $powerStatus
            }
    }
}
