BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
}

Describe 'Get-CloudStorage' {

    Context 'parameter validation' {
        It 'makes Provider optional in every parameter set' {
            foreach ($parameterSet in 'Azure', 'AWS', 'GCP') {
                Should-HaveOptionalParameter `
                    -CommandName 'Get-CloudStorage' `
                    -ParameterSetName $parameterSet `
                    -ParameterName 'Provider'
            }
        }

        It 'requires -ResourceGroup in the Azure parameter set' {
            Should-HaveMandatoryParameter `
                -CommandName 'Get-CloudStorage' `
                -ParameterSetName 'Azure' `
                -ParameterName 'ResourceGroup'
        }

        It 'requires -Region in the AWS parameter set' {
            Should-HaveMandatoryParameter `
                -CommandName 'Get-CloudStorage' `
                -ParameterSetName 'AWS' `
                -ParameterName 'Region'
        }

        It 'requires -Project in the GCP parameter set' {
            Should-HaveMandatoryParameter `
                -CommandName 'Get-CloudStorage' `
                -ParameterSetName 'GCP' `
                -ParameterName 'Project'
        }

        It 'rejects an invalid provider name' {
            { Get-CloudStorage -Provider Oracle -Region 'us-east-1' } | Should -Throw
        }
    }

    Context 'Azure routing' {
        It 'calls Get-AzureStorageData for Azure provider' {
            InModuleScope PSCumulus {
                Mock Get-AzureStorageData { }
                Get-CloudStorage -Provider Azure -ResourceGroup 'prod-rg'
                Should -Invoke Get-AzureStorageData -Times 1
            }
        }

        It 'passes ResourceGroup to the Azure backend' {
            InModuleScope PSCumulus {
                Mock Get-AzureStorageData {
                    param([string]$ResourceGroup)
                    [AzureStorageRecord]@{ Name = 'storage01'; Provider = 'Azure'; Metadata = @{ RG = $ResourceGroup } }
                }

                $result = Get-CloudStorage -Provider Azure -ResourceGroup 'my-rg'
                $result.Metadata.RG | Should -Be 'my-rg'
            }
        }
    }

    Context 'AWS routing' {
        It 'calls Get-AWSStorageData for AWS provider' {
            InModuleScope PSCumulus {
                Mock Get-AWSStorageData { }
                Get-CloudStorage -Provider AWS -Region 'us-east-1'
                Should -Invoke Get-AWSStorageData -Times 1
            }
        }

        It 'passes Region to the AWS backend' {
            InModuleScope PSCumulus {
                Mock Get-AWSStorageData {
                    param([string]$Region)
                    [AWSStorageRecord]@{ Name = 'my-bucket'; Provider = 'AWS'; Region = $Region }
                }

                $result = Get-CloudStorage -Provider AWS -Region 'eu-west-1'
                $result.Region | Should -Be 'eu-west-1'
            }
        }
    }

    Context 'GCP routing' {
        It 'calls Get-GCPStorageData for GCP provider' {
            InModuleScope PSCumulus {
                Mock Get-GCPStorageData { }
                Get-CloudStorage -Provider GCP -Project 'my-project'
                Should -Invoke Get-GCPStorageData -Times 1
            }
        }

        It 'passes Project to the GCP backend' {
            InModuleScope PSCumulus {
                Mock Get-GCPStorageData {
                    param([string]$Project)
                    [GCPStorageRecord]@{ Name = 'my-bucket'; Provider = 'GCP'; Metadata = @{ Proj = $Project } }
                }

                $result = Get-CloudStorage -Provider GCP -Project 'prod-gcp'
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

                Mock Get-AzureStorageData { [AzureStorageRecord]@{ Name = 'az-storage'; Provider = 'Azure' } }
                Mock Get-AWSStorageData   { [AWSStorageRecord]@{ Name = 'aws-storage'; Provider = 'AWS' } }
                Mock Get-GCPStorageData   { [GCPStorageRecord]@{ Name = 'gcp-storage'; Provider = 'GCP' } }

                $null = Get-CloudStorage -All

                Should -Invoke Get-AzureStorageData -Times 1
                Should -Invoke Get-AWSStorageData   -Times 1
                Should -Invoke Get-GCPStorageData   -Times 1
            }
        }

        It 'skips providers with no stored context' {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.Providers['AWS'] = @{ Region = 'us-east-1'; Scope = $null }

                Mock Get-AzureStorageData { [AzureStorageRecord]@{ Name = 'az-storage'; Provider = 'Azure' } }
                Mock Get-AWSStorageData   { [AWSStorageRecord]@{ Name = 'aws-storage'; Provider = 'AWS' } }
                Mock Get-GCPStorageData   { [GCPStorageRecord]@{ Name = 'gcp-storage'; Provider = 'GCP' } }

                $null = Get-CloudStorage -All

                Should -Invoke Get-AWSStorageData   -Times 1
                Should -Invoke Get-AzureStorageData -Times 0
                Should -Invoke Get-GCPStorageData   -Times 0
            }
        }

        It 'returns CloudRecord objects from all connected providers' {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.Providers['Azure'] = @{ Region = $null; Scope = 'prod-rg' }
                $script:PSCumulusContext.Providers['AWS']   = @{ Region = 'us-east-1'; Scope = $null }
                $script:PSCumulusContext.Providers['GCP']   = @{ Region = 'us-central1'; Scope = 'my-project' }

                Mock Get-AzureStorageData { [AzureStorageRecord]@{ Name = 'az-storage';  Provider = 'Azure' } }
                Mock Get-AWSStorageData   { [AWSStorageRecord]@{ Name = 'aws-storage'; Provider = 'AWS' } }
                Mock Get-GCPStorageData   { [GCPStorageRecord]@{ Name = 'gcp-storage'; Provider = 'GCP' } }

                $results = @(Get-CloudStorage -All)
                $results.Count | Should -Be 3
            }
        }

        It 'warns when a provider is skipped because it has no usable context' {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.Providers['AWS'] = @{ Region = $null; Scope = $null }

                Mock Write-Verbose {}
                Mock Get-AzureStorageData {}
                Mock Get-AWSStorageData {}
                Mock Get-GCPStorageData {}

                $null = Get-CloudStorage -All -Verbose

                Should -Invoke Get-AzureStorageData -Times 0
                Should -Invoke Get-AWSStorageData -Times 0
                Should -Invoke Get-GCPStorageData -Times 0
                Should -Invoke Write-Verbose -Times 1 -ParameterFilter {
                    $Message -match 'AWS \(no stored region\)'
                }
            }
        }
    }
}
