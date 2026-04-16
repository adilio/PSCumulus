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

    It 'maps "RUNNING" to Running' {
        InModuleScope PSCumulus {
            ConvertFrom-GCPInstanceStatus -Status 'RUNNING' | Should -BeExactly 'Running'
        }
    }

    It 'maps "TERMINATED" to Stopped' {
        InModuleScope PSCumulus {
            ConvertFrom-GCPInstanceStatus -Status 'TERMINATED' | Should -BeExactly 'Stopped'
        }
    }

    It 'maps "STAGING" to Pending' {
        InModuleScope PSCumulus {
            ConvertFrom-GCPInstanceStatus -Status 'STAGING' | Should -BeExactly 'Pending'
        }
    }

    It 'maps "STOPPING" to Stopping' {
        InModuleScope PSCumulus {
            ConvertFrom-GCPInstanceStatus -Status 'STOPPING' | Should -BeExactly 'Stopping'
        }
    }

    It 'maps "SUSPENDED" to Suspended' {
        InModuleScope PSCumulus {
            ConvertFrom-GCPInstanceStatus -Status 'SUSPENDED' | Should -BeExactly 'Suspended'
        }
    }

    It 'handles already lower-case input' {
        InModuleScope PSCumulus {
            ConvertFrom-GCPInstanceStatus -Status 'running' | Should -BeExactly 'Running'
        }
    }
}
