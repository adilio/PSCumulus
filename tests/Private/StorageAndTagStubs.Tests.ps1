BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Storage and tag backend availability' {

    Context 'Get-AzureStorageData' {
        It 'is defined in the module' {
            InModuleScope PSCumulus {
                Get-Command Get-AzureStorageData | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Get-AWSStorageData' {
        It 'is defined in the module' {
            InModuleScope PSCumulus {
                Get-Command Get-AWSStorageData | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Get-GCPStorageData' {
        It 'is defined in the module' {
            InModuleScope PSCumulus {
                Get-Command Get-GCPStorageData | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Get-AzureTagData' {
        It 'is defined in the module' {
            InModuleScope PSCumulus {
                Get-Command Get-AzureTagData | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Get-AWSTagData' {
        It 'is defined in the module' {
            InModuleScope PSCumulus {
                Get-Command Get-AWSTagData | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Get-GCPTagData' {
        It 'is defined in the module' {
            InModuleScope PSCumulus {
                Get-Command Get-GCPTagData | Should -Not -BeNullOrEmpty
            }
        }
    }
}
