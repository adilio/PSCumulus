BeforeAll {
    $script:SkipProvider = $PSVersionTable.PSVersion.Major -lt 7 -or
        -not (Get-Module SHiPS -ListAvailable)

    if (-not $script:SkipProvider) {
        Import-Module SHiPS -ErrorAction SilentlyContinue
        Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
    }
}

Describe 'New-CloudDrive' -Skip:$script:SkipProvider {
    BeforeEach {
        InModuleScope PSCumulus {
            $script:PSCumulusContext = @{
                ActiveProvider = $null
                Providers      = @{
                    Azure = $null
                    AWS   = $null
                    GCP   = $null
                }
            }
        }
    }

    It 'Throws when SHiPS is not available' {
        InModuleScope PSCumulus {
            Mock Get-Module { return $null } -ParameterFilter { $Name -eq 'SHiPS' }

            { New-CloudDrive -Provider Azure } | Should -Throw -ExpectedMessage '*SHiPS module is required*'
        }
    }

    It 'Throws when PS version is less than 7' {
        InModuleScope PSCumulus {
            Mock Get-Module { return $true } -ParameterFilter { $Name -eq 'SHiPS' }

            Mock Get-Variable {
                return @{
                    Value = [version]'5.1.0'
                }
            } -ParameterFilter { $Name -eq 'PSVersionTable' }

            $originalVersion = $PSVersionTable.PSVersion
            $PSVersionTable.PSVersion = [version]'5.1.0'

            try {
                { New-CloudDrive -Provider Azure } | Should -Throw -ExpectedMessage '*PowerShell 7 or later*'
            } finally {
                $PSVersionTable.PSVersion = $originalVersion
            }
        }
    }

    It 'Throws when no active session context for provider' {
        InModuleScope PSCumulus {
            Mock Get-Module { return $true } -ParameterFilter { $Name -eq 'SHiPS' }

            { New-CloudDrive -Provider Azure } | Should -Throw -ExpectedMessage "*No active session for provider 'Azure'*"
        }
    }

    It 'Creates drive successfully when context exists' {
        InModuleScope PSCumulus {
            Mock Get-Module { return $true } -ParameterFilter { $Name -eq 'SHiPS' }
            $script:PSCumulusContext.Providers['Azure'] = @{ Subscription = 'test-sub' }

            Mock New-PSDrive { return [pscustomobject]@{ Name = 'Azure' } }

            $result = New-CloudDrive -Provider Azure
            $result.Name | Should -Be 'Azure'

            Should -Invoke New-PSDrive -Times 1 -Exactly -ParameterFilter {
                $Name -eq 'Azure' -and
                $PSProvider -eq 'SHiPS' -and
                $Root -eq 'PSCumulus#CloudProviderRoot'
            }
        }
    }
}
