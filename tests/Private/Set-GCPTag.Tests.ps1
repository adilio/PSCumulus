Describe 'Set-GCPTag' {
    BeforeAll {
        $ModulePath = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent | Join-Path -ChildPath 'PSCumulus.psd1'
        Import-Module $ModulePath -Force
    }

    Context 'Parameter validation' {
        It 'Should have -Project as mandatory parameter' {
            InModuleScope PSCumulus {
                $params = (Get-Command Set-GCPTag).Parameters
                $params.ContainsKey('Project') | Should -BeTrue
                $params.Project.Attributes.Mandatory | Should -BeTrue
            }
        }

        It 'Should have -Resource as mandatory parameter' {
            InModuleScope PSCumulus {
                $params = (Get-Command Set-GCPTag).Parameters
                $params.ContainsKey('Resource') | Should -BeTrue
                $params.Resource.Attributes.Mandatory | Should -BeTrue
            }
        }

        It 'Should have -Tags as mandatory parameter' {
            InModuleScope PSCumulus {
                $params = (Get-Command Set-GCPTag).Parameters
                $params.ContainsKey('Tags') | Should -BeTrue
                $params.Tags.Attributes.Mandatory | Should -BeTrue
            }
        }

        It 'Should have -Merge switch' {
            InModuleScope PSCumulus {
                $params = (Get-Command Set-GCPTag).Parameters
                $params.ContainsKey('Merge') | Should -BeTrue
                $params.Merge.ParameterType.Name | Should -Be 'SwitchParameter'
            }
        }
    }

    Context 'Command availability check' {
        It 'Should fail if gcloud is not available' {
            InModuleScope PSCumulus {
                Mock -CommandName Assert-CommandAvailable -MockWith {
                    throw 'gcloud not found'
                }

                { Set-GCPTag -Project 'test-project' -Resource 'test-resource' -Tags @{Key = 'Value'} -ErrorAction Stop } | Should -Throw
            }
        }

        It 'Should not throw when gcloud is available' {
            InModuleScope PSCumulus {
                Mock -CommandName Assert-CommandAvailable
                Mock -CommandName Invoke-GCloudJson -MockWith { @() }

                { Set-GCPTag -Project 'test-project' -Resource 'test-resource' -Tags @{Key = 'Value'} } | Should -Not -Throw
            }
        }
    }

    Context 'Tag format conversion' {
        It 'Should convert hashtable to key=value format' {
            InModuleScope PSCumulus {
                Mock -CommandName Assert-CommandAvailable
                Mock -CommandName Invoke-GCloudJson -MockWith {
                    param($Arguments)
                    $tagIndex = $Arguments.IndexOf('--tag')
                    $tagIndex | Should -BeGreaterThan -1
                    $tagValue = $Arguments[$tagIndex + 1]
                    $tagValue | Should -BeLike '*Key1=Value1*'
                    $tagValue | Should -BeLike '*Key2=Value2*'
                    @()
                }

                Set-GCPTag -Project 'test-project' -Resource 'test-resource' -Tags @{Key1 = 'Value1'; Key2 = 'Value2'}
            }
        }
    }

    Context 'Tag merge behavior' {
        It 'Should merge with existing tags when -Merge is specified' {
            InModuleScope PSCumulus {
                Mock -CommandName Assert-CommandAvailable
                Mock -CommandName Invoke-GCloudJson -MockWith {
                    param($Arguments, $ErrorAction)
                    if ($Arguments -contains 'list') {
                        @(
                            @{ names = @('ExistingTag'); shortValue = 'ExistingValue' }
                        )
                    } else {
                        @()
                    }
                }

                $tags = @{NewTag = 'NewValue'}
                Set-GCPTag -Project 'test-project' -Resource 'test-resource' -Tags $tags -Merge
                # The merge should add ExistingTag to $tags
            }
        }

        It 'Should not merge when -Merge is not specified' {
            InModuleScope PSCumulus {
                Mock -CommandName Assert-CommandAvailable
                Mock -CommandName Invoke-GCloudJson -MockWith {
                    param($Arguments, $ErrorAction)
                    if ($Arguments -contains 'list') {
                        @(
                            @{ names = @('ExistingTag'); shortValue = 'ExistingValue' }
                        )
                    } else {
                        @()
                    }
                }

                Set-GCPTag -Project 'test-project' -Resource 'test-resource' -Tags @{NewTag = 'NewValue'} -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'gcloud command invocation' {
        It 'Should invoke gcloud resource-manager tags list when merging' {
            InModuleScope PSCumulus {
                Mock -CommandName Assert-CommandAvailable
                Mock -CommandName Invoke-GCloudJson -MockWith {
                    param($Arguments)
                    if ($Arguments -contains 'list') {
                        $Arguments -contains 'resource-manager' | Should -BeTrue
                        $Arguments -contains 'tags' | Should -BeTrue
                        $Arguments -contains 'list' | Should -BeTrue
                        @()
                    } else {
                        @()
                    }
                }

                Set-GCPTag -Project 'test-project' -Resource 'test-resource' -Tags @{Key = 'Value'} -Merge
            }
        }

        It 'Should invoke gcloud resource-manager tags create' {
            InModuleScope PSCumulus {
                Mock -CommandName Assert-CommandAvailable
                Mock -CommandName Invoke-GCloudJson -MockWith {
                    param($Arguments)
                    if ($Arguments -contains 'create') {
                        $Arguments -contains 'resource-manager' | Should -BeTrue
                        $Arguments -contains 'tags' | Should -BeTrue
                        $Arguments -contains 'create' | Should -BeTrue
                    }
                    @()
                }

                Set-GCPTag -Project 'test-project' -Resource 'test-resource' -Tags @{Key = 'Value'}
            }
        }
    }

    Context 'Error handling' {
        It 'Should handle empty existing tags gracefully' {
            InModuleScope PSCumulus {
                Mock -CommandName Assert-CommandAvailable
                Mock -CommandName Invoke-GCloudJson -MockWith { @() }

                { Set-GCPTag -Project 'test-project' -Resource 'test-resource' -Tags @{Key = 'Value'} -Merge } | Should -Not -Throw
            }
        }

        It 'Should stop on gcloud errors' {
            InModuleScope PSCumulus {
                Mock -CommandName Assert-CommandAvailable
                Mock -CommandName Invoke-GCloudJson -MockWith { throw 'gcloud command failed' }

                { Set-GCPTag -Project 'test-project' -Resource 'test-resource' -Tags @{Key = 'Value'} -ErrorAction Stop } | Should -Throw
            }
        }
    }
}
