BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Assert-ProviderParameterSet' {

    Context 'matching provider and parameter set' {
        It 'passes for Azure/Azure' {
            InModuleScope PSCumulus {
                { Assert-ProviderParameterSet -Provider Azure -ParameterSetName Azure } |
                    Should -Not -Throw
            }
        }

        It 'passes for AWS/AWS' {
            InModuleScope PSCumulus {
                { Assert-ProviderParameterSet -Provider AWS -ParameterSetName AWS } |
                    Should -Not -Throw
            }
        }

        It 'passes for GCP/GCP' {
            InModuleScope PSCumulus {
                { Assert-ProviderParameterSet -Provider GCP -ParameterSetName GCP } |
                    Should -Not -Throw
            }
        }

        It 'passes for Azure/AzureTag' {
            InModuleScope PSCumulus {
                { Assert-ProviderParameterSet -Provider Azure -ParameterSetName AzureTag } |
                    Should -Not -Throw
            }
        }

        It 'passes for AWS/AWSTag' {
            InModuleScope PSCumulus {
                { Assert-ProviderParameterSet -Provider AWS -ParameterSetName AWSTag } |
                    Should -Not -Throw
            }
        }

        It 'passes for GCP/GCPTag' {
            InModuleScope PSCumulus {
                { Assert-ProviderParameterSet -Provider GCP -ParameterSetName GCPTag } |
                    Should -Not -Throw
            }
        }
    }

    Context 'mismatched provider and parameter set' {
        It 'throws when Azure provider uses AWS parameter set' {
            InModuleScope PSCumulus {
                { Assert-ProviderParameterSet -Provider Azure -ParameterSetName AWS } |
                    Should -Throw
            }
        }

        It 'throws when AWS provider uses GCP parameter set' {
            InModuleScope PSCumulus {
                { Assert-ProviderParameterSet -Provider AWS -ParameterSetName GCP } |
                    Should -Throw
            }
        }

        It 'throws when GCP provider uses Azure parameter set' {
            InModuleScope PSCumulus {
                { Assert-ProviderParameterSet -Provider GCP -ParameterSetName Azure } |
                    Should -Throw
            }
        }
    }

    Context 'unsupported parameter set' {
        It 'throws for an unknown parameter set name' {
            InModuleScope PSCumulus {
                { Assert-ProviderParameterSet -Provider Azure -ParameterSetName '__AllParameterSets' } |
                    Should -Throw "Unsupported parameter set '__AllParameterSets'."
            }
        }
    }
}
