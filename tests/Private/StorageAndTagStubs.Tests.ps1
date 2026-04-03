BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Storage and tag backend stubs' {

    Context 'Get-AzureStorageData' {
        It 'throws with not-implemented message' {
            InModuleScope PSCumulus {
                { Get-AzureStorageData -ResourceGroup 'prod-rg' } |
                    Should -Throw 'Get-AzureStorageData is not implemented yet.'
            }
        }
    }

    Context 'Get-AWSStorageData' {
        It 'throws with not-implemented message' {
            InModuleScope PSCumulus {
                { Get-AWSStorageData -Region 'us-east-1' } |
                    Should -Throw 'Get-AWSStorageData is not implemented yet.'
            }
        }
    }

    Context 'Get-GCPStorageData' {
        It 'throws with not-implemented message' {
            InModuleScope PSCumulus {
                { Get-GCPStorageData -Project 'my-project' } |
                    Should -Throw 'Get-GCPStorageData is not implemented yet.'
            }
        }
    }

    Context 'Get-AzureTagData' {
        It 'throws with not-implemented message' {
            InModuleScope PSCumulus {
                { Get-AzureTagData -ResourceId '/subscriptions/abc/vm/vm01' } |
                    Should -Throw 'Get-AzureTagData is not implemented yet.'
            }
        }
    }

    Context 'Get-AWSTagData' {
        It 'throws with not-implemented message' {
            InModuleScope PSCumulus {
                { Get-AWSTagData -ResourceId 'i-0123456789abcdef0' } |
                    Should -Throw 'Get-AWSTagData is not implemented yet.'
            }
        }
    }

    Context 'Get-GCPTagData' {
        It 'throws with not-implemented message' {
            InModuleScope PSCumulus {
                { Get-GCPTagData -Project 'my-project' -Resource 'instances/vm-01' } |
                    Should -Throw 'Get-GCPTagData is not implemented yet.'
            }
        }
    }
}
