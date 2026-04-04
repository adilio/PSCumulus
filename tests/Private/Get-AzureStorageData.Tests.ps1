BeforeAll {
    # Stub Az.Storage commands so Pester can create mocks when Az.Storage is not installed
    if (-not (Get-Command Get-AzStorageAccount -ErrorAction SilentlyContinue)) {
        $script:stubCreatedGetAzStorageAccount = $true
        function global:Get-AzStorageAccount { param([string]$ResourceGroupName) }
    }

    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

AfterAll {
    if ($script:stubCreatedGetAzStorageAccount) {
        Remove-Item -Path Function:global:Get-AzStorageAccount -ErrorAction SilentlyContinue
    }
}

Describe 'Get-AzureStorageData' {

    Context 'when Az.Storage is not installed' {
        It 'throws when Get-AzStorageAccount is unavailable' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {
                    throw [System.Management.Automation.CommandNotFoundException]::new(
                        "Required command 'Get-AzStorageAccount' was not found."
                    )
                }

                { Get-AzureStorageData -ResourceGroup 'prod-rg' } | Should -Throw
            }
        }
    }

    Context 'when storage accounts are returned' {
        BeforeAll {
            $script:mockAccount = [pscustomobject]@{
                StorageAccountName = 'prodstore01'
                ResourceGroupName  = 'prod-rg'
                PrimaryLocation    = 'eastus'
                StatusOfPrimary    = 'available'
                Sku                = [pscustomobject]@{ Name = 'Standard_LRS' }
                Kind               = 'StorageV2'
                AccessTier         = 'Hot'
                CreationTime       = [datetime]'2026-01-10T08:00:00Z'
            }
        }

        It 'returns a CloudRecord for each account' {
            InModuleScope PSCumulus -Parameters @{ MockAccount = $script:mockAccount } {
                param($MockAccount)
                Mock Assert-CommandAvailable {}
                Mock Get-AzStorageAccount { @($MockAccount) }

                $results = @(Get-AzureStorageData -ResourceGroup 'prod-rg')
                $results.Count | Should -Be 1
            }
        }

        It 'maps StorageAccountName to Name' {
            InModuleScope PSCumulus -Parameters @{ MockAccount = $script:mockAccount } {
                param($MockAccount)
                Mock Assert-CommandAvailable {}
                Mock Get-AzStorageAccount { @($MockAccount) }

                $result = Get-AzureStorageData -ResourceGroup 'prod-rg'
                $result.Name | Should -Be 'prodstore01'
            }
        }

        It 'sets Provider to Azure' {
            InModuleScope PSCumulus -Parameters @{ MockAccount = $script:mockAccount } {
                param($MockAccount)
                Mock Assert-CommandAvailable {}
                Mock Get-AzStorageAccount { @($MockAccount) }

                $result = Get-AzureStorageData -ResourceGroup 'prod-rg'
                $result.Provider | Should -Be 'Azure'
            }
        }

        It 'maps PrimaryLocation to Region' {
            InModuleScope PSCumulus -Parameters @{ MockAccount = $script:mockAccount } {
                param($MockAccount)
                Mock Assert-CommandAvailable {}
                Mock Get-AzStorageAccount { @($MockAccount) }

                $result = Get-AzureStorageData -ResourceGroup 'prod-rg'
                $result.Region | Should -Be 'eastus'
            }
        }

        It 'maps Sku.Name to Size' {
            InModuleScope PSCumulus -Parameters @{ MockAccount = $script:mockAccount } {
                param($MockAccount)
                Mock Assert-CommandAvailable {}
                Mock Get-AzStorageAccount { @($MockAccount) }

                $result = Get-AzureStorageData -ResourceGroup 'prod-rg'
                $result.Size | Should -Be 'Standard_LRS'
            }
        }

        It 'maps CreationTime to CreatedAt' {
            InModuleScope PSCumulus -Parameters @{ MockAccount = $script:mockAccount } {
                param($MockAccount)
                Mock Assert-CommandAvailable {}
                Mock Get-AzStorageAccount { @($MockAccount) }

                $result = Get-AzureStorageData -ResourceGroup 'prod-rg'
                $result.CreatedAt | Should -Be ([datetime]'2026-01-10T08:00:00Z')
            }
        }

        It 'includes ResourceGroup in Metadata' {
            InModuleScope PSCumulus -Parameters @{ MockAccount = $script:mockAccount } {
                param($MockAccount)
                Mock Assert-CommandAvailable {}
                Mock Get-AzStorageAccount { @($MockAccount) }

                $result = Get-AzureStorageData -ResourceGroup 'prod-rg'
                $result.Metadata.ResourceGroup | Should -Be 'prod-rg'
            }
        }

        It 'returns PSCumulus.CloudRecord type' {
            InModuleScope PSCumulus -Parameters @{ MockAccount = $script:mockAccount } {
                param($MockAccount)
                Mock Assert-CommandAvailable {}
                Mock Get-AzStorageAccount { @($MockAccount) }

                $result = Get-AzureStorageData -ResourceGroup 'prod-rg'
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRecord'
            }
        }

        It 'returns nothing when the resource group has no storage accounts' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Get-AzStorageAccount { @() }

                $results = @(Get-AzureStorageData -ResourceGroup 'empty-rg')
                $results.Count | Should -Be 0
            }
        }
    }
}
