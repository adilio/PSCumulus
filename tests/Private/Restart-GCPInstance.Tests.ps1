BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Restart-GCPInstance' {

    It 'resets a GCP compute instance by name and zone' {
        InModuleScope PSCumulus {
            Mock Invoke-GCloudJson { }

            Restart-GCPInstance -Name 'test-vm' -Zone 'us-central1-a' -Project 'test-proj'

            Should -Invoke Invoke-GCloudJson -Times 1 -ParameterFilter {
                $Arguments -contains 'compute' -and $Arguments -contains 'instances' -and $Arguments -contains 'reset'
            }
        }
    }

    It 'returns a GCPCloudRecord with Status Running' {
        InModuleScope PSCumulus {
            Mock Invoke-GCloudJson { }

            $result = Restart-GCPInstance -Name 'test-vm' -Zone 'us-central1-a' -Project 'test-proj'

            $result.Name | Should -Be 'test-vm'
            $result.Status | Should -Be 'Running'
            $result.Provider | Should -Be 'GCP'
            $result.Zone | Should -Be 'us-central1-a'
            $result.Project | Should -Be 'test-proj'
        }
    }
}
