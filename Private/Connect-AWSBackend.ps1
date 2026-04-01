function Connect-AWSBackend {
    [CmdletBinding()]
    param(
        [string]$Region
    )

    Assert-CommandAvailable `
        -CommandName 'Initialize-AWSDefaultConfiguration' `
        -InstallHint "Install the AWS.Tools.Common module with: Install-Module AWS.Tools.Common -Scope CurrentUser"

    $configuration = if ([string]::IsNullOrWhiteSpace($Region)) {
        Initialize-AWSDefaultConfiguration -ErrorAction Stop
    } else {
        Initialize-AWSDefaultConfiguration -Region $Region -ErrorAction Stop
    }

    [pscustomobject]@{
        PSTypeName   = 'PSCumulus.ConnectionResult'
        Provider     = 'AWS'
        Connected    = $true
        Region       = if ($Region) { $Region } else { $configuration.Region }
        ProfileName  = $configuration.Name
        StoreAs      = $configuration.ProfileLocation
    }
}
