BeforeAll {
    $script:SkipProvider = $PSVersionTable.PSVersion.Major -lt 7 -or
        -not (Get-Module SHiPS -ListAvailable)

    if (-not $script:SkipProvider) {
        Import-Module SHiPS -ErrorAction SilentlyContinue
        Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
    }
}

Describe 'New-CloudAggregationDrive' -Skip:$script:SkipProvider {
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

            { New-CloudAggregationDrive } | Should -Throw -ExpectedMessage '*SHiPS module is required*'
        }
    }

    It 'Throws when PS version is less than 7' {
        InModuleScope PSCumulus {
            Mock Get-Module { return $true } -ParameterFilter { $Name -eq 'SHiPS' }

            $originalVersion = $PSVersionTable.PSVersion
            $PSVersionTable.PSVersion = [version]'5.1.0'

            try {
                { New-CloudAggregationDrive } | Should -Throw -ExpectedMessage '*PowerShell 7 or later*'
            } finally {
                $PSVersionTable.PSVersion = $originalVersion
            }
        }
    }

    It 'Throws when no providers are connected' {
        InModuleScope PSCumulus {
            Mock Get-Module { return $true } -ParameterFilter { $Name -eq 'SHiPS' }

            { New-CloudAggregationDrive } | Should -Throw -ExpectedMessage "*No cloud providers are connected*"
        }
    }

    It 'Creates drive successfully when providers are connected' {
        InModuleScope PSCumulus {
            Mock Get-Module { return $true } -ParameterFilter { $Name -eq 'SHiPS' }
            $script:PSCumulusContext.Providers['Azure'] = @{ Subscription = 'test-sub' }
            $script:PSCumulusContext.Providers['AWS'] = @{ Region = 'us-east-1' }

            Mock New-PSDrive { return [pscustomobject]@{ Name = 'Cloud' } }

            $result = New-CloudAggregationDrive
            $result.Name | Should -Be 'Cloud'

            Should -Invoke New-PSDrive -Times 1 -Exactly -ParameterFilter {
                $Name -eq 'Cloud' -and
                $PSProvider -eq 'SHiPS' -and
                $Root -eq 'PSCumulus#CloudAggregationRoot'
            }
        }
    }
}
