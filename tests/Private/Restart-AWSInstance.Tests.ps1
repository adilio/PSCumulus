BeforeAll {
    # Stub AWS EC2 stop command so Pester can create mocks when AWS.Tools is not installed
    if (-not (Get-Command Stop-EC2Instance -ErrorAction SilentlyContinue)) {
        $script:stubCreatedStopEC2 = $true
        function global:Stop-EC2Instance { param([string]$InstanceId) }
    }

    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

AfterAll {
    if ($script:stubCreatedStopEC2) {
        Remove-Item -Path Function:global:Stop-EC2Instance -ErrorAction SilentlyContinue
    }
}

Describe 'Restart-AWSInstance' {
    BeforeAll {
        InModuleScope PSCumulus {
            # Mock Assert-CommandAvailable to avoid additional validation
            Mock -CommandName Assert-CommandAvailable
        }
    }

    It 'restarts an AWS EC2 instance by InstanceId' {
        InModuleScope PSCumulus {
            Mock -CommandName Stop-EC2Instance { }

            Restart-AWSInstance -InstanceId 'i-12345678'

            Should -Invoke Stop-EC2Instance -Times 1 -ParameterFilter {
                $InstanceId -eq 'i-12345678'
            }
        }
    }

    It 'returns an AWSCloudRecord with Status Stopping' {
        InModuleScope PSCumulus {
            Mock -CommandName Stop-EC2Instance { }

            $result = Restart-AWSInstance -InstanceId 'i-12345678' -Region 'us-east-1'

            $result.InstanceId | Should -Be 'i-12345678'
            $result.Status | Should -Be 'Stopping'
            $result.Provider | Should -Be 'AWS'
            $result.Region | Should -Be 'us-east-1'
        }
    }
}
