BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Stop-CloudInstance' {

    Context 'parameter validation' {
        It 'requires -Provider' {
            { Stop-CloudInstance } | Should -Throw
        }

        It 'requires -Name and -ResourceGroup for Azure' {
            { Stop-CloudInstance -Provider Azure -Name 'vm01' } | Should -Throw
        }

        It 'requires -InstanceId for AWS' {
            { Stop-CloudInstance -Provider AWS } | Should -Throw
        }

        It 'requires -Name, -Zone, and -Project for GCP' {
            { Stop-CloudInstance -Provider GCP -Name 'vm01' -Zone 'us-central1-a' } | Should -Throw
        }

        It 'rejects an invalid provider name' {
            { Stop-CloudInstance -Provider Oracle -Name 'vm' -ResourceGroup 'rg' } | Should -Throw
        }
    }

    Context 'Azure routing' {
        It 'calls Stop-AzureInstance for Azure provider' {
            InModuleScope PSCumulus {
                Mock Stop-AzureInstance {
                    ConvertTo-CloudRecord -Name 'vm01' -Provider Azure -Status 'Stopping'
                }

                Stop-CloudInstance -Provider Azure -Name 'vm01' -ResourceGroup 'prod-rg'

                Should -Invoke Stop-AzureInstance -Times 1
            }
        }

        It 'passes Name and ResourceGroup to the Azure backend' {
            InModuleScope PSCumulus {
                Mock Stop-AzureInstance {
                    param([string]$Name, [string]$ResourceGroup)
                    ConvertTo-CloudRecord -Name $Name -Provider Azure -Metadata @{ RG = $ResourceGroup }
                }

                $result = Stop-CloudInstance -Provider Azure -Name 'my-vm' -ResourceGroup 'my-rg'
                $result.Name | Should -Be 'my-vm'
                $result.Metadata.RG | Should -Be 'my-rg'
            }
        }
    }

    Context 'AWS routing' {
        It 'calls Stop-AWSInstance for AWS provider' {
            InModuleScope PSCumulus {
                Mock Stop-AWSInstance {
                    ConvertTo-CloudRecord -Name 'i-abc' -Provider AWS -Status 'Stopping'
                }

                Stop-CloudInstance -Provider AWS -InstanceId 'i-abc' -Region 'us-east-1'

                Should -Invoke Stop-AWSInstance -Times 1
            }
        }

        It 'passes InstanceId to the AWS backend' {
            InModuleScope PSCumulus {
                Mock Stop-AWSInstance {
                    param([string]$InstanceId)
                    ConvertTo-CloudRecord -Name $InstanceId -Provider AWS -Status 'Stopping'
                }

                $result = Stop-CloudInstance -Provider AWS -InstanceId 'i-0abc123'
                $result.Name | Should -Be 'i-0abc123'
            }
        }
    }

    Context 'GCP routing' {
        It 'calls Stop-GCPInstance for GCP provider' {
            InModuleScope PSCumulus {
                Mock Stop-GCPInstance {
                    ConvertTo-CloudRecord -Name 'gcp-vm' -Provider GCP -Status 'Stopping'
                }

                Stop-CloudInstance -Provider GCP -Name 'gcp-vm' -Zone 'us-central1-a' -Project 'my-project'

                Should -Invoke Stop-GCPInstance -Times 1
            }
        }

        It 'passes Name, Zone, and Project to the GCP backend' {
            InModuleScope PSCumulus {
                Mock Stop-GCPInstance {
                    param([string]$Name, [string]$Zone, [string]$Project)
                    ConvertTo-CloudRecord -Name $Name -Provider GCP -Region $Zone -Metadata @{ Proj = $Project }
                }

                $result = Stop-CloudInstance -Provider GCP -Name 'gcp-vm' -Zone 'us-central1-a' -Project 'prod-gcp'
                $result.Name | Should -Be 'gcp-vm'
                $result.Region | Should -Be 'us-central1-a'
                $result.Metadata.Proj | Should -Be 'prod-gcp'
            }
        }
    }
}
