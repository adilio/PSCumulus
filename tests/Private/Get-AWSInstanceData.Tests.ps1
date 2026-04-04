BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Get-AWSInstanceData' {

    Context 'when AWS.Tools.EC2 is not installed' {
        It 'throws when Get-EC2Instance is unavailable' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {
                    throw [System.Management.Automation.CommandNotFoundException]::new(
                        "Required command 'Get-EC2Instance' was not found."
                    )
                }

                { Get-AWSInstanceData -Region 'us-east-1' } | Should -Throw
            }
        }
    }

    Context 'when instances are returned' {
        BeforeAll {
            InModuleScope PSCumulus {
                $script:mockInstance = [pscustomobject]@{
                    InstanceId       = 'i-0abc123def456789'
                    Tags             = @([pscustomobject]@{ Key = 'Name'; Value = 'app-server-01' })
                    State            = [pscustomobject]@{ Name = [pscustomobject]@{ Value = 'running' } }
                    InstanceType     = [pscustomobject]@{ Value = 't3.medium' }
                    Placement        = [pscustomobject]@{ AvailabilityZone = 'us-east-1a' }
                    LaunchTime       = [datetime]'2026-01-15T10:00:00Z'
                    PrivateIpAddress = '10.0.1.5'
                    PublicIpAddress  = '52.1.2.3'
                    VpcId            = 'vpc-0abc123'
                    SubnetId         = 'subnet-0def456'
                }
                $script:mockResponse = [pscustomobject]@{
                    Reservations = @([pscustomobject]@{
                        Instances = @($script:mockInstance)
                    })
                }
                $script:noTagResponse = [pscustomobject]@{
                    Reservations = @([pscustomobject]@{
                        Instances = @([pscustomobject]@{
                            InstanceId       = 'i-noname'
                            Tags             = @()
                            State            = [pscustomobject]@{ Name = [pscustomobject]@{ Value = 'running' } }
                            InstanceType     = [pscustomobject]@{ Value = 't3.micro' }
                            Placement        = [pscustomobject]@{ AvailabilityZone = 'us-east-1b' }
                            LaunchTime       = [datetime]'2026-01-01'
                            PrivateIpAddress = '10.0.0.1'
                            PublicIpAddress  = $null
                            VpcId            = 'vpc-123'
                            SubnetId         = 'subnet-123'
                        })
                    })
                }
            }
        }

        BeforeEach {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Instance { $script:mockResponse }
            }
        }

        It 'returns a CloudRecord for each instance' {
            $results = @(InModuleScope PSCumulus { Get-AWSInstanceData -Region 'us-east-1' })
            $results.Count | Should -Be 1
        }

        It 'uses the Name tag as the record name' {
            $result = InModuleScope PSCumulus { Get-AWSInstanceData -Region 'us-east-1' }
            $result.Name | Should -Be 'app-server-01'
        }

        It 'falls back to InstanceId when no Name tag exists' {
            InModuleScope PSCumulus {
                Mock Get-EC2Instance { $script:noTagResponse }
                $result = Get-AWSInstanceData -Region 'us-east-1'
                $result.Name | Should -Be 'i-noname'
            }
        }

        It 'sets Provider to AWS' {
            $result = InModuleScope PSCumulus { Get-AWSInstanceData -Region 'us-east-1' }
            $result.Provider | Should -Be 'AWS'
        }

        It 'maps AvailabilityZone to Region' {
            $result = InModuleScope PSCumulus { Get-AWSInstanceData -Region 'us-east-1' }
            $result.Region | Should -Be 'us-east-1a'
        }

        It 'title-cases the instance state' {
            $result = InModuleScope PSCumulus { Get-AWSInstanceData -Region 'us-east-1' }
            $result.Status | Should -Be 'Running'
        }

        It 'maps InstanceType to Size' {
            $result = InModuleScope PSCumulus { Get-AWSInstanceData -Region 'us-east-1' }
            $result.Size | Should -Be 't3.medium'
        }

        It 'maps LaunchTime to CreatedAt' {
            $result = InModuleScope PSCumulus { Get-AWSInstanceData -Region 'us-east-1' }
            $result.CreatedAt | Should -Be ([datetime]'2026-01-15T10:00:00Z')
        }

        It 'includes InstanceId in Metadata' {
            $result = InModuleScope PSCumulus { Get-AWSInstanceData -Region 'us-east-1' }
            $result.Metadata.InstanceId | Should -Be 'i-0abc123def456789'
        }

        It 'calls Get-EC2Instance with Region when provided' {
            $null = InModuleScope PSCumulus { Get-AWSInstanceData -Region 'eu-west-1' }

            Should -Invoke Get-EC2Instance -ModuleName PSCumulus -Times 1 -ParameterFilter { $Region -eq 'eu-west-1' }
        }

        It 'calls Get-EC2Instance without Region when omitted' {
            $null = InModuleScope PSCumulus { Get-AWSInstanceData }

            Should -Invoke Get-EC2Instance -ModuleName PSCumulus -Times 1 -ParameterFilter { -not $Region }
        }
    }
}
