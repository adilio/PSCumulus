BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
}

Describe 'Connect-Cloud' {

    Context 'parameter validation' {
        It 'marks Provider as mandatory in every parameter set' {
            foreach ($parameterSet in 'Azure', 'AWS', 'GCP') {
                Should-HaveMandatoryParameter `
                    -CommandName 'Connect-Cloud' `
                    -ParameterSetName $parameterSet `
                    -ParameterName 'Provider'
            }
        }

        It 'rejects an invalid provider name' {
            { Connect-Cloud -Provider Oracle } | Should -Throw
        }

        It 'requires -Region in the AWS parameter set' {
            Should-HaveMandatoryParameter `
                -CommandName 'Connect-Cloud' `
                -ParameterSetName 'AWS' `
                -ParameterName 'Region'
        }

        It 'requires -Project in the GCP parameter set' {
            Should-HaveMandatoryParameter `
                -CommandName 'Connect-Cloud' `
                -ParameterSetName 'GCP' `
                -ParameterName 'Project'
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

        It 'passes Tenant and Subscription to the Azure backend' {
            InModuleScope PSCumulus {
                Mock Connect-AzureBackend {
                    param([string]$Tenant, [string]$Subscription)
                    [pscustomobject]@{
                        PSTypeName   = 'PSCumulus.ConnectionResult'
                        Provider     = 'Azure'
                        Connected    = $true
                        Tenant       = $Tenant
                        Subscription = $Subscription
                    }
                }

                $result = Connect-Cloud -Provider Azure -Tenant 'tenant-abc' -Subscription 'sub-abc'

                $result.Tenant | Should -Be 'tenant-abc'
                $result.Subscription | Should -Be 'sub-abc'
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

        It 'stores Azure as the current provider' {
            InModuleScope PSCumulus {
                Mock Connect-AzureBackend {
                    [pscustomobject]@{ PSTypeName = 'PSCumulus.ConnectionResult'; Provider = 'Azure'; Connected = $true }
                }

                $null = Connect-Cloud -Provider Azure

                Get-CurrentCloudProvider | Should -Be 'Azure'
            }
        }

        It 'stores per-provider context after Azure connection' {
            InModuleScope PSCumulus {
                Mock Connect-AzureBackend {
                    [pscustomobject]@{
                        PSTypeName   = 'PSCumulus.ConnectionResult'
                        Provider     = 'Azure'
                        Connected    = $true
                        Account      = 'adil@contoso.com'
                        Subscription = 'my-sub'
                        Region       = $null
                    }
                }

                $null = Connect-Cloud -Provider Azure

                $ctx = $script:PSCumulusContext.Providers['Azure']
                $ctx | Should -Not -BeNullOrEmpty
                $ctx.Account | Should -Be 'adil@contoso.com'
                $ctx.Scope | Should -Be 'my-sub'
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

        It 'stores AWS as the current provider' {
            InModuleScope PSCumulus {
                Mock Connect-AWSBackend {
                    [pscustomobject]@{ PSTypeName = 'PSCumulus.ConnectionResult'; Provider = 'AWS'; Connected = $true }
                }

                $null = Connect-Cloud -Provider AWS -Region 'us-east-1'

                Get-CurrentCloudProvider | Should -Be 'AWS'
            }
        }

        It 'stores per-provider context after AWS connection' {
            InModuleScope PSCumulus {
                Mock Connect-AWSBackend {
                    [pscustomobject]@{
                        PSTypeName  = 'PSCumulus.ConnectionResult'
                        Provider    = 'AWS'
                        Connected   = $true
                        Account     = 'default'
                        ProfileName = 'default'
                        Region      = 'us-east-1'
                    }
                }

                $null = Connect-Cloud -Provider AWS -Region 'us-east-1'

                $ctx = $script:PSCumulusContext.Providers['AWS']
                $ctx | Should -Not -BeNullOrEmpty
                $ctx.Region | Should -Be 'us-east-1'
                $ctx.Scope | Should -Be 'default'
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

        It 'stores GCP as the current provider' {
            InModuleScope PSCumulus {
                Mock Connect-GCPBackend {
                    [pscustomobject]@{ PSTypeName = 'PSCumulus.ConnectionResult'; Provider = 'GCP'; Connected = $true }
                }

                $null = Connect-Cloud -Provider GCP -Project 'my-project'

                Get-CurrentCloudProvider | Should -Be 'GCP'
            }
        }

        It 'stores per-provider context after GCP connection' {
            InModuleScope PSCumulus {
                Mock Connect-GCPBackend {
                    [pscustomobject]@{
                        PSTypeName = 'PSCumulus.ConnectionResult'
                        Provider   = 'GCP'
                        Connected  = $true
                        Account    = 'adil@example.com'
                        Project    = 'my-project'
                        Region     = $null
                    }
                }

                $null = Connect-Cloud -Provider GCP -Project 'my-project'

                $ctx = $script:PSCumulusContext.Providers['GCP']
                $ctx | Should -Not -BeNullOrEmpty
                $ctx.Account | Should -Be 'adil@example.com'
                $ctx.Scope | Should -Be 'my-project'
            }
        }
    }

    Context 'multi-provider' {
        BeforeEach {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.Providers = @{ Azure = $null; AWS = $null; GCP = $null }
            }
        }

        It 'calls each backend when given an array of providers' {
            InModuleScope PSCumulus {
                Mock Connect-AzureBackend {
                    [pscustomobject]@{ Provider = 'Azure'; Account = 'a@a.com'; Subscription = 'sub'; Region = $null }
                }
                Mock Connect-AWSBackend {
                    [pscustomobject]@{ Provider = 'AWS'; Account = '123'; ProfileName = 'default'; Region = 'us-east-1' }
                }
                Mock Connect-GCPBackend {
                    [pscustomobject]@{ Provider = 'GCP'; Account = 'g@g.com'; Project = 'proj'; Region = 'us-central1' }
                }

                $null = Connect-Cloud -Provider Azure, AWS, GCP

                Should -Invoke Connect-AzureBackend -Times 1
                Should -Invoke Connect-AWSBackend -Times 1
                Should -Invoke Connect-GCPBackend -Times 1
            }
        }

        It 'stores context for each provider after multi-connect' {
            InModuleScope PSCumulus {
                Mock Connect-AzureBackend {
                    [pscustomobject]@{ Provider = 'Azure'; Account = 'a@a.com'; Subscription = 'sub'; Region = $null }
                }
                Mock Connect-AWSBackend {
                    [pscustomobject]@{ Provider = 'AWS'; Account = '123'; ProfileName = 'default'; Region = 'us-east-1' }
                }
                Mock Connect-GCPBackend {
                    [pscustomobject]@{ Provider = 'GCP'; Account = 'g@g.com'; Project = 'proj'; Region = 'us-central1' }
                }

                $null = Connect-Cloud -Provider Azure, AWS, GCP

                $script:PSCumulusContext.Providers['Azure'] | Should -Not -BeNullOrEmpty
                $script:PSCumulusContext.Providers['AWS']   | Should -Not -BeNullOrEmpty
                $script:PSCumulusContext.Providers['GCP']   | Should -Not -BeNullOrEmpty
            }
        }

        It 'sets ActiveProvider to the last provider in the array' {
            InModuleScope PSCumulus {
                Mock Connect-AzureBackend {
                    [pscustomobject]@{ Provider = 'Azure'; Account = 'a@a.com'; Subscription = 'sub'; Region = $null }
                }
                Mock Connect-AWSBackend {
                    [pscustomobject]@{ Provider = 'AWS'; Account = '123'; ProfileName = 'default'; Region = 'us-east-1' }
                }
                Mock Connect-GCPBackend {
                    [pscustomobject]@{ Provider = 'GCP'; Account = 'g@g.com'; Project = 'proj'; Region = 'us-central1' }
                }

                $null = Connect-Cloud -Provider Azure, AWS, GCP

                Get-CurrentCloudProvider | Should -Be 'GCP'
            }
        }

        It 'returns a result for each provider' {
            InModuleScope PSCumulus {
                Mock Connect-AzureBackend {
                    [pscustomobject]@{ Provider = 'Azure'; Account = 'a@a.com'; Subscription = 'sub'; Region = $null }
                }
                Mock Connect-AWSBackend {
                    [pscustomobject]@{ Provider = 'AWS'; Account = '123'; ProfileName = 'default'; Region = 'us-east-1' }
                }
                Mock Connect-GCPBackend {
                    [pscustomobject]@{ Provider = 'GCP'; Account = 'g@g.com'; Project = 'proj'; Region = 'us-central1' }
                }

                $results = @(Connect-Cloud -Provider Azure, AWS, GCP)
                $results.Count | Should -Be 3
            }
        }
    }
}
