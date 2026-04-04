BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Get-GCPTagData' {

    BeforeAll {
        $script:activeAccount = [pscustomobject]@{ account = 'user@example.com'; status = 'ACTIVE' }

        $script:mockInstance = [pscustomobject]@{
            name   = 'vm-01'
            labels = [pscustomobject]@{
                env  = 'prod'
                team = 'platform'
            }
        }
    }

    Context 'successful retrieval' {
        It 'returns a CloudRecord' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Instance = $script:mockInstance } {
                param($Account, $Instance)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Instance) }

                $result = Get-GCPTagData -Project 'my-project' -Resource 'instances/vm-01'
                $result | Should -Not -BeNullOrEmpty
            }
        }

        It 'sets Name to the resource name segment' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Instance = $script:mockInstance } {
                param($Account, $Instance)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Instance) }

                $result = Get-GCPTagData -Project 'my-project' -Resource 'instances/vm-01'
                $result.Name | Should -Be 'vm-01'
            }
        }

        It 'sets Provider to GCP' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Instance = $script:mockInstance } {
                param($Account, $Instance)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Instance) }

                $result = Get-GCPTagData -Project 'my-project' -Resource 'instances/vm-01'
                $result.Provider | Should -Be 'GCP'
            }
        }

        It 'includes Project in Metadata' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Instance = $script:mockInstance } {
                param($Account, $Instance)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Instance) }

                $result = Get-GCPTagData -Project 'my-project' -Resource 'instances/vm-01'
                $result.Metadata.Project | Should -Be 'my-project'
            }
        }

        It 'builds Labels hashtable from GCP labels' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Instance = $script:mockInstance } {
                param($Account, $Instance)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Instance) }

                $result = Get-GCPTagData -Project 'my-project' -Resource 'instances/vm-01'
                $result.Metadata.Labels['env'] | Should -Be 'prod'
                $result.Metadata.Labels['team'] | Should -Be 'platform'
            }
        }

        It 'returns PSCumulus.CloudRecord type' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Instance = $script:mockInstance } {
                param($Account, $Instance)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Instance) }

                $result = Get-GCPTagData -Project 'my-project' -Resource 'instances/vm-01'
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRecord'
            }
        }

        It 'returns empty Labels when resource has no labels' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount } {
                param($Account)
                $noLabelsInstance = [pscustomobject]@{ name = 'vm-02'; labels = $null }
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($noLabelsInstance) }

                $result = Get-GCPTagData -Project 'my-project' -Resource 'instances/vm-02'
                $result.Metadata.Labels.Count | Should -Be 0
            }
        }
    }

    Context 'authentication' {
        It 'throws when not authenticated' {
            InModuleScope PSCumulus {
                Mock Assert-GCloudAuthenticated {
                    throw [System.InvalidOperationException]::new('No active gcloud account found.')
                }

                { Get-GCPTagData -Project 'my-project' -Resource 'instances/vm-01' } | Should -Throw
            }
        }
    }
}
