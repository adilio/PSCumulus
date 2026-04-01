function Get-AzureInstanceData {
    [CmdletBinding()]
    param(
        [string]$ResourceGroup
    )

    Assert-CommandAvailable `
        -CommandName 'Get-AzVM' `
        -InstallHint "Install the Az.Compute module with: Install-Module Az.Compute -Scope CurrentUser"

    $virtualMachines = Get-AzVM -ResourceGroupName $ResourceGroup -Status -ErrorAction Stop

    foreach ($virtualMachine in $virtualMachines) {
        $powerStatus = $virtualMachine.Statuses |
            Where-Object { $_.Code -like 'PowerState/*' } |
            Select-Object -First 1 -ExpandProperty DisplayStatus

        ConvertTo-CloudRecord `
            -Name $virtualMachine.Name `
            -Provider Azure `
            -Region $virtualMachine.Location `
            -Status (ConvertFrom-AzurePowerState -PowerState $powerStatus) `
            -Size $virtualMachine.HardwareProfile.VmSize `
            -CreatedAt $null `
            -Metadata @{
                ResourceGroup = $virtualMachine.ResourceGroupName
                VmId          = $virtualMachine.VmId
                OsType        = $virtualMachine.StorageProfile.OsDisk.OsType.ToString()
            }
    }
}
