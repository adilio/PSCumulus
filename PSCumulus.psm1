$script:PSCumulusContext = @{
    ActiveProvider = $null
    Providers      = @{
        Azure = $null
        AWS   = $null
        GCP   = $null
    }
}

$publicPath = Join-Path -Path $PSScriptRoot -ChildPath 'Public'
$privatePath = Join-Path -Path $PSScriptRoot -ChildPath 'Private'

foreach ($path in @($privatePath, $publicPath)) {
    if (-not (Test-Path -Path $path)) {
        continue
    }

    Get-ChildItem -Path $path -Filter '*.ps1' -File |
        Sort-Object -Property Name |
        ForEach-Object {
            . $_.FullName
        }
}

Set-Alias -Name conc  -Value Connect-Cloud -Scope Script
Set-Alias -Name gcont -Value Get-CloudContext -Scope Script
Set-Alias -Name gcin  -Value Get-CloudInstance -Scope Script
Set-Alias -Name sci   -Value Start-CloudInstance -Scope Script
Set-Alias -Name tci   -Value Stop-CloudInstance -Scope Script
