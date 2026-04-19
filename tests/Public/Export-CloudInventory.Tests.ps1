Describe 'Export-CloudInventory' {
    BeforeAll {
        $ModulePath = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent | Join-Path -ChildPath 'PSCumulus.psd1'
        Import-Module $ModulePath -Force
        $testPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "test-inventory-$([Guid]::NewGuid()).json")
    }

    AfterAll {
        if (Test-Path $testPath) {
            Remove-Item $testPath -Force
        }
    }

    Context 'Parameter validation' {
        It 'Should have -Path parameter as mandatory' {
            { Export-CloudInventory -Path $testPath -WhatIf } | Should -Not -Throw
        }

        It 'Should accept -Format Json' {
            { Export-CloudInventory -Path $testPath -Format Json -WhatIf } | Should -Not -Throw
        }

        It 'Should accept -Format Csv' {
            { Export-CloudInventory -Path $testPath -Format Csv -WhatIf } | Should -Not -Throw
        }
    }

    Context 'Output shape' {
        It 'Should return FileInfo object' {
            InModuleScope PSCumulus {
                Mock Get-CloudInstance -MockWith { @() }
                $script:PSCumulusContext.Providers['Azure'] = @{
                    Account       = 'test@example.com'
                    ResourceGroup = 'test-rg'
                    Connected     = $true
                }

                $result = Export-CloudInventory -Path $testPath
                $result | Should -BeOfType [System.IO.FileInfo]
            }
        }

        It 'Should create file in JSON format by default' {
            InModuleScope PSCumulus {
                Mock Get-CloudInstance -MockWith { @() }
                $script:PSCumulusContext.Providers['Azure'] = @{
                    Account       = 'test@example.com'
                    ResourceGroup = 'test-rg'
                    Connected     = $true
                }

                Export-CloudInventory -Path $testPath
                Test-Path $testPath | Should -BeTrue
            }
        }
    }

    Context 'Provider dispatch' {
        It 'Should query all connected providers' {
            InModuleScope PSCumulus {
                Mock Get-CloudInstance -MockWith { @() }
                $script:PSCumulusContext.Providers['Azure'] = @{
                    Account       = 'test@example.com'
                    ResourceGroup = 'test-rg'
                    Connected     = $true
                }

                { Export-CloudInventory -Path $testPath } | Should -Not -Throw
            }
        }
    }
}
