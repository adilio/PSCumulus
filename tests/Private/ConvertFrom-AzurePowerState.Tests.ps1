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

    It 'maps "VM running" to Running' {
        InModuleScope PSCumulus {
            ConvertFrom-AzurePowerState -PowerState 'VM running' | Should -BeExactly 'Running'
        }
    }

    It 'maps "VM stopped" to Stopped' {
        InModuleScope PSCumulus {
            ConvertFrom-AzurePowerState -PowerState 'VM stopped' | Should -BeExactly 'Stopped'
        }
    }

    It 'maps "VM deallocated" to Stopped' {
        InModuleScope PSCumulus {
            ConvertFrom-AzurePowerState -PowerState 'VM deallocated' | Should -BeExactly 'Stopped'
        }
    }

    It 'maps "VM deallocating" to Stopping' {
        InModuleScope PSCumulus {
            ConvertFrom-AzurePowerState -PowerState 'VM deallocating' | Should -BeExactly 'Stopping'
        }
    }

    It 'maps "running" to Running without a prefix' {
        InModuleScope PSCumulus {
            ConvertFrom-AzurePowerState -PowerState 'running' | Should -BeExactly 'Running'
        }
    }

    It 'maps unrecognised states to Unknown' {
        InModuleScope PSCumulus {
            ConvertFrom-AzurePowerState -PowerState 'unknown' | Should -BeExactly 'Unknown'
        }
    }
}
