BeforeAll {
    # Stub Az.Resources commands so Pester can create mocks when Az.Resources is not installed
    if (-not (Get-Command Get-AzTag -ErrorAction SilentlyContinue)) {
        $script:stubCreatedGetAzTag = $true
        function global:Get-AzTag { param([string]$ResourceId) }
    }

    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

AfterAll {
    if ($script:stubCreatedGetAzTag) {
        Remove-Item -Path Function:global:Get-AzTag -ErrorAction SilentlyContinue
    }
}

Describe 'Get-AzureTagData' {

    Context 'when Az.Resources is not installed' {
        It 'throws when Get-AzTag is unavailable' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {
                    throw [System.Management.Automation.CommandNotFoundException]::new(
                        "Required command 'Get-AzTag' was not found."
                    )
                }

                { Get-AzureTagData -ResourceId '/subscriptions/abc/vm/vm01' } | Should -Throw
            }
        }
    }

    Context 'when tags are returned' {
        BeforeAll {
            $script:mockTagWrapper = [pscustomobject]@{
                Properties = [pscustomobject]@{
                    TagsProperty = @{
                        Environment = 'production'
                        Team        = 'platform'
                    }
                }
            }
        }

        It 'returns a CloudRecord' {
            InModuleScope PSCumulus -Parameters @{ MockTagWrapper = $script:mockTagWrapper } {
                param($MockTagWrapper)
                Mock Assert-CommandAvailable {}
                Mock Get-AzTag { $MockTagWrapper }

                $result = Get-AzureTagData -ResourceId '/subscriptions/abc/virtualMachines/vm01'
                $result | Should -Not -BeNullOrEmpty
            }
        }

        It 'sets Name to the last segment of ResourceId' {
            InModuleScope PSCumulus -Parameters @{ MockTagWrapper = $script:mockTagWrapper } {
                param($MockTagWrapper)
                Mock Assert-CommandAvailable {}
                Mock Get-AzTag { $MockTagWrapper }

                $result = Get-AzureTagData -ResourceId '/subscriptions/abc/virtualMachines/vm01'
                $result.Name | Should -Be 'vm01'
            }
        }

        It 'sets Provider to Azure' {
            InModuleScope PSCumulus -Parameters @{ MockTagWrapper = $script:mockTagWrapper } {
                param($MockTagWrapper)
                Mock Assert-CommandAvailable {}
                Mock Get-AzTag { $MockTagWrapper }

                $result = Get-AzureTagData -ResourceId '/subscriptions/abc/virtualMachines/vm01'
                $result.Provider | Should -Be 'Azure'
            }
        }

        It 'includes ResourceId in Metadata' {
            InModuleScope PSCumulus -Parameters @{ MockTagWrapper = $script:mockTagWrapper } {
                param($MockTagWrapper)
                Mock Assert-CommandAvailable {}
                Mock Get-AzTag { $MockTagWrapper }

                $result = Get-AzureTagData -ResourceId '/subscriptions/abc/virtualMachines/vm01'
                $result.Metadata.ResourceId | Should -Be '/subscriptions/abc/virtualMachines/vm01'
            }
        }

        It 'includes Tags in Metadata' {
            InModuleScope PSCumulus -Parameters @{ MockTagWrapper = $script:mockTagWrapper } {
                param($MockTagWrapper)
                Mock Assert-CommandAvailable {}
                Mock Get-AzTag { $MockTagWrapper }

                $result = Get-AzureTagData -ResourceId '/subscriptions/abc/virtualMachines/vm01'
                $result.Metadata.Tags['Environment'] | Should -Be 'production'
                $result.Metadata.Tags['Team'] | Should -Be 'platform'
            }
        }

        It 'returns PSCumulus.CloudRecord type' {
            InModuleScope PSCumulus -Parameters @{ MockTagWrapper = $script:mockTagWrapper } {
                param($MockTagWrapper)
                Mock Assert-CommandAvailable {}
                Mock Get-AzTag { $MockTagWrapper }

                $result = Get-AzureTagData -ResourceId '/subscriptions/abc/virtualMachines/vm01'
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRecord'
            }
        }

        It 'returns empty Tags hashtable when resource has no tags' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Get-AzTag {
                    [pscustomobject]@{
                        Properties = [pscustomobject]@{ TagsProperty = @{} }
                    }
                }

                $result = Get-AzureTagData -ResourceId '/subscriptions/abc/virtualMachines/vm02'
                $result.Metadata.Tags.Count | Should -Be 0
            }
        }
    }
}
