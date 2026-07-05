function Get-AzureImageData {
    [CmdletBinding()]
    [OutputType([AzureImageRecord])]
    param(
        [string]$ResourceGroup
    )

    Assert-CommandAvailable `
        -CommandName 'Get-AzImage' `
        -InstallHint "Install the Az.Compute module with: Install-Module Az.Compute -Scope CurrentUser"

    $images = if ([string]::IsNullOrWhiteSpace($ResourceGroup)) {
        Get-AzImage -ErrorAction Stop
    } else {
        Get-AzImage -ResourceGroupName $ResourceGroup -ErrorAction Stop
    }

    foreach ($image in $images) {
        [AzureImageRecord]::FromAzImage($image)
    }
}
