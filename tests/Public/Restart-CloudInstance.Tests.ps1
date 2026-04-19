BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Restart-CloudInstance' {

    Context 'parameter validation' {
        It 'has Piped parameter set with ValueFromPipeline' {
            $parameter = (Get-Command Restart-CloudInstance).Parameters['InputObject']
            $parameter.ParameterSets['Piped'].ValueFromPipeline | Should -Be $true
        }

        It 'has Path parameter set with ValueFromPipelineByPropertyName' {
            $parameter = (Get-Command Restart-CloudInstance).Parameters['Path']
            $parameter.ParameterSets['Path'].ValueFromPipelineByPropertyName | Should -Be $true
        }
    }

    Context 'Azure routing' {
        It 'calls Restart-AzureInstance for Azure provider' {
            InModuleScope PSCumulus {
                Mock Restart-AzureInstance {
                    [AzureCloudRecord]@{ Name = 'vm01'; Provider = 'Azure'; Status = 'Starting' }
                }
                Mock Assert-CommandAvailable { }

                Restart-CloudInstance -Provider Azure -Name 'vm01' -ResourceGroup 'rg'

                Should -Invoke Restart-AzureInstance -Times 1
            }
        }

        It 'passes Name and ResourceGroup to the Azure backend' {
            InModuleScope PSCumulus {
                Mock Restart-AzureInstance {
                    param([string]$Name, [string]$ResourceGroup)
                    [AzureCloudRecord]@{ Name = $Name; ResourceGroup = $ResourceGroup; Provider = 'Azure' }
                }
                Mock Assert-CommandAvailable { }

                $result = Restart-CloudInstance -Provider Azure -Name 'test-vm' -ResourceGroup 'test-rg'
                $result.Name | Should -Be 'test-vm'
                $result.ResourceGroup | Should -Be 'test-rg'
            }
        }
    }

    Context 'AWS routing' {
        It 'calls Restart-AWSInstance for AWS provider' {
            InModuleScope PSCumulus {
                Mock Restart-AWSInstance {
                    [AWSCloudRecord]@{ Name = 'i-abc'; Provider = 'AWS'; Status = 'Stopping' }
                }
                Mock Assert-CommandAvailable { }

                Restart-CloudInstance -Provider AWS -InstanceId 'i-abc'

                Should -Invoke Restart-AWSInstance -Times 1
            }
        }

        It 'passes InstanceId and Region to the AWS backend' {
            InModuleScope PSCumulus {
                Mock Restart-AWSInstance {
                    param([string]$InstanceId, [string]$Region)
                    [AWSCloudRecord]@{ InstanceId = $InstanceId; Region = $Region; Provider = 'AWS' }
                }
                Mock Assert-CommandAvailable { }

                $result = Restart-CloudInstance -Provider AWS -InstanceId 'i-123' -Region 'us-east-1'
                $result.InstanceId | Should -Be 'i-123'
                $result.Region | Should -Be 'us-east-1'
            }
        }
    }

    Context 'GCP routing' {
        It 'calls Restart-GCPInstance for GCP provider' {
            InModuleScope PSCumulus {
                Mock Restart-GCPInstance {
                    [GCPCloudRecord]@{ Name = 'gcp-vm'; Provider = 'GCP'; Status = 'Running' }
                }
                Mock Assert-CommandAvailable { }

                Restart-CloudInstance -Provider GCP -Name 'gcp-vm' -Zone 'us-central1-a' -Project 'proj'

                Should -Invoke Restart-GCPInstance -Times 1
            }
        }

        It 'passes Name, Zone, and Project to the GCP backend' {
            InModuleScope PSCumulus {
                Mock Restart-GCPInstance {
                    param([string]$Name, [string]$Zone, [string]$Project)
                    [GCPCloudRecord]@{ Name = $Name; Zone = $Zone; Project = $Project; Provider = 'GCP' }
                }
                Mock Assert-CommandAvailable { }

                $result = Restart-CloudInstance -Provider GCP -Name 'test-vm' -Zone 'us-central1-a' -Project 'test-proj'
                $result.Name | Should -Be 'test-vm'
                $result.Zone | Should -Be 'us-central1-a'
                $result.Project | Should -Be 'test-proj'
            }
        }
    }

    Context 'pipeline input' {
        It 'accepts piped CloudRecord objects' {
            InModuleScope PSCumulus {
                Mock Restart-AzureInstance {
                    [AzureCloudRecord]@{ Name = 'vm01'; Provider = 'Azure'; Status = 'Starting' }
                }
                Mock Assert-CommandAvailable { }

                $inputRecord = [pscustomobject]@{
                    Name = 'vm01'
                    Provider = 'Azure'
                    ResourceGroup = 'rg'
                    Status = 'Running'
                    PSTypeName = 'PSCumulus.CloudRecord'
                }

                $inputRecord | Restart-CloudInstance

                Should -Invoke Restart-AzureInstance -Times 1
            }
        }
    }

    Context 'Path parameter set -Wait -PassThru' {
        It 'emits the freshest polled record with -Wait -PassThru' {
            InModuleScope PSCumulus {
                Mock Restart-AzureInstance { }
                Mock Start-Sleep { }
                Mock Get-AzureInstanceData {
                    [AzureCloudRecord]@{ Name = 'web-server-01'; Provider = 'Azure'; ResourceGroup = 'prod-rg'; Status = 'Running' }
                }

                $result = Restart-CloudInstance -Path 'Azure:\prod-rg\Instances\web-server-01' -Wait -PassThru -PollingIntervalSeconds 1 -Confirm:$false

                $result.Status | Should -Be 'Running'
                Should -Invoke Get-AzureInstanceData -Times 1
            }
        }

        It 'emits nothing extra with -PassThru alone when no wait was done' {
            InModuleScope PSCumulus {
                Mock Restart-AzureInstance { }
                Mock Get-AzureInstanceData {
                    [AzureCloudRecord]@{ Name = 'web-server-01'; Provider = 'Azure'; ResourceGroup = 'prod-rg'; Status = 'Running' }
                }

                $result = Restart-CloudInstance -Path 'Azure:\prod-rg\Instances\web-server-01' -PassThru -Confirm:$false

                $result | Should -BeNullOrEmpty
                Should -Invoke Get-AzureInstanceData -Times 0
            }
        }

        It 'does not poll under -Wait -WhatIf' {
            InModuleScope PSCumulus {
                Mock Restart-AzureInstance { }
                Mock Get-AzureInstanceData {
                    [AzureCloudRecord]@{ Name = 'web-server-01'; Provider = 'Azure'; ResourceGroup = 'prod-rg'; Status = 'Running' }
                }

                Restart-CloudInstance -Path 'Azure:\prod-rg\Instances\web-server-01' -Wait -WhatIf

                Should -Invoke Restart-AzureInstance -Times 0
                Should -Invoke Get-AzureInstanceData -Times 0
            }
        }
    }
}
