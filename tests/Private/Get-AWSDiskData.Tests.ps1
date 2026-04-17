BeforeAll {
    # Stub AWS EC2 volume command so Pester can create mocks when AWS.Tools is not installed
    if (-not (Get-Command Get-EC2Volume -ErrorAction SilentlyContinue)) {
        $script:stubCreatedGetEC2Volume = $true
        function global:Get-EC2Volume { param([string]$Region) }
    }

    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

AfterAll {
    if ($script:stubCreatedGetEC2Volume) {
        Remove-Item -Path Function:global:Get-EC2Volume -ErrorAction SilentlyContinue
    }
}

Describe 'Get-AWSDiskData' {

    Context 'when AWS.Tools.EC2 is not installed' {
        It 'throws when Get-EC2Volume is unavailable' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {
                    throw [System.Management.Automation.CommandNotFoundException]::new(
                        "Required command 'Get-EC2Volume' was not found."
                    )
                }

                { Get-AWSDiskData -Region 'us-east-1' } | Should -Throw
            }
        }
    }

    Context 'when volumes are returned' {
        BeforeAll {
            $script:mockVolume = [pscustomobject]@{
                VolumeId         = 'vol-0abc123def456'
                AvailabilityZone = 'us-east-1a'
                Size             = 100
                State            = [pscustomobject]@{ Value = 'in-use' }
                VolumeType       = [pscustomobject]@{ Value = 'gp3' }
                Encrypted        = $true
                CreateTime       = [datetime]'2026-01-20T11:00:00Z'
                Tags             = @([pscustomobject]@{ Key = 'Name'; Value = 'data-volume' })
                Attachments      = @([pscustomobject]@{ InstanceId = 'i-0abc123def456789' })
            }
            $script:noNameVolume = [pscustomobject]@{
                VolumeId         = 'vol-0noname'
                AvailabilityZone = 'us-east-1b'
                Size             = 50
                State            = [pscustomobject]@{ Value = 'available' }
                VolumeType       = [pscustomobject]@{ Value = 'gp2' }
                Encrypted        = $false
                CreateTime       = [datetime]'2026-02-01'
                Tags             = @()
                Attachments      = @()
            }
        }

        It 'returns a CloudRecord for each volume' {
            InModuleScope PSCumulus -Parameters @{ MockVolume = $script:mockVolume } {
                param($MockVolume)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Volume { @($MockVolume) }

                $results = @(Get-AWSDiskData -Region 'us-east-1')
                $results.Count | Should -Be 1
            }
        }

        It 'uses Name tag as Name' {
            InModuleScope PSCumulus -Parameters @{ MockVolume = $script:mockVolume } {
                param($MockVolume)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Volume { @($MockVolume) }

                $result = Get-AWSDiskData -Region 'us-east-1'
                $result.Name | Should -Be 'data-volume'
            }
        }

        It 'falls back to VolumeId when no Name tag exists' {
            InModuleScope PSCumulus -Parameters @{ NoNameVolume = $script:noNameVolume } {
                param($NoNameVolume)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Volume { @($NoNameVolume) }

                $result = Get-AWSDiskData -Region 'us-east-1'
                $result.Name | Should -Be 'vol-0noname'
            }
        }

        It 'sets Provider to AWS' {
            InModuleScope PSCumulus -Parameters @{ MockVolume = $script:mockVolume } {
                param($MockVolume)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Volume { @($MockVolume) }

                $result = Get-AWSDiskData -Region 'us-east-1'
                $result.Provider | Should -Be 'AWS'
            }
        }

        It 'maps AvailabilityZone to Region' {
            InModuleScope PSCumulus -Parameters @{ MockVolume = $script:mockVolume } {
                param($MockVolume)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Volume { @($MockVolume) }

                $result = Get-AWSDiskData -Region 'us-east-1'
                $result.Region | Should -Be 'us-east-1a'
            }
        }

        It 'formats Size as GB string' {
            InModuleScope PSCumulus -Parameters @{ MockVolume = $script:mockVolume } {
                param($MockVolume)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Volume { @($MockVolume) }

                $result = Get-AWSDiskData -Region 'us-east-1'
                $result.Size | Should -Be '100 GB'
            }
        }

        It 'maps State to Status' {
            InModuleScope PSCumulus -Parameters @{ MockVolume = $script:mockVolume } {
                param($MockVolume)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Volume { @($MockVolume) }

                $result = Get-AWSDiskData -Region 'us-east-1'
                $result.Status | Should -Be 'Attached'
            }
        }

        It 'maps CreateTime to CreatedAt' {
            InModuleScope PSCumulus -Parameters @{ MockVolume = $script:mockVolume } {
                param($MockVolume)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Volume { @($MockVolume) }

                $result = Get-AWSDiskData -Region 'us-east-1'
                $result.CreatedAt | Should -Be ([datetime]'2026-01-20T11:00:00Z')
            }
        }

        It 'includes VolumeId in Metadata' {
            InModuleScope PSCumulus -Parameters @{ MockVolume = $script:mockVolume } {
                param($MockVolume)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Volume { @($MockVolume) }

                $result = Get-AWSDiskData -Region 'us-east-1'
                $result.Metadata.VolumeId | Should -Be 'vol-0abc123def456'
            }
        }

        It 'returns PSCumulus.CloudRecord type' {
            InModuleScope PSCumulus -Parameters @{ MockVolume = $script:mockVolume } {
                param($MockVolume)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Volume { @($MockVolume) }

                $result = Get-AWSDiskData -Region 'us-east-1'
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRecord'
            }
        }
    }
}
