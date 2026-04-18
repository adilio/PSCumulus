function Set-AzureTag {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'This internal helper is invoked only by Set-CloudTag, which implements ShouldProcess.'
    )]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ResourceId,

        [Parameter(Mandatory)]
        [hashtable]$Tags,

        [switch]$Merge
    )

    Assert-CommandAvailable `
        -CommandName 'Update-AzTag' `
        -InstallHint "Install the Az.Resources module with: Install-Module Az.Resources -Scope CurrentUser"

    $existingTags = Get-AzTag -ResourceId $ResourceId -ErrorAction SilentlyContinue

    $operation = if ($Merge) { 'Merge' } else { 'Replace' }

    Update-AzTag -ResourceId $ResourceId -Tag $Tags -Operation $operation -ErrorAction Stop
}
