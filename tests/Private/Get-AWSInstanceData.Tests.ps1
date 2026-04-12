BeforeAll {
    # Stub AWS commands so Pester can create mocks when AWS.Tools is not installed
    if (-not (Get-Command Get-EC2Instance -ErrorAction SilentlyContinue)) {
        $script:stubCreatedGetEC2 = $true
        function global:Get-EC2Instance { param([string]$Region) }
    }

    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

AfterAll {
    if ($script:stubCreatedGetEC2) {
        Remove-Item -Path Function:global:Get-EC2Instance -ErrorAction SilentlyContinue
    }
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

        It 'returns a CloudRecord for each instance' {
            InModuleScope PSCumulus -Parameters @{ MockResponse = $script:mockResponse } {
                param($MockResponse)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Instance { $MockResponse }

                $results = @(Get-AWSInstanceData -Region 'us-east-1')
                $results.Count | Should -Be 1
            }
        }

        It 'uses the Name tag as the record name' {
            InModuleScope PSCumulus -Parameters @{ MockResponse = $script:mockResponse } {
                param($MockResponse)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Instance { $MockResponse }

                $result = Get-AWSInstanceData -Region 'us-east-1'
                $result.Name | Should -Be 'app-server-01'
            }
        }

        It 'falls back to InstanceId when no Name tag exists' {
            InModuleScope PSCumulus -Parameters @{ NoTagResponse = $script:noTagResponse } {
                param($NoTagResponse)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Instance { $NoTagResponse }

                $result = Get-AWSInstanceData -Region 'us-east-1'
                $result.Name | Should -Be 'i-noname'
            }
        }

        It 'sets Provider to AWS' {
            InModuleScope PSCumulus -Parameters @{ MockResponse = $script:mockResponse } {
                param($MockResponse)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Instance { $MockResponse }

                $result = Get-AWSInstanceData -Region 'us-east-1'
                $result.Provider | Should -Be 'AWS'
            }
        }

        It 'maps AvailabilityZone to Region' {
            InModuleScope PSCumulus -Parameters @{ MockResponse = $script:mockResponse } {
                param($MockResponse)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Instance { $MockResponse }

                $result = Get-AWSInstanceData -Region 'us-east-1'
                $result.Region | Should -Be 'us-east-1a'
            }
        }

        It 'title-cases the instance state' {
            InModuleScope PSCumulus -Parameters @{ MockResponse = $script:mockResponse } {
                param($MockResponse)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Instance { $MockResponse }

                $result = Get-AWSInstanceData -Region 'us-east-1'
                $result.Status | Should -Be 'Running'
            }
        }

        It 'maps InstanceType to Size' {
            InModuleScope PSCumulus -Parameters @{ MockResponse = $script:mockResponse } {
                param($MockResponse)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Instance { $MockResponse }

                $result = Get-AWSInstanceData -Region 'us-east-1'
                $result.Size | Should -Be 't3.medium'
            }
        }

        It 'maps LaunchTime to CreatedAt' {
            InModuleScope PSCumulus -Parameters @{ MockResponse = $script:mockResponse } {
                param($MockResponse)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Instance { $MockResponse }

                $result = Get-AWSInstanceData -Region 'us-east-1'
                $result.CreatedAt | Should -Be ([datetime]'2026-01-15T10:00:00Z')
            }
        }

        It 'surfaces PrivateIpAddress and PublicIpAddress' {
            InModuleScope PSCumulus -Parameters @{ MockResponse = $script:mockResponse } {
                param($MockResponse)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Instance { $MockResponse }

                $result = Get-AWSInstanceData -Region 'us-east-1'
                $result.PrivateIpAddress | Should -Be '10.0.1.5'
                $result.PublicIpAddress | Should -Be '52.1.2.3'
            }
        }

        It 'includes InstanceId in Metadata' {
            InModuleScope PSCumulus -Parameters @{ MockResponse = $script:mockResponse } {
                param($MockResponse)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Instance { $MockResponse }

                $result = Get-AWSInstanceData -Region 'us-east-1'
                $result.Metadata.InstanceId | Should -Be 'i-0abc123def456789'
            }
        }

        It 'calls Get-EC2Instance with Region when provided' {
            InModuleScope PSCumulus -Parameters @{ MockResponse = $script:mockResponse } {
                param($MockResponse)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Instance { $MockResponse }

                $null = Get-AWSInstanceData -Region 'eu-west-1'
                Should -Invoke Get-EC2Instance -Times 1 -ParameterFilter { $Region -eq 'eu-west-1' }
            }
        }

        It 'calls Get-EC2Instance without Region when omitted' {
            InModuleScope PSCumulus -Parameters @{ MockResponse = $script:mockResponse } {
                param($MockResponse)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Instance { $MockResponse }

                $null = Get-AWSInstanceData
                Should -Invoke Get-EC2Instance -Times 1 -ParameterFilter { -not $Region }
            }
        }

        It 'populates Tags from instance tags' {
            InModuleScope PSCumulus {
                $taggedResponse = [pscustomobject]@{
                    Reservations = @([pscustomobject]@{
                        Instances = @([pscustomobject]@{
                            InstanceId       = 'i-tagged'
                            Tags             = @(
                                [pscustomobject]@{ Key = 'Name'; Value = 'tagged-server' }
                                [pscustomobject]@{ Key = 'env';  Value = 'prod' }
                            )
                            State            = [pscustomobject]@{ Name = [pscustomobject]@{ Value = 'running' } }
                            InstanceType     = [pscustomobject]@{ Value = 't3.medium' }
                            Placement        = [pscustomobject]@{ AvailabilityZone = 'us-east-1a' }
                            LaunchTime       = [datetime]'2026-01-01'
                            PrivateIpAddress = '10.0.0.1'
                            PublicIpAddress  = $null
                            VpcId            = 'vpc-123'
                            SubnetId         = 'subnet-123'
                        })
                    })
                }
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Instance { $taggedResponse }

                $result = Get-AWSInstanceData -Region 'us-east-1'
                $result.Tags['env'] | Should -Be 'prod'
            }
        }

        It 'filters by Name tag when provided' {
            InModuleScope PSCumulus -Parameters @{ MockInstance = $script:mockInstance } {
                param($MockInstance)
                $otherResponse = [pscustomobject]@{
                    Reservations = @([pscustomobject]@{
                        Instances = @(
                            [pscustomobject]@{
                                InstanceId       = 'i-other'
                                Tags             = @([pscustomobject]@{ Key = 'Name'; Value = 'other-server' })
                                State            = [pscustomobject]@{ Name = [pscustomobject]@{ Value = 'running' } }
                                InstanceType     = [pscustomobject]@{ Value = 't3.medium' }
                                Placement        = [pscustomobject]@{ AvailabilityZone = 'us-east-1a' }
                                LaunchTime       = [datetime]'2026-01-01'
                                PrivateIpAddress = '10.0.0.1'
                                PublicIpAddress  = $null
                                VpcId            = 'vpc-123'
                                SubnetId         = 'subnet-123'
                            }
                            $MockInstance
                        )
                    })
                }
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Instance { $otherResponse }

                $results = @(Get-AWSInstanceData -Region 'us-east-1' -Name 'app-server-01')
                $results.Count | Should -Be 1
                $results[0].Name | Should -Be 'app-server-01'
            }
        }
    }
}
