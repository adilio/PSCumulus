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
        $addressData = Get-AzureInstanceAddressData -VirtualMachine $virtualMachine
        [AzureCloudRecord]::FromAzVM($virtualMachine, $addressData)
    }
}
