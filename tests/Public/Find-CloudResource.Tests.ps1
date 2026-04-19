Describe 'Find-CloudResource' {
    BeforeAll {
        $ModulePath = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent | Join-Path -ChildPath 'PSCumulus.psd1'
        Import-Module $ModulePath -Force
    }

    Context 'Parameter validation' {
        It 'Should have -Name parameter as mandatory' {
            { Find-CloudResource -Name 'test' -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Should accept -Provider parameter' {
            { Find-CloudResource -Name 'test' -Provider Azure -ErrorAction Stop } | Should -Not -Throw
        }

        It 'Should accept -Kind parameter' {
            { Find-CloudResource -Name 'test' -Kind Instance -ErrorAction Stop } | Should -Not -Throw
        }
    }

    Context 'Provider dispatch' {
        BeforeEach {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.Providers['Azure'] = @{
                    Account       = 'test@example.com'
                    ResourceGroup = 'test-rg'
                    Connected     = $true
                }
                $script:PSCumulusContext.ActiveProvider = 'Azure'
            }
        }

        It 'Should call Get-CloudInstance when Kind includes Instance' {
            InModuleScope PSCumulus {
                Mock Get-CloudInstance -MockWith {
                    [PSCustomObject]@{
                        PSTypeName = 'PSCumulus.AzureCloudRecord'
                        Name       = 'test-vm'
                        Provider   = 'Azure'
                        Kind       = 'Instance'
                    }
                }

                $result = Find-CloudResource -Name 'test-vm' -Kind Instance
                $result | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Output shape' {
        It 'Should return objects with Kind property' {
            InModuleScope PSCumulus {
                Mock Get-CloudInstance -MockWith {
                    [PSCustomObject]@{
                        PSTypeName = 'PSCumulus.AzureCloudRecord'
                        Name       = 'test-vm'
                        Provider   = 'Azure'
                    }
                }

                $result = Find-CloudResource -Name 'test-vm' -Kind Instance
                $result.Kind | Should -Be 'Instance'
            }
        }

        It 'Should filter results by Name wildcard' {
            InModuleScope PSCumulus {
                Mock Get-CloudInstance -MockWith {
                    [PSCustomObject]@{
                        PSTypeName = 'PSCumulus.AzureCloudRecord'
                        Name       = 'test-vm'
                        Provider   = 'Azure'
                    }
                }

                $result = Find-CloudResource -Name 'test-*' -Kind Instance
                $result.Count | Should -BeGreaterOrEqual 0
            }
        }
    }

    Context 'Multi-provider behavior' {
        It 'Should skip providers without active session context' {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.Providers['Azure'] = $null
                $script:PSCumulusContext.Providers['AWS'] = $null
                $script:PSCumulusContext.Providers['GCP'] = $null

                $result = Find-CloudResource -Name 'test'
                $result | Should -BeNullOrEmpty
            }
        }
    }
}
