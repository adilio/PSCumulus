BeforeAll {
    if (-not (Get-Command Get-AzSnapshot -ErrorAction SilentlyContinue)) {
        $script:stubCreatedGetAzSnapshot = $true
        function global:Get-AzSnapshot { param([string]$ResourceGroupName) }
    }

    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

AfterAll {
    if ($script:stubCreatedGetAzSnapshot) {
        Remove-Item -Path Function:global:Get-AzSnapshot -ErrorAction SilentlyContinue
    }
}

Describe 'Get-AzureSnapshotData' {

    Context 'when Az.Compute is not installed' {
        It 'throws when Get-AzSnapshot is unavailable' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {
                    throw [System.Management.Automation.CommandNotFoundException]::new(
                        "Required command 'Get-AzSnapshot' was not found."
                    )
                }

                { Get-AzureSnapshotData -ResourceGroup 'prod-rg' } | Should -Throw
            }
        }
    }

    Context 'when snapshots are returned' {
        BeforeAll {
            $script:mockSnapshot = [pscustomobject]@{
                Name              = 'nightly-data-01'
                ResourceGroupName = 'prod-rg'
                Location          = 'eastus'
                DiskSizeGB        = 256
                ProvisioningState = 'Succeeded'
                Incremental       = $true
                Sku               = [pscustomobject]@{ Name = 'Standard_LRS' }
                TimeCreated       = [datetime]'2026-02-01T02:00:00Z'
                CreationData      = [pscustomobject]@{ SourceResourceId = '/subscriptions/1/resourceGroups/prod-rg/providers/Microsoft.Compute/disks/data-01' }
            }
        }

        It 'returns a normalized snapshot record' {
            InModuleScope PSCumulus -Parameters @{ MockSnapshot = $script:mockSnapshot } {
                param($MockSnapshot)
                Mock Assert-CommandAvailable {}
                Mock Get-AzSnapshot { @($MockSnapshot) }

                $result = Get-AzureSnapshotData -ResourceGroup 'prod-rg'
                $result.Name | Should -Be 'nightly-data-01'
                $result.Provider | Should -Be 'Azure'
                $result.Kind | Should -Be 'Snapshot'
                $result.SizeGB | Should -Be 256
                $result.SourceDiskId | Should -Be '/subscriptions/1/resourceGroups/prod-rg/providers/Microsoft.Compute/disks/data-01'
                $result.CreatedAt | Should -Be ([datetime]'2026-02-01T02:00:00Z')
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRecord'
            }
        }

        It 'passes ResourceGroup to Get-AzSnapshot when provided' {
            InModuleScope PSCumulus -Parameters @{ MockSnapshot = $script:mockSnapshot } {
                param($MockSnapshot)
                Mock Assert-CommandAvailable {}
                Mock Get-AzSnapshot { @($MockSnapshot) }

                $null = Get-AzureSnapshotData -ResourceGroup 'prod-rg'
                Should -Invoke Get-AzSnapshot -Times 1 -ParameterFilter { $ResourceGroupName -eq 'prod-rg' }
            }
        }
    }
}
