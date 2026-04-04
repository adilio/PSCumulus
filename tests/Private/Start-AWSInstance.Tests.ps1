BeforeAll {
    # Stub AWS EC2 start command so Pester can create mocks when AWS.Tools is not installed
    if (-not (Get-Command Start-EC2Instance -ErrorAction SilentlyContinue)) {
        $script:stubCreatedStartEC2 = $true
        function global:Start-EC2Instance { param([string]$InstanceId, [string]$Region) }
    }

    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

AfterAll {
    if ($script:stubCreatedStartEC2) {
        Remove-Item -Path Function:global:Start-EC2Instance -ErrorAction SilentlyContinue
    }
}

Describe 'Start-AWSInstance' {

    Context 'when AWS.Tools.EC2 is not installed' {
        It 'throws when Start-EC2Instance is unavailable' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {
                    throw [System.Management.Automation.CommandNotFoundException]::new(
                        "Required command 'Start-EC2Instance' was not found."
                    )
                }

                { Start-AWSInstance -InstanceId 'i-0abc123' } | Should -Throw
            }
        }
    }

    Context 'when the instance is started' {
        It 'returns a CloudRecord' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Start-EC2Instance { }

                $result = Start-AWSInstance -InstanceId 'i-0abc123' -Region 'us-east-1'
                $result | Should -Not -BeNullOrEmpty
            }
        }

        It 'uses InstanceId as Name' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Start-EC2Instance { }

                $result = Start-AWSInstance -InstanceId 'i-0abc123' -Region 'us-east-1'
                $result.Name | Should -Be 'i-0abc123'
            }
        }

        It 'sets Provider to AWS' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Start-EC2Instance { }

                $result = Start-AWSInstance -InstanceId 'i-0abc123' -Region 'us-east-1'
                $result.Provider | Should -Be 'AWS'
            }
        }

        It 'sets Status to Starting' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Start-EC2Instance { }

                $result = Start-AWSInstance -InstanceId 'i-0abc123' -Region 'us-east-1'
                $result.Status | Should -Be 'Starting'
            }
        }

        It 'includes InstanceId in Metadata' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Start-EC2Instance { }

                $result = Start-AWSInstance -InstanceId 'i-0abc123' -Region 'us-east-1'
                $result.Metadata.InstanceId | Should -Be 'i-0abc123'
            }
        }

        It 'calls Start-EC2Instance with Region when provided' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Start-EC2Instance { }

                $null = Start-AWSInstance -InstanceId 'i-0abc123' -Region 'eu-west-1'
                Should -Invoke Start-EC2Instance -Times 1 -ParameterFilter { $Region -eq 'eu-west-1' }
            }
        }

        It 'returns PSCumulus.CloudRecord type' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Start-EC2Instance { }

                $result = Start-AWSInstance -InstanceId 'i-0abc123' -Region 'us-east-1'
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRecord'
            }
        }
    }
}
