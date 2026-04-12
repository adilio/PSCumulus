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

        It 'makes Name optional in the Azure parameter set' {
            Should-HaveOptionalParameter `
                -CommandName 'Get-CloudInstance' `
                -ParameterSetName 'Azure' `
                -ParameterName 'Name'
        }

        It 'makes Name optional in the AWS parameter set' {
            Should-HaveOptionalParameter `
                -CommandName 'Get-CloudInstance' `
                -ParameterSetName 'AWS' `
                -ParameterName 'Name'
        }

        It 'makes Name optional in the GCP parameter set' {
            Should-HaveOptionalParameter `
                -CommandName 'Get-CloudInstance' `
                -ParameterSetName 'GCP' `
                -ParameterName 'Name'
        }

        It 'makes Detailed optional in every parameter set' {
            foreach ($parameterSet in 'Azure', 'AWS', 'GCP', 'All') {
                Should-HaveOptionalParameter `
                    -CommandName 'Get-CloudInstance' `
                    -ParameterSetName $parameterSet `
                    -ParameterName 'Detailed'
            }
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

        It 'passes Name to the Azure backend when provided' {
            InModuleScope PSCumulus {
                Mock Get-AzureInstanceData {
                    param([string]$ResourceGroup, [string]$Name)
                    ConvertTo-CloudRecord -Name $Name -Provider Azure -Metadata @{ RG = $ResourceGroup }
                }

                $result = Get-CloudInstance -Provider Azure -ResourceGroup 'my-rg' -Name 'vm01'
                $result.Name | Should -Be 'vm01'
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

        It 'adds the detailed type name when Detailed is specified' {
            InModuleScope PSCumulus {
                Mock Get-AzureInstanceData {
                    ConvertTo-CloudRecord -Name 'vm01' -Provider Azure -Region 'eastus' -Status 'Running'
                }

                $result = Get-CloudInstance -Provider Azure -ResourceGroup 'rg' -Detailed
                $result.PSObject.TypeNames[0] | Should -Be 'PSCumulus.CloudRecord.Detailed'
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

        It 'passes Name to the AWS backend when provided' {
            InModuleScope PSCumulus {
                Mock Get-AWSInstanceData {
                    param([string]$Region, [string]$Name)
                    ConvertTo-CloudRecord -Name $Name -Provider AWS -Region $Region
                }

                $result = Get-CloudInstance -Provider AWS -Region 'ap-southeast-1' -Name 'app-server-01'
                $result.Name | Should -Be 'app-server-01'
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

        It 'passes Name to the GCP backend when provided' {
            InModuleScope PSCumulus {
                Mock Get-GCPInstanceData {
                    param([string]$Project, [string]$Name)
                    ConvertTo-CloudRecord -Name $Name -Provider GCP -Metadata @{ Proj = $Project }
                }

                $result = Get-CloudInstance -Provider GCP -Project 'prod-gcp' -Name 'gcp-vm'
                $result.Name | Should -Be 'gcp-vm'
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
                $script:PSCumulusContext.Providers['Azure'] = @{ Region = $null; Scope = $null }
                $script:PSCumulusContext.Providers['AWS']   = @{ Region = 'us-east-1'; Scope = $null }
                $script:PSCumulusContext.Providers['GCP']   = @{ Region = 'us-central1'; Scope = 'my-project' }

                Mock Get-AzureInstanceData { ConvertTo-CloudRecord -Name 'az-vm' -Provider Azure }
                Mock Get-AWSInstanceData   { ConvertTo-CloudRecord -Name 'aws-vm' -Provider AWS }
                Mock Get-GCPInstanceData   { ConvertTo-CloudRecord -Name 'gcp-vm' -Provider GCP }

                $null = Get-CloudInstance -All

                Should -Invoke Get-AzureInstanceData -Times 1
                Should -Invoke Get-AWSInstanceData   -Times 1
                Should -Invoke Get-GCPInstanceData   -Times 1
            }
        }

        It 'skips providers with no stored context' {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.Providers['AWS'] = @{ Region = 'us-east-1'; Scope = $null }

                Mock Get-AzureInstanceData { ConvertTo-CloudRecord -Name 'az-vm' -Provider Azure }
                Mock Get-AWSInstanceData   { ConvertTo-CloudRecord -Name 'aws-vm' -Provider AWS }
                Mock Get-GCPInstanceData   { ConvertTo-CloudRecord -Name 'gcp-vm' -Provider GCP }

                $null = Get-CloudInstance -All

                Should -Invoke Get-AWSInstanceData   -Times 1
                Should -Invoke Get-AzureInstanceData -Times 0
                Should -Invoke Get-GCPInstanceData   -Times 0
            }
        }

        It 'passes stored Region to the AWS backend' {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.Providers['AWS'] = @{ Region = 'eu-west-1'; Scope = $null }

                Mock Get-AWSInstanceData { ConvertTo-CloudRecord -Name 'aws-vm' -Provider AWS }

                $null = Get-CloudInstance -All

                Should -Invoke Get-AWSInstanceData -Times 1 -ParameterFilter { $Region -eq 'eu-west-1' }
            }
        }

        It 'passes stored Scope as Project to the GCP backend' {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.Providers['GCP'] = @{ Region = 'us-central1'; Scope = 'my-project' }

                Mock Get-GCPInstanceData { ConvertTo-CloudRecord -Name 'gcp-vm' -Provider GCP }

                $null = Get-CloudInstance -All

                Should -Invoke Get-GCPInstanceData -Times 1 -ParameterFilter { $Project -eq 'my-project' }
            }
        }

        It 'returns CloudRecord objects from all connected providers' {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.Providers['Azure'] = @{ Region = $null; Scope = $null }
                $script:PSCumulusContext.Providers['AWS']   = @{ Region = 'us-east-1'; Scope = $null }
                $script:PSCumulusContext.Providers['GCP']   = @{ Region = 'us-central1'; Scope = 'my-project' }

                Mock Get-AzureInstanceData { ConvertTo-CloudRecord -Name 'az-vm'  -Provider Azure }
                Mock Get-AWSInstanceData   { ConvertTo-CloudRecord -Name 'aws-vm' -Provider AWS }
                Mock Get-GCPInstanceData   { ConvertTo-CloudRecord -Name 'gcp-vm' -Provider GCP }

                $results = @(Get-CloudInstance -All)
                $results.Count | Should -Be 3
            }
        }

        It 'warns when a provider is skipped because it has no usable context' {
            InModuleScope PSCumulus {
                $script:PSCumulusContext.Providers['AWS'] = @{ Region = $null; Scope = $null }

                Mock Write-Verbose {}
                Mock Get-AzureInstanceData {}
                Mock Get-AWSInstanceData {}
                Mock Get-GCPInstanceData {}

                $null = Get-CloudInstance -All -Verbose

                Should -Invoke Get-AzureInstanceData -Times 0
                Should -Invoke Get-AWSInstanceData -Times 0
                Should -Invoke Get-GCPInstanceData -Times 0
                Should -Invoke Write-Verbose -Times 1 -ParameterFilter {
                    $Message -match 'AWS \(no stored region\)'
                }
            }
        }
    }
}
