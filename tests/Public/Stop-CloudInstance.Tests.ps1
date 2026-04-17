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
                    [AzureCloudRecord]@{ Name = 'vm01'; Provider = 'Azure'; Status = 'Stopping' }
                }

                Stop-CloudInstance -Provider Azure -Name 'vm01' -ResourceGroup 'prod-rg'

                Should -Invoke Stop-AzureInstance -Times 1
            }
        }

        It 'passes Name and ResourceGroup to the Azure backend' {
            InModuleScope PSCumulus {
                Mock Stop-AzureInstance {
                    param([string]$Name, [string]$ResourceGroup)
                    [AzureCloudRecord]@{ Name = $Name; Provider = 'Azure'; Metadata = @{ RG = $ResourceGroup } }
                }

                $result = Stop-CloudInstance -Provider Azure -Name 'my-vm' -ResourceGroup 'my-rg'
                $result.Name | Should -Be 'my-vm'
                $result.Metadata.RG | Should -Be 'my-rg'
            }
        }

        It 'infers Azure when Provider is omitted' {
            InModuleScope PSCumulus {
                Mock Stop-AzureInstance {
                    [AzureCloudRecord]@{ Name = 'vm01'; Provider = 'Azure'; Status = 'Stopping' }
                }

                Stop-CloudInstance -Name 'vm01' -ResourceGroup 'prod-rg'

                Should -Invoke Stop-AzureInstance -Times 1
            }
        }

        It 'accepts piped Azure instance records' {
            InModuleScope PSCumulus {
                Mock Stop-AzureInstance {
                    param([string]$Name, [string]$ResourceGroup)
                    [AzureCloudRecord]@{ Name = $Name; Provider = 'Azure'; Metadata = @{ RG = $ResourceGroup } }
                }

                $inputRecord = [AzureCloudRecord]@{ Name = 'web-server-01'; Provider = 'Azure'; ResourceGroup = 'prod-rg' }
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
                    [AWSCloudRecord]@{ Name = 'i-abc'; Provider = 'AWS'; Status = 'Stopping' }
                }

                Stop-CloudInstance -Provider AWS -InstanceId 'i-abc' -Region 'us-east-1'

                Should -Invoke Stop-AWSInstance -Times 1
            }
        }

        It 'passes InstanceId to the AWS backend' {
            InModuleScope PSCumulus {
                Mock Stop-AWSInstance {
                    param([string]$InstanceId)
                    [AWSCloudRecord]@{ Name = $InstanceId; Provider = 'AWS'; Status = 'Stopping' }
                }

                $result = Stop-CloudInstance -Provider AWS -InstanceId 'i-0abc123'
                $result.Name | Should -Be 'i-0abc123'
            }
        }

        It 'infers AWS when Provider is omitted' {
            InModuleScope PSCumulus {
                Mock Stop-AWSInstance {
                    [AWSCloudRecord]@{ Name = 'i-abc'; Provider = 'AWS'; Status = 'Stopping' }
                }

                Stop-CloudInstance -InstanceId 'i-abc' -Region 'us-east-1'

                Should -Invoke Stop-AWSInstance -Times 1
            }
        }

        It 'accepts piped AWS instance records' {
            InModuleScope PSCumulus {
                Mock Stop-AWSInstance {
                    param([string]$InstanceId, [string]$Region)
                    [AWSCloudRecord]@{ Name = $InstanceId; Provider = 'AWS'; Region = $Region; Status = 'Stopping' }
                }

                $inputRecord = [AWSCloudRecord]@{ Name = 'app-server-01'; Provider = 'AWS'; InstanceId = 'i-0abc123' }
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
                    [GCPCloudRecord]@{ Name = 'gcp-vm'; Provider = 'GCP'; Status = 'Stopping' }
                }

                Stop-CloudInstance -Provider GCP -Name 'gcp-vm' -Zone 'us-central1-a' -Project 'my-project'

                Should -Invoke Stop-GCPInstance -Times 1
            }
        }

        It 'passes Name, Zone, and Project to the GCP backend' {
            InModuleScope PSCumulus {
                Mock Stop-GCPInstance {
                    param([string]$Name, [string]$Zone, [string]$Project)
                    [GCPCloudRecord]@{ Name = $Name; Provider = 'GCP'; Region = $Zone; Metadata = @{ Proj = $Project } }
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
                    [GCPCloudRecord]@{ Name = $Name; Provider = 'GCP'; Region = $Zone; Metadata = @{ Proj = $Project } }
                }

                $inputRecord = [GCPCloudRecord]@{ Name = 'gcp-vm'; Provider = 'GCP'; Region = 'us-central1-a'; Project = 'prod-gcp'; Zone = 'us-central1-a' }
                $result = $inputRecord | Stop-CloudInstance -Confirm:$false

                $result.Name | Should -Be 'gcp-vm'
                $result.Region | Should -Be 'us-central1-a'
                $result.Metadata.Proj | Should -Be 'prod-gcp'
            }
        }
    }

    Context 'Path parameter set' {
        It 'dispatches Azure path to Stop-AzureInstance with correct parameters' {
            InModuleScope PSCumulus {
                Mock Stop-AzureInstance {
                    param([string]$Name, [string]$ResourceGroup)
                    [AzureCloudRecord]@{ Name = $Name; Provider = 'Azure'; Metadata = @{ RG = $ResourceGroup } }
                }

                Stop-CloudInstance -Path 'Azure:\prod-rg\Instances\web-server-01' -Confirm:$false

                Should -Invoke Stop-AzureInstance -Times 1 -ParameterFilter {
                    $Name -eq 'web-server-01' -and $ResourceGroup -eq 'prod-rg'
                }
            }
        }

        It 'dispatches AWS path to Stop-AWSInstance with correct parameters' {
            InModuleScope PSCumulus {
                Mock Stop-AWSInstance {
                    param([string]$InstanceId, [string]$Region)
                    [AWSCloudRecord]@{ Name = $InstanceId; Provider = 'AWS'; Region = $Region; Status = 'Stopping' }
                }

                Stop-CloudInstance -Path 'AWS:\us-east-1\Instances\i-12345678' -Confirm:$false

                Should -Invoke Stop-AWSInstance -Times 1 -ParameterFilter {
                    $InstanceId -eq 'i-12345678' -and $Region -eq 'us-east-1'
                }
            }
        }

        It 'dispatches GCP path and resolves Zone via Get-GCPInstanceData lookup' {
            InModuleScope PSCumulus {
                Mock Get-GCPInstanceData {
                    [GCPCloudRecord]@{ Name = 'gcp-vm'; Provider = 'GCP'; Zone = 'us-central1-a'; Project = 'my-project' }
                }
                Mock Stop-GCPInstance {
                    param([string]$Name, [string]$Zone, [string]$Project)
                    [GCPCloudRecord]@{ Name = $Name; Provider = 'GCP'; Region = $Zone; Metadata = @{ Proj = $Project } }
                }

                Stop-CloudInstance -Path 'GCP:\my-project\Instances\gcp-vm' -Confirm:$false

                Should -Invoke Get-GCPInstanceData -Times 1 -ParameterFilter {
                    $Project -eq 'my-project' -and $Name -eq 'gcp-vm'
                }
                Should -Invoke Stop-GCPInstance -Times 1 -ParameterFilter {
                    $Name -eq 'gcp-vm' -and $Zone -eq 'us-central1-a' -and $Project -eq 'my-project'
                }
            }
        }

        It 'throws ArgumentException for non-Resource depth paths' {
            InModuleScope PSCumulus {
                { Stop-CloudInstance -Path 'Azure:\prod-rg\Instances' } | Should -Throw -ExpectedMessage '*Path must resolve to a specific resource*'
                { Stop-CloudInstance -Path 'Azure:\prod-rg' } | Should -Throw -ExpectedMessage '*Path must resolve to a specific resource*'
                { Stop-CloudInstance -Path 'Azure:\' } | Should -Throw -ExpectedMessage '*Path must resolve to a specific resource*'
            }
        }

        It 'throws ArgumentException for non-Instances kind' {
            InModuleScope PSCumulus {
                { Stop-CloudInstance -Path 'Azure:\prod-rg\Disks\disk-01' } | Should -Throw -ExpectedMessage '*only supported for Instances*'
                { Stop-CloudInstance -Path 'AWS:\us-east-1\Storage\bucket' } | Should -Throw -ExpectedMessage '*only supported for Instances*'
            }
        }

        It 'does not invoke backend when -WhatIf is used' {
            InModuleScope PSCumulus {
                Mock Stop-AzureInstance {
                    [AzureCloudRecord]@{ Name = 'vm01'; Provider = 'Azure'; Status = 'Stopping' }
                }

                Stop-CloudInstance -Path 'Azure:\prod-rg\Instances\web-server-01' -WhatIf

                Should -Invoke Stop-AzureInstance -Times 0
            }
        }

        It 'throws InvalidOperationException when GCP instance not found' {
            InModuleScope PSCumulus {
                Mock Get-GCPInstanceData { return $null }

                { Stop-CloudInstance -Path 'GCP:\my-project\Instances\nonexistent-vm' } | Should -Throw -ExpectedMessage '*not found in project*'
            }
        }
    }
}
