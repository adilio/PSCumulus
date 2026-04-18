$script:PSCumulusContext = @{
    ActiveProvider = $null
    Providers      = @{
        Azure = $null
        AWS   = $null
        GCP   = $null
    }
}

$classesPath = Join-Path -Path $PSScriptRoot -ChildPath 'Classes'
$publicPath = Join-Path -Path $PSScriptRoot -ChildPath 'Public'
$privatePath = Join-Path -Path $PSScriptRoot -ChildPath 'Private'

# Classes must load before Private/Public files that reference their types.
foreach ($path in @($classesPath, $privatePath, $publicPath)) {
    if (-not (Test-Path -Path $path)) {
        continue
    }

    Get-ChildItem -Path $path -Filter '*.ps1' -File |
        Sort-Object -Property Name |
        ForEach-Object { . $_.FullName }
}

. (Join-Path -Path $privatePath -ChildPath 'Register-PSCumpleters.ps1')

Set-Alias -Name conc  -Value Connect-Cloud -Scope Script
Set-Alias -Name gcont -Value Get-CloudContext -Scope Script
Set-Alias -Name gcin  -Value Get-CloudInstance -Scope Script
Set-Alias -Name sci   -Value Start-CloudInstance -Scope Script
Set-Alias -Name tci   -Value Test-CloudConnection -Scope Script
Set-Alias -Name rci   -Value Restart-CloudInstance -Scope Script
Set-Alias -Name sct   -Value Set-CloudTag -Scope Script
