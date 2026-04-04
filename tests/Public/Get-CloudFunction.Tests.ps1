BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Get-CloudFunction' {

    Context 'parameter validation' {
        It 'requires -Provider' {
            { Get-CloudFunction } | Should -Throw
        }

        It 'requires -ResourceGroup for Azure' {
            { Get-CloudFunction -Provider Azure } | Should -Throw
        }

        It 'requires -Region for AWS' {
            { Get-CloudFunction -Provider AWS } | Should -Throw
        }

        It 'requires -Project for GCP' {
            { Get-CloudFunction -Provider GCP } | Should -Throw
        }

        It 'rejects an invalid provider name' {
            { Get-CloudFunction -Provider Oracle -ResourceGroup 'rg' } | Should -Throw
        }
    }

    Context 'Azure routing' {
        It 'calls Get-AzureFunctionData for Azure provider' {
            InModuleScope PSCumulus {
                Mock Get-AzureFunctionData {
                    ConvertTo-CloudRecord -Name 'prod-func-app' -Provider Azure -Region 'eastus'
                }

                Get-CloudFunction -Provider Azure -ResourceGroup 'prod-rg'

                Should -Invoke Get-AzureFunctionData -Times 1
            }
        }

        It 'passes ResourceGroup to the Azure backend' {
            InModuleScope PSCumulus {
                Mock Get-AzureFunctionData {
                    param([string]$ResourceGroup)
                    ConvertTo-CloudRecord -Name 'prod-func-app' -Provider Azure -Metadata @{ RG = $ResourceGroup }
                }

                $result = Get-CloudFunction -Provider Azure -ResourceGroup 'my-rg'
                $result.Metadata.RG | Should -Be 'my-rg'
            }
        }

        It 'returns CloudRecord objects' {
            InModuleScope PSCumulus {
                Mock Get-AzureFunctionData {
                    ConvertTo-CloudRecord -Name 'prod-func-app' -Provider Azure -Region 'eastus' -Size 'dotnet'
                }

                $result = Get-CloudFunction -Provider Azure -ResourceGroup 'rg'
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRecord'
            }
        }
    }

    Context 'AWS routing' {
        It 'calls Get-AWSFunctionData for AWS provider' {
            InModuleScope PSCumulus {
                Mock Get-AWSFunctionData {
                    ConvertTo-CloudRecord -Name 'my-lambda' -Provider AWS -Region 'us-east-1'
                }

                Get-CloudFunction -Provider AWS -Region 'us-east-1'

                Should -Invoke Get-AWSFunctionData -Times 1
            }
        }

        It 'passes Region to the AWS backend' {
            InModuleScope PSCumulus {
                Mock Get-AWSFunctionData {
                    param([string]$Region)
                    ConvertTo-CloudRecord -Name 'my-lambda' -Provider AWS -Region $Region
                }

                $result = Get-CloudFunction -Provider AWS -Region 'eu-west-1'
                $result.Region | Should -Be 'eu-west-1'
            }
        }
    }

    Context 'GCP routing' {
        It 'calls Get-GCPFunctionData for GCP provider' {
            InModuleScope PSCumulus {
                Mock Get-GCPFunctionData {
                    ConvertTo-CloudRecord -Name 'hello-world' -Provider GCP -Region 'us-central1'
                }

                Get-CloudFunction -Provider GCP -Project 'my-project'

                Should -Invoke Get-GCPFunctionData -Times 1
            }
        }

        It 'passes Project to the GCP backend' {
            InModuleScope PSCumulus {
                Mock Get-GCPFunctionData {
                    param([string]$Project)
                    ConvertTo-CloudRecord -Name 'hello-world' -Provider GCP -Metadata @{ Proj = $Project }
                }

                $result = Get-CloudFunction -Provider GCP -Project 'prod-gcp'
                $result.Metadata.Proj | Should -Be 'prod-gcp'
            }
        }
    }
}
