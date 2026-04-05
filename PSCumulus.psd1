@{
    RootModule        = 'PSCumulus.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '9e7bb15e-7fc3-47ec-a6f9-86a8b4478fd7'
    Author            = 'Adil Leghari'
    CompanyName       = 'Open Source'
    Copyright         = '(c) Adil. All rights reserved.'
    Description       = 'Thin cross-cloud PowerShell abstraction for Azure, AWS, and GCP.'
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
            Tags         = @('PowerShell', 'Cloud', 'Azure', 'AWS', 'GCP')
            ProjectUri   = 'https://github.com/adilio/PSCumulus'
            LicenseUri   = 'https://opensource.org/licenses/MIT'
            ReleaseNotes = 'Initial scaffold for Summit talk proof of concept.'
        }
    }
}
