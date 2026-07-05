BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
}

Describe 'Get-CloudImage' {

    Context 'parameter validation' {
        It 'requires -ResourceGroup in the Azure parameter set' {
            Should-HaveMandatoryParameter -CommandName 'Get-CloudImage' -ParameterSetName 'Azure' -ParameterName 'ResourceGroup'
        }

        It 'requires -Region in the AWS parameter set' {
            Should-HaveMandatoryParameter -CommandName 'Get-CloudImage' -ParameterSetName 'AWS' -ParameterName 'Region'
        }

        It 'requires -Project in the GCP parameter set' {
            Should-HaveMandatoryParameter -CommandName 'Get-CloudImage' -ParameterSetName 'GCP' -ParameterName 'Project'
        }

        It 'has no -Status parameter (images share no status vocabulary)' {
            (Get-Command Get-CloudImage).Parameters.ContainsKey('Status') | Should -BeFalse
        }

        It 'throws on an invalid provider' {
            { Get-CloudImage -Provider Oracle -ResourceGroup 'rg' } | Should -Throw
        }
    }

    Context 'provider dispatch' {
        It 'calls Get-AzureImageData for Azure' {
            InModuleScope PSCumulus {
                Mock Get-AzureImageData {
                    [AzureImageRecord]@{ Name = 'img-01'; Provider = 'Azure' }
                }

                Get-CloudImage -Provider Azure -ResourceGroup 'prod-rg'
                Should -Invoke Get-AzureImageData -Times 1
            }
        }

        It 'calls Get-AWSImageData for AWS with the region' {
            InModuleScope PSCumulus {
                Mock Get-AWSImageData {
                    param([string]$Region)
                    [AWSImageRecord]@{ Name = 'img-01'; Provider = 'AWS'; Metadata = @{ Region = $Region } }
                }

                $result = Get-CloudImage -Provider AWS -Region 'us-east-1'
                $result.Metadata.Region | Should -Be 'us-east-1'
            }
        }

        It 'calls Get-GCPImageData for GCP with the project' {
            InModuleScope PSCumulus {
                Mock Get-GCPImageData {
                    param([string]$Project)
                    [GCPImageRecord]@{ Name = 'img-01'; Provider = 'GCP'; Metadata = @{ Project = $Project } }
                }

                $result = Get-CloudImage -Provider GCP -Project 'my-project'
                $result.Metadata.Project | Should -Be 'my-project'
            }
        }
    }

    Context 'output shape' {
        It 'returns CloudRecord objects with Kind Image' {
            InModuleScope PSCumulus {
                Mock Get-AzureImageData {
                    $record = [AzureImageRecord]::new()
                    $record.Name = 'img-01'
                    $record.Provider = 'Azure'
                    $record.Kind = 'Image'
                    $record
                }

                $result = Get-CloudImage -Provider Azure -ResourceGroup 'rg'
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRecord'
                $result.Kind | Should -Be 'Image'
            }
        }

        It 'filters by -Name' {
            InModuleScope PSCumulus {
                Mock Get-AzureImageData {
                    @(
                        [AzureImageRecord]@{ Name = 'img-a'; Provider = 'Azure' },
                        [AzureImageRecord]@{ Name = 'img-b'; Provider = 'Azure' }
                    )
                }

                $result = Get-CloudImage -Provider Azure -ResourceGroup 'rg' -Name 'img-b'
                @($result).Count | Should -Be 1
                $result.Name | Should -Be 'img-b'
            }
        }

        It 'adds the detailed type name when -Detailed is specified' {
            InModuleScope PSCumulus {
                Mock Get-AzureImageData {
                    [AzureImageRecord]@{ Name = 'img-01'; Provider = 'Azure' }
                }

                $result = Get-CloudImage -Provider Azure -ResourceGroup 'rg' -Detailed
                $result.PSObject.TypeNames[0] | Should -Be 'PSCumulus.CloudRecord.Detailed'
            }
        }
    }

    Context '-All across providers' {
        It 'skips providers without a stored context and reports via verbose' {
            InModuleScope PSCumulus {
                Mock Get-AzureImageData { [AzureImageRecord]@{ Name = 'img-az'; Provider = 'Azure' } }
                Mock Get-AWSImageData { [AWSImageRecord]@{ Name = 'img-aws'; Provider = 'AWS' } }
                Mock Get-GCPImageData { [GCPImageRecord]@{ Name = 'img-gcp'; Provider = 'GCP' } }

                $script:PSCumulusContext = @{
                    Providers = @{
                        Azure = @{ Account = 'a@b.c'; Connected = $true }
                    }
                    ActiveProvider = 'Azure'
                }

                $verboseOutput = Get-CloudImage -All -Verbose 4>&1
                $verboseMessages = $verboseOutput | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] }

                ($verboseMessages | Out-String) | Should -Match 'skipped'
                Should -Invoke Get-AzureImageData -Times 1
                Should -Invoke Get-AWSImageData -Times 0
                Should -Invoke Get-GCPImageData -Times 0
            }
        }
    }
}
