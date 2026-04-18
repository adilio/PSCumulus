BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Restart-AWSInstance' {

    It 'restarts an AWS EC2 instance by InstanceId' {
        InModuleScope PSCumulus {
            Mock Stop-EC2Instance { }

            Restart-AWSInstance -InstanceId 'i-12345678'

            Should -Invoke Stop-EC2Instance -Times 1 -ParameterFilter {
                $InstanceId -eq 'i-12345678'
            }
        }
    }

    It 'returns an AWSCloudRecord with Status Stopping' {
        InModuleScope PSCumulus {
            Mock Stop-EC2Instance { }

            $result = Restart-AWSInstance -InstanceId 'i-12345678' -Region 'us-east-1'

            $result.InstanceId | Should -Be 'i-12345678'
            $result.Status | Should -Be 'Stopping'
            $result.Provider | Should -Be 'AWS'
            $result.Region | Should -Be 'us-east-1'
        }
    }
}
