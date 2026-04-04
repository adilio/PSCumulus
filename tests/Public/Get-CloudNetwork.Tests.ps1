BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Get-CloudNetwork' {

    Context 'parameter validation' {
        It 'requires -Provider' {
            { Get-CloudNetwork } | Should -Throw
        }

        It 'requires -ResourceGroup for Azure' {
            { Get-CloudNetwork -Provider Azure } | Should -Throw
        }

        It 'requires -Region for AWS' {
            { Get-CloudNetwork -Provider AWS } | Should -Throw
        }

        It 'requires -Project for GCP' {
            { Get-CloudNetwork -Provider GCP } | Should -Throw
        }

        It 'rejects an invalid provider name' {
            { Get-CloudNetwork -Provider Oracle -ResourceGroup 'rg' } | Should -Throw
        }
    }

    Context 'Azure routing' {
        It 'calls Get-AzureNetworkData for Azure provider' {
            InModuleScope PSCumulus {
                Mock Get-AzureNetworkData {
                    ConvertTo-CloudRecord -Name 'prod-vnet' -Provider Azure -Region 'eastus'
                }

                Get-CloudNetwork -Provider Azure -ResourceGroup 'prod-rg'

                Should -Invoke Get-AzureNetworkData -Times 1
            }
        }

        It 'passes ResourceGroup to the Azure backend' {
            InModuleScope PSCumulus {
                Mock Get-AzureNetworkData {
                    param([string]$ResourceGroup)
                    ConvertTo-CloudRecord -Name 'prod-vnet' -Provider Azure -Metadata @{ RG = $ResourceGroup }
                }

                $result = Get-CloudNetwork -Provider Azure -ResourceGroup 'my-rg'
                $result.Metadata.RG | Should -Be 'my-rg'
            }
        }

        It 'returns CloudRecord objects' {
            InModuleScope PSCumulus {
                Mock Get-AzureNetworkData {
                    ConvertTo-CloudRecord -Name 'prod-vnet' -Provider Azure -Region 'eastus' -Status 'Succeeded'
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
                    ConvertTo-CloudRecord -Name 'prod-vpc' -Provider AWS -Region 'us-east-1'
                }

                Get-CloudNetwork -Provider AWS -Region 'us-east-1'

                Should -Invoke Get-AWSNetworkData -Times 1
            }
        }

        It 'passes Region to the AWS backend' {
            InModuleScope PSCumulus {
                Mock Get-AWSNetworkData {
                    param([string]$Region)
                    ConvertTo-CloudRecord -Name 'prod-vpc' -Provider AWS -Region $Region
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
                    ConvertTo-CloudRecord -Name 'prod-network' -Provider GCP -Region 'global'
                }

                Get-CloudNetwork -Provider GCP -Project 'my-project'

                Should -Invoke Get-GCPNetworkData -Times 1
            }
        }

        It 'passes Project to the GCP backend' {
            InModuleScope PSCumulus {
                Mock Get-GCPNetworkData {
                    param([string]$Project)
                    ConvertTo-CloudRecord -Name 'prod-network' -Provider GCP -Metadata @{ Proj = $Project }
                }

                $result = Get-CloudNetwork -Provider GCP -Project 'prod-gcp'
                $result.Metadata.Proj | Should -Be 'prod-gcp'
            }
        }
    }
}
