# Determine if AWS tests should be skipped
$skipAWSTests = -not (Get-Command Get-EC2Tag -ErrorAction SilentlyContinue)

Describe 'Set-AWSTag' {
    BeforeAll {
        $ModulePath = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent | Join-Path -ChildPath 'PSCumulus.psd1'
        Import-Module $ModulePath -Force
    }

    Context 'Parameter validation' {
        It 'Should have -ResourceId as mandatory parameter' {
            InModuleScope PSCumulus {
                $params = (Get-Command Set-AWSTag).Parameters
                $params.ContainsKey('ResourceId') | Should -BeTrue
                $params.ResourceId.Attributes.Mandatory | Should -BeTrue
            }
        }

        It 'Should have -Tags as mandatory parameter' {
            InModuleScope PSCumulus {
                $params = (Get-Command Set-AWSTag).Parameters
                $params.ContainsKey('Tags') | Should -BeTrue
                $params.Tags.Attributes.Mandatory | Should -BeTrue
            }
        }

        It 'Should have optional -Region parameter' {
            InModuleScope PSCumulus {
                $params = (Get-Command Set-AWSTag).Parameters
                $params.ContainsKey('Region') | Should -BeTrue
                $params.Region.Attributes.Mandatory | Should -BeFalse
            }
        }

        It 'Should have -Merge switch' {
            InModuleScope PSCumulus {
                $params = (Get-Command Set-AWSTag).Parameters
                $params.ContainsKey('Merge') | Should -BeTrue
                $params.Merge.ParameterType.Name | Should -Be 'SwitchParameter'
            }
        }
    }

    Context 'Command availability check' {
        It 'Should fail if Add-EC2Tag is not available' {
            InModuleScope PSCumulus {
                Mock -CommandName Assert-CommandAvailable -MockWith {
                    throw 'Add-EC2Tag not found'
                }

                { Set-AWSTag -ResourceId 'i-12345' -Tags @{Key = 'Value' } -ErrorAction Stop } | Should -Throw
            }
        }

        It 'Should not throw when Add-EC2Tag is available' -Skip:$skipAWSTests {
            InModuleScope PSCumulus {
                Mock -CommandName Assert-CommandAvailable
                Mock -CommandName Get-EC2Tag -MockWith { @() }
                Mock -CommandName New-EC2Tag -MockWith { @() }

                { Set-AWSTag -ResourceId 'i-12345' -Tags @{Key = 'Value' } } | Should -Not -Throw
            }
        }
    }

    Context 'Tag merge behavior' {
        It 'Should merge with existing tags when -Merge is specified' -Skip:$skipAWSTests {
            InModuleScope PSCumulus {
                Mock -CommandName Assert-CommandAvailable
                Mock -CommandName Get-EC2Tag -MockWith {
                    @(
                        @{ Key = 'ExistingTag'; Value = 'ExistingValue' }
                    )
                }
                Mock -CommandName New-EC2Tag -MockWith {
                    param($Resource, $Tag)
                    # Verify both tags are passed to New-EC2Tag
                    $Tag.Count | Should -Be 2
                }

                Set-AWSTag -ResourceId 'i-12345' -Tags @{NewTag = 'NewValue'} -Merge
            }
        }

        It 'Should replace all tags when -Merge is not specified' -Skip:$skipAWSTests {
            InModuleScope PSCumulus {
                Mock -CommandName Assert-CommandAvailable
                Mock -CommandName Get-EC2Tag -MockWith {
                    @(
                        @{ Key = 'ExistingTag'; Value = 'ExistingValue' }
                    )
                }
                Mock -CommandName New-EC2Tag -MockWith {
                    param($Resource, $Tag)
                    $combinedTags = $Tag | ForEach-Object { @{$_."Key" = $_."Value"} }
                    $combinedTags.ContainsKey('ExistingTag') | Should -BeFalse
                    $combinedTags.ContainsKey('NewTag') | Should -BeTrue
                }

                Set-AWSTag -ResourceId 'i-12345' -Tags @{NewTag = 'NewValue'}
            }
        }
    }

    Context 'Tag object conversion' {
        It 'Should convert hashtable to PSCustomObject array' -Skip:$skipAWSTests {
            InModuleScope PSCumulus {
                Mock -CommandName Assert-CommandAvailable
                Mock -CommandName Get-EC2Tag -MockWith { @() }
                Mock -CommandName New-EC2Tag -MockWith {
                    param($Resource, $Tag)
                    $Tag[0].Key | Should -Be 'TestKey'
                    $Tag[0].Value | Should -Be 'TestValue'
                }

                Set-AWSTag -ResourceId 'i-12345' -Tags @{TestKey = 'TestValue'}
            }
        }
    }

    Context 'Error handling' {
        It 'Should handle missing existing tags gracefully' -Skip:$skipAWSTests {
            InModuleScope PSCumulus {
                Mock -CommandName Assert-CommandAvailable
                Mock -CommandName Get-EC2Tag -MockWith { $null }
                Mock -CommandName New-EC2Tag -MockWith { @() }

                { Set-AWSTag -ResourceId 'i-12345' -Tags @{Key = 'Value' } } | Should -Not -Throw
            }
        }

        It 'Should stop on New-EC2Tag errors' -Skip:$skipAWSTests {
            InModuleScope PSCumulus {
                Mock -CommandName Assert-CommandAvailable
                Mock -CommandName Get-EC2Tag -MockWith { @() }
                Mock -CommandName New-EC2Tag -MockWith { throw 'Tag creation failed' }

                { Set-AWSTag -ResourceId 'i-12345' -Tags @{Key = 'Value' } -ErrorAction Stop } | Should -Throw
            }
        }
    }

    Context 'Regional execution' {
        It 'Should pass Region parameter to Get-EC2Tag' -Skip:$skipAWSTests {
            InModuleScope PSCumulus {
                Mock -CommandName Assert-CommandAvailable
                Mock -CommandName Get-EC2Tag -MockWith {
                    param($ResourceId, $Region)
                    $Region | Should -Be 'us-west-2'
                    @()
                }
                Mock -CommandName New-EC2Tag -MockWith { @() }

                Set-AWSTag -ResourceId 'i-12345' -Tags @{Key = 'Value'} -Region 'us-west-2'
            }
        }
    }
}
