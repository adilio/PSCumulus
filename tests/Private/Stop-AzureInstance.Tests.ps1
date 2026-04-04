BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Stop-AzureInstance' {

    Context 'when Az.Compute is not installed' {
        It 'throws when Stop-AzVM is unavailable' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {
                    throw [System.Management.Automation.CommandNotFoundException]::new(
                        "Required command 'Stop-AzVM' was not found."
                    )
                }

                { Stop-AzureInstance -Name 'web-server-01' -ResourceGroup 'prod-rg' } | Should -Throw
            }
        }
    }

    Context 'when the instance is stopped' {
        It 'returns a CloudRecord' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Stop-AzVM { }

                $result = Stop-AzureInstance -Name 'web-server-01' -ResourceGroup 'prod-rg'
                $result | Should -Not -BeNullOrEmpty
            }
        }

        It 'sets Name correctly' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Stop-AzVM { }

                $result = Stop-AzureInstance -Name 'web-server-01' -ResourceGroup 'prod-rg'
                $result.Name | Should -Be 'web-server-01'
            }
        }

        It 'sets Provider to Azure' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Stop-AzVM { }

                $result = Stop-AzureInstance -Name 'web-server-01' -ResourceGroup 'prod-rg'
                $result.Provider | Should -Be 'Azure'
            }
        }

        It 'sets Status to Stopping' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Stop-AzVM { }

                $result = Stop-AzureInstance -Name 'web-server-01' -ResourceGroup 'prod-rg'
                $result.Status | Should -Be 'Stopping'
            }
        }

        It 'includes ResourceGroup in Metadata' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Stop-AzVM { }

                $result = Stop-AzureInstance -Name 'web-server-01' -ResourceGroup 'prod-rg'
                $result.Metadata.ResourceGroup | Should -Be 'prod-rg'
            }
        }

        It 'returns PSCumulus.CloudRecord type' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Stop-AzVM { }

                $result = Stop-AzureInstance -Name 'web-server-01' -ResourceGroup 'prod-rg'
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRecord'
            }
        }
    }
}
