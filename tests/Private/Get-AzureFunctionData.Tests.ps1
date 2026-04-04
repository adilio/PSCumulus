BeforeAll {
    # Stub Az.Functions commands so Pester can create mocks when Az.Functions is not installed
    if (-not (Get-Command Get-AzFunctionApp -ErrorAction SilentlyContinue)) {
        $script:stubCreatedGetAzFunctionApp = $true
        function global:Get-AzFunctionApp { param([string]$ResourceGroupName) }
    }

    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

AfterAll {
    if ($script:stubCreatedGetAzFunctionApp) {
        Remove-Item -Path Function:global:Get-AzFunctionApp -ErrorAction SilentlyContinue
    }
}

Describe 'Get-AzureFunctionData' {

    Context 'when Az.Functions is not installed' {
        It 'throws when Get-AzFunctionApp is unavailable' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {
                    throw [System.Management.Automation.CommandNotFoundException]::new(
                        "Required command 'Get-AzFunctionApp' was not found."
                    )
                }

                { Get-AzureFunctionData -ResourceGroup 'prod-rg' } | Should -Throw
            }
        }
    }

    Context 'when function apps are returned' {
        BeforeAll {
            $script:mockApp = [pscustomobject]@{
                Name              = 'prod-func-app'
                ResourceGroupName = 'prod-rg'
                Location          = 'eastus'
                State             = 'Running'
                Runtime           = 'dotnet'
                RuntimeVersion    = '8'
                OSType            = $null
                Kind              = 'functionapp'
            }
        }

        It 'returns a CloudRecord for each function app' {
            InModuleScope PSCumulus -Parameters @{ MockApp = $script:mockApp } {
                param($MockApp)
                Mock Assert-CommandAvailable {}
                Mock Get-AzFunctionApp { @($MockApp) }

                $results = @(Get-AzureFunctionData -ResourceGroup 'prod-rg')
                $results.Count | Should -Be 1
            }
        }

        It 'maps Name to Name' {
            InModuleScope PSCumulus -Parameters @{ MockApp = $script:mockApp } {
                param($MockApp)
                Mock Assert-CommandAvailable {}
                Mock Get-AzFunctionApp { @($MockApp) }

                $result = Get-AzureFunctionData -ResourceGroup 'prod-rg'
                $result.Name | Should -Be 'prod-func-app'
            }
        }

        It 'sets Provider to Azure' {
            InModuleScope PSCumulus -Parameters @{ MockApp = $script:mockApp } {
                param($MockApp)
                Mock Assert-CommandAvailable {}
                Mock Get-AzFunctionApp { @($MockApp) }

                $result = Get-AzureFunctionData -ResourceGroup 'prod-rg'
                $result.Provider | Should -Be 'Azure'
            }
        }

        It 'maps Location to Region' {
            InModuleScope PSCumulus -Parameters @{ MockApp = $script:mockApp } {
                param($MockApp)
                Mock Assert-CommandAvailable {}
                Mock Get-AzFunctionApp { @($MockApp) }

                $result = Get-AzureFunctionData -ResourceGroup 'prod-rg'
                $result.Region | Should -Be 'eastus'
            }
        }

        It 'maps State to Status' {
            InModuleScope PSCumulus -Parameters @{ MockApp = $script:mockApp } {
                param($MockApp)
                Mock Assert-CommandAvailable {}
                Mock Get-AzFunctionApp { @($MockApp) }

                $result = Get-AzureFunctionData -ResourceGroup 'prod-rg'
                $result.Status | Should -Be 'Running'
            }
        }

        It 'maps Runtime to Size' {
            InModuleScope PSCumulus -Parameters @{ MockApp = $script:mockApp } {
                param($MockApp)
                Mock Assert-CommandAvailable {}
                Mock Get-AzFunctionApp { @($MockApp) }

                $result = Get-AzureFunctionData -ResourceGroup 'prod-rg'
                $result.Size | Should -Be 'dotnet'
            }
        }

        It 'includes Runtime in Metadata' {
            InModuleScope PSCumulus -Parameters @{ MockApp = $script:mockApp } {
                param($MockApp)
                Mock Assert-CommandAvailable {}
                Mock Get-AzFunctionApp { @($MockApp) }

                $result = Get-AzureFunctionData -ResourceGroup 'prod-rg'
                $result.Metadata.Runtime | Should -Be 'dotnet'
            }
        }

        It 'includes ResourceGroup in Metadata' {
            InModuleScope PSCumulus -Parameters @{ MockApp = $script:mockApp } {
                param($MockApp)
                Mock Assert-CommandAvailable {}
                Mock Get-AzFunctionApp { @($MockApp) }

                $result = Get-AzureFunctionData -ResourceGroup 'prod-rg'
                $result.Metadata.ResourceGroup | Should -Be 'prod-rg'
            }
        }

        It 'returns PSCumulus.CloudRecord type' {
            InModuleScope PSCumulus -Parameters @{ MockApp = $script:mockApp } {
                param($MockApp)
                Mock Assert-CommandAvailable {}
                Mock Get-AzFunctionApp { @($MockApp) }

                $result = Get-AzureFunctionData -ResourceGroup 'prod-rg'
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRecord'
            }
        }

        It 'returns nothing when the resource group has no function apps' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Get-AzFunctionApp { @() }

                $results = @(Get-AzureFunctionData -ResourceGroup 'empty-rg')
                $results.Count | Should -Be 0
            }
        }
    }
}
