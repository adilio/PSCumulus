BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Start-AzureInstance' {

    Context 'when Az.Compute is not installed' {
        It 'throws when Start-AzVM is unavailable' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {
                    throw [System.Management.Automation.CommandNotFoundException]::new(
                        "Required command 'Start-AzVM' was not found."
                    )
                }

                { Start-AzureInstance -Name 'web-server-01' -ResourceGroup 'prod-rg' } | Should -Throw
            }
        }
    }

    Context 'when the instance is started' {
        It 'returns a CloudRecord' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Start-AzVM { }

                $result = Start-AzureInstance -Name 'web-server-01' -ResourceGroup 'prod-rg'
                $result | Should -Not -BeNullOrEmpty
            }
        }

        It 'sets Name correctly' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Start-AzVM { }

                $result = Start-AzureInstance -Name 'web-server-01' -ResourceGroup 'prod-rg'
                $result.Name | Should -Be 'web-server-01'
            }
        }

        It 'sets Provider to Azure' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Start-AzVM { }

                $result = Start-AzureInstance -Name 'web-server-01' -ResourceGroup 'prod-rg'
                $result.Provider | Should -Be 'Azure'
            }
        }

        It 'sets Status to Starting' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Start-AzVM { }

                $result = Start-AzureInstance -Name 'web-server-01' -ResourceGroup 'prod-rg'
                $result.Status | Should -Be 'Starting'
            }
        }

        It 'includes ResourceGroup in Metadata' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Start-AzVM { }

                $result = Start-AzureInstance -Name 'web-server-01' -ResourceGroup 'prod-rg'
                $result.Metadata.ResourceGroup | Should -Be 'prod-rg'
            }
        }

        It 'calls Start-AzVM with the correct parameters' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Start-AzVM { }

                $null = Start-AzureInstance -Name 'my-vm' -ResourceGroup 'my-rg'
                Should -Invoke Start-AzVM -Times 1 -ParameterFilter {
                    $Name -eq 'my-vm' -and $ResourceGroupName -eq 'my-rg'
                }
            }
        }

        It 'returns PSCumulus.CloudRecord type' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Start-AzVM { }

                $result = Start-AzureInstance -Name 'web-server-01' -ResourceGroup 'prod-rg'
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRecord'
            }
        }
    }
}
