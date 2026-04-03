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

    Context 'successful connection' {
        It 'returns a PSCumulus.ConnectionResult object' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Connect-AzAccount {
                    [pscustomobject]@{
                        Context = [pscustomobject]@{
                            Name         = 'my-sub (tenant)'
                            Tenant       = [pscustomobject]@{ Id = 'tenant-guid-123' }
                            Subscription = [pscustomobject]@{ Name = 'my-subscription' }
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
                Mock Connect-AzAccount {
                    [pscustomobject]@{
                        Context = [pscustomobject]@{
                            Name         = 'ctx'
                            Tenant       = [pscustomobject]@{ Id = 'tid' }
                            Subscription = [pscustomobject]@{ Name = 'sub' }
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
                Mock Connect-AzAccount {
                    [pscustomobject]@{
                        Context = [pscustomobject]@{
                            Name         = 'ctx'
                            Tenant       = [pscustomobject]@{ Id = 'tid' }
                            Subscription = [pscustomobject]@{ Name = 'sub' }
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
                Mock Connect-AzAccount {
                    [pscustomobject]@{
                        Context = [pscustomobject]@{
                            Name         = 'ctx'
                            Tenant       = [pscustomobject]@{ Id = 'tenant-abc-123' }
                            Subscription = [pscustomobject]@{ Name = 'sub' }
                        }
                    }
                }

                $result = Connect-AzureBackend
                $result.TenantId | Should -Be 'tenant-abc-123'
            }
        }
    }
}
