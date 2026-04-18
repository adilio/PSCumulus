BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Restart-AzureInstance' {

    It 'restarts an Azure VM by name and resource group' {
        InModuleScope PSCumulus {
            Mock Restart-AzVM { }

            Restart-AzureInstance -Name 'test-vm' -ResourceGroup 'test-rg'

            Should -Invoke Restart-AzVM -Times 1 -ParameterFilter {
                $Name -eq 'test-vm' -and $ResourceGroupName -eq 'test-rg'
            }
        }
    }

    It 'returns an AzureCloudRecord with Status Starting' {
        InModuleScope PSCumulus {
            Mock Restart-AzVM { }

            $result = Restart-AzureInstance -Name 'test-vm' -ResourceGroup 'test-rg'

            $result.Name | Should -Be 'test-vm'
            $result.Status | Should -Be 'Starting'
            $result.Provider | Should -Be 'Azure'
        }
    }
}
