BeforeAll {
    if (-not (Get-Command Get-AzImage -ErrorAction SilentlyContinue)) {
        $script:stubCreatedGetAzImage = $true
        function global:Get-AzImage { param([string]$ResourceGroupName) }
    }

    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

AfterAll {
    if ($script:stubCreatedGetAzImage) {
        Remove-Item -Path Function:global:Get-AzImage -ErrorAction SilentlyContinue
    }
}

Describe 'Get-AzureImageData' {

    Context 'when images are returned' {
        BeforeAll {
            $script:mockImage = [pscustomobject]@{
                Name                 = 'golden-web-2026'
                ResourceGroupName    = 'images-rg'
                Location             = 'eastus'
                Id                   = '/subscriptions/1/resourceGroups/images-rg/providers/Microsoft.Compute/images/golden-web-2026'
                ProvisioningState    = 'Succeeded'
                StorageProfile       = [pscustomobject]@{ OsDisk = [pscustomobject]@{ OsType = 'Linux' } }
                SourceVirtualMachine = [pscustomobject]@{ Id = '/subscriptions/1/vm/web-01' }
            }
        }

        It 'returns a normalized image record' {
            InModuleScope PSCumulus -Parameters @{ MockImage = $script:mockImage } {
                param($MockImage)
                Mock Assert-CommandAvailable {}
                Mock Get-AzImage { @($MockImage) }

                $result = Get-AzureImageData -ResourceGroup 'images-rg'
                $result.Name | Should -Be 'golden-web-2026'
                $result.Provider | Should -Be 'Azure'
                $result.Kind | Should -Be 'Image'
                $result.OsType | Should -Be 'Linux'
                $result.ImageId | Should -Match 'images/golden-web-2026'
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRecord'
            }
        }
    }
}
