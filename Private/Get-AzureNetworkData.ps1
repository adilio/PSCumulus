function Get-AzureNetworkData {
    [CmdletBinding()]
    [OutputType([AzureNetworkRecord])]
    param(
        [string]$ResourceGroup
    )

    Assert-CommandAvailable `
        -CommandName 'Get-AzVirtualNetwork' `
        -InstallHint "Install the Az.Network module with: Install-Module Az.Network -Scope CurrentUser"

    $vnets = if ([string]::IsNullOrWhiteSpace($ResourceGroup)) {
        Get-AzVirtualNetwork -ErrorAction Stop
    } else {
        Get-AzVirtualNetwork -ResourceGroupName $ResourceGroup -ErrorAction Stop
    }

    foreach ($vnet in $vnets) {
        [AzureNetworkRecord]::FromAzVirtualNetwork($vnet)
    }
}
