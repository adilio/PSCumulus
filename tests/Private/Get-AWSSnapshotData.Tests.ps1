BeforeAll {
    if (-not (Get-Command Get-EC2Snapshot -ErrorAction SilentlyContinue)) {
        $script:stubCreatedGetEC2Snapshot = $true
        function global:Get-EC2Snapshot { param([string]$OwnerId, [string]$Region) }
    }

    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

AfterAll {
    if ($script:stubCreatedGetEC2Snapshot) {
        Remove-Item -Path Function:global:Get-EC2Snapshot -ErrorAction SilentlyContinue
    }
}

Describe 'Get-AWSSnapshotData' {

    Context 'when snapshots are returned' {
        BeforeAll {
            $script:mockSnapshot = [pscustomobject]@{
                SnapshotId = 'snap-0abc123'
                VolumeId   = 'vol-0def456'
                VolumeSize = 100
                StartTime  = [datetime]'2026-03-01T04:00:00Z'
                State      = [pscustomobject]@{ Value = 'completed' }
                OwnerId    = '123456789012'
                Description = 'nightly backup'
                Tags       = @([pscustomobject]@{ Key = 'Name'; Value = 'payment-vol-backup' })
            }
        }

        It 'returns a normalized snapshot record with the Name tag as Name' {
            InModuleScope PSCumulus -Parameters @{ MockSnapshot = $script:mockSnapshot } {
                param($MockSnapshot)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Snapshot { @($MockSnapshot) }

                $result = Get-AWSSnapshotData -Region 'us-east-1'
                $result.Name | Should -Be 'payment-vol-backup'
                $result.Provider | Should -Be 'AWS'
                $result.Kind | Should -Be 'Snapshot'
                $result.SourceDiskId | Should -Be 'vol-0def456'
                $result.SizeGB | Should -Be 100
                $result.Status | Should -Be 'completed'
            }
        }

        It 'requests only self-owned snapshots' {
            InModuleScope PSCumulus -Parameters @{ MockSnapshot = $script:mockSnapshot } {
                param($MockSnapshot)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Snapshot { @($MockSnapshot) }

                $null = Get-AWSSnapshotData -Region 'us-east-1'
                Should -Invoke Get-EC2Snapshot -Times 1 -ParameterFilter { $OwnerId -eq 'self' -and $Region -eq 'us-east-1' }
            }
        }

        It 'falls back to SnapshotId when no Name tag exists' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Snapshot {
                    @([pscustomobject]@{
                        SnapshotId = 'snap-noname'
                        VolumeId   = 'vol-1'
                        VolumeSize = 8
                        StartTime  = [datetime]'2026-03-01T04:00:00Z'
                        State      = [pscustomobject]@{ Value = 'completed' }
                        Tags       = @()
                    })
                }

                $result = Get-AWSSnapshotData
                $result.Name | Should -Be 'snap-noname'
            }
        }
    }
}
