BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'ConvertFrom-AWSInstanceState' {

    It 'returns null for null input' {
        InModuleScope PSCumulus {
            ConvertFrom-AWSInstanceState -StateName $null | Should -BeNullOrEmpty
        }
    }

    It 'returns null for empty string' {
        InModuleScope PSCumulus {
            ConvertFrom-AWSInstanceState -StateName '' | Should -BeNullOrEmpty
        }
    }

    It 'returns null for whitespace' {
        InModuleScope PSCumulus {
            ConvertFrom-AWSInstanceState -StateName '   ' | Should -BeNullOrEmpty
        }
    }

    It 'maps "running" to Running' {
        InModuleScope PSCumulus {
            ConvertFrom-AWSInstanceState -StateName 'running' | Should -BeExactly 'Running'
        }
    }

    It 'maps "stopped" to Stopped' {
        InModuleScope PSCumulus {
            ConvertFrom-AWSInstanceState -StateName 'stopped' | Should -BeExactly 'Stopped'
        }
    }

    It 'maps "pending" to Pending' {
        InModuleScope PSCumulus {
            ConvertFrom-AWSInstanceState -StateName 'pending' | Should -BeExactly 'Pending'
        }
    }

    It 'maps "shutting-down" to Terminating' {
        InModuleScope PSCumulus {
            ConvertFrom-AWSInstanceState -StateName 'shutting-down' | Should -BeExactly 'Terminating'
        }
    }

    It 'maps "terminated" to Terminated' {
        InModuleScope PSCumulus {
            ConvertFrom-AWSInstanceState -StateName 'terminated' | Should -BeExactly 'Terminated'
        }
    }

    It 'normalises an already-uppercase state name' {
        InModuleScope PSCumulus {
            ConvertFrom-AWSInstanceState -StateName 'RUNNING' | Should -BeExactly 'Running'
        }
    }
}
