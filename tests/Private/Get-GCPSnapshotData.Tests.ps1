BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Get-GCPSnapshotData' {

    Context 'when snapshots are returned' {
        It 'returns a normalized snapshot record scoped to the project' {
            InModuleScope PSCumulus {
                Mock Assert-GCloudAuthenticated { $true }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson {
                    @([pscustomobject]@{
                        name              = 'disk-snap-01'
                        diskSizeGb        = '50'
                        sourceDisk        = 'https://compute.googleapis.com/v1/projects/my-project/zones/us-central1-a/disks/data-01'
                        creationTimestamp = '2026-03-05T01:00:00-07:00'
                        status            = 'READY'
                        storageBytes      = '1234567'
                    })
                }

                $result = Get-GCPSnapshotData -Project 'my-project'
                $result.Name | Should -Be 'disk-snap-01'
                $result.Provider | Should -Be 'GCP'
                $result.Kind | Should -Be 'Snapshot'
                $result.SizeGB | Should -Be 50
                $result.Project | Should -Be 'my-project'
                $result.SourceDiskId | Should -Match 'disks/data-01'
            }
        }

        It 'passes the compute snapshots list arguments with the project' {
            InModuleScope PSCumulus {
                Mock Assert-GCloudAuthenticated { $true }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @() }

                $null = Get-GCPSnapshotData -Project 'my-project'
                Should -Invoke Invoke-GCloudJson -Times 1 -ParameterFilter {
                    ($Arguments -join ' ') -eq 'compute snapshots list --project=my-project'
                }
            }
        }
    }
}
