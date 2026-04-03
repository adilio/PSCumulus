BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'ConvertFrom-GCPInstanceStatus' {

    It 'returns null for null input' {
        InModuleScope PSCumulus {
            ConvertFrom-GCPInstanceStatus -Status $null | Should -BeNullOrEmpty
        }
    }

    It 'returns null for empty string' {
        InModuleScope PSCumulus {
            ConvertFrom-GCPInstanceStatus -Status '' | Should -BeNullOrEmpty
        }
    }

    It 'returns null for whitespace' {
        InModuleScope PSCumulus {
            ConvertFrom-GCPInstanceStatus -Status '   ' | Should -BeNullOrEmpty
        }
    }

    It 'title-cases "RUNNING"' {
        InModuleScope PSCumulus {
            ConvertFrom-GCPInstanceStatus -Status 'RUNNING' | Should -Be 'Running'
        }
    }

    It 'title-cases "TERMINATED"' {
        InModuleScope PSCumulus {
            ConvertFrom-GCPInstanceStatus -Status 'TERMINATED' | Should -Be 'Terminated'
        }
    }

    It 'title-cases "STAGING"' {
        InModuleScope PSCumulus {
            ConvertFrom-GCPInstanceStatus -Status 'STAGING' | Should -Be 'Staging'
        }
    }

    It 'title-cases "STOPPING"' {
        InModuleScope PSCumulus {
            ConvertFrom-GCPInstanceStatus -Status 'STOPPING' | Should -Be 'Stopping'
        }
    }

    It 'handles already lower-case input' {
        InModuleScope PSCumulus {
            ConvertFrom-GCPInstanceStatus -Status 'running' | Should -Be 'Running'
        }
    }
}
