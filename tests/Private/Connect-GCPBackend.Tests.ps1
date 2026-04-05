BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Connect-GCPBackend' {

    Context 'successful connection' {
        It 'returns a PSCumulus.ConnectionResult object' {
            InModuleScope PSCumulus {
                Mock Assert-GCloudAuthenticated { [pscustomobject]@{ account = 'u@e.com'; status = 'ACTIVE' } }
                Mock Get-GCloudProject { 'my-project' }

                $result = Connect-GCPBackend -Project 'my-project'
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.ConnectionResult'
            }
        }

        It 'sets Provider to GCP' {
            InModuleScope PSCumulus {
                Mock Assert-GCloudAuthenticated { [pscustomobject]@{ account = 'u@e.com'; status = 'ACTIVE' } }
                Mock Get-GCloudProject { 'my-project' }

                $result = Connect-GCPBackend -Project 'my-project'
                $result.Provider | Should -Be 'GCP'
            }
        }

        It 'sets Connected to true' {
            InModuleScope PSCumulus {
                Mock Assert-GCloudAuthenticated { [pscustomobject]@{ account = 'u@e.com'; status = 'ACTIVE' } }
                Mock Get-GCloudProject { 'my-project' }

                $result = Connect-GCPBackend -Project 'my-project'
                $result.Connected | Should -Be $true
            }
        }

        It 'includes the active account' {
            InModuleScope PSCumulus {
                Mock Assert-GCloudAuthenticated { [pscustomobject]@{ account = 'adil@example.com'; status = 'ACTIVE' } }
                Mock Get-GCloudProject { 'my-project' }

                $result = Connect-GCPBackend -Project 'my-project'
                $result.Account | Should -Be 'adil@example.com'
            }
        }

        It 'includes the resolved project' {
            InModuleScope PSCumulus {
                Mock Assert-GCloudAuthenticated { [pscustomobject]@{ account = 'u@e.com'; status = 'ACTIVE' } }
                Mock Get-GCloudProject { 'resolved-project-id' }

                $result = Connect-GCPBackend
                $result.Project | Should -Be 'resolved-project-id'
            }
        }
    }

    Context 'authentication failure' {
        It 'triggers login when no active gcloud account is found' {
            InModuleScope PSCumulus {
                Mock Assert-GCloudAuthenticated {
                    throw [System.InvalidOperationException]::new('No active gcloud account found.')
                }
                Mock Invoke-GCloudLogin {}

                { Connect-GCPBackend -Project 'my-project' } | Should -Throw
                Should -Invoke Invoke-GCloudLogin -Times 1
            }
        }

        It 'throws when login succeeds but authentication still fails' {
            InModuleScope PSCumulus {
                Mock Assert-GCloudAuthenticated {
                    throw [System.InvalidOperationException]::new('No active gcloud account found.')
                }
                Mock Invoke-GCloudLogin {}

                { Connect-GCPBackend -Project 'my-project' } | Should -Throw
            }
        }
    }

    Context 'project resolution' {
        It 'throws when no project is supplied or configured' {
            InModuleScope PSCumulus {
                Mock Assert-GCloudAuthenticated { [pscustomobject]@{ account = 'u@e.com'; status = 'ACTIVE' } }
                Mock Get-GCloudProject {
                    throw [System.ArgumentException]::new(
                        'No GCP project was supplied and no default gcloud project is configured.'
                    )
                }

                { Connect-GCPBackend } | Should -Throw
            }
        }
    }
}
