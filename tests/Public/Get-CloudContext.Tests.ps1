BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Get-CloudContext' {

    Context 'when no providers are connected' {
        It 'returns nothing' {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.ActiveProvider   = $null
                $script:PSCumulusContext.Providers.Azure = $null
                $script:PSCumulusContext.Providers.AWS   = $null
                $script:PSCumulusContext.Providers.GCP   = $null

                $result = Get-CloudContext
                $result | Should -BeNullOrEmpty
            }
        }
    }

    Context 'when one provider is connected' {
        It 'returns one context entry' {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.ActiveProvider   = 'GCP'
                $script:PSCumulusContext.Providers.Azure = $null
                $script:PSCumulusContext.Providers.AWS   = $null
                $script:PSCumulusContext.Providers.GCP   = @{
                    Account     = 'adil@example.com'
                    Scope       = 'my-project'
                    Region      = $null
                    ConnectedAt = (Get-Date)
                }

                $result = @(Get-CloudContext)
                $result.Count | Should -Be 1
                $result[0].Provider | Should -Be 'GCP'
            }
        }

        It 'marks the connected provider as Current' {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.ActiveProvider   = 'GCP'
                $script:PSCumulusContext.Providers.Azure = $null
                $script:PSCumulusContext.Providers.AWS   = $null
                $script:PSCumulusContext.Providers.GCP   = @{
                    Account = 'adil@example.com'; Scope = 'my-project'; Region = $null; ConnectedAt = (Get-Date)
                }

                $result = Get-CloudContext
                $result.ConnectionState | Should -Be 'Current'
                $result.IsActive | Should -BeTrue
            }
        }

        It 'returns a PSCumulus.CloudContext object' {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.ActiveProvider   = 'Azure'
                $script:PSCumulusContext.Providers.Azure = @{
                    Account = 'adil@contoso.com'; Scope = 'my-sub'; Region = $null; ConnectedAt = (Get-Date)
                }
                $script:PSCumulusContext.Providers.AWS = $null
                $script:PSCumulusContext.Providers.GCP = $null

                $result = Get-CloudContext
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudContext'
            }
        }

        It 'exposes Account and Scope from the stored context' {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.ActiveProvider   = 'Azure'
                $script:PSCumulusContext.Providers.Azure = @{
                    Account = 'adil@contoso.com'; Scope = 'my-sub'; Region = $null; ConnectedAt = (Get-Date)
                }
                $script:PSCumulusContext.Providers.AWS = $null
                $script:PSCumulusContext.Providers.GCP = $null

                $result = Get-CloudContext
                $result.Account | Should -Be 'adil@contoso.com'
                $result.Scope   | Should -Be 'my-sub'
            }
        }
    }

    Context 'when multiple providers are connected' {
        It 'returns an entry for each connected provider' {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.ActiveProvider   = 'AWS'
                $script:PSCumulusContext.Providers.Azure = @{
                    Account = 'adil@contoso.com'; Scope = 'my-sub'; Region = $null; ConnectedAt = (Get-Date)
                }
                $script:PSCumulusContext.Providers.AWS   = @{
                    Account = 'default'; Scope = 'default'; Region = 'us-east-1'; ConnectedAt = (Get-Date)
                }
                $script:PSCumulusContext.Providers.GCP   = $null

                $result = @(Get-CloudContext)
                $result.Count | Should -Be 2
            }
        }

        It 'marks only the active provider as Current' {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.ActiveProvider   = 'AWS'
                $script:PSCumulusContext.Providers.Azure = @{
                    Account = 'adil@contoso.com'; Scope = 'my-sub'; Region = $null; ConnectedAt = (Get-Date)
                }
                $script:PSCumulusContext.Providers.AWS   = @{
                    Account = 'default'; Scope = 'default'; Region = 'us-east-1'; ConnectedAt = (Get-Date)
                }
                $script:PSCumulusContext.Providers.GCP   = $null

                $result = @(Get-CloudContext)
                $active = $result | Where-Object { $_.ConnectionState -eq 'Current' }
                @($active).Count | Should -Be 1
                $active.Provider | Should -Be 'AWS'
                ($result | Where-Object Provider -eq 'Azure').ConnectionState | Should -Be 'Connected'
                ($result | Where-Object Provider -eq 'Azure').IsActive | Should -BeNullOrEmpty
            }
        }

        It 'omits providers that have not been connected' {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.ActiveProvider   = 'GCP'
                $script:PSCumulusContext.Providers.Azure = $null
                $script:PSCumulusContext.Providers.AWS   = $null
                $script:PSCumulusContext.Providers.GCP   = @{
                    Account = 'adil@gcp.com'; Scope = 'proj'; Region = $null; ConnectedAt = (Get-Date)
                }

                $result = @(Get-CloudContext)
                $result.Provider | Should -Not -Contain 'Azure'
                $result.Provider | Should -Not -Contain 'AWS'
            }
        }

        It 'recomputes the active provider when the stored active provider is missing' {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.ActiveProvider   = 'AWS'
                $script:PSCumulusContext.Providers.Azure = @{
                    Account = 'adil@contoso.com'; Scope = 'my-sub'; Region = $null; ConnectedAt = (Get-Date).AddMinutes(-10)
                }
                $script:PSCumulusContext.Providers.AWS   = $null
                $script:PSCumulusContext.Providers.GCP   = @{
                    Account = 'adil@gcp.com'; Scope = 'proj'; Region = $null; ConnectedAt = (Get-Date)
                }

                $result = @(Get-CloudContext)
                $active = $result | Where-Object { $_.ConnectionState -eq 'Current' }
                @($active).Count | Should -Be 1
                $active.Provider | Should -Be 'GCP'
                (Get-CurrentCloudProvider) | Should -Be 'GCP'
            }
        }
    }
}
