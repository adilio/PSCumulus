param()

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path $repoRoot 'PSCumulus.psd1'
$referenceRoot = Join-Path $repoRoot 'docs/reference'
$commandOutputRoot = Join-Path $referenceRoot 'commands'
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("pscumulus-docs-" + [guid]::NewGuid().ToString('n'))

function Update-AliasSection {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [string[]]$Aliases
    )

    $content = Get-Content -Path $Path -Raw
    $aliasText = if ($Aliases.Count -gt 0) {
        ($Aliases | Sort-Object | ForEach-Object { "  $_" }) -join [Environment]::NewLine
    }
    else {
        '  None'
    }

    $updated = $content -replace [regex]::Escape("This cmdlet has the following aliases,$([Environment]::NewLine)  {{Insert list of aliases}}"), "This cmdlet has the following aliases,$([Environment]::NewLine)$aliasText"
    $updated = $updated -replace 'Locale: .+', 'Locale: en-US'
    $updated = $updated -replace '(?m)^ms\.date: .+\r?\n', ''
    $updated = $updated -replace '\{\{ Fill in the Description \}\}', 'See the command description and examples above.'
    $updated = $updated -replace '\{\{ Fill [A-Za-z0-9_]+ Description \}\}', 'See the description and examples above.'
    $updated = $updated -replace '\{\{ Fill in the related links here \}\}', 'None.'
    if ((Split-Path -Leaf $Path) -eq 'Get-CloudInstance.md') {
        $updated = $updated -replace 'See the command description and examples above\.', 'PSCumulus.CloudRecord or a vendor subclass (PSCumulus.AzureCloudRecord, PSCumulus.AWSCloudRecord, PSCumulus.GCPCloudRecord).'
    }
    if ($PSCmdlet.ShouldProcess($Path, 'Update generated command help')) {
        Set-Content -Path $Path -Value $updated -Encoding utf8NoBOM
    }
}

try {
    New-Item -ItemType Directory -Path $commandOutputRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

    if (-not (Get-Module -ListAvailable -Name Microsoft.PowerShell.PlatyPS)) {
        Install-Module Microsoft.PowerShell.PlatyPS -Scope CurrentUser -Force -AllowClobber
    }

    Import-Module Microsoft.PowerShell.PlatyPS -Force

    # Load classes first before importing the module
    $classesPath = Join-Path $repoRoot 'Classes'
    if (Test-Path $classesPath) {
        Get-ChildItem -Path $classesPath -Filter '*.ps1' -File |
            Sort-Object -Property Name |
            ForEach-Object { . $_.FullName }
    }

    Import-Module $modulePath -Force

    $module = Get-Module PSCumulus
    $null = New-MarkdownCommandHelp `
        -ModuleInfo $module `
        -OutputFolder $tempRoot `
        -WithModulePage `
        -Locale 'en-US' `
        -Force

    $moduleFolder = Join-Path $tempRoot 'PSCumulus'
    $targetModulePage = Join-Path $referenceRoot 'module.md'

    Get-ChildItem -Path $commandOutputRoot -Filter '*.md' -File -ErrorAction SilentlyContinue |
        Remove-Item -Force

    Get-ChildItem -Path $moduleFolder -Filter '*.md' -File | ForEach-Object {
        if ($_.Name -eq 'PSCumulus.md') {
            Copy-Item -Path $_.FullName -Destination $targetModulePage -Force
            return
        }

        $targetPath = Join-Path $commandOutputRoot $_.Name
        Copy-Item -Path $_.FullName -Destination $targetPath -Force

        $commandName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
        $aliases = @(Get-Alias -Definition $commandName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
        Update-AliasSection -Path $targetPath -Aliases $aliases
    }

    if (Test-Path $targetModulePage) {
        $moduleContent = Get-Content -Path $targetModulePage -Raw
        $moduleContent = $moduleContent -replace 'title: PSCumulus Module', 'title: PSCumulus Module Reference'
        $moduleContent = $moduleContent -replace 'Locale: .+', 'Locale: en-US'
        $moduleContent = $moduleContent -replace '(?m)^ms\.date: .+\r?\n', ''
        $moduleContent = $moduleContent -replace '\]\(([^)]+)\.md\)', '](commands/$1.md)'
        Set-Content -Path $targetModulePage -Value $moduleContent -Encoding utf8NoBOM
    }
}
finally {
    if (Test-Path $tempRoot) {
        Remove-Item -Path $tempRoot -Recurse -Force
    }
}
