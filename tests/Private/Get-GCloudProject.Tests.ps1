BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Get-GCloudProject' {

    Context 'when Project is provided explicitly' {
        It 'returns the provided project without calling gcloud' {
            InModuleScope PSCumulus {
                Mock Invoke-GCloudJson {}

                $result = Get-GCloudProject -Project 'explicit-project'

                $result | Should -Be 'explicit-project'
                Should -Invoke Invoke-GCloudJson -Times 0
            }
        }

        It 'returns the project unchanged regardless of gcloud state' {
            InModuleScope PSCumulus {
                $result = Get-GCloudProject -Project 'my-prod-project'
                $result | Should -Be 'my-prod-project'
            }
        }
    }

    Context 'when Project is not provided' {
        It 'returns the configured project from gcloud config' {
            InModuleScope PSCumulus {
                Mock Invoke-GCloudJson {
                    [pscustomobject]@{
                        core = [pscustomobject]@{ project = 'default-project-from-config' }
                    }
                }

                $result = Get-GCloudProject

                $result | Should -Be 'default-project-from-config'
            }
        }

        It 'calls gcloud config list to get the project' {
            InModuleScope PSCumulus {
                Mock Invoke-GCloudJson {
                    [pscustomobject]@{
                        core = [pscustomobject]@{ project = 'some-project' }
                    }
                }

                $null = Get-GCloudProject

                Should -Invoke Invoke-GCloudJson -Times 1 -ParameterFilter {
                    $Arguments -contains 'config' -and $Arguments -contains 'list'
                }
            }
        }

        It 'throws when no default project is configured' {
            InModuleScope PSCumulus {
                Mock Invoke-GCloudJson {
                    [pscustomobject]@{
                        core = [pscustomobject]@{ project = $null }
                    }
                }

                { Get-GCloudProject } |
                    Should -Throw "No GCP project was supplied and no default gcloud project is configured."
            }
        }

        It 'throws when gcloud config returns empty project string' {
            InModuleScope PSCumulus {
                Mock Invoke-GCloudJson {
                    [pscustomobject]@{
                        core = [pscustomobject]@{ project = '' }
                    }
                }

                { Get-GCloudProject } | Should -Throw
            }
        }
    }
}
