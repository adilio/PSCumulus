BeforeAll {
    if (-not (Get-Command Get-EC2Image -ErrorAction SilentlyContinue)) {
        $script:stubCreatedGetEC2Image = $true
        function global:Get-EC2Image { param([string[]]$Owner, [string]$Region) }
    }

    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

AfterAll {
    if ($script:stubCreatedGetEC2Image) {
        Remove-Item -Path Function:global:Get-EC2Image -ErrorAction SilentlyContinue
    }
}

Describe 'Get-AWSImageData' {

    Context 'when images are returned' {
        BeforeAll {
            $script:mockImage = [pscustomobject]@{
                ImageId         = 'ami-0abc123'
                Name            = 'golden-api-2026'
                CreationDate    = '2026-01-20T10:00:00.000Z'
                State           = [pscustomobject]@{ Value = 'available' }
                OwnerId         = '123456789012'
                PlatformDetails = 'Linux/UNIX'
                Description     = 'golden image'
            }
        }

        It 'returns a normalized image record' {
            InModuleScope PSCumulus -Parameters @{ MockImage = $script:mockImage } {
                param($MockImage)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Image { @($MockImage) }

                $result = Get-AWSImageData -Region 'us-east-1'
                $result.Name | Should -Be 'golden-api-2026'
                $result.Provider | Should -Be 'AWS'
                $result.Kind | Should -Be 'Image'
                $result.ImageId | Should -Be 'ami-0abc123'
                $result.Publisher | Should -Be '123456789012'
                $result.OsType | Should -Be 'Linux/UNIX'
            }
        }

        It 'requests only self-owned images' {
            InModuleScope PSCumulus -Parameters @{ MockImage = $script:mockImage } {
                param($MockImage)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Image { @($MockImage) }

                $null = Get-AWSImageData -Region 'us-east-1'
                Should -Invoke Get-EC2Image -Times 1 -ParameterFilter { $Owner -contains 'self' -and $Region -eq 'us-east-1' }
            }
        }
    }
}
