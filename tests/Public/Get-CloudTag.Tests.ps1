BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Get-CloudTag' {

    Context 'parameter validation' {
        It 'makes Provider optional' {
            (Get-Command Get-CloudTag).Parameters['Provider'].Attributes.Mandatory |
                Should -Not -Contain $true
        }

        It 'rejects an invalid provider name' {
            { Get-CloudTag -Provider Oracle } | Should -Throw
        }

        It 'throws when Azure is used without ResourceId' {
            { Get-CloudTag -Provider Azure } |
                Should -Throw "Provider 'Azure' requires -ResourceId."
        }

        It 'throws when AWS is used without ResourceId' {
            { Get-CloudTag -Provider AWS } |
                Should -Throw "Provider 'AWS' requires -ResourceId."
        }

        It 'throws when GCP is used without Project' {
            { Get-CloudTag -Provider GCP -Resource 'instances/vm-01' } |
                Should -Throw "Provider 'GCP' requires both -Project and -Resource."
        }

        It 'throws when GCP is used without Resource' {
            { Get-CloudTag -Provider GCP -Project 'my-project' } |
                Should -Throw "Provider 'GCP' requires both -Project and -Resource."
        }

        It 'throws when GCP is used without either Project or Resource' {
            { Get-CloudTag -Provider GCP } |
                Should -Throw "Provider 'GCP' requires both -Project and -Resource."
        }

        It 'throws when neither Provider nor current provider is available for ResourceId lookups' {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.ActiveProvider = $null

                { Get-CloudTag -ResourceId 'i-0123456789abcdef0' } |
                    Should -Throw "*No provider was supplied for tag lookup and no current provider is set*"
            }
        }
    }

    Context 'Azure routing' {
        It 'calls Get-AzureTagData for Azure provider' {
            InModuleScope PSCumulus {
                Mock Get-AzureTagData { }
                Get-CloudTag -Provider Azure -ResourceId '/subscriptions/abc/vm/vm01'
                Should -Invoke Get-AzureTagData -Times 1
            }
        }
    }

    Context 'AWS routing' {
        It 'calls Get-AWSTagData for AWS provider' {
            InModuleScope PSCumulus {
                Mock Get-AWSTagData { }
                Get-CloudTag -Provider AWS -ResourceId 'i-0123456789abcdef0'
                Should -Invoke Get-AWSTagData -Times 1
            }
        }
    }

    Context 'GCP routing' {
        It 'calls Get-GCPTagData for GCP provider' {
            InModuleScope PSCumulus {
                Mock Get-GCPTagData { }
                Get-CloudTag -Provider GCP -Project 'my-project' -Resource 'instances/vm-01'
                Should -Invoke Get-GCPTagData -Times 1
            }
        }
    }

    Context 'argument forwarding' {
        It 'passes ResourceId to the Azure backend' {
            InModuleScope PSCumulus {
                Mock Get-AzureTagData {
                    param([string]$ResourceId)
                    [pscustomobject]@{ ResourceId = $ResourceId }
                }

                $result = Get-CloudTag -Provider Azure -ResourceId '/subscriptions/sub/vm/my-vm'
                $result.ResourceId | Should -Be '/subscriptions/sub/vm/my-vm'
            }
        }

        It 'passes ResourceId to the AWS backend' {
            InModuleScope PSCumulus {
                Mock Get-AWSTagData {
                    param([string]$ResourceId)
                    [pscustomobject]@{ ResourceId = $ResourceId }
                }

                $result = Get-CloudTag -Provider AWS -ResourceId 'i-abc123'
                $result.ResourceId | Should -Be 'i-abc123'
            }
        }

        It 'passes Project and Resource to the GCP backend' {
            InModuleScope PSCumulus {
                Mock Get-GCPTagData {
                    param([string]$Project, [string]$Resource)
                    [pscustomobject]@{ Project = $Project; Resource = $Resource }
                }

                $result = Get-CloudTag -Provider GCP -Project 'proj-x' -Resource 'instances/vm-a'
                $result.Project | Should -Be 'proj-x'
                $result.Resource | Should -Be 'instances/vm-a'
            }
        }

        It 'uses the current provider when Provider is omitted for ResourceId lookups' {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.ActiveProvider = 'AWS'
                $script:PSCumulusContext.Providers.AWS = @{
                    Account     = '123456789012'
                    AccountId   = '123456789012'
                    Scope       = 'default'
                    Region      = 'us-east-1'
                    ConnectedAt = (Get-Date)
                }

                Mock Get-AWSTagData {
                    param([string]$ResourceId)
                    [pscustomobject]@{ ResourceId = $ResourceId }
                }

                $result = Get-CloudTag -ResourceId 'i-abc123'
                $result.ResourceId | Should -Be 'i-abc123'
            }
        }

        It 'infers GCP when Project and Resource are supplied without Provider' {
            InModuleScope PSCumulus {
                Mock Get-GCPTagData {
                    param([string]$Project, [string]$Resource)
                    [pscustomobject]@{ Project = $Project; Resource = $Resource }
                }

                $result = Get-CloudTag -Project 'proj-x' -Resource 'instances/vm-a'
                $result.Project | Should -Be 'proj-x'
                $result.Resource | Should -Be 'instances/vm-a'
            }
        }
    }

    Context '-All parameter' {
        BeforeEach {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.Providers = @{ Azure = $null; AWS = $null; GCP = $null }
            }
        }

        It 'calls all backend functions when providers are connected' {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.Providers['Azure'] = @{ SubscriptionId = '12345678-1234-1234-1234-123456789012'; Region = $null; Scope = 'prod-rg' }
                $script:PSCumulusContext.Providers['AWS']   = @{ Region = 'us-east-1'; Scope = $null }
                $script:PSCumulusContext.Providers['GCP']   = @{ Region = 'us-central1'; Scope = 'my-project' }

                Mock Get-AzureTagData { [AzureTagRecord]@{ Name = 'az-tags'; Provider = 'Azure' } }
                Mock Get-AWSTagData   { [AWSTagRecord]@{ Name = 'aws-tags'; Provider = 'AWS' } }
                Mock Get-GCPTagData   { [GCPTagRecord]@{ Name = 'gcp-tags'; Provider = 'GCP' } }

                $null = Get-CloudTag -All

                Should -Invoke Get-AzureTagData -Times 1
                Should -Invoke Get-AWSTagData   -Times 1
                Should -Invoke Get-GCPTagData   -Times 1
            }
        }

        It 'returns CloudRecord objects from all connected providers' {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.Providers['Azure'] = @{ SubscriptionId = '12345678-1234-1234-1234-123456789012'; Region = $null; Scope = 'prod-rg' }
                $script:PSCumulusContext.Providers['AWS']   = @{ Region = 'us-east-1'; Scope = $null }
                $script:PSCumulusContext.Providers['GCP']   = @{ Region = 'us-central1'; Scope = 'my-project' }

                Mock Get-AzureTagData { [AzureTagRecord]@{ Name = 'az-tags';  Provider = 'Azure' } }
                Mock Get-AWSTagData   { [AWSTagRecord]@{ Name = 'aws-tags'; Provider = 'AWS' } }
                Mock Get-GCPTagData   { [GCPTagRecord]@{ Name = 'gcp-tags'; Provider = 'GCP' } }

                $results = @(Get-CloudTag -All)
                $results.Count | Should -Be 3
            }
        }
    }
}
