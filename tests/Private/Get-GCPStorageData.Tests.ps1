BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Get-GCPStorageData' {

    BeforeAll {
        $script:activeAccount = [pscustomobject]@{ account = 'user@example.com'; status = 'ACTIVE' }

        $script:mockBucket = [pscustomobject]@{
            name         = 'my-prod-bucket'
            location     = 'US-EAST1'
            storageClass = 'STANDARD'
            timeCreated  = '2026-03-01T10:00:00.000Z'
        }
    }

    Context 'successful retrieval' {
        It 'returns a CloudRecord for each bucket' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Bucket = $script:mockBucket } {
                param($Account, $Bucket)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Bucket) }

                $results = @(Get-GCPStorageData -Project 'my-project')
                $results.Count | Should -Be 1
            }
        }

        It 'maps bucket name to Name' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Bucket = $script:mockBucket } {
                param($Account, $Bucket)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Bucket) }

                $result = Get-GCPStorageData -Project 'my-project'
                $result.Name | Should -Be 'my-prod-bucket'
            }
        }

        It 'sets Provider to GCP' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Bucket = $script:mockBucket } {
                param($Account, $Bucket)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Bucket) }

                $result = Get-GCPStorageData -Project 'my-project'
                $result.Provider | Should -Be 'GCP'
            }
        }

        It 'maps location to Region' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Bucket = $script:mockBucket } {
                param($Account, $Bucket)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Bucket) }

                $result = Get-GCPStorageData -Project 'my-project'
                $result.Region | Should -Be 'US-EAST1'
            }
        }

        It 'maps storageClass to Size' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Bucket = $script:mockBucket } {
                param($Account, $Bucket)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Bucket) }

                $result = Get-GCPStorageData -Project 'my-project'
                $result.Size | Should -Be 'STANDARD'
            }
        }

        It 'sets Status to Available' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Bucket = $script:mockBucket } {
                param($Account, $Bucket)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Bucket) }

                $result = Get-GCPStorageData -Project 'my-project'
                $result.Status | Should -Be 'Available'
            }
        }

        It 'parses timeCreated to CreatedAt' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Bucket = $script:mockBucket } {
                param($Account, $Bucket)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Bucket) }

                $result = Get-GCPStorageData -Project 'my-project'
                $result.CreatedAt | Should -BeOfType [datetime]
            }
        }

        It 'includes Project in Metadata' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Bucket = $script:mockBucket } {
                param($Account, $Bucket)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Bucket) }

                $result = Get-GCPStorageData -Project 'my-project'
                $result.Metadata.Project | Should -Be 'my-project'
            }
        }

        It 'strips the gs:// prefix from bucket names' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount } {
                param($Account)
                $prefixedBucket = [pscustomobject]@{
                    name         = 'gs://my-prefixed-bucket'
                    location     = 'US'
                    storageClass = 'STANDARD'
                    timeCreated  = ''
                }
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($prefixedBucket) }

                $result = Get-GCPStorageData -Project 'my-project'
                $result.Name | Should -Be 'my-prefixed-bucket'
            }
        }

        It 'returns PSCumulus.CloudRecord type' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Bucket = $script:mockBucket } {
                param($Account, $Bucket)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Bucket) }

                $result = Get-GCPStorageData -Project 'my-project'
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

                { Get-GCPStorageData -Project 'my-project' } | Should -Throw
            }
        }
    }
}
