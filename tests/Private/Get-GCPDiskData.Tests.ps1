BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Get-GCPDiskData' {

    BeforeAll {
        $script:activeAccount = [pscustomobject]@{ account = 'user@example.com'; status = 'ACTIVE' }

        $script:mockDisk = [pscustomobject]@{
            name              = 'data-disk-01'
            zone              = 'projects/my-proj/zones/us-central1-a'
            type              = 'projects/my-proj/diskTypes/pd-ssd'
            sizeGb            = '100'
            status            = 'READY'
            creationTimestamp = '2026-03-01T08:00:00.000-07:00'
        }
    }

    Context 'successful retrieval' {
        It 'returns a CloudRecord for each disk' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Disk = $script:mockDisk } {
                param($Account, $Disk)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Disk) }

                $results = @(Get-GCPDiskData -Project 'my-project')
                $results.Count | Should -Be 1
            }
        }

        It 'maps disk name correctly' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Disk = $script:mockDisk } {
                param($Account, $Disk)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Disk) }

                $result = Get-GCPDiskData -Project 'my-project'
                $result.Name | Should -Be 'data-disk-01'
            }
        }

        It 'sets Provider to GCP' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Disk = $script:mockDisk } {
                param($Account, $Disk)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Disk) }

                $result = Get-GCPDiskData -Project 'my-project'
                $result.Provider | Should -Be 'GCP'
            }
        }

        It 'extracts zone short name from full zone URL' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Disk = $script:mockDisk } {
                param($Account, $Disk)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Disk) }

                $result = Get-GCPDiskData -Project 'my-project'
                $result.Region | Should -Be 'us-central1-a'
            }
        }

        It 'formats sizeGb as Size string' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Disk = $script:mockDisk } {
                param($Account, $Disk)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Disk) }

                $result = Get-GCPDiskData -Project 'my-project'
                $result.Size | Should -Be '100 GB'
            }
        }

        It 'title-cases the disk status' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Disk = $script:mockDisk } {
                param($Account, $Disk)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Disk) }

                $result = Get-GCPDiskData -Project 'my-project'
                $result.Status | Should -Be 'Ready'
            }
        }

        It 'parses creationTimestamp to CreatedAt' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Disk = $script:mockDisk } {
                param($Account, $Disk)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Disk) }

                $result = Get-GCPDiskData -Project 'my-project'
                $result.CreatedAt | Should -BeOfType [datetime]
            }
        }

        It 'extracts disk type short name from full type URL' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Disk = $script:mockDisk } {
                param($Account, $Disk)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Disk) }

                $result = Get-GCPDiskData -Project 'my-project'
                $result.Metadata.DiskType | Should -Be 'pd-ssd'
            }
        }

        It 'includes Project in Metadata' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Disk = $script:mockDisk } {
                param($Account, $Disk)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Disk) }

                $result = Get-GCPDiskData -Project 'my-project'
                $result.Metadata.Project | Should -Be 'my-project'
            }
        }

        It 'returns PSCumulus.CloudRecord type' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Disk = $script:mockDisk } {
                param($Account, $Disk)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Disk) }

                $result = Get-GCPDiskData -Project 'my-project'
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRecord'
            }
        }
    }

    Context 'authentication' {
        It 'throws when not authenticated' {
            InModuleScope PSCumulus {
                Mock Assert-GCloudAuthenticated {
                    throw [System.InvalidOperationException]::new('No active gcloud account found.')
                }

                { Get-GCPDiskData -Project 'my-project' } | Should -Throw
            }
        }
    }
}
