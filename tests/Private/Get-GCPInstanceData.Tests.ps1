BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Get-GCPInstanceData' {

    BeforeAll {
        $script:activeAccount = [pscustomobject]@{ account = 'user@example.com'; status = 'ACTIVE' }

        $script:mockGcpInstance = [pscustomobject]@{
            name              = 'gcp-vm-01'
            zone              = 'projects/my-proj/zones/us-central1-a'
            machineType       = 'projects/my-proj/machineTypes/n1-standard-2'
            status            = 'RUNNING'
            creationTimestamp = '2026-02-01T09:00:00.000-07:00'
            id                = '1234567890'
            networkInterfaces = @([pscustomobject]@{
                networkIP     = '10.128.0.5'
                accessConfigs = @([pscustomobject]@{ natIP = '34.1.2.3' })
            })
            labels = [pscustomobject]@{ env = 'prod' }
        }
    }

    Context 'successful retrieval' {
        It 'returns a CloudRecord for each GCP instance' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Instance = $script:mockGcpInstance } {
                param($Account, $Instance)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Instance) }

                $results = @(Get-GCPInstanceData -Project 'my-project')
                $results.Count | Should -Be 1
            }
        }

        It 'maps instance name correctly' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Instance = $script:mockGcpInstance } {
                param($Account, $Instance)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Instance) }

                $result = Get-GCPInstanceData -Project 'my-project'
                $result.Name | Should -Be 'gcp-vm-01'
            }
        }

        It 'sets Provider to GCP' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Instance = $script:mockGcpInstance } {
                param($Account, $Instance)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Instance) }

                $result = Get-GCPInstanceData -Project 'my-project'
                $result.Provider | Should -Be 'GCP'
            }
        }

        It 'extracts zone short name from the full zone URL' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Instance = $script:mockGcpInstance } {
                param($Account, $Instance)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Instance) }

                $result = Get-GCPInstanceData -Project 'my-project'
                $result.Region | Should -Be 'us-central1-a'
            }
        }

        It 'extracts machine type short name from the full machineType URL' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Instance = $script:mockGcpInstance } {
                param($Account, $Instance)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Instance) }

                $result = Get-GCPInstanceData -Project 'my-project'
                $result.Size | Should -Be 'n1-standard-2'
            }
        }

        It 'title-cases the GCP status' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Instance = $script:mockGcpInstance } {
                param($Account, $Instance)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Instance) }

                $result = Get-GCPInstanceData -Project 'my-project'
                $result.Status | Should -Be 'Running'
            }
        }

        It 'parses creationTimestamp to CreatedAt' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Instance = $script:mockGcpInstance } {
                param($Account, $Instance)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Instance) }

                $result = Get-GCPInstanceData -Project 'my-project'
                $result.CreatedAt | Should -BeOfType [datetime]
            }
        }

        It 'includes Project in Metadata' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Instance = $script:mockGcpInstance } {
                param($Account, $Instance)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Instance) }

                $result = Get-GCPInstanceData -Project 'my-project'
                $result.Metadata.Project | Should -Be 'my-project'
            }
        }

        It 'returns nothing when gcloud returns no instances' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount } {
                param($Account)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @() }

                $results = @(Get-GCPInstanceData -Project 'my-project')
                $results.Count | Should -Be 0
            }
        }
    }

    Context 'authentication' {
        It 'throws when not authenticated' {
            InModuleScope PSCumulus {
                Mock Assert-GCloudAuthenticated {
                    throw [System.InvalidOperationException]::new('No active gcloud account found.')
                }

                { Get-GCPInstanceData -Project 'my-project' } | Should -Throw
            }
        }
    }
}
