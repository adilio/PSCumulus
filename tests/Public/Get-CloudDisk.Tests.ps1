BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
}

Describe 'Get-CloudDisk' {

    Context 'parameter validation' {
        It 'makes Provider optional in every parameter set' {
            foreach ($parameterSet in 'Azure', 'AWS', 'GCP') {
                Should-HaveOptionalParameter `
                    -CommandName 'Get-CloudDisk' `
                    -ParameterSetName $parameterSet `
                    -ParameterName 'Provider'
            }
        }

        It 'requires -ResourceGroup in the Azure parameter set' {
            Should-HaveMandatoryParameter `
                -CommandName 'Get-CloudDisk' `
                -ParameterSetName 'Azure' `
                -ParameterName 'ResourceGroup'
        }

        It 'requires -Region in the AWS parameter set' {
            Should-HaveMandatoryParameter `
                -CommandName 'Get-CloudDisk' `
                -ParameterSetName 'AWS' `
                -ParameterName 'Region'
        }

        It 'requires -Project in the GCP parameter set' {
            Should-HaveMandatoryParameter `
                -CommandName 'Get-CloudDisk' `
                -ParameterSetName 'GCP' `
                -ParameterName 'Project'
        }

        It 'rejects an invalid provider name' {
            { Get-CloudDisk -Provider Oracle -ResourceGroup 'rg' } | Should -Throw
        }
    }

    Context 'Azure routing' {
        It 'calls Get-AzureDiskData for Azure provider' {
            InModuleScope PSCumulus {
                Mock Get-AzureDiskData {
                    [AzureDiskRecord]@{ Name = 'os-disk-01'; Provider = 'Azure'; Region = 'eastus' }
                }

                Get-CloudDisk -Provider Azure -ResourceGroup 'prod-rg'

                Should -Invoke Get-AzureDiskData -Times 1
            }
        }

        It 'infers Azure when Provider is omitted' {
            InModuleScope PSCumulus {
                Mock Get-AzureDiskData {
                    [AzureDiskRecord]@{ Name = 'os-disk-01'; Provider = 'Azure'; Region = 'eastus' }
                }

                Get-CloudDisk -ResourceGroup 'prod-rg'

                Should -Invoke Get-AzureDiskData -Times 1
            }
        }

        It 'passes ResourceGroup to the Azure backend' {
            InModuleScope PSCumulus {
                Mock Get-AzureDiskData {
                    param([string]$ResourceGroup)
                    [AzureDiskRecord]@{ Name = 'os-disk-01'; Provider = 'Azure'; Metadata = @{ RG = $ResourceGroup } }
                }

                $result = Get-CloudDisk -Provider Azure -ResourceGroup 'my-rg'
                $result.Metadata.RG | Should -Be 'my-rg'
            }
        }

        It 'returns CloudRecord objects' {
            InModuleScope PSCumulus {
                Mock Get-AzureDiskData {
                    [AzureDiskRecord]@{ Name = 'os-disk-01'; Provider = 'Azure'; Region = 'eastus'; Size = '128 GB' }
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
                    [AWSDiskRecord]@{ Name = 'data-volume'; Provider = 'AWS'; Region = 'us-east-1a' }
                }

                Get-CloudDisk -Provider AWS -Region 'us-east-1'

                Should -Invoke Get-AWSDiskData -Times 1
            }
        }

        It 'passes Region to the AWS backend' {
            InModuleScope PSCumulus {
                Mock Get-AWSDiskData {
                    param([string]$Region)
                    [AWSDiskRecord]@{ Name = 'data-volume'; Provider = 'AWS'; Region = $Region }
                }

                $result = Get-CloudDisk -Provider AWS -Region 'eu-west-1'
                $result.Region | Should -Be 'eu-west-1'
            }
        }

        It 'infers AWS when Provider is omitted' {
            InModuleScope PSCumulus {
                Mock Get-AWSDiskData {
                    [AWSDiskRecord]@{ Name = 'data-volume'; Provider = 'AWS'; Region = 'us-east-1a' }
                }

                Get-CloudDisk -Region 'us-east-1'

                Should -Invoke Get-AWSDiskData -Times 1
            }
        }
    }

    Context 'GCP routing' {
        It 'calls Get-GCPDiskData for GCP provider' {
            InModuleScope PSCumulus {
                Mock Get-GCPDiskData {
                    [GCPDiskRecord]@{ Name = 'data-disk-01'; Provider = 'GCP'; Region = 'us-central1-a' }
                }

                Get-CloudDisk -Provider GCP -Project 'my-project'

                Should -Invoke Get-GCPDiskData -Times 1
            }
        }

        It 'passes Project to the GCP backend' {
            InModuleScope PSCumulus {
                Mock Get-GCPDiskData {
                    param([string]$Project)
                    [GCPDiskRecord]@{ Name = 'data-disk-01'; Provider = 'GCP'; Metadata = @{ Proj = $Project } }
                }

                $result = Get-CloudDisk -Provider GCP -Project 'prod-gcp'
                $result.Metadata.Proj | Should -Be 'prod-gcp'
            }
        }
    }

    Context '-All parameter' {
        BeforeEach {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.Providers = @{ Azure = $null; AWS = $null; GCP = $null }
            }
        }

        It 'calls all backend functions when providers are connected' {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.Providers['Azure'] = @{ Region = $null; Scope = 'prod-rg' }
                $script:PSCumulusContext.Providers['AWS']   = @{ Region = 'us-east-1'; Scope = $null }
                $script:PSCumulusContext.Providers['GCP']   = @{ Region = 'us-central1'; Scope = 'my-project' }

                Mock Get-AzureDiskData { [AzureDiskRecord]@{ Name = 'az-disk'; Provider = 'Azure' } }
                Mock Get-AWSDiskData   { [AWSDiskRecord]@{ Name = 'aws-disk'; Provider = 'AWS' } }
                Mock Get-GCPDiskData   { [GCPDiskRecord]@{ Name = 'gcp-disk'; Provider = 'GCP' } }

                $null = Get-CloudDisk -All

                Should -Invoke Get-AzureDiskData -Times 1
                Should -Invoke Get-AWSDiskData   -Times 1
                Should -Invoke Get-GCPDiskData   -Times 1
            }
        }

        It 'returns CloudRecord objects from all connected providers' {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.Providers['Azure'] = @{ Region = $null; Scope = 'prod-rg' }
                $script:PSCumulusContext.Providers['AWS']   = @{ Region = 'us-east-1'; Scope = $null }
                $script:PSCumulusContext.Providers['GCP']   = @{ Region = 'us-central1'; Scope = 'my-project' }

                Mock Get-AzureDiskData { [AzureDiskRecord]@{ Name = 'az-disk';  Provider = 'Azure' } }
                Mock Get-AWSDiskData   { [AWSDiskRecord]@{ Name = 'aws-disk'; Provider = 'AWS' } }
                Mock Get-GCPDiskData   { [GCPDiskRecord]@{ Name = 'gcp-disk'; Provider = 'GCP' } }

                $results = @(Get-CloudDisk -All)
                $results.Count | Should -Be 3
            }
        }
    }
}
