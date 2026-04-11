@{
    RootModule        = 'PSCumulus.psm1'
    ModuleVersion     = '0.2.0'
    GUID              = '9e7bb15e-7fc3-47ec-a6f9-86a8b4478fd7'
    Author            = 'Adil Leghari'
    CompanyName       = 'Open Source'
    Copyright         = '(c) Adil. All rights reserved.'
    Description       = 'Cross-cloud PowerShell module for Azure, AWS, and GCP. Unified commands (Get-CloudInstance, Get-CloudStorage, etc.) return normalized objects with a consistent output shape across all three providers.'
    PowerShellVersion = '7.4'

    FormatsToProcess  = @('PSCumulus.Format.ps1xml')

    FunctionsToExport = @(
        'Connect-Cloud',
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
0.1.0
- Connect-Cloud: unified auth for Azure, AWS, and GCP; accepts array of providers
- Get-CloudInstance -All: query all connected providers in one pipeline
- Tags property on all CloudRecord objects, normalized across providers
- Get-CloudStorage, Get-CloudDisk, Get-CloudNetwork, Get-CloudFunction
- Start-CloudInstance, Stop-CloudInstance
- Get-CloudContext, Get-CloudTag
'@
        }
    }
}
