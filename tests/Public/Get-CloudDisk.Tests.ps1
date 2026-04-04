BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Get-CloudDisk' {

    Context 'parameter validation' {
        It 'requires -Provider' {
            { Get-CloudDisk } | Should -Throw
        }

        It 'requires -ResourceGroup for Azure' {
            { Get-CloudDisk -Provider Azure } | Should -Throw
        }

        It 'requires -Region for AWS' {
            { Get-CloudDisk -Provider AWS } | Should -Throw
        }

        It 'requires -Project for GCP' {
            { Get-CloudDisk -Provider GCP } | Should -Throw
        }

        It 'rejects an invalid provider name' {
            { Get-CloudDisk -Provider Oracle -ResourceGroup 'rg' } | Should -Throw
        }
    }

    Context 'Azure routing' {
        It 'calls Get-AzureDiskData for Azure provider' {
            InModuleScope PSCumulus {
                Mock Get-AzureDiskData {
                    ConvertTo-CloudRecord -Name 'os-disk-01' -Provider Azure -Region 'eastus'
                }

                Get-CloudDisk -Provider Azure -ResourceGroup 'prod-rg'

                Should -Invoke Get-AzureDiskData -Times 1
            }
        }

        It 'passes ResourceGroup to the Azure backend' {
            InModuleScope PSCumulus {
                Mock Get-AzureDiskData {
                    param([string]$ResourceGroup)
                    ConvertTo-CloudRecord -Name 'os-disk-01' -Provider Azure -Metadata @{ RG = $ResourceGroup }
                }

                $result = Get-CloudDisk -Provider Azure -ResourceGroup 'my-rg'
                $result.Metadata.RG | Should -Be 'my-rg'
            }
        }

        It 'returns CloudRecord objects' {
            InModuleScope PSCumulus {
                Mock Get-AzureDiskData {
                    ConvertTo-CloudRecord -Name 'os-disk-01' -Provider Azure -Region 'eastus' -Size '128 GB'
                }

                $result = Get-CloudDisk -Provider Azure -ResourceGroup 'rg'
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRecord'
            }
        }
    }

    Context 'AWS routing' {
        It 'calls Get-AWSDiskData for AWS provider' {
            InModuleScope PSCumulus {
                Mock Get-AWSDiskData {
                    ConvertTo-CloudRecord -Name 'data-volume' -Provider AWS -Region 'us-east-1a'
                }

                Get-CloudDisk -Provider AWS -Region 'us-east-1'

                Should -Invoke Get-AWSDiskData -Times 1
            }
        }

        It 'passes Region to the AWS backend' {
            InModuleScope PSCumulus {
                Mock Get-AWSDiskData {
                    param([string]$Region)
                    ConvertTo-CloudRecord -Name 'data-volume' -Provider AWS -Region $Region
                }

                $result = Get-CloudDisk -Provider AWS -Region 'eu-west-1'
                $result.Region | Should -Be 'eu-west-1'
            }
        }
    }

    Context 'GCP routing' {
        It 'calls Get-GCPDiskData for GCP provider' {
            InModuleScope PSCumulus {
                Mock Get-GCPDiskData {
                    ConvertTo-CloudRecord -Name 'data-disk-01' -Provider GCP -Region 'us-central1-a'
                }

                Get-CloudDisk -Provider GCP -Project 'my-project'

                Should -Invoke Get-GCPDiskData -Times 1
            }
        }

        It 'passes Project to the GCP backend' {
            InModuleScope PSCumulus {
                Mock Get-GCPDiskData {
                    param([string]$Project)
                    ConvertTo-CloudRecord -Name 'data-disk-01' -Provider GCP -Metadata @{ Proj = $Project }
                }

                $result = Get-CloudDisk -Provider GCP -Project 'prod-gcp'
                $result.Metadata.Proj | Should -Be 'prod-gcp'
            }
        }
    }
}
