BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
}

Describe 'Get-CloudInstance' {

    Context 'parameter validation' {
        It 'makes Provider optional in every parameter set' {
            foreach ($parameterSet in 'Azure', 'AWS', 'GCP') {
                Should-HaveOptionalParameter `
                    -CommandName 'Get-CloudInstance' `
                    -ParameterSetName $parameterSet `
                    -ParameterName 'Provider'
            }
        }

        It 'requires -ResourceGroup in the Azure parameter set' {
            Should-HaveMandatoryParameter `
                -CommandName 'Get-CloudInstance' `
                -ParameterSetName 'Azure' `
                -ParameterName 'ResourceGroup'
        }

        It 'requires -Region in the AWS parameter set' {
            Should-HaveMandatoryParameter `
                -CommandName 'Get-CloudInstance' `
                -ParameterSetName 'AWS' `
                -ParameterName 'Region'
        }

        It 'requires -Project in the GCP parameter set' {
            Should-HaveMandatoryParameter `
                -CommandName 'Get-CloudInstance' `
                -ParameterSetName 'GCP' `
                -ParameterName 'Project'
        }

        It 'rejects an invalid provider name' {
            { Get-CloudInstance -Provider Oracle -ResourceGroup 'rg' } | Should -Throw
        }
    }

    Context 'Azure routing' {
        It 'calls Get-AzureInstanceData for Azure provider' {
            InModuleScope PSCumulus {
                Mock Get-AzureInstanceData {
                    ConvertTo-CloudRecord -Name 'vm01' -Provider Azure -Region 'eastus'
                }

                Get-CloudInstance -Provider Azure -ResourceGroup 'prod-rg'

                Should -Invoke Get-AzureInstanceData -Times 1
            }
        }

        It 'passes ResourceGroup to the Azure backend' {
            InModuleScope PSCumulus {
                Mock Get-AzureInstanceData {
                    param([string]$ResourceGroup)
                    ConvertTo-CloudRecord -Name 'vm01' -Provider Azure -Metadata @{ RG = $ResourceGroup }
                }

                $result = Get-CloudInstance -Provider Azure -ResourceGroup 'my-rg'
                $result.Metadata.RG | Should -Be 'my-rg'
            }
        }

        It 'infers Azure when Provider is omitted' {
            InModuleScope PSCumulus {
                Mock Get-AzureInstanceData {
                    ConvertTo-CloudRecord -Name 'vm01' -Provider Azure -Region 'eastus'
                }

                Get-CloudInstance -ResourceGroup 'prod-rg'

                Should -Invoke Get-AzureInstanceData -Times 1
            }
        }

        It 'returns CloudRecord objects' {
            InModuleScope PSCumulus {
                Mock Get-AzureInstanceData {
                    ConvertTo-CloudRecord -Name 'vm01' -Provider Azure -Region 'eastus' -Status 'Running'
                }

                $result = Get-CloudInstance -Provider Azure -ResourceGroup 'rg'
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRecord'
            }
        }
    }

    Context 'AWS routing' {
        It 'calls Get-AWSInstanceData for AWS provider' {
            InModuleScope PSCumulus {
                Mock Get-AWSInstanceData {
                    ConvertTo-CloudRecord -Name 'i-abc' -Provider AWS -Region 'us-east-1a'
                }

                Get-CloudInstance -Provider AWS -Region 'us-east-1'

                Should -Invoke Get-AWSInstanceData -Times 1
            }
        }

        It 'passes Region to the AWS backend' {
            InModuleScope PSCumulus {
                Mock Get-AWSInstanceData {
                    param([string]$Region)
                    ConvertTo-CloudRecord -Name 'i-abc' -Provider AWS -Region $Region
                }

                $result = Get-CloudInstance -Provider AWS -Region 'ap-southeast-1'
                $result.Region | Should -Be 'ap-southeast-1'
            }
        }

        It 'infers AWS when Provider is omitted' {
            InModuleScope PSCumulus {
                Mock Get-AWSInstanceData {
                    ConvertTo-CloudRecord -Name 'i-abc' -Provider AWS -Region 'us-east-1a'
                }

                Get-CloudInstance -Region 'us-east-1'

                Should -Invoke Get-AWSInstanceData -Times 1
            }
        }
    }

    Context 'GCP routing' {
        It 'calls Get-GCPInstanceData for GCP provider' {
            InModuleScope PSCumulus {
                Mock Get-GCPInstanceData {
                    ConvertTo-CloudRecord -Name 'gcp-vm' -Provider GCP -Region 'us-central1-a'
                }

                Get-CloudInstance -Provider GCP -Project 'my-project'

                Should -Invoke Get-GCPInstanceData -Times 1
            }
        }

        It 'passes Project to the GCP backend' {
            InModuleScope PSCumulus {
                Mock Get-GCPInstanceData {
                    param([string]$Project)
                    ConvertTo-CloudRecord -Name 'gcp-vm' -Provider GCP -Metadata @{ Proj = $Project }
                }

                $result = Get-CloudInstance -Provider GCP -Project 'prod-gcp'
                $result.Metadata.Proj | Should -Be 'prod-gcp'
            }
        }
    }
}
