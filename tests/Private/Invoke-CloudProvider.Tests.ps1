BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Invoke-CloudProvider' {

    Context 'successful dispatch' {
        It 'calls the mapped command for the given provider' {
            InModuleScope PSCumulus {
                Mock Get-AzureInstanceData { 'azure-result' }

                $commandMap = @{ Azure = 'Get-AzureInstanceData'; AWS = 'Get-AWSInstanceData'; GCP = 'Get-GCPInstanceData' }
                $result = Invoke-CloudProvider -Provider Azure -CommandMap $commandMap

                $result | Should -Be 'azure-result'
                Should -Invoke Get-AzureInstanceData -Times 1
            }
        }

        It 'passes ArgumentMap entries as splatted parameters' {
            InModuleScope PSCumulus {
                Mock Get-AzureInstanceData { param([string]$ResourceGroup) $ResourceGroup }

                $commandMap = @{ Azure = 'Get-AzureInstanceData' }
                $result = Invoke-CloudProvider -Provider Azure -CommandMap $commandMap -ArgumentMap @{ ResourceGroup = 'prod-rg' }

                $result | Should -Be 'prod-rg'
            }
        }

        It 'calls the AWS backend for AWS provider' {
            InModuleScope PSCumulus {
                Mock Get-AWSInstanceData { 'aws-result' }

                $commandMap = @{ Azure = 'Get-AzureInstanceData'; AWS = 'Get-AWSInstanceData'; GCP = 'Get-GCPInstanceData' }
                $result = Invoke-CloudProvider -Provider AWS -CommandMap $commandMap

                $result | Should -Be 'aws-result'
                Should -Invoke Get-AWSInstanceData -Times 1
            }
        }

        It 'defaults ArgumentMap to empty when not provided' {
            InModuleScope PSCumulus {
                Mock Get-GCPInstanceData { 'gcp-result' }

                $commandMap = @{ GCP = 'Get-GCPInstanceData' }
                { Invoke-CloudProvider -Provider GCP -CommandMap $commandMap } | Should -Not -Throw
            }
        }
    }

    Context 'error cases' {
        It 'throws InvalidOperationException when provider has no mapping' {
            InModuleScope PSCumulus {
                $emptyMap = @{}
                { Invoke-CloudProvider -Provider Azure -CommandMap $emptyMap } |
                    Should -Throw "No command mapping exists for provider 'Azure'."
            }
        }

        It 'throws CommandNotFoundException when the mapped command does not exist' {
            InModuleScope PSCumulus {
                $badMap = @{ Azure = 'Invoke-NonExistentCommand-XYZABC' }
                { Invoke-CloudProvider -Provider Azure -CommandMap $badMap } |
                    Should -Throw
            }
        }

        It 'includes the provider name in the missing-mapping error' {
            InModuleScope PSCumulus {
                try {
                    Invoke-CloudProvider -Provider AWS -CommandMap @{}
                } catch {
                    $_.Exception.Message | Should -BeLike "*'AWS'*"
                }
            }
        }
    }
}
