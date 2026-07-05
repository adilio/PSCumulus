BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
    . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
}

Describe 'Get-CloudSnapshot' {

    Context 'parameter validation' {
        It 'requires -ResourceGroup in the Azure parameter set' {
            Should-HaveMandatoryParameter -CommandName 'Get-CloudSnapshot' -ParameterSetName 'Azure' -ParameterName 'ResourceGroup'
        }

        It 'requires -Region in the AWS parameter set' {
            Should-HaveMandatoryParameter -CommandName 'Get-CloudSnapshot' -ParameterSetName 'AWS' -ParameterName 'Region'
        }

        It 'requires -Project in the GCP parameter set' {
            Should-HaveMandatoryParameter -CommandName 'Get-CloudSnapshot' -ParameterSetName 'GCP' -ParameterName 'Project'
        }

        It 'has no -Status parameter (snapshots share no status vocabulary)' {
            (Get-Command Get-CloudSnapshot).Parameters.ContainsKey('Status') | Should -BeFalse
        }

        It 'throws on an invalid provider' {
            { Get-CloudSnapshot -Provider Oracle -ResourceGroup 'rg' } | Should -Throw
        }
    }

    Context 'provider dispatch' {
        It 'calls Get-AzureSnapshotData for Azure' {
            InModuleScope PSCumulus {
                Mock Get-AzureSnapshotData {
                    [AzureSnapshotRecord]@{ Name = 'snap-01'; Provider = 'Azure' }
                }

                Get-CloudSnapshot -Provider Azure -ResourceGroup 'prod-rg'
                Should -Invoke Get-AzureSnapshotData -Times 1
            }
        }

        It 'calls Get-AWSSnapshotData for AWS with the region' {
            InModuleScope PSCumulus {
                Mock Get-AWSSnapshotData {
                    param([string]$Region)
                    [AWSSnapshotRecord]@{ Name = 'snap-01'; Provider = 'AWS'; Metadata = @{ Region = $Region } }
                }

                $result = Get-CloudSnapshot -Provider AWS -Region 'us-east-1'
                $result.Metadata.Region | Should -Be 'us-east-1'
            }
        }

        It 'calls Get-GCPSnapshotData for GCP with the project' {
            InModuleScope PSCumulus {
                Mock Get-GCPSnapshotData {
                    param([string]$Project)
                    [GCPSnapshotRecord]@{ Name = 'snap-01'; Provider = 'GCP'; Metadata = @{ Project = $Project } }
                }

                $result = Get-CloudSnapshot -Provider GCP -Project 'my-project'
                $result.Metadata.Project | Should -Be 'my-project'
            }
        }
    }

    Context 'output shape' {
        It 'returns CloudRecord objects with Kind Snapshot' {
            InModuleScope PSCumulus {
                Mock Get-AzureSnapshotData {
                    $record = [AzureSnapshotRecord]::new()
                    $record.Name = 'snap-01'
                    $record.Provider = 'Azure'
                    $record.Kind = 'Snapshot'
                    $record
                }

                $result = Get-CloudSnapshot -Provider Azure -ResourceGroup 'rg'
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRecord'
                $result.Kind | Should -Be 'Snapshot'
            }
        }

        It 'filters by -Name' {
            InModuleScope PSCumulus {
                Mock Get-AzureSnapshotData {
                    @(
                        [AzureSnapshotRecord]@{ Name = 'snap-a'; Provider = 'Azure' },
                        [AzureSnapshotRecord]@{ Name = 'snap-b'; Provider = 'Azure' }
                    )
                }

                $result = Get-CloudSnapshot -Provider Azure -ResourceGroup 'rg' -Name 'snap-b'
                @($result).Count | Should -Be 1
                $result.Name | Should -Be 'snap-b'
            }
        }

        It 'adds the detailed type name when -Detailed is specified' {
            InModuleScope PSCumulus {
                Mock Get-AzureSnapshotData {
                    [AzureSnapshotRecord]@{ Name = 'snap-01'; Provider = 'Azure' }
                }

                $result = Get-CloudSnapshot -Provider Azure -ResourceGroup 'rg' -Detailed
                $result.PSObject.TypeNames[0] | Should -Be 'PSCumulus.CloudRecord.Detailed'
            }
        }
    }

    Context '-All across providers' {
        It 'skips providers without a stored context and reports via verbose' {
            InModuleScope PSCumulus {
                Mock Get-AzureSnapshotData { [AzureSnapshotRecord]@{ Name = 'snap-az'; Provider = 'Azure' } }
                Mock Get-AWSSnapshotData { [AWSSnapshotRecord]@{ Name = 'snap-aws'; Provider = 'AWS' } }
                Mock Get-GCPSnapshotData { [GCPSnapshotRecord]@{ Name = 'snap-gcp'; Provider = 'GCP' } }

                $script:PSCumulusContext = @{
                    Providers = @{
                        Azure = @{ Account = 'a@b.c'; Connected = $true }
                    }
                    ActiveProvider = 'Azure'
                }

                $verboseOutput = Get-CloudSnapshot -All -Verbose 4>&1
                $verboseMessages = $verboseOutput | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] }

                ($verboseMessages | Out-String) | Should -Match 'skipped'
                Should -Invoke Get-AzureSnapshotData -Times 1
                Should -Invoke Get-AWSSnapshotData -Times 0
                Should -Invoke Get-GCPSnapshotData -Times 0
            }
        }
    }
}
