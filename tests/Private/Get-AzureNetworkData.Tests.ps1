BeforeAll {
    # Stub Az.Network commands so Pester can create mocks when Az.Network is not installed
    if (-not (Get-Command Get-AzVirtualNetwork -ErrorAction SilentlyContinue)) {
        $script:stubCreatedGetAzVirtualNetwork = $true
        function global:Get-AzVirtualNetwork { param([string]$ResourceGroupName) }
    }

    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

AfterAll {
    if ($script:stubCreatedGetAzVirtualNetwork) {
        Remove-Item -Path Function:global:Get-AzVirtualNetwork -ErrorAction SilentlyContinue
    }
}

Describe 'Get-AzureNetworkData' {

    Context 'when Az.Network is not installed' {
        It 'throws when Get-AzVirtualNetwork is unavailable' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {
                    throw [System.Management.Automation.CommandNotFoundException]::new(
                        "Required command 'Get-AzVirtualNetwork' was not found."
                    )
                }

                { Get-AzureNetworkData -ResourceGroup 'prod-rg' } | Should -Throw
            }
        }
    }

    Context 'when virtual networks are returned' {
        BeforeAll {
            $script:mockVnet = [pscustomobject]@{
                Name              = 'prod-vnet'
                ResourceGroupName = 'prod-rg'
                Location          = 'eastus'
                ProvisioningState = 'Succeeded'
                AddressSpace      = [pscustomobject]@{
                    AddressPrefixes = @('10.0.0.0/16', '10.1.0.0/16')
                }
                Subnets           = @(
                    [pscustomobject]@{ Name = 'subnet-01' }
                    [pscustomobject]@{ Name = 'subnet-02' }
                )
            }
        }

        It 'returns a CloudRecord for each VNet' {
            InModuleScope PSCumulus -Parameters @{ MockVnet = $script:mockVnet } {
                param($MockVnet)
                Mock Assert-CommandAvailable {}
                Mock Get-AzVirtualNetwork { @($MockVnet) }

                $results = @(Get-AzureNetworkData -ResourceGroup 'prod-rg')
                $results.Count | Should -Be 1
            }
        }

        It 'maps Name correctly' {
            InModuleScope PSCumulus -Parameters @{ MockVnet = $script:mockVnet } {
                param($MockVnet)
                Mock Assert-CommandAvailable {}
                Mock Get-AzVirtualNetwork { @($MockVnet) }

                $result = Get-AzureNetworkData -ResourceGroup 'prod-rg'
                $result.Name | Should -Be 'prod-vnet'
            }
        }

        It 'sets Provider to Azure' {
            InModuleScope PSCumulus -Parameters @{ MockVnet = $script:mockVnet } {
                param($MockVnet)
                Mock Assert-CommandAvailable {}
                Mock Get-AzVirtualNetwork { @($MockVnet) }

                $result = Get-AzureNetworkData -ResourceGroup 'prod-rg'
                $result.Provider | Should -Be 'Azure'
            }
        }

        It 'maps Location to Region' {
            InModuleScope PSCumulus -Parameters @{ MockVnet = $script:mockVnet } {
                param($MockVnet)
                Mock Assert-CommandAvailable {}
                Mock Get-AzVirtualNetwork { @($MockVnet) }

                $result = Get-AzureNetworkData -ResourceGroup 'prod-rg'
                $result.Region | Should -Be 'eastus'
            }
        }

        It 'maps ProvisioningState to Status' {
            InModuleScope PSCumulus -Parameters @{ MockVnet = $script:mockVnet } {
                param($MockVnet)
                Mock Assert-CommandAvailable {}
                Mock Get-AzVirtualNetwork { @($MockVnet) }

                $result = Get-AzureNetworkData -ResourceGroup 'prod-rg'
                $result.Status | Should -Be 'Succeeded'
            }
        }

        It 'uses first address prefix as Size' {
            InModuleScope PSCumulus -Parameters @{ MockVnet = $script:mockVnet } {
                param($MockVnet)
                Mock Assert-CommandAvailable {}
                Mock Get-AzVirtualNetwork { @($MockVnet) }

                $result = Get-AzureNetworkData -ResourceGroup 'prod-rg'
                $result.Size | Should -Be '10.0.0.0/16'
            }
        }

        It 'includes SubnetCount in Metadata' {
            InModuleScope PSCumulus -Parameters @{ MockVnet = $script:mockVnet } {
                param($MockVnet)
                Mock Assert-CommandAvailable {}
                Mock Get-AzVirtualNetwork { @($MockVnet) }

                $result = Get-AzureNetworkData -ResourceGroup 'prod-rg'
                $result.Metadata.SubnetCount | Should -Be 2
            }
        }

        It 'returns PSCumulus.CloudRecord type' {
            InModuleScope PSCumulus -Parameters @{ MockVnet = $script:mockVnet } {
                param($MockVnet)
                Mock Assert-CommandAvailable {}
                Mock Get-AzVirtualNetwork { @($MockVnet) }

                $result = Get-AzureNetworkData -ResourceGroup 'prod-rg'
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRecord'
            }
        }
    }
}
