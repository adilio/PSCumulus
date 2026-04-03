BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Assert-GCloudAuthenticated' {

    Context 'when an active account exists' {
        It 'returns the active account object' {
            InModuleScope PSCumulus {
                $fakeAccounts = @(
                    [pscustomobject]@{ account = 'user@example.com'; status = 'ACTIVE' }
                    [pscustomobject]@{ account = 'other@example.com'; status = 'INACTIVE' }
                )
                Mock Invoke-GCloudJson { $fakeAccounts }

                $result = Assert-GCloudAuthenticated
                $result.account | Should -Be 'user@example.com'
                $result.status | Should -Be 'ACTIVE'
            }
        }

        It 'returns the first active account when multiple are active' {
            InModuleScope PSCumulus {
                $fakeAccounts = @(
                    [pscustomobject]@{ account = 'first@example.com'; status = 'ACTIVE' }
                    [pscustomobject]@{ account = 'second@example.com'; status = 'ACTIVE' }
                )
                Mock Invoke-GCloudJson { $fakeAccounts }

                $result = Assert-GCloudAuthenticated
                $result.account | Should -Be 'first@example.com'
            }
        }
    }

    Context 'when no active account exists' {
        It 'throws when account list is empty' {
            InModuleScope PSCumulus {
                Mock Invoke-GCloudJson { @() }

                { Assert-GCloudAuthenticated } |
                    Should -Throw "*No active gcloud account found*"
            }
        }

        It 'throws when all accounts are inactive' {
            InModuleScope PSCumulus {
                $inactiveAccounts = @(
                    [pscustomobject]@{ account = 'user@example.com'; status = 'INACTIVE' }
                )
                Mock Invoke-GCloudJson { $inactiveAccounts }

                { Assert-GCloudAuthenticated } |
                    Should -Throw "*No active gcloud account found*"
            }
        }

        It 'throws when gcloud returns null' {
            InModuleScope PSCumulus {
                Mock Invoke-GCloudJson { $null }

                { Assert-GCloudAuthenticated } |
                    Should -Throw
            }
        }
    }

    Context 'gcloud invocation' {
        It 'calls Invoke-GCloudJson with auth list arguments' {
            InModuleScope PSCumulus {
                Mock Invoke-GCloudJson {
                    @([pscustomobject]@{ account = 'u@e.com'; status = 'ACTIVE' })
                }

                $null = Assert-GCloudAuthenticated

                Should -Invoke Invoke-GCloudJson -Times 1 -ParameterFilter {
                    $Arguments -contains 'auth' -and $Arguments -contains 'list'
                }
            }
        }
    }
}
