BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'ConvertFrom-AzurePowerState' {

    It 'returns null for null input' {
        InModuleScope PSCumulus {
            ConvertFrom-AzurePowerState -PowerState $null | Should -BeNullOrEmpty
        }
    }

    It 'returns null for empty string' {
        InModuleScope PSCumulus {
            ConvertFrom-AzurePowerState -PowerState '' | Should -BeNullOrEmpty
        }
    }

    It 'returns null for whitespace' {
        InModuleScope PSCumulus {
            ConvertFrom-AzurePowerState -PowerState '   ' | Should -BeNullOrEmpty
        }
    }

    It 'strips the "VM " prefix from Azure power state' {
        InModuleScope PSCumulus {
            ConvertFrom-AzurePowerState -PowerState 'VM running' | Should -Be 'running'
        }
    }

    It 'strips "VM " prefix from stopped state' {
        InModuleScope PSCumulus {
            ConvertFrom-AzurePowerState -PowerState 'VM stopped' | Should -Be 'stopped'
        }
    }

    It 'strips "VM " prefix from deallocated state' {
        InModuleScope PSCumulus {
            ConvertFrom-AzurePowerState -PowerState 'VM deallocated' | Should -Be 'deallocated'
        }
    }

    It 'returns value unchanged when no "VM " prefix is present' {
        InModuleScope PSCumulus {
            ConvertFrom-AzurePowerState -PowerState 'running' | Should -Be 'running'
        }
    }

    It 'returns value unchanged for unrecognised state without VM prefix' {
        InModuleScope PSCumulus {
            ConvertFrom-AzurePowerState -PowerState 'unknown' | Should -Be 'unknown'
        }
    }
}
