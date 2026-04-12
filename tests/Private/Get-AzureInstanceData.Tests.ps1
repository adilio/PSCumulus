BeforeAll {
    if (-not (Get-Command Get-AzNetworkInterface -ErrorAction SilentlyContinue)) {
        $script:stubCreatedGetAzNetworkInterface = $true
        function global:Get-AzNetworkInterface { param([string]$ResourceId) }
    }

    if (-not (Get-Command Get-AzPublicIpAddress -ErrorAction SilentlyContinue)) {
        $script:stubCreatedGetAzPublicIpAddress = $true
        function global:Get-AzPublicIpAddress { param([string]$ResourceId) }
    }

    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

AfterAll {
    if ($script:stubCreatedGetAzNetworkInterface) {
        Remove-Item -Path Function:global:Get-AzNetworkInterface -ErrorAction SilentlyContinue
    }

    if ($script:stubCreatedGetAzPublicIpAddress) {
        Remove-Item -Path Function:global:Get-AzPublicIpAddress -ErrorAction SilentlyContinue
    }
}

Describe 'Get-AzureInstanceData' {

    Context 'when Az.Compute is not installed' {
        It 'throws when Get-AzVM is unavailable' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {
                    throw [System.Management.Automation.CommandNotFoundException]::new(
                        "Required command 'Get-AzVM' was not found."
                    )
                }

                { Get-AzureInstanceData -ResourceGroup 'prod-rg' } | Should -Throw
            }
        }
    }

    Context 'when VMs are returned' {
        BeforeAll {
            $script:mockVm = [pscustomobject]@{
                Name              = 'web-server-01'
                Location          = 'eastus'
                ResourceGroupName = 'prod-rg'
                VmId              = 'vm-guid-1234'
                NetworkProfile    = [pscustomobject]@{ NetworkInterfaces = @() }
                HardwareProfile   = [pscustomobject]@{ VmSize = 'Standard_D2s_v3' }
                StorageProfile    = [pscustomobject]@{
                    OsDisk = [pscustomobject]@{ OsType = 'Linux' }
                }
                Statuses          = @(
                    [pscustomobject]@{ Code = 'ProvisioningState/succeeded'; DisplayStatus = 'Provisioning succeeded' }
                    [pscustomobject]@{ Code = 'PowerState/running'; DisplayStatus = 'VM running' }
                )
            }
        }

        It 'returns a CloudRecord for each VM' {
            InModuleScope PSCumulus -Parameters @{ MockVm = $script:mockVm } {
                param($MockVm)
                Mock Assert-CommandAvailable {}
                Mock Get-AzVM { @($MockVm) }

                $results = @(Get-AzureInstanceData -ResourceGroup 'prod-rg')
                $results.Count | Should -Be 1
            }
        }

        It 'maps Name correctly' {
            InModuleScope PSCumulus -Parameters @{ MockVm = $script:mockVm } {
                param($MockVm)
                Mock Assert-CommandAvailable {}
                Mock Get-AzVM { @($MockVm) }

                $result = Get-AzureInstanceData -ResourceGroup 'prod-rg'
                $result.Name | Should -Be 'web-server-01'
            }
        }

        It 'sets Provider to Azure' {
            InModuleScope PSCumulus -Parameters @{ MockVm = $script:mockVm } {
                param($MockVm)
                Mock Assert-CommandAvailable {}
                Mock Get-AzVM { @($MockVm) }

                $result = Get-AzureInstanceData -ResourceGroup 'prod-rg'
                $result.Provider | Should -Be 'Azure'
            }
        }

        It 'maps Location to Region' {
            InModuleScope PSCumulus -Parameters @{ MockVm = $script:mockVm } {
                param($MockVm)
                Mock Assert-CommandAvailable {}
                Mock Get-AzVM { @($MockVm) }

                $result = Get-AzureInstanceData -ResourceGroup 'prod-rg'
                $result.Region | Should -Be 'eastus'
            }
        }

        It 'strips the VM prefix from the power state' {
            InModuleScope PSCumulus -Parameters @{ MockVm = $script:mockVm } {
                param($MockVm)
                Mock Assert-CommandAvailable {}
                Mock Get-AzVM { @($MockVm) }

                $result = Get-AzureInstanceData -ResourceGroup 'prod-rg'
                $result.Status | Should -Be 'Running'
            }
        }

        It 'falls back to Ready when no power state is returned' {
            InModuleScope PSCumulus {
                $vmWithoutPowerState = [pscustomobject]@{
                    Name              = 'offline-vm'
                    Location          = 'eastus'
                    ResourceGroupName = 'prod-rg'
                    VmId              = 'vm-guid-offline'
                    NetworkProfile    = [pscustomobject]@{ NetworkInterfaces = @() }
                    HardwareProfile   = [pscustomobject]@{ VmSize = 'Standard_D2s_v3' }
                    StorageProfile    = [pscustomobject]@{
                        OsDisk = [pscustomobject]@{ OsType = 'Linux' }
                    }
                    Statuses          = @(
                        [pscustomobject]@{ Code = 'ProvisioningState/succeeded'; DisplayStatus = 'Provisioning succeeded' }
                    )
                }

                Mock Assert-CommandAvailable {}
                Mock Get-AzVM { @($vmWithoutPowerState) }

                $result = Get-AzureInstanceData -ResourceGroup 'prod-rg'
                $result.Status | Should -Be 'Ready'
                $result.Metadata.PowerState | Should -BeNullOrEmpty
            }
        }

        It 'maps VmSize to Size' {
            InModuleScope PSCumulus -Parameters @{ MockVm = $script:mockVm } {
                param($MockVm)
                Mock Assert-CommandAvailable {}
                Mock Get-AzVM { @($MockVm) }

                $result = Get-AzureInstanceData -ResourceGroup 'prod-rg'
                $result.Size | Should -Be 'Standard_D2s_v3'
            }
        }

        It 'includes ResourceGroup in Metadata' {
            InModuleScope PSCumulus -Parameters @{ MockVm = $script:mockVm } {
                param($MockVm)
                Mock Assert-CommandAvailable {}
                Mock Get-AzVM { @($MockVm) }

                $result = Get-AzureInstanceData -ResourceGroup 'prod-rg'
                $result.Metadata.ResourceGroup | Should -Be 'prod-rg'
            }
        }

        It 'includes VmId in Metadata' {
            InModuleScope PSCumulus -Parameters @{ MockVm = $script:mockVm } {
                param($MockVm)
                Mock Assert-CommandAvailable {}
                Mock Get-AzVM { @($MockVm) }

                $result = Get-AzureInstanceData -ResourceGroup 'prod-rg'
                $result.Metadata.VmId | Should -Be 'vm-guid-1234'
            }
        }

        It 'returns PSCumulus.CloudRecord type' {
            InModuleScope PSCumulus -Parameters @{ MockVm = $script:mockVm } {
                param($MockVm)
                Mock Assert-CommandAvailable {}
                Mock Get-AzVM { @($MockVm) }

                $result = Get-AzureInstanceData -ResourceGroup 'prod-rg'
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRecord'
            }
        }

        It 'returns nothing when the resource group has no VMs' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Get-AzVM { @() }

                $results = @(Get-AzureInstanceData -ResourceGroup 'empty-rg')
                $results.Count | Should -Be 0
            }
        }

        It 'returns all VMs when ResourceGroup is empty' {
            InModuleScope PSCumulus -Parameters @{ MockVm = $script:mockVm } {
                param($MockVm)
                Mock Assert-CommandAvailable {}
                Mock Get-AzVM { @($MockVm) }

                $results = @(Get-AzureInstanceData)
                $results.Count | Should -Be 1
                Should -Invoke Get-AzVM -Times 1 -ParameterFilter { -not $ResourceGroupName }
            }
        }

        It 'includes VM tags in the Tags property' {
            InModuleScope PSCumulus {
                $vmWithTags = [pscustomobject]@{
                    Name              = 'tagged-vm'
                    Location          = 'eastus'
                    ResourceGroupName = 'prod-rg'
                    VmId              = 'vm-guid-tagged'
                    NetworkProfile    = [pscustomobject]@{ NetworkInterfaces = @() }
                    HardwareProfile   = [pscustomobject]@{ VmSize = 'Standard_D2s_v3' }
                    StorageProfile    = [pscustomobject]@{
                        OsDisk = [pscustomobject]@{ OsType = 'Linux' }
                    }
                    Tags              = @{ environment = 'prod'; team = 'platform' }
                    Statuses          = @(
                        [pscustomobject]@{ Code = 'PowerState/running'; DisplayStatus = 'VM running' }
                    )
                }
                Mock Assert-CommandAvailable {}
                Mock Get-AzVM { @($vmWithTags) }

                $result = Get-AzureInstanceData -ResourceGroup 'prod-rg'
                $result.Tags['environment'] | Should -Be 'prod'
                $result.Tags['team'] | Should -Be 'platform'
            }
        }

        It 'includes private and public IPs when network data is available' {
            InModuleScope PSCumulus {
                $vmWithNetwork = [pscustomobject]@{
                    Name              = 'networked-vm'
                    Location          = 'eastus'
                    ResourceGroupName = 'prod-rg'
                    VmId              = 'vm-guid-network'
                    NetworkProfile    = [pscustomobject]@{
                        NetworkInterfaces = @([pscustomobject]@{ Id = '/subscriptions/sub/resourceGroups/prod-rg/providers/Microsoft.Network/networkInterfaces/nic-1' })
                    }
                    HardwareProfile   = [pscustomobject]@{ VmSize = 'Standard_D2s_v3' }
                    StorageProfile    = [pscustomobject]@{
                        OsDisk = [pscustomobject]@{ OsType = 'Linux' }
                    }
                    Statuses          = @(
                        [pscustomobject]@{ Code = 'PowerState/running'; DisplayStatus = 'VM running' }
                    )
                }

                $networkInterface = [pscustomobject]@{
                    IpConfigurations = @([pscustomobject]@{
                        Primary          = $true
                        PrivateIpAddress = '10.0.1.4'
                        PublicIpAddress  = [pscustomobject]@{ Id = '/subscriptions/sub/resourceGroups/prod-rg/providers/Microsoft.Network/publicIPAddresses/pip-1' }
                    })
                }

                Mock Assert-CommandAvailable {}
                Mock Get-AzVM { @($vmWithNetwork) }
                Mock Get-AzNetworkInterface { $networkInterface }
                Mock Get-AzPublicIpAddress { [pscustomobject]@{ IpAddress = '52.160.1.10' } }

                $result = Get-AzureInstanceData -ResourceGroup 'prod-rg'
                $result.PrivateIpAddress | Should -Be '10.0.1.4'
                $result.PublicIpAddress | Should -Be '52.160.1.10'
            }
        }

        It 'leaves IPs null when network data is unavailable' {
            InModuleScope PSCumulus {
                $vmWithoutNetwork = [pscustomobject]@{
                    Name              = 'bare-vm'
                    Location          = 'eastus'
                    ResourceGroupName = 'prod-rg'
                    VmId              = 'vm-guid-bare'
                    HardwareProfile   = [pscustomobject]@{ VmSize = 'Standard_D2s_v3' }
                    StorageProfile    = [pscustomobject]@{
                        OsDisk = [pscustomobject]@{ OsType = 'Linux' }
                    }
                    Statuses          = @(
                        [pscustomobject]@{ Code = 'PowerState/running'; DisplayStatus = 'VM running' }
                    )
                }

                Mock Assert-CommandAvailable {}
                Mock Get-AzVM { @($vmWithoutNetwork) }

                $result = Get-AzureInstanceData -ResourceGroup 'prod-rg'
                $result.PrivateIpAddress | Should -BeNullOrEmpty
                $result.PublicIpAddress | Should -BeNullOrEmpty
            }
        }

        It 'filters by Name when provided' {
            InModuleScope PSCumulus -Parameters @{ MockVm = $script:mockVm } {
                param($MockVm)
                $otherVm = [pscustomobject]@{
                    Name              = 'other-vm'
                    Location          = 'eastus'
                    ResourceGroupName = 'prod-rg'
                    VmId              = 'vm-guid-other'
                    HardwareProfile   = [pscustomobject]@{ VmSize = 'Standard_D2s_v3' }
                    StorageProfile    = [pscustomobject]@{
                        OsDisk = [pscustomobject]@{ OsType = 'Linux' }
                    }
                    Statuses          = @(
                        [pscustomobject]@{ Code = 'PowerState/running'; DisplayStatus = 'VM running' }
                    )
                }
                Mock Assert-CommandAvailable {}
                Mock Get-AzVM { @($MockVm, $otherVm) }

                $results = @(Get-AzureInstanceData -ResourceGroup 'prod-rg' -Name 'web-server-01')
                $results.Count | Should -Be 1
                $results[0].Name | Should -Be 'web-server-01'
            }
        }
    }
}
