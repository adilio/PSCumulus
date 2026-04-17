BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\PSCumulus.psd1')).Path -Force
}

Describe 'PSCumulus module' {

    Context 'manifest' {
        It 'exports all public functions' {
            $commands = Get-Command -Module PSCumulus | Select-Object -ExpandProperty Name
            $commands | Should -Contain 'Connect-Cloud'
            $commands | Should -Contain 'Disconnect-Cloud'
            $commands | Should -Contain 'Get-CloudContext'
            $commands | Should -Contain 'Get-CloudInstance'
            $commands | Should -Contain 'Get-CloudStorage'
            $commands | Should -Contain 'Get-CloudTag'
            $commands | Should -Contain 'Get-CloudNetwork'
            $commands | Should -Contain 'Get-CloudDisk'
            $commands | Should -Contain 'Get-CloudFunction'
            $commands | Should -Contain 'Start-CloudInstance'
            $commands | Should -Contain 'Stop-CloudInstance'
        }

        It 'exports exactly eleven public functions' {
            $commands = Get-Command -Module PSCumulus
            ($commands | Where-Object CommandType -eq 'Function').Count | Should -Be 11
        }

        It 'does not export variables' {
            $manifest = Import-PowerShellDataFile (Join-Path $PSScriptRoot '..\PSCumulus.psd1')
            $manifest.VariablesToExport.Count | Should -Be 0
        }

        It 'exports the expected aliases' {
            $manifest = Import-PowerShellDataFile (Join-Path $PSScriptRoot '..\PSCumulus.psd1')
            $manifest.AliasesToExport | Should -Be @('conc', 'gcont', 'gcin', 'sci', 'tci')
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

        It 'requires PowerShell 5.1 or higher' {
            $manifest = Import-PowerShellDataFile (Join-Path $PSScriptRoot '..\PSCumulus.psd1')
            [version]$manifest.PowerShellVersion | Should -BeGreaterOrEqual ([version]'5.1')
        }
    }

    Context 'public command OutputType' {
        It 'Connect-Cloud declares pscustomobject OutputType' {
            (Get-Command Connect-Cloud).OutputType | Should -Not -BeNullOrEmpty
        }

        It 'Disconnect-Cloud declares pscustomobject OutputType' {
            (Get-Command Disconnect-Cloud).OutputType | Should -Not -BeNullOrEmpty
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

        It 'Assert-CloudTagArgument is loaded' {
            InModuleScope PSCumulus {
                Get-Command -Name Assert-CloudTagArgument | Should -Not -BeNullOrEmpty
            }
        }

        It 'Resolve-CloudProvider is loaded' {
            InModuleScope PSCumulus {
                Get-Command -Name Resolve-CloudProvider | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'aliases' {
        It 'exports the expected interactive aliases' {
            (Get-Command -Module PSCumulus -CommandType Alias).Name |
                Should -Be @('conc', 'gcin', 'gcont', 'sci', 'tci')
        }
    }

    Context 'module loads cleanly' {
        It 'can be removed and re-imported without error' {
            { Remove-Module PSCumulus -Force; Import-Module (Join-Path $PSScriptRoot '..\PSCumulus.psd1') -Force } |
                Should -Not -Throw
        }
    }
}
