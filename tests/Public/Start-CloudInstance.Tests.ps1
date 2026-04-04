BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
}

Describe 'Start-CloudInstance' {

    Context 'parameter validation' {
        It 'marks Provider as mandatory in every parameter set' {
            foreach ($parameterSet in 'Azure', 'AWS', 'GCP') {
                Should-HaveMandatoryParameter `
                    -CommandName 'Start-CloudInstance' `
                    -ParameterSetName $parameterSet `
                    -ParameterName 'Provider'
            }
        }

        It 'requires -Name and -ResourceGroup in the Azure parameter set' {
            Should-HaveMandatoryParameters `
                -CommandName 'Start-CloudInstance' `
                -ParameterSetName 'Azure' `
                -ParameterNames @('Name', 'ResourceGroup')
        }

        It 'requires -InstanceId in the AWS parameter set' {
            Should-HaveMandatoryParameter `
                -CommandName 'Start-CloudInstance' `
                -ParameterSetName 'AWS' `
                -ParameterName 'InstanceId'
        }

        It 'requires -Name, -Zone, and -Project in the GCP parameter set' {
            Should-HaveMandatoryParameters `
                -CommandName 'Start-CloudInstance' `
                -ParameterSetName 'GCP' `
                -ParameterNames @('Name', 'Zone', 'Project')
        }

        It 'rejects an invalid provider name' {
            { Start-CloudInstance -Provider Oracle -Name 'vm' -ResourceGroup 'rg' } | Should -Throw
        }
    }

    Context 'Azure routing' {
        It 'calls Start-AzureInstance for Azure provider' {
            InModuleScope PSCumulus {
                Mock Start-AzureInstance {
                    ConvertTo-CloudRecord -Name 'vm01' -Provider Azure -Status 'Starting'
                }

                Start-CloudInstance -Provider Azure -Name 'vm01' -ResourceGroup 'prod-rg'

                Should -Invoke Start-AzureInstance -Times 1
            }
        }

        It 'passes Name and ResourceGroup to the Azure backend' {
            InModuleScope PSCumulus {
                Mock Start-AzureInstance {
                    param([string]$Name, [string]$ResourceGroup)
                    ConvertTo-CloudRecord -Name $Name -Provider Azure -Metadata @{ RG = $ResourceGroup }
                }

                $result = Start-CloudInstance -Provider Azure -Name 'my-vm' -ResourceGroup 'my-rg'
                $result.Name | Should -Be 'my-vm'
                $result.Metadata.RG | Should -Be 'my-rg'
            }
        }
    }

    Context 'AWS routing' {
        It 'calls Start-AWSInstance for AWS provider' {
            InModuleScope PSCumulus {
                Mock Start-AWSInstance {
                    ConvertTo-CloudRecord -Name 'i-abc' -Provider AWS -Status 'Starting'
                }

                Start-CloudInstance -Provider AWS -InstanceId 'i-abc' -Region 'us-east-1'

                Should -Invoke Start-AWSInstance -Times 1
            }
        }

        It 'passes InstanceId to the AWS backend' {
            InModuleScope PSCumulus {
                Mock Start-AWSInstance {
                    param([string]$InstanceId)
                    ConvertTo-CloudRecord -Name $InstanceId -Provider AWS -Status 'Starting'
                }

                $result = Start-CloudInstance -Provider AWS -InstanceId 'i-0abc123'
                $result.Name | Should -Be 'i-0abc123'
            }
        }
    }

    Context 'GCP routing' {
        It 'calls Start-GCPInstance for GCP provider' {
            InModuleScope PSCumulus {
                Mock Start-GCPInstance {
                    ConvertTo-CloudRecord -Name 'gcp-vm' -Provider GCP -Status 'Starting'
                }

                Start-CloudInstance -Provider GCP -Name 'gcp-vm' -Zone 'us-central1-a' -Project 'my-project'

                Should -Invoke Start-GCPInstance -Times 1
            }
        }

        It 'passes Name, Zone, and Project to the GCP backend' {
            InModuleScope PSCumulus {
                Mock Start-GCPInstance {
                    param([string]$Name, [string]$Zone, [string]$Project)
                    ConvertTo-CloudRecord -Name $Name -Provider GCP -Region $Zone -Metadata @{ Proj = $Project }
                }

                $result = Start-CloudInstance -Provider GCP -Name 'gcp-vm' -Zone 'us-central1-a' -Project 'prod-gcp'
                $result.Name | Should -Be 'gcp-vm'
                $result.Region | Should -Be 'us-central1-a'
                $result.Metadata.Proj | Should -Be 'prod-gcp'
            }
        }
    }
}
