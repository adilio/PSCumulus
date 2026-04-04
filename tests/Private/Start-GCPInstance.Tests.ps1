BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Start-GCPInstance' {

    BeforeAll {
        $script:activeAccount = [pscustomobject]@{ account = 'user@example.com'; status = 'ACTIVE' }
    }

    Context 'successful start' {
        It 'returns a CloudRecord' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount } {
                param($Account)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { }

                $result = Start-GCPInstance -Name 'gcp-vm-01' -Zone 'us-central1-a' -Project 'my-project'
                $result | Should -Not -BeNullOrEmpty
            }
        }

        It 'sets Name correctly' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount } {
                param($Account)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { }

                $result = Start-GCPInstance -Name 'gcp-vm-01' -Zone 'us-central1-a' -Project 'my-project'
                $result.Name | Should -Be 'gcp-vm-01'
            }
        }

        It 'sets Provider to GCP' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount } {
                param($Account)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { }

                $result = Start-GCPInstance -Name 'gcp-vm-01' -Zone 'us-central1-a' -Project 'my-project'
                $result.Provider | Should -Be 'GCP'
            }
        }

        It 'sets Status to Starting' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount } {
                param($Account)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { }

                $result = Start-GCPInstance -Name 'gcp-vm-01' -Zone 'us-central1-a' -Project 'my-project'
                $result.Status | Should -Be 'Starting'
            }
        }

        It 'maps Zone to Region' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount } {
                param($Account)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { }

                $result = Start-GCPInstance -Name 'gcp-vm-01' -Zone 'us-central1-a' -Project 'my-project'
                $result.Region | Should -Be 'us-central1-a'
            }
        }

        It 'includes Project in Metadata' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount } {
                param($Account)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { }

                $result = Start-GCPInstance -Name 'gcp-vm-01' -Zone 'us-central1-a' -Project 'my-project'
                $result.Metadata.Project | Should -Be 'my-project'
            }
        }

        It 'returns PSCumulus.CloudRecord type' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount } {
                param($Account)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { }

                $result = Start-GCPInstance -Name 'gcp-vm-01' -Zone 'us-central1-a' -Project 'my-project'
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

                { Start-GCPInstance -Name 'gcp-vm-01' -Zone 'us-central1-a' } | Should -Throw
            }
        }
    }
}
