BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
}

Describe 'Stop-CloudInstance' {

    Context 'parameter validation' {
        It 'makes Provider optional in every parameter set' {
            foreach ($parameterSet in 'Azure', 'AWS', 'GCP') {
                Should-HaveOptionalParameter `
                    -CommandName 'Stop-CloudInstance' `
                    -ParameterSetName $parameterSet `
                    -ParameterName 'Provider'
            }
        }

        It 'requires -Name and -ResourceGroup in the Azure parameter set' {
            Should-HaveMandatoryParameters `
                -CommandName 'Stop-CloudInstance' `
                -ParameterSetName 'Azure' `
                -ParameterNames @('Name', 'ResourceGroup')
        }

        It 'requires -InstanceId in the AWS parameter set' {
            Should-HaveMandatoryParameter `
                -CommandName 'Stop-CloudInstance' `
                -ParameterSetName 'AWS' `
                -ParameterName 'InstanceId'
        }

        It 'requires -Name, -Zone, and -Project in the GCP parameter set' {
            Should-HaveMandatoryParameters `
                -CommandName 'Stop-CloudInstance' `
                -ParameterSetName 'GCP' `
                -ParameterNames @('Name', 'Zone', 'Project')
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

        It 'infers Azure when Provider is omitted' {
            InModuleScope PSCumulus {
                Mock Stop-AzureInstance {
                    ConvertTo-CloudRecord -Name 'vm01' -Provider Azure -Status 'Stopping'
                }

                Stop-CloudInstance -Name 'vm01' -ResourceGroup 'prod-rg'

                Should -Invoke Stop-AzureInstance -Times 1
            }
        }

        It 'accepts piped Azure instance records' {
            InModuleScope PSCumulus {
                Mock Stop-AzureInstance {
                    param([string]$Name, [string]$ResourceGroup)
                    ConvertTo-CloudRecord -Name $Name -Provider Azure -Metadata @{ RG = $ResourceGroup }
                }

                $inputRecord = ConvertTo-CloudRecord -Name 'web-server-01' -Provider Azure -Metadata @{ ResourceGroup = 'prod-rg' }
                $result = $inputRecord | Stop-CloudInstance -Confirm:$false

                $result.Name | Should -Be 'web-server-01'
                $result.Metadata.RG | Should -Be 'prod-rg'
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

        It 'infers AWS when Provider is omitted' {
            InModuleScope PSCumulus {
                Mock Stop-AWSInstance {
                    ConvertTo-CloudRecord -Name 'i-abc' -Provider AWS -Status 'Stopping'
                }

                Stop-CloudInstance -InstanceId 'i-abc' -Region 'us-east-1'

                Should -Invoke Stop-AWSInstance -Times 1
            }
        }

        It 'accepts piped AWS instance records' {
            InModuleScope PSCumulus {
                Mock Stop-AWSInstance {
                    param([string]$InstanceId, [string]$Region)
                    ConvertTo-CloudRecord -Name $InstanceId -Provider AWS -Region $Region -Status 'Stopping'
                }

                $inputRecord = ConvertTo-CloudRecord -Name 'app-server-01' -Provider AWS -Metadata @{ InstanceId = 'i-0abc123' }
                $result = $inputRecord | Stop-CloudInstance -Confirm:$false

                $result.Name | Should -Be 'i-0abc123'
                $result.Region | Should -BeNullOrEmpty
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

        It 'accepts piped GCP instance records' {
            InModuleScope PSCumulus {
                Mock Stop-GCPInstance {
                    param([string]$Name, [string]$Zone, [string]$Project)
                    ConvertTo-CloudRecord -Name $Name -Provider GCP -Region $Zone -Metadata @{ Proj = $Project }
                }

                $inputRecord = ConvertTo-CloudRecord -Name 'gcp-vm' -Provider GCP -Region 'us-central1-a' -Metadata @{ Project = 'prod-gcp'; Zone = 'us-central1-a' }
                $result = $inputRecord | Stop-CloudInstance -Confirm:$false

                $result.Name | Should -Be 'gcp-vm'
                $result.Region | Should -Be 'us-central1-a'
                $result.Metadata.Proj | Should -Be 'prod-gcp'
            }
        }
    }
}
