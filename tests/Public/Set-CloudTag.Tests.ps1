Describe 'Set-CloudTag' {
    BeforeAll {
        $ModulePath = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent | Join-Path -ChildPath 'PSCumulus.psd1'
        Import-Module $ModulePath -Force
    }

    Context 'Parameter validation' {
        It 'Should have -Tags parameter as mandatory' {
            InModuleScope PSCumulus {
                Mock -CommandName Assert-CommandAvailable
                Mock -CommandName Invoke-CloudProvider
                # Mock the private Set-AzureTag function
                Mock Set-AzureTag -MockWith { @() }
            }
            { Set-CloudTag -Name 'test' -ResourceGroup 'rg' -Tags @{} -WhatIf } | Should -Not -Throw
        }

        It 'Should have -Merge switch' {
            InModuleScope PSCumulus {
                Mock -CommandName Assert-CommandAvailable
                Mock -CommandName Invoke-CloudProvider
                Mock Set-AzureTag -MockWith { @() }
            }
            { Set-CloudTag -Name 'test' -ResourceGroup 'rg' -Tags @{} -Merge -WhatIf } | Should -Not -Throw
        }
    }

    Context 'Azure parameter set' {
        BeforeEach {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.Providers['Azure'] = @{
                    Account  = 'test@example.com'
                    Connected = $true
                }
                $script:PSCumulusContext.ActiveProvider = 'Azure'
                Mock -CommandName Assert-CommandAvailable
                Mock Set-AzureTag -MockWith { @() }
            }
        }

        It 'Should accept Azure parameters' {
            { Set-CloudTag -Name 'vm01' -ResourceGroup 'rg-test' -Tags @{Environment = 'Dev' } -WhatIf } | Should -Not -Throw
        }
    }

    Context 'AWS parameter set' {
        BeforeEach {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.Providers['AWS'] = @{
                    Account  = 'test@example.com'
                    Connected = $true
                }
                $script:PSCumulusContext.ActiveProvider = 'AWS'
                Mock -CommandName Assert-CommandAvailable
                Mock Set-AWSTag -MockWith { @() }
            }
        }

        It 'Should accept AWS parameters' {
            { Set-CloudTag -ResourceId 'i-12345' -Region 'us-east-1' -Tags @{Environment = 'Dev' } -WhatIf } | Should -Not -Throw
        }
    }

    Context 'GCP parameter set' {
        BeforeEach {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.Providers['GCP'] = @{
                    Account  = 'test@example.com'
                    Connected = $true
                }
                $script:PSCumulusContext.ActiveProvider = 'GCP'
                Mock -CommandName Assert-CommandAvailable
                Mock Set-GCPTag -MockWith { @() }
            }
        }

        It 'Should accept GCP parameters' {
            { Set-CloudTag -Project 'test-project' -Resource 'projects/test/zones/us-central1-a/instances/vm01' -Tags @{Environment = 'Dev' } -WhatIf } | Should -Not -Throw
        }
    }

    Context 'Pipeline input' {
        BeforeEach {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.Providers['Azure'] = @{
                    Account  = 'test@example.com'
                    Connected = $true
                }
                $script:PSCumulusContext.ActiveProvider = 'Azure'
                Mock -CommandName Assert-CommandAvailable
                Mock Set-AzureTag -MockWith { @() }

                # Create mock record at script level so it's available outside InModuleScope
                $script:mockRecord = New-Object PSObject -Property @{
                    Name          = 'vm01'
                    Provider      = 'Azure'
                    ResourceGroup = 'rg-test'
                    Id            = '/subscriptions/123/resourceGroups/rg-test/providers/Microsoft.Compute/virtualMachines/vm01'
                }
                $script:mockRecord.PSTypeNames.Insert(0, 'PSCumulus.CloudRecord')
            }
        }

        It 'Should accept piped CloudRecord object' {
            InModuleScope PSCumulus {
                { $script:mockRecord | Set-CloudTag -Tags @{Environment = 'Dev' } -WhatIf } | Should -Not -Throw
            }
        }
    }

    Context 'Path parameter set (Stage 4)' {
        # -Path was removed in v0.6.0 and restored in Stage 4, now backed by Get-CloudResource.
        It 'Should resolve the path via Get-CloudResource and tag the resolved Azure resource' {
            InModuleScope PSCumulus {
                Mock Get-CloudResource {
                    $record = New-Object PSObject -Property @{
                        Name          = 'vm01'
                        Provider      = 'Azure'
                        ResourceGroup = 'rg-test'
                        Id            = '/subscriptions/123/resourceGroups/rg-test/providers/Microsoft.Compute/virtualMachines/vm01'
                    }
                    $record.PSTypeNames.Insert(0, 'PSCumulus.CloudRecord')
                    $record
                }
                Mock Set-AzureTag { @() }

                Set-CloudTag -Path 'Azure:\rg-test\Instances\vm01' -Tags @{Environment = 'Dev' } -Confirm:$false

                Should -Invoke Get-CloudResource -Times 1 -ParameterFilter { $Path -eq 'Azure:\rg-test\Instances\vm01' }
                Should -Invoke Set-AzureTag -Times 1 -ParameterFilter {
                    $ResourceId -eq '/subscriptions/123/resourceGroups/rg-test/providers/Microsoft.Compute/virtualMachines/vm01'
                }
            }
        }

        It 'Should tag every resource a kind-depth path resolves to' {
            InModuleScope PSCumulus {
                Mock Get-CloudResource {
                    foreach ($name in 'vol-1', 'vol-2') {
                        $record = New-Object PSObject -Property @{
                            Name     = $name
                            Provider = 'AWS'
                            Id       = $name
                            Region   = 'us-east-1'
                        }
                        $record.PSTypeNames.Insert(0, 'PSCumulus.CloudRecord')
                        $record
                    }
                }
                Mock Set-AWSTag { @() }

                Set-CloudTag -Path 'AWS:\us-east-1\Disks' -Tags @{team = 'ops' } -Confirm:$false

                Should -Invoke Set-AWSTag -Times 2
            }
        }

        It 'Should support -WhatIf without calling any tag backend' {
            InModuleScope PSCumulus {
                Mock Get-CloudResource {
                    $record = New-Object PSObject -Property @{
                        Name          = 'vm01'
                        Provider      = 'Azure'
                        ResourceGroup = 'rg-test'
                        Id            = '/id/vm01'
                    }
                    $record.PSTypeNames.Insert(0, 'PSCumulus.CloudRecord')
                    $record
                }
                Mock Set-AzureTag { @() }

                Set-CloudTag -Path 'Azure:\rg-test\Instances\vm01' -Tags @{Environment = 'Dev' } -WhatIf

                Should -Invoke Set-AzureTag -Times 0
            }
        }
    }

    Context 'ShouldProcess support' {
        BeforeEach {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.Providers['Azure'] = @{
                    Account  = 'test@example.com'
                    Connected = $true
                }
                $script:PSCumulusContext.ActiveProvider = 'Azure'
                Mock -CommandName Assert-CommandAvailable
                Mock Set-AzureTag -MockWith { @() }
            }
        }

        It 'Should support -WhatIf' {
            Set-CloudTag -Name 'vm01' -ResourceGroup 'rg-test' -Tags @{Environment = 'Dev' } -WhatIf | Should -BeNullOrEmpty
        }

        It 'Should support -Confirm' -Pending {
            InModuleScope PSCumulus {
                Mock -CommandName Invoke-CloudProvider
            }
            Mock -CommandName $PSCmdlet.ShouldProcess -MockWith { $true }

            { Set-CloudTag -Name 'vm01' -ResourceGroup 'rg-test' -Tags @{Environment = 'Dev' } -Confirm:($false) } | Should -Not -Throw
        }
    }
}
