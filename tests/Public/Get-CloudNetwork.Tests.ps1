BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
}

Describe 'Get-CloudNetwork' {

    Context 'parameter validation' {
        It 'makes Provider optional in every parameter set' {
            foreach ($parameterSet in 'Azure', 'AWS', 'GCP') {
                Should-HaveOptionalParameter `
                    -CommandName 'Get-CloudNetwork' `
                    -ParameterSetName $parameterSet `
                    -ParameterName 'Provider'
            }
        }

        It 'requires -ResourceGroup in the Azure parameter set' {
            Should-HaveMandatoryParameter `
                -CommandName 'Get-CloudNetwork' `
                -ParameterSetName 'Azure' `
                -ParameterName 'ResourceGroup'
        }

        It 'requires -Region in the AWS parameter set' {
            Should-HaveMandatoryParameter `
                -CommandName 'Get-CloudNetwork' `
                -ParameterSetName 'AWS' `
                -ParameterName 'Region'
        }

        It 'requires -Project in the GCP parameter set' {
            Should-HaveMandatoryParameter `
                -CommandName 'Get-CloudNetwork' `
                -ParameterSetName 'GCP' `
                -ParameterName 'Project'
        }

        It 'rejects an invalid provider name' {
            { Get-CloudNetwork -Provider Oracle -ResourceGroup 'rg' } | Should -Throw
        }
    }

    Context 'Azure routing' {
        It 'calls Get-AzureNetworkData for Azure provider' {
            InModuleScope PSCumulus {
                Mock Get-AzureNetworkData {
                    [AzureNetworkRecord]@{ Name = 'prod-vnet'; Provider = 'Azure'; Region = 'eastus' }
                }

                Get-CloudNetwork -Provider Azure -ResourceGroup 'prod-rg'

                Should -Invoke Get-AzureNetworkData -Times 1
            }
        }

        It 'passes ResourceGroup to the Azure backend' {
            InModuleScope PSCumulus {
                Mock Get-AzureNetworkData {
                    param([string]$ResourceGroup)
                    [AzureNetworkRecord]@{ Name = 'prod-vnet'; Provider = 'Azure'; Metadata = @{ RG = $ResourceGroup } }
                }

                $result = Get-CloudNetwork -Provider Azure -ResourceGroup 'my-rg'
                $result.Metadata.RG | Should -Be 'my-rg'
            }
        }

        It 'returns CloudRecord objects' {
            InModuleScope PSCumulus {
                Mock Get-AzureNetworkData {
                    [AzureNetworkRecord]@{ Name = 'prod-vnet'; Provider = 'Azure'; Region = 'eastus'; Status = 'Succeeded' }
                }

                $result = Get-CloudNetwork -Provider Azure -ResourceGroup 'rg'
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRecord'
            }
        }
    }

    Context 'AWS routing' {
        It 'calls Get-AWSNetworkData for AWS provider' {
            InModuleScope PSCumulus {
                Mock Get-AWSNetworkData {
                    [AWSNetworkRecord]@{ Name = 'prod-vpc'; Provider = 'AWS'; Region = 'us-east-1' }
                }

                Get-CloudNetwork -Provider AWS -Region 'us-east-1'

                Should -Invoke Get-AWSNetworkData -Times 1
            }
        }

        It 'passes Region to the AWS backend' {
            InModuleScope PSCumulus {
                Mock Get-AWSNetworkData {
                    param([string]$Region)
                    [AWSNetworkRecord]@{ Name = 'prod-vpc'; Provider = 'AWS'; Region = $Region }
                }

                $result = Get-CloudNetwork -Provider AWS -Region 'ap-southeast-1'
                $result.Region | Should -Be 'ap-southeast-1'
            }
        }
    }

    Context 'GCP routing' {
        It 'calls Get-GCPNetworkData for GCP provider' {
            InModuleScope PSCumulus {
                Mock Get-GCPNetworkData {
                    [GCPNetworkRecord]@{ Name = 'prod-network'; Provider = 'GCP'; Region = 'global' }
                }

                Get-CloudNetwork -Provider GCP -Project 'my-project'

                Should -Invoke Get-GCPNetworkData -Times 1
            }
        }

        It 'passes Project to the GCP backend' {
            InModuleScope PSCumulus {
                Mock Get-GCPNetworkData {
                    param([string]$Project)
                    [GCPNetworkRecord]@{ Name = 'prod-network'; Provider = 'GCP'; Metadata = @{ Proj = $Project } }
                }

                $result = Get-CloudNetwork -Provider GCP -Project 'prod-gcp'
                $result.Metadata.Proj | Should -Be 'prod-gcp'
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
                $script:PSCumulusContext.Providers['Azure'] = @{ Region = $null; Scope = 'prod-rg' }
                $script:PSCumulusContext.Providers['AWS']   = @{ Region = 'us-east-1'; Scope = $null }
                $script:PSCumulusContext.Providers['GCP']   = @{ Region = 'us-central1'; Scope = 'my-project' }

                Mock Get-AzureNetworkData { [AzureNetworkRecord]@{ Name = 'az-vnet'; Provider = 'Azure' } }
                Mock Get-AWSNetworkData   { [AWSNetworkRecord]@{ Name = 'aws-vpc'; Provider = 'AWS' } }
                Mock Get-GCPNetworkData   { [GCPNetworkRecord]@{ Name = 'gcp-network'; Provider = 'GCP' } }

                $null = Get-CloudNetwork -All

                Should -Invoke Get-AzureNetworkData -Times 1
                Should -Invoke Get-AWSNetworkData   -Times 1
                Should -Invoke Get-GCPNetworkData   -Times 1
            }
        }

        It 'returns CloudRecord objects from all connected providers' {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.Providers['Azure'] = @{ Region = $null; Scope = 'prod-rg' }
                $script:PSCumulusContext.Providers['AWS']   = @{ Region = 'us-east-1'; Scope = $null }
                $script:PSCumulusContext.Providers['GCP']   = @{ Region = 'us-central1'; Scope = 'my-project' }

                Mock Get-AzureNetworkData { [AzureNetworkRecord]@{ Name = 'az-vnet';  Provider = 'Azure' } }
                Mock Get-AWSNetworkData   { [AWSNetworkRecord]@{ Name = 'aws-vpc'; Provider = 'AWS' } }
                Mock Get-GCPNetworkData   { [GCPNetworkRecord]@{ Name = 'gcp-network'; Provider = 'GCP' } }

                $results = @(Get-CloudNetwork -All)
                $results.Count | Should -Be 3
            }
        }
    }
}
