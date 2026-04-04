BeforeAll {
    # Stub AWS EC2 stop command so Pester can create mocks when AWS.Tools is not installed
    if (-not (Get-Command Stop-EC2Instance -ErrorAction SilentlyContinue)) {
        $script:stubCreatedStopEC2 = $true
        function global:Stop-EC2Instance { param([string]$InstanceId, [string]$Region) }
    }

    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

AfterAll {
    if ($script:stubCreatedStopEC2) {
        Remove-Item -Path Function:global:Stop-EC2Instance -ErrorAction SilentlyContinue
    }
}

Describe 'Stop-AWSInstance' {

    Context 'when AWS.Tools.EC2 is not installed' {
        It 'throws when Stop-EC2Instance is unavailable' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {
                    throw [System.Management.Automation.CommandNotFoundException]::new(
                        "Required command 'Stop-EC2Instance' was not found."
                    )
                }

                { Stop-AWSInstance -InstanceId 'i-0abc123' } | Should -Throw
            }
        }
    }

    Context 'when the instance is stopped' {
        It 'returns a CloudRecord' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Stop-EC2Instance { }

                $result = Stop-AWSInstance -InstanceId 'i-0abc123' -Region 'us-east-1'
                $result | Should -Not -BeNullOrEmpty
            }
        }

        It 'uses InstanceId as Name' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Stop-EC2Instance { }

                $result = Stop-AWSInstance -InstanceId 'i-0abc123' -Region 'us-east-1'
                $result.Name | Should -Be 'i-0abc123'
            }
        }

        It 'sets Provider to AWS' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Stop-EC2Instance { }

                $result = Stop-AWSInstance -InstanceId 'i-0abc123' -Region 'us-east-1'
                $result.Provider | Should -Be 'AWS'
            }
        }

        It 'sets Status to Stopping' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Stop-EC2Instance { }

                $result = Stop-AWSInstance -InstanceId 'i-0abc123' -Region 'us-east-1'
                $result.Status | Should -Be 'Stopping'
            }
        }

        It 'includes InstanceId in Metadata' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Stop-EC2Instance { }

                $result = Stop-AWSInstance -InstanceId 'i-0abc123' -Region 'us-east-1'
                $result.Metadata.InstanceId | Should -Be 'i-0abc123'
            }
        }

        It 'calls Stop-EC2Instance with Region when provided' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Stop-EC2Instance { }

                $null = Stop-AWSInstance -InstanceId 'i-0abc123' -Region 'eu-west-1'
                Should -Invoke Stop-EC2Instance -Times 1 -ParameterFilter { $Region -eq 'eu-west-1' }
            }
        }

        It 'returns PSCumulus.CloudRecord type' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Stop-EC2Instance { }

                $result = Stop-AWSInstance -InstanceId 'i-0abc123' -Region 'us-east-1'
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRecord'
            }
        }
    }
}
