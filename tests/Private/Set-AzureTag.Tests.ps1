# Determine if Azure tests should be skipped (must be outside Describe)
$skipAzureTests = -not (Get-Command Get-AzTag -ErrorAction SilentlyContinue)

Describe 'Set-AzureTag' {
    BeforeAll {
        $ModulePath = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent | Join-Path -ChildPath 'PSCumulus.psd1'
        Import-Module $ModulePath -Force
    }

    Context 'Parameter validation' {
        It 'Should have -ResourceId as mandatory parameter' {
            InModuleScope PSCumulus {
                $params = (Get-Command Set-AzureTag).Parameters
                $params.ContainsKey('ResourceId') | Should -BeTrue
                $params.ResourceId.Attributes.Mandatory | Should -BeTrue
            }
        }

        It 'Should have -Tags as mandatory parameter' {
            InModuleScope PSCumulus {
                $params = (Get-Command Set-AzureTag).Parameters
                $params.ContainsKey('Tags') | Should -BeTrue
                $params.Tags.Attributes.Mandatory | Should -BeTrue
            }
        }

        It 'Should have -Merge switch' {
            InModuleScope PSCumulus {
                $params = (Get-Command Set-AzureTag).Parameters
                $params.ContainsKey('Merge') | Should -BeTrue
                $params.Merge.ParameterType.Name | Should -Be 'SwitchParameter'
            }
        }
    }

    Context 'Command availability check' {
        It 'Should fail if Update-AzTag is not available' {
            InModuleScope PSCumulus {
                Mock -CommandName Assert-CommandAvailable -MockWith {
                    throw 'Update-AzTag not found'
                }

                { Set-AzureTag -ResourceId 'test-id' -Tags @{Key = 'Value' } -ErrorAction Stop } | Should -Throw
            }
        }

        It 'Should not throw when Update-AzTag is available' -Skip:$skipAzureTests {
            InModuleScope PSCumulus {
                Mock -CommandName Assert-CommandAvailable
                Mock -CommandName Get-AzTag -MockWith { $null }
                Mock -CommandName Update-AzTag -MockWith {
                    param($ResourceId, $Tag, $Operation)
                    @{Properties = @{ Tags = @{}} }
                }

                { Set-AzureTag -ResourceId 'test-id' -Tags @{Key = 'Value' } } | Should -Not -Throw
            }
        }
    }

    Context 'Tag merge behavior' {
        It 'Should merge with existing tags when -Merge is specified' -Skip:$skipAzureTests {
            InModuleScope PSCumulus {
                Mock -CommandName Assert-CommandAvailable
                Mock -CommandName Get-AzTag -MockWith {
                    @{
                        Properties = @{
                            Tags = @{
                                ExistingTag = 'ExistingValue'
                            }
                        }
                    }
                }
                Mock -CommandName Update-AzTag -MockWith {
                    param($ResourceId, $Tag, $Operation)
                    $Operation | Should -Be 'Merge'
                    $Tag.ContainsKey('ExistingTag') | Should -BeTrue
                    $Tag.ContainsKey('NewTag') | Should -BeTrue
                }

                Set-AzureTag -ResourceId 'test-id' -Tags @{NewTag = 'NewValue'} -Merge
            }
        }

        It 'Should replace all tags when -Merge is not specified' -Skip:$skipAzureTests {
            InModuleScope PSCumulus {
                Mock -CommandName Assert-CommandAvailable
                Mock -CommandName Get-AzTag -MockWith {
                    @{
                        Properties = @{
                            Tags = @{
                                ExistingTag = 'ExistingValue'
                            }
                        }
                    }
                }
                Mock -CommandName Update-AzTag -MockWith {
                    param($ResourceId, $Tag, $Operation)
                    $Operation | Should -Be 'Replace'
                    $Tag.ContainsKey('ExistingTag') | Should -BeFalse
                    $Tag.ContainsKey('NewTag') | Should -BeTrue
                }

                Set-AzureTag -ResourceId 'test-id' -Tags @{NewTag = 'NewValue'}
            }
        }
    }

    Context 'Error handling' {
        It 'Should handle missing existing tags gracefully' -Skip:$skipAzureTests {
            InModuleScope PSCumulus {
                Mock -CommandName Assert-CommandAvailable
                Mock -CommandName Get-AzTag -MockWith { $null }
                Mock -CommandName Update-AzTag -MockWith {
                    param($ResourceId, $Tag, $Operation)
                    @{Properties = @{ Tags = @{}} }
                }

                { Set-AzureTag -ResourceId 'test-id' -Tags @{Key = 'Value' } } | Should -Not -Throw
            }
        }

        It 'Should stop on Update-AzTag errors' -Skip:$skipAzureTests {
            InModuleScope PSCumulus {
                Mock -CommandName Assert-CommandAvailable
                Mock -CommandName Get-AzTag -MockWith { $null }
                Mock -CommandName Update-AzTag -MockWith {
                    param($ResourceId, $Tag, $Operation)
                    throw 'Update failed'
                }

                { Set-AzureTag -ResourceId 'test-id' -Tags @{Key = 'Value' } -ErrorAction Stop } | Should -Throw
            }
        }
    }
}
