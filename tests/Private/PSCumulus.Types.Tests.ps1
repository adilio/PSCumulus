BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'PSCumulus internal types' {

    Context 'CloudInstanceStatusMap' {
        It 'maps AWS states through the static helper' {
            InModuleScope PSCumulus {
                ([CloudInstanceStatusMap]::FromAws('shutting-down')).ToString() | Should -BeExactly 'Terminating'
                ([CloudInstanceStatusMap]::FromAws('terminated')).ToString() | Should -BeExactly 'Terminated'
            }
        }

        It 'maps Azure states through the static helper' {
            InModuleScope PSCumulus {
                ([CloudInstanceStatusMap]::FromAzure('VM deallocated')).ToString() | Should -BeExactly 'Stopped'
            }
        }

        It 'maps GCP states through the static helper' {
            InModuleScope PSCumulus {
                ([CloudInstanceStatusMap]::FromGcp('TERMINATED')).ToString() | Should -BeExactly 'Stopped'
                ([CloudInstanceStatusMap]::FromGcp('SUSPENDED')).ToString() | Should -BeExactly 'Suspended'
            }
        }
    }

    Context 'CloudTagHelper' {
        It 'returns plain hashtables from the read helpers' {
            InModuleScope PSCumulus {
                $awsTags = [CloudTagHelper]::FromAwsTags(@([pscustomobject]@{ Key = 'Owner'; Value = 'alice' }))
                $azureTags = [CloudTagHelper]::FromAzureTags(@{ Team = 'platform' })
                $gcpTags = [CloudTagHelper]::FromGcpLabels([pscustomobject]@{ env = 'prod' })

                $awsTags | Should -BeOfType [hashtable]
                $azureTags | Should -BeOfType [hashtable]
                $gcpTags | Should -BeOfType [hashtable]
            }
        }

        It 'preserves case-insensitive lookup on returned hashtables' {
            InModuleScope PSCumulus {
                $tags = [CloudTagHelper]::FromAwsTags(@([pscustomobject]@{ Key = 'Owner'; Value = 'alice' }))
                $tags['owner'] | Should -Be 'alice'
            }
        }

        It 'preserves original key casing for enumeration on first insert' {
            InModuleScope PSCumulus {
                $tags = [CloudTagHelper]::FromAwsTags(@([pscustomobject]@{ Key = 'Owner'; Value = 'alice' }))
                (@($tags.GetEnumerator())[0]).Key | Should -BeExactly 'Owner'
            }
        }

        It 'copies Azure tags without complex transformation' {
            InModuleScope PSCumulus {
                $source = @{ Environment = 'prod'; Team = 'platform' }
                $copy = [CloudTagHelper]::FromAzureTags($source)

                $copy['Environment'] | Should -Be 'prod'
                $copy['Team'] | Should -Be 'platform'
                [object]::ReferenceEquals($copy, $source) | Should -BeFalse
            }
        }

        It 'converts GCP labels from object properties' {
            InModuleScope PSCumulus {
                $tags = [CloudTagHelper]::FromGcpLabels([pscustomobject]@{ env = 'prod'; cost_center = 'ops' })
                $tags['env'] | Should -Be 'prod'
                $tags['cost_center'] | Should -Be 'ops'
            }
        }

        It 'emits AWS tags as key/value objects' {
            InModuleScope PSCumulus {
                $awsTags = [CloudTagHelper]::ToAwsTags(@{ Owner = 'alice' })
                $awsTags.Count | Should -Be 1
                $awsTags[0].Key | Should -BeExactly 'Owner'
                $awsTags[0].Value | Should -BeExactly 'alice'
            }
        }

        It 'rejects invalid GCP label keys in ToGcpLabels' {
            InModuleScope PSCumulus {
                { [CloudTagHelper]::ToGcpLabels(@{ Owner = 'alice' }) } | Should -Throw
            }
        }
    }

    Context 'CloudRecord classes' {
        It 'creates a base record with PSCumulus.CloudRecord type-name compatibility' {
            InModuleScope PSCumulus {
                $record = [CloudRecord]::new()

                $record.Tags | Should -BeOfType [hashtable]
                $record.Metadata | Should -BeOfType [hashtable]
                $record.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRecord'
            }
        }

        It 'creates AzureCloudRecord instances with first-class provider properties' {
            InModuleScope PSCumulus {
                $vm = [pscustomobject]@{
                    Name              = 'web-01'
                    Location          = 'eastus'
                    ResourceGroupName = 'prod-rg'
                    VmId              = 'vm-guid-123'
                    HardwareProfile   = [pscustomobject]@{ VmSize = 'Standard_D2s_v3' }
                    StorageProfile    = [pscustomobject]@{
                        OsDisk = [pscustomobject]@{ OsType = 'Linux' }
                    }
                    Tags              = @{ env = 'prod' }
                    Statuses          = @(
                        [pscustomobject]@{ Code = 'PowerState/running'; DisplayStatus = 'VM running' }
                    )
                }

                $record = [AzureCloudRecord]::FromAzVM($vm, [pscustomobject]@{
                    PrivateIpAddress = '10.0.0.4'
                    PublicIpAddress  = '52.1.2.3'
                })

                $record.PSObject.TypeNames | Should -Contain 'PSCumulus.AzureCloudRecord'
                $record.Kind | Should -Be 'Instance'
                $record.ResourceGroup | Should -Be 'prod-rg'
                $record.VmId | Should -Be 'vm-guid-123'
                $record.OsType | Should -Be 'Linux'
                $record.Metadata.NativeStatus | Should -Be 'VM running'
                $record.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRecord'
            }
        }

        It 'uses Unknown when Azure power state is missing' {
            InModuleScope PSCumulus {
                $vm = [pscustomobject]@{
                    Name              = 'offline-vm'
                    Location          = 'eastus'
                    ResourceGroupName = 'prod-rg'
                    VmId              = 'vm-guid-offline'
                    HardwareProfile   = [pscustomobject]@{ VmSize = 'Standard_D2s_v3' }
                    StorageProfile    = [pscustomobject]@{
                        OsDisk = [pscustomobject]@{ OsType = 'Linux' }
                    }
                    Statuses          = @()
                }

                $record = [AzureCloudRecord]::FromAzVM($vm, [pscustomobject]@{})
                $record.Status | Should -Be 'Unknown'
            }
        }
    }
}
