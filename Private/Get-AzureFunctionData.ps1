function Get-AzureFunctionData {
    [CmdletBinding()]
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
        $params = @{
            Name     = $app.Name
            Provider = 'Azure'
            Region   = $app.Location
            Status   = $app.State
            Metadata = @{
                ResourceGroup  = $app.ResourceGroupName
                Runtime        = $app.Runtime
                RuntimeVersion = $app.RuntimeVersion
                OSType         = if ($app.OSType) { $app.OSType.ToString() } else { $null }
                Kind           = $app.Kind
            }
        }

        if ($app.Runtime) { $params.Size = $app.Runtime }

        ConvertTo-CloudRecord @params
    }
}
