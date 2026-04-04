function Get-AzureNetworkData {
    [CmdletBinding()]
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
        $addressPrefix = if ($vnet.AddressSpace -and $vnet.AddressSpace.AddressPrefixes) {
            $vnet.AddressSpace.AddressPrefixes | Select-Object -First 1
        } else {
            $null
        }

        $params = @{
            Name     = $vnet.Name
            Provider = 'Azure'
            Region   = $vnet.Location
            Status   = $vnet.ProvisioningState
            Metadata = @{
                ResourceGroup = $vnet.ResourceGroupName
                AddressSpace  = $vnet.AddressSpace.AddressPrefixes
                SubnetCount   = @($vnet.Subnets).Count
            }
        }

        if ($addressPrefix) { $params.Size = $addressPrefix }

        ConvertTo-CloudRecord @params
    }
}
