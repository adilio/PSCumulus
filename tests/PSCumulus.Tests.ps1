BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\PSCumulus.psd1')).Path -Force
}

Describe 'PSCumulus module' {

    Context 'manifest' {
        It 'exports all public functions' {
            $commands = Get-Command -Module PSCumulus | Select-Object -ExpandProperty Name
            $commands | Should -Contain 'Connect-Cloud'
            $commands | Should -Contain 'Get-CloudInstance'
            $commands | Should -Contain 'Get-CloudStorage'
            $commands | Should -Contain 'Get-CloudTag'
            $commands | Should -Contain 'Get-CloudNetwork'
            $commands | Should -Contain 'Get-CloudDisk'
            $commands | Should -Contain 'Get-CloudFunction'
            $commands | Should -Contain 'Start-CloudInstance'
            $commands | Should -Contain 'Stop-CloudInstance'
        }

        It 'exports exactly nine public functions' {
            $commands = Get-Command -Module PSCumulus
            $commands.Count | Should -Be 9
        }

        It 'does not export variables' {
            $manifest = Import-PowerShellDataFile (Join-Path $PSScriptRoot '..\PSCumulus.psd1')
            $manifest.VariablesToExport.Count | Should -Be 0
        }

        It 'does not export aliases' {
            $manifest = Import-PowerShellDataFile (Join-Path $PSScriptRoot '..\PSCumulus.psd1')
            $manifest.AliasesToExport.Count | Should -Be 0
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

        It 'Get-CloudNetwork declares pscustomobject OutputType' {
            (Get-Command Get-CloudNetwork).OutputType | Should -Not -BeNullOrEmpty
        }

        It 'Get-CloudDisk declares pscustomobject OutputType' {
            (Get-Command Get-CloudDisk).OutputType | Should -Not -BeNullOrEmpty
        }

        It 'Start-CloudInstance declares pscustomobject OutputType' {
            (Get-Command Start-CloudInstance).OutputType | Should -Not -BeNullOrEmpty
        }

        It 'Get-CloudFunction declares pscustomobject OutputType' {
            (Get-Command Get-CloudFunction).OutputType | Should -Not -BeNullOrEmpty
        }

        It 'Stop-CloudInstance declares pscustomobject OutputType' {
            (Get-Command Stop-CloudInstance).OutputType | Should -Not -BeNullOrEmpty
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

        It 'Assert-CloudTagArgument is loaded' {
            InModuleScope PSCumulus {
                Get-Command -Name Assert-CloudTagArgument | Should -Not -BeNullOrEmpty
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
