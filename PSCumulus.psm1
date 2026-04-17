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

# Conditionally load SHiPS provider classes (PS 7+ only)
$loadShipsProvider = $false
if ($PSVersionTable.PSVersion.Major -ge 7) {
    $shipsModule = Get-Module SHiPS -ListAvailable -ErrorAction SilentlyContinue
    if ($shipsModule) {
        Import-Module SHiPS -ErrorAction SilentlyContinue
        $loadShipsProvider = $true
    }
}

# Classes must load before Private/Public files that reference their types.
# PSCumulusProvider.ps1 requires SHiPS and is conditionally loaded below.
foreach ($path in @($classesPath, $privatePath, $publicPath)) {
    if (-not (Test-Path -Path $path)) {
        continue
    }

    Get-ChildItem -Path $path -Filter '*.ps1' -File |
        Where-Object { $_.Name -ne 'PSCumulusProvider.ps1' } |
        Sort-Object -Property Name |
        ForEach-Object { . $_.FullName }
}

# Load SHiPS provider after checking if SHiPS is available
if ($loadShipsProvider) {
    $providerFile = Join-Path -Path $classesPath -ChildPath 'PSCumulusProvider.ps1'
    if (Test-Path -Path $providerFile) {
        . $providerFile
    }
}

Set-Alias -Name conc  -Value Connect-Cloud -Scope Script
Set-Alias -Name gcont -Value Get-CloudContext -Scope Script
Set-Alias -Name gcin  -Value Get-CloudInstance -Scope Script
Set-Alias -Name sci   -Value Start-CloudInstance -Scope Script
Set-Alias -Name tci   -Value Stop-CloudInstance -Scope Script
Set-Alias -Name ncd   -Value New-CloudDrive -Scope Script
Set-Alias -Name rcd   -Value Remove-CloudDrive -Scope Script
