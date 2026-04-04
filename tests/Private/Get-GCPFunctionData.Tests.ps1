BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Get-GCPFunctionData' {

    BeforeAll {
        $script:activeAccount = [pscustomobject]@{ account = 'user@example.com'; status = 'ACTIVE' }

        # gen2 function (uses 'state' field)
        $script:mockFunctionGen2 = [pscustomobject]@{
            name        = 'projects/my-project/locations/us-central1/functions/hello-world'
            state       = 'ACTIVE'
            runtime     = 'nodejs20'
            entryPoint  = 'helloWorld'
            updateTime  = '2026-03-10T14:00:00.000Z'
        }

        # gen1 function (uses 'status' field)
        $script:mockFunctionGen1 = [pscustomobject]@{
            name        = 'projects/my-project/locations/europe-west1/functions/legacy-fn'
            status      = 'ACTIVE'
            runtime     = 'python39'
            entryPoint  = 'main'
            updateTime  = '2025-11-01T09:00:00.000Z'
        }
    }

    Context 'successful retrieval' {
        It 'returns a CloudRecord for each function' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Fn = $script:mockFunctionGen2 } {
                param($Account, $Fn)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Fn) }

                $results = @(Get-GCPFunctionData -Project 'my-project')
                $results.Count | Should -Be 1
            }
        }

        It 'extracts the short function name from the full resource path' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Fn = $script:mockFunctionGen2 } {
                param($Account, $Fn)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Fn) }

                $result = Get-GCPFunctionData -Project 'my-project'
                $result.Name | Should -Be 'hello-world'
            }
        }

        It 'sets Provider to GCP' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Fn = $script:mockFunctionGen2 } {
                param($Account, $Fn)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Fn) }

                $result = Get-GCPFunctionData -Project 'my-project'
                $result.Provider | Should -Be 'GCP'
            }
        }

        It 'extracts the region from the resource path' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Fn = $script:mockFunctionGen2 } {
                param($Account, $Fn)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Fn) }

                $result = Get-GCPFunctionData -Project 'my-project'
                $result.Region | Should -Be 'us-central1'
            }
        }

        It 'title-cases the gen2 state field into Status' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Fn = $script:mockFunctionGen2 } {
                param($Account, $Fn)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Fn) }

                $result = Get-GCPFunctionData -Project 'my-project'
                $result.Status | Should -Be 'Active'
            }
        }

        It 'title-cases the gen1 status field into Status' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Fn = $script:mockFunctionGen1 } {
                param($Account, $Fn)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Fn) }

                $result = Get-GCPFunctionData -Project 'my-project'
                $result.Status | Should -Be 'Active'
            }
        }

        It 'maps runtime to Size' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Fn = $script:mockFunctionGen2 } {
                param($Account, $Fn)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Fn) }

                $result = Get-GCPFunctionData -Project 'my-project'
                $result.Size | Should -Be 'nodejs20'
            }
        }

        It 'parses updateTime to CreatedAt' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Fn = $script:mockFunctionGen2 } {
                param($Account, $Fn)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Fn) }

                $result = Get-GCPFunctionData -Project 'my-project'
                $result.CreatedAt | Should -BeOfType [datetime]
            }
        }

        It 'includes Project in Metadata' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Fn = $script:mockFunctionGen2 } {
                param($Account, $Fn)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Fn) }

                $result = Get-GCPFunctionData -Project 'my-project'
                $result.Metadata.Project | Should -Be 'my-project'
            }
        }

        It 'includes EntryPoint in Metadata' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Fn = $script:mockFunctionGen2 } {
                param($Account, $Fn)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Fn) }

                $result = Get-GCPFunctionData -Project 'my-project'
                $result.Metadata.EntryPoint | Should -Be 'helloWorld'
            }
        }

        It 'returns PSCumulus.CloudRecord type' {
            InModuleScope PSCumulus -Parameters @{ Account = $script:activeAccount; Fn = $script:mockFunctionGen2 } {
                param($Account, $Fn)
                Mock Assert-GCloudAuthenticated { $Account }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @($Fn) }

                $result = Get-GCPFunctionData -Project 'my-project'
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

                { Get-GCPFunctionData -Project 'my-project' } | Should -Throw
            }
        }
    }
}
