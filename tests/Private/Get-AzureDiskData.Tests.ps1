BeforeAll {
    # Stub Az.Compute disk command so Pester can create mocks when Az.Compute does not expose Get-AzDisk
    if (-not (Get-Command Get-AzDisk -ErrorAction SilentlyContinue)) {
        $script:stubCreatedGetAzDisk = $true
        function global:Get-AzDisk { param([string]$ResourceGroupName) }
    }

    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

AfterAll {
    if ($script:stubCreatedGetAzDisk) {
        Remove-Item -Path Function:global:Get-AzDisk -ErrorAction SilentlyContinue
    }
}

Describe 'Get-AzureDiskData' {

    Context 'when Az.Compute is not installed' {
        It 'throws when Get-AzDisk is unavailable' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {
                    throw [System.Management.Automation.CommandNotFoundException]::new(
                        "Required command 'Get-AzDisk' was not found."
                    )
                }

                { Get-AzureDiskData -ResourceGroup 'prod-rg' } | Should -Throw
            }
        }
    }

    Context 'when disks are returned' {
        BeforeAll {
            # Use plain strings for enum-like properties so .ToString() returns expected values
            $script:mockDisk = [pscustomobject]@{
                Name              = 'os-disk-01'
                ResourceGroupName = 'prod-rg'
                Location          = 'eastus'
                DiskSizeGB        = 128
                DiskState         = 'Attached'
                OsType            = 'Linux'
                Sku               = [pscustomobject]@{ Name = 'Premium_LRS' }
                TimeCreated       = [datetime]'2026-01-15T09:00:00Z'
            }
        }

        It 'returns a CloudRecord for each disk' {
            InModuleScope PSCumulus -Parameters @{ MockDisk = $script:mockDisk } {
                param($MockDisk)
                Mock Assert-CommandAvailable {}
                Mock Get-AzDisk { @($MockDisk) }

                $results = @(Get-AzureDiskData -ResourceGroup 'prod-rg')
                $results.Count | Should -Be 1
            }
        }

        It 'maps Name correctly' {
            InModuleScope PSCumulus -Parameters @{ MockDisk = $script:mockDisk } {
                param($MockDisk)
                Mock Assert-CommandAvailable {}
                Mock Get-AzDisk { @($MockDisk) }

                $result = Get-AzureDiskData -ResourceGroup 'prod-rg'
                $result.Name | Should -Be 'os-disk-01'
            }
        }

        It 'sets Provider to Azure' {
            InModuleScope PSCumulus -Parameters @{ MockDisk = $script:mockDisk } {
                param($MockDisk)
                Mock Assert-CommandAvailable {}
                Mock Get-AzDisk { @($MockDisk) }

                $result = Get-AzureDiskData -ResourceGroup 'prod-rg'
                $result.Provider | Should -Be 'Azure'
            }
        }

        It 'maps Location to Region' {
            InModuleScope PSCumulus -Parameters @{ MockDisk = $script:mockDisk } {
                param($MockDisk)
                Mock Assert-CommandAvailable {}
                Mock Get-AzDisk { @($MockDisk) }

                $result = Get-AzureDiskData -ResourceGroup 'prod-rg'
                $result.Region | Should -Be 'eastus'
            }
        }

        It 'formats DiskSizeGB as Size' {
            InModuleScope PSCumulus -Parameters @{ MockDisk = $script:mockDisk } {
                param($MockDisk)
                Mock Assert-CommandAvailable {}
                Mock Get-AzDisk { @($MockDisk) }

                $result = Get-AzureDiskData -ResourceGroup 'prod-rg'
                $result.Size | Should -Be '128 GB'
            }
        }

        It 'maps TimeCreated to CreatedAt' {
            InModuleScope PSCumulus -Parameters @{ MockDisk = $script:mockDisk } {
                param($MockDisk)
                Mock Assert-CommandAvailable {}
                Mock Get-AzDisk { @($MockDisk) }

                $result = Get-AzureDiskData -ResourceGroup 'prod-rg'
                $result.CreatedAt | Should -Be ([datetime]'2026-01-15T09:00:00Z')
            }
        }

        It 'includes Sku in Metadata' {
            InModuleScope PSCumulus -Parameters @{ MockDisk = $script:mockDisk } {
                param($MockDisk)
                Mock Assert-CommandAvailable {}
                Mock Get-AzDisk { @($MockDisk) }

                $result = Get-AzureDiskData -ResourceGroup 'prod-rg'
                $result.Metadata.Sku | Should -Be 'Premium_LRS'
            }
        }

        It 'returns PSCumulus.CloudRecord type' {
            InModuleScope PSCumulus -Parameters @{ MockDisk = $script:mockDisk } {
                param($MockDisk)
                Mock Assert-CommandAvailable {}
                Mock Get-AzDisk { @($MockDisk) }

                $result = Get-AzureDiskData -ResourceGroup 'prod-rg'
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRecord'
            }
        }
    }
}
