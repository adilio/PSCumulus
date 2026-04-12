function Get-AzureInstanceAddressData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$VirtualMachine
    )

    $result = @{
        PrivateIpAddress = $null
        PublicIpAddress  = $null
    }

    $networkInterfaces = @($VirtualMachine.NetworkProfile.NetworkInterfaces)
    if (-not $networkInterfaces -or $networkInterfaces.Count -eq 0) {
        return $result
    }

    $canResolveNetworkInterface = Get-Command -Name 'Get-AzNetworkInterface' -ErrorAction SilentlyContinue
    if (-not $canResolveNetworkInterface) {
        return $result
    }

    $canResolvePublicIp = Get-Command -Name 'Get-AzPublicIpAddress' -ErrorAction SilentlyContinue

    function Get-ResourceGroupAndNameFromResourceId {
        param(
            [string]$ResourceId
        )

        if ([string]::IsNullOrWhiteSpace($ResourceId)) {
            return $null
        }

        $segments = @($ResourceId -split '/')
        $resourceGroupIndex = [Array]::IndexOf($segments, 'resourceGroups')
        $providersIndex = [Array]::IndexOf($segments, 'providers')

        if ($resourceGroupIndex -lt 0 -or $resourceGroupIndex + 1 -ge $segments.Count) {
            return $null
        }

        if ($providersIndex -lt 0 -or $providersIndex + 1 -ge $segments.Count) {
            return $null
        }

        [pscustomobject]@{
            ResourceGroupName = $segments[$resourceGroupIndex + 1]
            Name              = $segments[-1]
        }
    }

    foreach ($networkInterfaceRef in $networkInterfaces) {
        if ([string]::IsNullOrWhiteSpace($networkInterfaceRef.Id)) {
            continue
        }

        $networkInterfaceIdentity = Get-ResourceGroupAndNameFromResourceId -ResourceId $networkInterfaceRef.Id
        if (-not $networkInterfaceIdentity) {
            continue
        }

        $networkInterface = Get-AzNetworkInterface `
            -ResourceGroupName $networkInterfaceIdentity.ResourceGroupName `
            -Name $networkInterfaceIdentity.Name `
            -ErrorAction Stop

        $ipConfig = @($networkInterface.IpConfigurations) |
            Where-Object { $_.Primary } |
            Select-Object -First 1

        if (-not $ipConfig) {
            $ipConfig = @($networkInterface.IpConfigurations) | Select-Object -First 1
        }

        if (-not $ipConfig) {
            continue
        }

        if (-not $result.PrivateIpAddress -and $ipConfig.PrivateIpAddress) {
            $result.PrivateIpAddress = $ipConfig.PrivateIpAddress
        }

        $publicIpReference = $ipConfig.PublicIpAddress
        if (-not $result.PublicIpAddress -and $publicIpReference -and $publicIpReference.Id -and $canResolvePublicIp) {
            $publicIpIdentity = Get-ResourceGroupAndNameFromResourceId -ResourceId $publicIpReference.Id
            if ($publicIpIdentity) {
                $publicIpAddress = Get-AzPublicIpAddress `
                    -ResourceGroupName $publicIpIdentity.ResourceGroupName `
                    -Name $publicIpIdentity.Name `
                    -ErrorAction Stop
            }

            if ($publicIpAddress.IpAddress) {
                $result.PublicIpAddress = $publicIpAddress.IpAddress
            }
        }

        if ($result.PrivateIpAddress -and $result.PublicIpAddress) {
            break
        }
    }

    $result
}
