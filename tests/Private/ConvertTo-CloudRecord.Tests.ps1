BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'ConvertTo-CloudRecord' {

    Context 'return type and type name' {
        It 'returns a PSCustomObject' {
            InModuleScope PSCumulus {
                $result = ConvertTo-CloudRecord -Name 'vm01' -Provider Azure
                $result | Should -BeOfType [pscustomobject]
            }
        }

        It 'stamps the PSCumulus.CloudRecord type name' {
            InModuleScope PSCumulus {
                $result = ConvertTo-CloudRecord -Name 'vm01' -Provider Azure
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRecord'
            }
        }

        It 'puts PSCumulus.CloudRecord at position 0' {
            InModuleScope PSCumulus {
                $result = ConvertTo-CloudRecord -Name 'vm01' -Provider Azure
                $result.PSObject.TypeNames[0] | Should -Be 'PSCumulus.CloudRecord'
            }
        }
    }

    Context 'required properties' {
        It 'sets Name correctly' {
            InModuleScope PSCumulus {
                $result = ConvertTo-CloudRecord -Name 'my-server' -Provider AWS
                $result.Name | Should -Be 'my-server'
            }
        }

        It 'sets Provider correctly' {
            InModuleScope PSCumulus {
                $result = ConvertTo-CloudRecord -Name 'vm' -Provider GCP
                $result.Provider | Should -Be 'GCP'
            }
        }
    }

    Context 'optional properties' {
        It 'sets Region when provided' {
            InModuleScope PSCumulus {
                $result = ConvertTo-CloudRecord -Name 'vm' -Provider Azure -Region 'eastus'
                $result.Region | Should -Be 'eastus'
            }
        }

        It 'sets Status when provided' {
            InModuleScope PSCumulus {
                $result = ConvertTo-CloudRecord -Name 'vm' -Provider AWS -Status 'Running'
                $result.Status | Should -Be 'Running'
            }
        }

        It 'sets Size when provided' {
            InModuleScope PSCumulus {
                $result = ConvertTo-CloudRecord -Name 'vm' -Provider Azure -Size 'Standard_D2s_v3'
                $result.Size | Should -Be 'Standard_D2s_v3'
            }
        }

        It 'sets CreatedAt when provided' {
            InModuleScope PSCumulus {
                $ts = [datetime]'2026-01-01T00:00:00Z'
                $result = ConvertTo-CloudRecord -Name 'vm' -Provider AWS -CreatedAt $ts
                $result.CreatedAt | Should -Be $ts
            }
        }

        It 'sets Metadata when provided' {
            InModuleScope PSCumulus {
                $meta = @{ VpcId = 'vpc-123'; InstanceId = 'i-abc' }
                $result = ConvertTo-CloudRecord -Name 'vm' -Provider AWS -Metadata $meta
                $result.Metadata.VpcId | Should -Be 'vpc-123'
                $result.Metadata.InstanceId | Should -Be 'i-abc'
            }
        }

        It 'defaults Metadata to an empty hashtable' {
            InModuleScope PSCumulus {
                $result = ConvertTo-CloudRecord -Name 'vm' -Provider GCP
                $result.Metadata | Should -BeOfType [hashtable]
                $result.Metadata.Count | Should -Be 0
            }
        }

        It 'defaults Tags to an empty hashtable' {
            InModuleScope PSCumulus {
                $result = ConvertTo-CloudRecord -Name 'vm' -Provider GCP
                $result.Tags | Should -BeOfType [hashtable]
                $result.Tags.Count | Should -Be 0
            }
        }

        It 'sets Tags when provided' {
            InModuleScope PSCumulus {
                $tags = @{ environment = 'prod'; team = 'platform' }
                $result = ConvertTo-CloudRecord -Name 'vm' -Provider AWS -Tags $tags
                $result.Tags['environment'] | Should -Be 'prod'
                $result.Tags['team'] | Should -Be 'platform'
            }
        }
    }

    Context 'all standard properties are present' {
        It 'has all seven top-level properties' {
            InModuleScope PSCumulus {
                $result = ConvertTo-CloudRecord -Name 'vm' -Provider Azure
                $result.PSObject.Properties.Name | Should -Contain 'Name'
                $result.PSObject.Properties.Name | Should -Contain 'Provider'
                $result.PSObject.Properties.Name | Should -Contain 'Region'
                $result.PSObject.Properties.Name | Should -Contain 'Status'
                $result.PSObject.Properties.Name | Should -Contain 'Size'
                $result.PSObject.Properties.Name | Should -Contain 'CreatedAt'
                $result.PSObject.Properties.Name | Should -Contain 'Tags'
                $result.PSObject.Properties.Name | Should -Contain 'Metadata'
            }
        }
    }
}
