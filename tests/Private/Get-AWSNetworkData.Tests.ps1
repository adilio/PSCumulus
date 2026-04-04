BeforeAll {
    # Stub AWS EC2 VPC command so Pester can create mocks when AWS.Tools is not installed
    if (-not (Get-Command Get-EC2Vpc -ErrorAction SilentlyContinue)) {
        $script:stubCreatedGetEC2Vpc = $true
        function global:Get-EC2Vpc { param([string]$Region) }
    }

    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

AfterAll {
    if ($script:stubCreatedGetEC2Vpc) {
        Remove-Item -Path Function:global:Get-EC2Vpc -ErrorAction SilentlyContinue
    }
}

Describe 'Get-AWSNetworkData' {

    Context 'when AWS.Tools.EC2 is not installed' {
        It 'throws when Get-EC2Vpc is unavailable' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {
                    throw [System.Management.Automation.CommandNotFoundException]::new(
                        "Required command 'Get-EC2Vpc' was not found."
                    )
                }

                { Get-AWSNetworkData -Region 'us-east-1' } | Should -Throw
            }
        }
    }

    Context 'when VPCs are returned' {
        BeforeAll {
            $script:mockVpc = [pscustomobject]@{
                VpcId     = 'vpc-0abc123'
                CidrBlock = '10.0.0.0/16'
                IsDefault = $false
                State     = [pscustomobject]@{ Value = 'available' }
                Tags      = @([pscustomobject]@{ Key = 'Name'; Value = 'prod-vpc' })
            }
            $script:noNameVpc = [pscustomobject]@{
                VpcId     = 'vpc-0def456'
                CidrBlock = '172.16.0.0/12'
                IsDefault = $true
                State     = [pscustomobject]@{ Value = 'available' }
                Tags      = @()
            }
        }

        It 'returns a CloudRecord for each VPC' {
            InModuleScope PSCumulus -Parameters @{ MockVpc = $script:mockVpc } {
                param($MockVpc)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Vpc { @($MockVpc) }

                $results = @(Get-AWSNetworkData -Region 'us-east-1')
                $results.Count | Should -Be 1
            }
        }

        It 'uses Name tag as Name' {
            InModuleScope PSCumulus -Parameters @{ MockVpc = $script:mockVpc } {
                param($MockVpc)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Vpc { @($MockVpc) }

                $result = Get-AWSNetworkData -Region 'us-east-1'
                $result.Name | Should -Be 'prod-vpc'
            }
        }

        It 'falls back to VpcId when no Name tag exists' {
            InModuleScope PSCumulus -Parameters @{ NoNameVpc = $script:noNameVpc } {
                param($NoNameVpc)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Vpc { @($NoNameVpc) }

                $result = Get-AWSNetworkData -Region 'us-east-1'
                $result.Name | Should -Be 'vpc-0def456'
            }
        }

        It 'sets Provider to AWS' {
            InModuleScope PSCumulus -Parameters @{ MockVpc = $script:mockVpc } {
                param($MockVpc)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Vpc { @($MockVpc) }

                $result = Get-AWSNetworkData -Region 'us-east-1'
                $result.Provider | Should -Be 'AWS'
            }
        }

        It 'maps State to Status' {
            InModuleScope PSCumulus -Parameters @{ MockVpc = $script:mockVpc } {
                param($MockVpc)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Vpc { @($MockVpc) }

                $result = Get-AWSNetworkData -Region 'us-east-1'
                $result.Status | Should -Be 'available'
            }
        }

        It 'maps CidrBlock to Size' {
            InModuleScope PSCumulus -Parameters @{ MockVpc = $script:mockVpc } {
                param($MockVpc)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Vpc { @($MockVpc) }

                $result = Get-AWSNetworkData -Region 'us-east-1'
                $result.Size | Should -Be '10.0.0.0/16'
            }
        }

        It 'includes VpcId in Metadata' {
            InModuleScope PSCumulus -Parameters @{ MockVpc = $script:mockVpc } {
                param($MockVpc)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Vpc { @($MockVpc) }

                $result = Get-AWSNetworkData -Region 'us-east-1'
                $result.Metadata.VpcId | Should -Be 'vpc-0abc123'
            }
        }

        It 'returns PSCumulus.CloudRecord type' {
            InModuleScope PSCumulus -Parameters @{ MockVpc = $script:mockVpc } {
                param($MockVpc)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Vpc { @($MockVpc) }

                $result = Get-AWSNetworkData -Region 'us-east-1'
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRecord'
            }
        }
    }
}
