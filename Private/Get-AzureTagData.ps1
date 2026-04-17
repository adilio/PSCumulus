function Get-AzureTagData {
    [CmdletBinding()]
    [OutputType([AzureTagRecord])]
    param(
        [string]$ResourceId
    )

    Assert-CommandAvailable `
        -CommandName 'Get-AzTag' `
        -InstallHint "Install the Az.Resources module with: Install-Module Az.Resources -Scope CurrentUser"

    $tagWrapper = Get-AzTag -ResourceId $ResourceId -ErrorAction Stop

    [AzureTagRecord]::FromAzTag($tagWrapper, $ResourceId)
}
