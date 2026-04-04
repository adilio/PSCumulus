BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Get-CloudStorage' {

    Context 'parameter validation' {
        It 'requires -Provider' {
            { Get-CloudStorage } | Should -Throw
        }

        It 'rejects an invalid provider name' {
            { Get-CloudStorage -Provider Oracle -Region 'us-east-1' } | Should -Throw
        }
    }

    Context 'Azure routing' {
        It 'calls Get-AzureStorageData for Azure provider' {
            InModuleScope PSCumulus {
                Mock Get-AzureStorageData { }
                Get-CloudStorage -Provider Azure -ResourceGroup 'prod-rg'
                Should -Invoke Get-AzureStorageData -Times 1
            }
        }

        It 'passes ResourceGroup to the Azure backend' {
            InModuleScope PSCumulus {
                Mock Get-AzureStorageData {
                    param([string]$ResourceGroup)
                    ConvertTo-CloudRecord -Name 'storage01' -Provider Azure -Metadata @{ RG = $ResourceGroup }
                }

                $result = Get-CloudStorage -Provider Azure -ResourceGroup 'my-rg'
                $result.Metadata.RG | Should -Be 'my-rg'
            }
        }
    }

    Context 'AWS routing' {
        It 'calls Get-AWSStorageData for AWS provider' {
            InModuleScope PSCumulus {
                Mock Get-AWSStorageData { }
                Get-CloudStorage -Provider AWS -Region 'us-east-1'
                Should -Invoke Get-AWSStorageData -Times 1
            }
        }

        It 'passes Region to the AWS backend' {
            InModuleScope PSCumulus {
                Mock Get-AWSStorageData {
                    param([string]$Region)
                    ConvertTo-CloudRecord -Name 'my-bucket' -Provider AWS -Region $Region
                }

                $result = Get-CloudStorage -Provider AWS -Region 'eu-west-1'
                $result.Region | Should -Be 'eu-west-1'
            }
        }
    }

    Context 'GCP routing' {
        It 'calls Get-GCPStorageData for GCP provider' {
            InModuleScope PSCumulus {
                Mock Get-GCPStorageData { }
                Get-CloudStorage -Provider GCP -Project 'my-project'
                Should -Invoke Get-GCPStorageData -Times 1
            }
        }

        It 'passes Project to the GCP backend' {
            InModuleScope PSCumulus {
                Mock Get-GCPStorageData {
                    param([string]$Project)
                    ConvertTo-CloudRecord -Name 'my-bucket' -Provider GCP -Metadata @{ Proj = $Project }
                }

                $result = Get-CloudStorage -Provider GCP -Project 'prod-gcp'
                $result.Metadata.Proj | Should -Be 'prod-gcp'
            }
        }
    }
}
