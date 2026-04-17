function Get-AzureFunctionData {
    [CmdletBinding()]
    [OutputType([AzureFunctionRecord])]
    param(
        [string]$ResourceGroup
    )

    Assert-CommandAvailable `
        -CommandName 'Get-AzFunctionApp' `
        -InstallHint "Install the Az.Functions module with: Install-Module Az.Functions -Scope CurrentUser"

    $apps = if ([string]::IsNullOrWhiteSpace($ResourceGroup)) {
        Get-AzFunctionApp -ErrorAction Stop
    } else {
        Get-AzFunctionApp -ResourceGroupName $ResourceGroup -ErrorAction Stop
    }

    foreach ($app in $apps) {
        [AzureFunctionRecord]::FromAzFunctionApp($app)
    }
}
