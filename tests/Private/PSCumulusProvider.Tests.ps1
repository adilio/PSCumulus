BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force

    # Check if SHiPS classes are available
    $script:ShipsProviderAvailable = $false
    try {
        $null = [CloudProviderRoot]
        $script:ShipsProviderAvailable = $true
    } catch {
        # SHiPS classes not available, tests will be skipped
    }
}

Describe 'CloudProviderRoot' -Skip:(-not $script:ShipsProviderAvailable) {
    BeforeEach {
        InModuleScope PSCumulus {
            $script:PSCumulusContext = @{
                ActiveProvider = $null
                Providers      = @{
                    Azure = $null
                    AWS   = @{ Region = 'us-east-1' }
                    GCP   = @{ Project = 'my-project' }
                }
            }
        }
    }

    It 'Returns scope nodes for Azure when context exists' {
        InModuleScope PSCumulus {
            Mock Get-AzResourceGroup { return @([pscustomobject]@{ ResourceGroupName = 'rg1' }, [pscustomobject]@{ ResourceGroupName = 'rg2' }) }

            $script:PSCumulusContext.Providers['Azure'] = @{ Subscription = 'test-sub' }

            $root = [CloudProviderRoot]::new('Azure')
            $children = $root.GetChildItem()

            $children.Count | Should -Be 2
            $children[0].GetType().Name | Should -Be 'CloudScopeNode'
            $children[0].ScopeName | Should -Be 'rg1'
            $children[1].ScopeName | Should -Be 'rg2'
        }
    }

    It 'Returns scope node for AWS from context' {
        InModuleScope PSCumulus {
            $root = [CloudProviderRoot]::new('AWS')
            $children = $root.GetChildItem()

            $children.Count | Should -Be 1
            $children[0].GetType().Name | Should -Be 'CloudScopeNode'
            $children[0].ScopeName | Should -Be 'us-east-1'
        }
    }

    It 'Returns scope node for GCP from context' {
        InModuleScope PSCumulus {
            $root = [CloudProviderRoot]::new('GCP')
            $children = $root.GetChildItem()

            $children.Count | Should -Be 1
            $children[0].GetType().Name | Should -Be 'CloudScopeNode'
            $children[0].ScopeName | Should -Be 'my-project'
        }
    }

    It 'Returns empty array when no context exists' {
        InModuleScope PSCumulus {
            $root = [CloudProviderRoot]::new('Azure')
            $children = $root.GetChildItem()

            $children.Count | Should -Be 0
        }
    }
}

Describe 'CloudScopeNode' -Skip:(-not $script:ShipsProviderAvailable) {
    It 'Returns six kind nodes' {
        InModuleScope PSCumulus {
            $scope = [CloudScopeNode]::new('test-rg', 'Azure', 'test-rg')
            $children = $scope.GetChildItem()

            $children.Count | Should -Be 6
            $children[0].GetType().Name | Should -Be 'CloudKindNode'

            $kindNames = $children | ForEach-Object { $_.KindName }
            $kindNames | Should -Contain 'Instances'
            $kindNames | Should -Contain 'Disks'
            $kindNames | Should -Contain 'Storage'
            $kindNames | Should -Contain 'Networks'
            $kindNames | Should -Contain 'Functions'
            $kindNames | Should -Contain 'Tags'
        }
    }
}

Describe 'CloudKindNode' -Skip:(-not $script:ShipsProviderAvailable) {
    BeforeEach {
        InModuleScope PSCumulus {
            $script:PSCumulusContext = @{
                ActiveProvider = 'Azure'
                Providers      = @{
                    Azure = @{ Subscription = 'test-sub' }
                    AWS   = $null
                    GCP   = $null
                }
            }
        }
    }

    It 'Returns resource leaf nodes from backend data function' {
        InModuleScope PSCumulus {
            Mock Get-AzureInstanceData {
                $record = [AzureCloudRecord]::new()
                $record.Name = 'vm1'
                $record.Kind = 'Instance'
                $record.Provider = 'Azure'
                return @($record)
            }

            $kind = [CloudKindNode]::new('Instances', 'Azure', 'test-rg')
            $children = $kind.GetChildItem()

            $children.Count | Should -Be 1
            $children[0].GetType().Name | Should -Be 'CloudResourceLeaf'
            $children[0].Name | Should -Be 'vm1'
        }
    }
}

Describe 'CloudResourceLeaf' -Skip:(-not $script:ShipsProviderAvailable) {
    It 'Wraps a CloudRecord object' {
        InModuleScope PSCumulus {
            $record = [CloudRecord]::new()
            $record.Name = 'test-resource'
            $record.Provider = 'Azure'

            $leaf = [CloudResourceLeaf]::new('test-resource', $record)
            $leaf.Name | Should -Be 'test-resource'
            $leaf.Record | Should -Not -Be $null
            $leaf.Record.Name | Should -Be 'test-resource'
        }
    }
}
