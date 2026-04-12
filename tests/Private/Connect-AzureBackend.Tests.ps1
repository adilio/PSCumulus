BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Connect-AzureBackend' {

    Context 'when Az.Accounts is not installed' {
        It 'throws when Connect-AzAccount is unavailable' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {
                    throw [System.Management.Automation.CommandNotFoundException]::new(
                        "Required command 'Connect-AzAccount' was not found."
                    )
                }

                { Connect-AzureBackend } | Should -Throw
            }
        }
    }

    Context 'when already authenticated' {
        It 'skips Connect-AzAccount when Get-AzContext returns a session' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Get-AzContext {
                    [pscustomobject]@{
                        Name         = 'existing-ctx'
                        Tenant       = [pscustomobject]@{ Id = 'tid' }
                        Subscription = [pscustomobject]@{ Name = 'sub' }
                        Account      = [pscustomobject]@{ Id = 'adil@contoso.com' }
                    }
                }
                Mock Connect-AzAccount {}

                $null = Connect-AzureBackend
                Should -Invoke Connect-AzAccount -Times 0
            }
        }
    }

    Context 'when not authenticated' {
        It 'calls Connect-AzAccount when Get-AzContext returns nothing' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Get-AzContext { $null }
                Mock Connect-AzAccount {
                    [pscustomobject]@{
                        Context = [pscustomobject]@{
                            Name         = 'new-ctx'
                            Tenant       = [pscustomobject]@{ Id = 'tid' }
                            Subscription = [pscustomobject]@{ Name = 'sub' }
                            Account      = [pscustomobject]@{ Id = 'adil@contoso.com' }
                        }
                    }
                }

                $null = Connect-AzureBackend
                Should -Invoke Connect-AzAccount -Times 1
            }
        }

        It 'passes Tenant and Subscription to Connect-AzAccount when provided' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Get-AzContext { $null }
                Mock Connect-AzAccount {
                    [pscustomobject]@{
                        Context = [pscustomobject]@{
                            Name         = 'ctx'
                            Tenant       = [pscustomobject]@{ Id = 'tenant-abc' }
                            Subscription = [pscustomobject]@{ Name = 'sub-abc' }
                            Account      = [pscustomobject]@{ Id = 'user@contoso.com' }
                        }
                    }
                }

                $null = Connect-AzureBackend -Tenant 'tenant-abc' -Subscription 'sub-abc'

                Should -Invoke Connect-AzAccount -Times 1 -ParameterFilter {
                    $Tenant -eq 'tenant-abc' -and $Subscription -eq 'sub-abc'
                }
            }
        }
    }

    Context 'successful connection' {
        It 'returns a PSCumulus.ConnectionResult object' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Get-AzContext { $null }
                Mock Connect-AzAccount {
                    [pscustomobject]@{
                        Context = [pscustomobject]@{
                            Name         = 'my-sub (tenant)'
                            Tenant       = [pscustomobject]@{ Id = 'tenant-guid-123' }
                            Subscription = [pscustomobject]@{ Name = 'my-subscription' }
                            Account      = [pscustomobject]@{ Id = 'adil@contoso.com' }
                        }
                    }
                }

                $result = Connect-AzureBackend
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.ConnectionResult'
            }
        }

        It 'sets Provider to Azure' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Get-AzContext { $null }
                Mock Connect-AzAccount {
                    [pscustomobject]@{
                        Context = [pscustomobject]@{
                            Name         = 'ctx'
                            Tenant       = [pscustomobject]@{ Id = 'tid' }
                            Subscription = [pscustomobject]@{ Name = 'sub' }
                            Account      = [pscustomobject]@{ Id = 'u@c.com' }
                        }
                    }
                }

                $result = Connect-AzureBackend
                $result.Provider | Should -Be 'Azure'
            }
        }

        It 'sets Connected to true' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Get-AzContext { $null }
                Mock Connect-AzAccount {
                    [pscustomobject]@{
                        Context = [pscustomobject]@{
                            Name         = 'ctx'
                            Tenant       = [pscustomobject]@{ Id = 'tid' }
                            Subscription = [pscustomobject]@{ Name = 'sub' }
                            Account      = [pscustomobject]@{ Id = 'u@c.com' }
                        }
                    }
                }

                $result = Connect-AzureBackend
                $result.Connected | Should -Be $true
            }
        }

        It 'includes TenantId from the context' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Get-AzContext { $null }
                Mock Connect-AzAccount {
                    [pscustomobject]@{
                        Context = [pscustomobject]@{
                            Name         = 'ctx'
                            Tenant       = [pscustomobject]@{ Id = 'tenant-abc-123' }
                            Subscription = [pscustomobject]@{ Name = 'sub' }
                            Account      = [pscustomobject]@{ Id = 'u@c.com' }
                        }
                    }
                }

                $result = Connect-AzureBackend
                $result.TenantId | Should -Be 'tenant-abc-123'
            }
        }

        It 'includes Account from the context' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Get-AzContext { $null }
                Mock Connect-AzAccount {
                    [pscustomobject]@{
                        Context = [pscustomobject]@{
                            Name         = 'ctx'
                            Tenant       = [pscustomobject]@{ Id = 'tid' }
                            Subscription = [pscustomobject]@{ Name = 'sub' }
                            Account      = [pscustomobject]@{ Id = 'adil@contoso.com' }
                        }
                    }
                }

                $result = Connect-AzureBackend
                $result.Account | Should -Be 'adil@contoso.com'
            }
        }
    }
}
