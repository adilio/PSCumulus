BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Connect-Cloud' {

    Context 'parameter validation' {
        It 'requires -Provider' {
            { Connect-Cloud } | Should -Throw
        }

        It 'rejects an invalid provider name' {
            { Connect-Cloud -Provider Oracle } | Should -Throw
        }

        It 'requires -Region when using AWS parameter set' {
            { Connect-Cloud -Provider AWS } | Should -Throw
        }

        It 'requires -Project when using GCP parameter set' {
            { Connect-Cloud -Provider GCP } | Should -Throw
        }
    }

    Context 'Azure routing' {
        It 'calls Connect-AzureBackend for Azure provider' {
            InModuleScope PSCumulus {
                Mock Connect-AzureBackend {
                    [pscustomobject]@{ PSTypeName = 'PSCumulus.ConnectionResult'; Provider = 'Azure'; Connected = $true }
                }

                Connect-Cloud -Provider Azure

                Should -Invoke Connect-AzureBackend -Times 1
            }
        }

        It 'returns the result from the backend' {
            InModuleScope PSCumulus {
                Mock Connect-AzureBackend {
                    [pscustomobject]@{ PSTypeName = 'PSCumulus.ConnectionResult'; Provider = 'Azure'; Connected = $true }
                }

                $result = Connect-Cloud -Provider Azure
                $result.Provider | Should -Be 'Azure'
            }
        }
    }

    Context 'AWS routing' {
        It 'calls Connect-AWSBackend for AWS provider' {
            InModuleScope PSCumulus {
                Mock Connect-AWSBackend {
                    [pscustomobject]@{ PSTypeName = 'PSCumulus.ConnectionResult'; Provider = 'AWS'; Connected = $true }
                }

                Connect-Cloud -Provider AWS -Region 'us-east-1'

                Should -Invoke Connect-AWSBackend -Times 1
            }
        }

        It 'passes Region to the AWS backend' {
            InModuleScope PSCumulus {
                Mock Connect-AWSBackend {
                    param([string]$Region)
                    [pscustomobject]@{ Provider = 'AWS'; Region = $Region }
                }

                $result = Connect-Cloud -Provider AWS -Region 'eu-west-1'
                $result.Region | Should -Be 'eu-west-1'
            }
        }
    }

    Context 'GCP routing' {
        It 'calls Connect-GCPBackend for GCP provider' {
            InModuleScope PSCumulus {
                Mock Connect-GCPBackend {
                    [pscustomobject]@{ PSTypeName = 'PSCumulus.ConnectionResult'; Provider = 'GCP'; Connected = $true }
                }

                Connect-Cloud -Provider GCP -Project 'my-project'

                Should -Invoke Connect-GCPBackend -Times 1
            }
        }

        It 'passes Project to the GCP backend' {
            InModuleScope PSCumulus {
                Mock Connect-GCPBackend {
                    param([string]$Project)
                    [pscustomobject]@{ Provider = 'GCP'; Project = $Project }
                }

                $result = Connect-Cloud -Provider GCP -Project 'prod-project'
                $result.Project | Should -Be 'prod-project'
            }
        }
    }
}
