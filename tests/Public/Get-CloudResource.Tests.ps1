BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
}

Describe 'Get-CloudResource' {

    Context 'parameter validation' {
        It 'requires -Path' {
            Should-HaveMandatoryParameter `
                -CommandName 'Get-CloudResource' `
                -ParameterSetName '__AllParameterSets' `
                -ParameterName 'Path'
        }

        It 'throws on an invalid provider in the path' {
            { Get-CloudResource -Path 'Oracle:\rg\Instances\vm01' } | Should -Throw
        }

        It 'throws when the path stops at scope depth' {
            { Get-CloudResource -Path 'Azure:\prod-rg' } | Should -Throw -ExpectedMessage '*kind segment*'
        }

        It 'throws for the Tags kind' {
            { Get-CloudResource -Path 'Azure:\prod-rg\Tags' } | Should -Throw -ExpectedMessage '*Get-CloudTag*'
        }
    }

    Context 'Azure dispatch' {
        It 'resolves an instance path through Get-AzureInstanceData with scope and name' {
            InModuleScope PSCumulus {
                Mock Get-AzureInstanceData {
                    param([string]$ResourceGroup, [string]$Name)
                    [AzureCloudRecord]@{ Name = $Name; Provider = 'Azure'; Metadata = @{ RG = $ResourceGroup } }
                }

                $result = Get-CloudResource -Path 'Azure:\prod-rg\Instances\web-01'

                Should -Invoke Get-AzureInstanceData -Times 1
                $result.Name | Should -Be 'web-01'
                $result.Metadata.RG | Should -Be 'prod-rg'
            }
        }

        It 'lists every record for a kind-depth path' {
            InModuleScope PSCumulus {
                Mock Get-AzureDiskData {
                    @(
                        [AzureDiskRecord]@{ Name = 'disk-a'; Provider = 'Azure' },
                        [AzureDiskRecord]@{ Name = 'disk-b'; Provider = 'Azure' }
                    )
                }

                $result = Get-CloudResource -Path 'Azure:\prod-rg\Disks'

                @($result).Count | Should -Be 2
            }
        }

        It 'filters non-instance kinds client-side by resource name' {
            InModuleScope PSCumulus {
                Mock Get-AzureDiskData {
                    param([string]$ResourceGroup)
                    @(
                        [AzureDiskRecord]@{ Name = 'disk-a'; Provider = 'Azure' },
                        [AzureDiskRecord]@{ Name = 'disk-b'; Provider = 'Azure' }
                    )
                }

                $result = Get-CloudResource -Path 'Azure:\prod-rg\Disks\disk-b'

                @($result).Count | Should -Be 1
                $result.Name | Should -Be 'disk-b'
            }
        }
    }

    Context 'AWS dispatch' {
        It 'resolves a disk path through Get-AWSDiskData with the region scope' {
            InModuleScope PSCumulus {
                Mock Get-AWSDiskData {
                    param([string]$Region)
                    [AWSDiskRecord]@{ Name = 'vol-1'; Provider = 'AWS'; Metadata = @{ Region = $Region } }
                }

                $result = Get-CloudResource -Path 'AWS:\us-east-1\Disks\vol-1'

                Should -Invoke Get-AWSDiskData -Times 1
                $result.Metadata.Region | Should -Be 'us-east-1'
            }
        }
    }

    Context 'GCP dispatch' {
        It 'resolves a function path through Get-GCPFunctionData with the project scope' {
            InModuleScope PSCumulus {
                Mock Get-GCPFunctionData {
                    param([string]$Project)
                    [GCPFunctionRecord]@{ Name = 'resize-images'; Provider = 'GCP'; Metadata = @{ Project = $Project } }
                }

                $result = Get-CloudResource -Path 'GCP:\my-project\Functions\resize-images'

                Should -Invoke Get-GCPFunctionData -Times 1
                $result.Metadata.Project | Should -Be 'my-project'
            }
        }
    }

    Context 'output shape' {
        It 'returns CloudRecord-typed objects' {
            InModuleScope PSCumulus {
                Mock Get-AzureInstanceData {
                    [AzureCloudRecord]@{ Name = 'vm01'; Provider = 'Azure'; Status = 'Running' }
                }

                $result = Get-CloudResource -Path 'Azure:\rg\Instances\vm01'
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRecord'
            }
        }

        It 'adds the detailed type name when -Detailed is specified' {
            InModuleScope PSCumulus {
                Mock Get-AzureInstanceData {
                    [AzureCloudRecord]@{ Name = 'vm01'; Provider = 'Azure'; Status = 'Running' }
                }

                $result = Get-CloudResource -Path 'Azure:\rg\Instances\vm01' -Detailed
                $result.PSObject.TypeNames[0] | Should -Be 'PSCumulus.CloudRecord.Detailed'
            }
        }

        It 'accepts the path from the pipeline' {
            InModuleScope PSCumulus {
                Mock Get-AzureInstanceData {
                    [AzureCloudRecord]@{ Name = 'vm01'; Provider = 'Azure' }
                }

                $result = 'Azure:\rg\Instances\vm01' | Get-CloudResource
                $result.Name | Should -Be 'vm01'
            }
        }
    }

    Context 'not found' {
        It 'writes a non-terminating ObjectNotFound error when a resource-depth path matches nothing' {
            InModuleScope PSCumulus {
                Mock Get-AzureDiskData { @() }

                $errors = $null
                $result = Get-CloudResource -Path 'Azure:\rg\Disks\missing' -ErrorAction SilentlyContinue -ErrorVariable errors

                $result | Should -BeNullOrEmpty
                $errors.Count | Should -BeGreaterThan 0
                $errors[0].CategoryInfo.Category | Should -Be 'ObjectNotFound'
            }
        }
    }
}
