BeforeAll {
    $script:SkipProvider = $PSVersionTable.PSVersion.Major -lt 7 -or
        -not (Get-Module SHiPS -ListAvailable)

    if (-not $script:SkipProvider) {
        Import-Module SHiPS -ErrorAction SilentlyContinue
        Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
    }
}

Describe 'CloudDriveIntegration' -Skip:$script:SkipProvider {
    It 'Connect-Cloud creates provider drive when SHiPS available' {
        InModuleScope PSCumulus {
            Mock Get-Module { return $true } -ParameterFilter { $Name -eq 'SHiPS' }
            Mock Get-PSDrive { return $null } -ParameterFilter { $Name -eq 'Azure' }
            Mock Connect-AzureBackend {
                return [pscustomobject]@{
                    Account     = 'user@example.com'
                    AccountId   = 'tenant-id'
                    Subscription = 'test-sub'
                    TenantId     = 'tenant-id'
                }
            }

            Connect-Cloud -Provider Azure -ErrorAction SilentlyContinue

            Should -Invoke New-PSDrive -Times 1 -Exactly -ParameterFilter {
                $Name -eq 'Azure' -and
                $PSProvider -eq 'SHiPS' -and
                $Root -eq 'PSCumulus#CloudProviderRoot'
            }
        }
    }

    It 'Disconnect-Cloud removes provider drive' {
        InModuleScope PSCumulus {
            Mock Get-Module { return $true } -ParameterFilter { $Name -eq 'SHiPS' }
            Mock Get-PSDrive {
                return [pscustomobject]@{
                    Name     = 'Azure'
                    Provider = [pscustomobject]@{ Name = 'SHiPS' }
                }
            }
            Mock Remove-PSDrive

            $script:PSCumulusContext.Providers['Azure'] = @{ Subscription = 'test-sub' }
            Disconnect-Cloud -Provider Azure -ErrorAction SilentlyContinue

            Should -Invoke Remove-PSDrive -Times 1 -Exactly -ParameterFilter { $Name -eq 'Azure' }
        }
    }

    It 'Aggregation drive shows only connected providers' {
        InModuleScope PSCumulus {
            Mock Get-Module { return $true } -ParameterFilter { $Name -eq 'SHiPS' }

            $script:PSCumulusContext.Providers['Azure'] = @{ Subscription = 'test-sub' }
            $script:PSCumulusContext.Providers['AWS'] = @{ Region = 'us-east-1' }
            # GCP not connected

            $root = [CloudAggregationRoot]::new('Cloud')
            $children = $root.GetChildItem()

            $children.Count | Should -Be 2

            $providerNames = $children | ForEach-Object { $_.ProviderName }
            $providerNames | Should -Contain 'Azure'
            $providerNames | Should -Contain 'AWS'
            $providerNames | Should -Not -Contain 'GCP'
        }
    }
}
