BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
}

Describe 'Disconnect-Cloud' {

    Context 'parameter validation' {
        It 'makes Provider mandatory in every parameter set' {
            foreach ($parameterSet in 'Azure', 'AWS', 'GCP') {
                Should-HaveMandatoryParameter `
                    -CommandName 'Disconnect-Cloud' `
                    -ParameterSetName $parameterSet `
                    -ParameterName 'Provider'
            }
        }
    }

    Context 'Azure routing' {
        It 'clears the Azure context when Subscription matches' {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.ActiveProvider = 'Azure'
                $script:PSCumulusContext.Providers.Azure = @{
                    Account        = 'adil@contoso.com'
                    TenantId       = 'tenant-1'
                    Subscription   = 'sub-1'
                    SubscriptionId = 'sub-1'
                    Scope          = 'sub-1'
                    Region         = $null
                    ConnectedAt    = (Get-Date).AddMinutes(-5)
                }
                $script:PSCumulusContext.Providers.AWS = @{
                    Account     = '123456789012'
                    AccountId   = '123456789012'
                    Scope       = 'default'
                    Region      = 'us-east-1'
                    ConnectedAt = Get-Date
                }
                $script:PSCumulusContext.Providers.GCP = $null

                $result = Disconnect-Cloud -Provider Azure -Subscription 'sub-1'

                $script:PSCumulusContext.Providers.Azure | Should -BeNullOrEmpty
                $result.Connected | Should -Be $false
                Get-CurrentCloudProvider | Should -Be 'AWS'
            }
        }
    }

    Context 'AWS routing' {
        It 'clears the AWS context when AccountId matches' {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.ActiveProvider = 'AWS'
                $script:PSCumulusContext.Providers.Azure = @{
                    Account        = 'adil@contoso.com'
                    TenantId       = 'tenant-1'
                    Subscription   = 'sub-1'
                    SubscriptionId = 'sub-1'
                    Scope          = 'sub-1'
                    ConnectedAt    = (Get-Date).AddMinutes(-10)
                }
                $script:PSCumulusContext.Providers.AWS = @{
                    Account     = '123456789012'
                    AccountId   = '123456789012'
                    ProfileName  = 'default'
                    Scope       = 'default'
                    Region      = 'us-east-1'
                    ConnectedAt = Get-Date
                }
                $script:PSCumulusContext.Providers.GCP = $null

                $result = Disconnect-Cloud -Provider AWS -AccountId '123456789012'

                $script:PSCumulusContext.Providers.AWS | Should -BeNullOrEmpty
                $result.Connected | Should -Be $false
                Get-CurrentCloudProvider | Should -Be 'Azure'
            }
        }
    }

    Context 'GCP routing' {
        It 'rejects mismatched project filters' {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.ActiveProvider = 'GCP'
                $script:PSCumulusContext.Providers.Azure = $null
                $script:PSCumulusContext.Providers.AWS = $null
                $script:PSCumulusContext.Providers.GCP = @{
                    Account     = 'adil@example.com'
                    Project     = 'proj-a'
                    Scope       = 'proj-a'
                    ConnectedAt = (Get-Date)
                }

                { Disconnect-Cloud -Provider GCP -Project 'proj-b' } | Should -Throw
            }
        }

        It 'supports GCP account-scoped disconnects' {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.ActiveProvider = 'GCP'
                $script:PSCumulusContext.Providers.Azure = $null
                $script:PSCumulusContext.Providers.AWS = $null
                $script:PSCumulusContext.Providers.GCP = @{
                    Account     = 'adil@example.com'
                    Project     = 'proj-a'
                    Scope       = 'proj-a'
                    ConnectedAt = (Get-Date)
                }

                $result = Disconnect-Cloud -Provider GCP -AccountEmail 'adil@example.com'
                $result.Connected | Should -Be $false
                $script:PSCumulusContext.Providers.GCP | Should -BeNullOrEmpty
            }
        }
    }
}
