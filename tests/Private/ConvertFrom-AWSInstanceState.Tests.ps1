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

    It 'title-cases "running"' {
        InModuleScope PSCumulus {
            ConvertFrom-AWSInstanceState -StateName 'running' | Should -Be 'Running'
        }
    }

    It 'title-cases "stopped"' {
        InModuleScope PSCumulus {
            ConvertFrom-AWSInstanceState -StateName 'stopped' | Should -Be 'Stopped'
        }
    }

    It 'title-cases "pending"' {
        InModuleScope PSCumulus {
            ConvertFrom-AWSInstanceState -StateName 'pending' | Should -Be 'Pending'
        }
    }

    It 'title-cases "shutting-down"' {
        InModuleScope PSCumulus {
            ConvertFrom-AWSInstanceState -StateName 'shutting-down' | Should -Be 'Shutting-Down'
        }
    }

    It 'normalises an already-uppercase state name' {
        InModuleScope PSCumulus {
            ConvertFrom-AWSInstanceState -StateName 'RUNNING' | Should -Be 'Running'
        }
    }
}
