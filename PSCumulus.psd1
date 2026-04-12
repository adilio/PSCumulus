@{
    RootModule        = 'PSCumulus.psm1'
    ModuleVersion     = '0.1.2'
    GUID              = '9e7bb15e-7fc3-47ec-a6f9-86a8b4478fd7'
    Author            = 'Adil Leghari'
    CompanyName       = 'Open Source'
    Copyright         = '(c) Adil. All rights reserved.'
    Description       = 'Cross-cloud PowerShell module for Azure, AWS, and GCP. Unified commands (Get-CloudInstance, Get-CloudStorage, etc.) return normalized objects with a consistent output shape across all three providers.'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')

    FormatsToProcess  = @('PSCumulus.Format.ps1xml')

    FunctionsToExport = @(
        'Connect-Cloud',
        'Disconnect-Cloud',
        'Get-CloudContext',
        'Get-CloudInstance',
        'Get-CloudStorage',
        'Get-CloudTag',
        'Get-CloudNetwork',
        'Get-CloudDisk',
        'Get-CloudFunction',
        'Start-CloudInstance',
        'Stop-CloudInstance'
    )

    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @(
        'conc',
        'gcont',
        'gcin',
        'sci',
        'tci'
    )

    PrivateData = @{
        PSData = @{
            Tags         = @('PowerShell', 'Cloud', 'Azure', 'AWS', 'GCP', 'MultiCloud', 'DevOps')
            ProjectUri   = 'https://github.com/adilio/PSCumulus'
            LicenseUri   = 'https://opensource.org/licenses/MIT'
            ReleaseNotes = @'
0.1.2
- Added scoped Disconnect-Cloud for Azure, AWS, and GCP
- Get-CloudInstance now supports name filtering, detailed output, and richer instance metadata
- Cloud context now reads Current vs Connected, with friendlier Azure VM state handling
- Azure tenant/subscription support, AWS instance parsing, and CI docs/test stability were improved

0.1.1
- Added demo setup and talk materials with simulated multi-cloud data and richer examples
- Added CloudRecord Tags, Connect-Cloud array-provider support, and Get-CloudInstance -All
- Prepared the manifest and docs for PSGallery install flow
- Refined the normalization philosophy and docs to match the cross-cloud design

0.1.0
- Initial release with Connect-Cloud, Get-CloudContext, inventory commands, lifecycle commands, and normalized cross-cloud output
'@
        }
    }
}
