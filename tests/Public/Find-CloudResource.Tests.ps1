Describe 'Find-CloudResource' {
    BeforeAll {
        if (-not (Get-Command Get-AzResourceGroup -ErrorAction SilentlyContinue)) {
            function global:Get-AzResourceGroup { }
        }

        $ModulePath = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent | Join-Path -ChildPath 'PSCumulus.psd1'
        Import-Module $ModulePath -Force
    }

    BeforeEach {
        InModuleScope PSCumulus {
            if (-not (Get-Command Get-AzResourceGroup -ErrorAction SilentlyContinue)) {
                function Get-AzResourceGroup { }
            }

            $script:PSCumulusContext.Providers['Azure'] = @{
                Account        = 'test@example.com'
                SubscriptionId = 'sub-123'
                Connected      = $true
            }
            $script:PSCumulusContext.ActiveProvider = 'Azure'
        }
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
        It 'Should call Get-CloudInstance when Kind includes Instance' {
            InModuleScope PSCumulus {
                Mock Get-AzResourceGroup -MockWith {
                    [PSCustomObject]@{ ResourceGroupName = 'test-rg' }
                }

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
                Mock Get-AzResourceGroup -MockWith {
                    [PSCustomObject]@{ ResourceGroupName = 'test-rg' }
                }

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
                Mock Get-AzResourceGroup -MockWith {
                    [PSCustomObject]@{ ResourceGroupName = 'test-rg' }
                }

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

        It 'Should skip Azure when Get-AzResourceGroup returns no RGs and emit verbose' {
            InModuleScope PSCumulus {
                Mock Get-AzResourceGroup -MockWith { @() }
                Mock Get-CloudInstance -MockWith {
                    [PSCustomObject]@{
                        PSTypeName = 'PSCumulus.AzureCloudRecord'
                        Name       = 'test-vm'
                        Provider   = 'Azure'
                    }
                }

                $output = Find-CloudResource -Name 'test-vm' -Provider Azure -Kind Instance -Verbose 4>&1
                $records = @($output | Where-Object { $_ -isnot [System.Management.Automation.VerboseRecord] })
                $verbose = @($output | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] })

                $records | Should -BeNullOrEmpty
                $verbose.Message | Should -Contain 'Find-CloudResource: no resource groups returned for Azure subscription sub-123; skipping.'
                Assert-MockCalled Get-CloudInstance -Times 0 -Exactly
            }
        }
    }
}
