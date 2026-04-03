BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\PSCumulus.psd1')).Path -Force
}

Describe 'PSCumulus module' {

    Context 'manifest' {
        It 'exports the four public functions' {
            $commands = Get-Command -Module PSCumulus | Select-Object -ExpandProperty Name
            $commands | Should -Contain 'Connect-Cloud'
            $commands | Should -Contain 'Get-CloudInstance'
            $commands | Should -Contain 'Get-CloudStorage'
            $commands | Should -Contain 'Get-CloudTag'
        }

        It 'exports exactly four public functions' {
            $commands = Get-Command -Module PSCumulus
            $commands.Count | Should -Be 4
        }

        It 'does not export variables' {
            $manifest = Import-PowerShellDataFile (Join-Path $PSScriptRoot '..\PSCumulus.psd1')
            $manifest.VariablesToExport | Should -BeEmpty
        }

        It 'does not export aliases' {
            $manifest = Import-PowerShellDataFile (Join-Path $PSScriptRoot '..\PSCumulus.psd1')
            $manifest.AliasesToExport | Should -BeEmpty
        }

        It 'declares a module version' {
            $manifest = Import-PowerShellDataFile (Join-Path $PSScriptRoot '..\PSCumulus.psd1')
            $manifest.ModuleVersion | Should -Not -BeNullOrEmpty
        }

        It 'declares a GUID' {
            $manifest = Import-PowerShellDataFile (Join-Path $PSScriptRoot '..\PSCumulus.psd1')
            $manifest.GUID | Should -Not -BeNullOrEmpty
        }

        It 'declares the correct author' {
            $manifest = Import-PowerShellDataFile (Join-Path $PSScriptRoot '..\PSCumulus.psd1')
            $manifest.Author | Should -Be 'Adil Leghari'
        }

        It 'declares the correct project URI' {
            $manifest = Import-PowerShellDataFile (Join-Path $PSScriptRoot '..\PSCumulus.psd1')
            $manifest.PrivateData.PSData.ProjectUri | Should -Be 'https://github.com/adilio/PSCumulus'
        }

        It 'requires PowerShell 7.4 or higher' {
            $manifest = Import-PowerShellDataFile (Join-Path $PSScriptRoot '..\PSCumulus.psd1')
            [version]$manifest.PowerShellVersion | Should -BeGreaterOrEqual ([version]'7.4')
        }
    }

    Context 'public command OutputType' {
        It 'Connect-Cloud declares pscustomobject OutputType' {
            (Get-Command Connect-Cloud).OutputType | Should -Not -BeNullOrEmpty
        }

        It 'Get-CloudInstance declares pscustomobject OutputType' {
            (Get-Command Get-CloudInstance).OutputType | Should -Not -BeNullOrEmpty
        }

        It 'Get-CloudStorage declares pscustomobject OutputType' {
            (Get-Command Get-CloudStorage).OutputType | Should -Not -BeNullOrEmpty
        }

        It 'Get-CloudTag declares pscustomobject OutputType' {
            (Get-Command Get-CloudTag).OutputType | Should -Not -BeNullOrEmpty
        }
    }

    Context 'private helpers are accessible within the module' {
        It 'Invoke-CloudProvider is loaded' {
            InModuleScope PSCumulus {
                Get-Command -Name Invoke-CloudProvider | Should -Not -BeNullOrEmpty
            }
        }

        It 'ConvertTo-CloudRecord is loaded' {
            InModuleScope PSCumulus {
                Get-Command -Name ConvertTo-CloudRecord | Should -Not -BeNullOrEmpty
            }
        }

        It 'Assert-CloudTagArguments is loaded' {
            InModuleScope PSCumulus {
                Get-Command -Name Assert-CloudTagArguments | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'module loads cleanly' {
        It 'can be removed and re-imported without error' {
            { Remove-Module PSCumulus -Force; Import-Module (Join-Path $PSScriptRoot '..\PSCumulus.psd1') -Force } |
                Should -Not -Throw
        }
    }
}
