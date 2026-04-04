BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Get-GCPNetworkData' {

    BeforeAll {
        $script:activeAccount = [pscustomobject]@{ account = 'user@example.com'; status = 'ACTIVE' }

        $script:mockNetwork = [pscustomobject]@{
            name                  = 'prod-network'
            autoCreateSubnetworks = $false
        }

        $script:mockAutoNetwork = [pscustomobject]@{
            name                  = 'default'
            autoCreateSubnetworks = $true
        }
    }

    Context 'successful retrieval' {
        It 'returns a CloudRecord for each network' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Network = $script:mockNetwork } {
                param($Account, $Network)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Network) }

                $results = @(Get-GCPNetworkData -Project 'my-project')
                $results.Count | Should -Be 1
            }
        }

        It 'maps network name correctly' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Network = $script:mockNetwork } {
                param($Account, $Network)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Network) }

                $result = Get-GCPNetworkData -Project 'my-project'
                $result.Name | Should -Be 'prod-network'
            }
        }

        It 'sets Provider to GCP' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Network = $script:mockNetwork } {
                param($Account, $Network)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Network) }

                $result = Get-GCPNetworkData -Project 'my-project'
                $result.Provider | Should -Be 'GCP'
            }
        }

        It 'sets Region to global' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Network = $script:mockNetwork } {
                param($Account, $Network)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Network) }

                $result = Get-GCPNetworkData -Project 'my-project'
                $result.Region | Should -Be 'global'
            }
        }

        It 'sets Status to Available' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Network = $script:mockNetwork } {
                param($Account, $Network)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Network) }

                $result = Get-GCPNetworkData -Project 'my-project'
                $result.Status | Should -Be 'Available'
            }
        }

        It 'sets SubnetworkMode to custom for manual subnet networks' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Network = $script:mockNetwork } {
                param($Account, $Network)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Network) }

                $result = Get-GCPNetworkData -Project 'my-project'
                $result.Metadata.SubnetworkMode | Should -Be 'custom'
            }
        }

        It 'sets SubnetworkMode to auto for auto subnet networks' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; AutoNetwork = $script:mockAutoNetwork } {
                param($Account, $AutoNetwork)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($AutoNetwork) }

                $result = Get-GCPNetworkData -Project 'my-project'
                $result.Metadata.SubnetworkMode | Should -Be 'auto'
            }
        }

        It 'returns PSCumulus.CloudRecord type' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Network = $script:mockNetwork } {
                param($Account, $Network)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Network) }

                $result = Get-GCPNetworkData -Project 'my-project'
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRecord'
            }
        }
    }

    Context 'authentication' {
        It 'throws when not authenticated' {
            InModuleScope PSCumulus {
                Mock Assert-GCloudAuthenticated {
                    throw [System.InvalidOperationException]::new('No active gcloud account found.')
                }

                { Get-GCPNetworkData -Project 'my-project' } | Should -Throw
            }
        }
    }
}
