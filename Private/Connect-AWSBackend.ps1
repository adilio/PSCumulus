function Connect-AWSBackend {
    [CmdletBinding()]
    param(
        [string]$Region
    )

    Assert-CommandAvailable `
        -CommandName 'Initialize-AWSDefaultConfiguration' `
        -InstallHint "Install the AWS.Tools.Common module with: Install-Module AWS.Tools.Common -Scope CurrentUser"

    $hasCredentials = $env:AWS_ACCESS_KEY_ID -or
                      $env:AWS_PROFILE -or
                      (Test-Path (Join-Path $HOME '.aws' 'credentials')) -or
                      (Test-Path (Join-Path $HOME '.aws' 'config'))

    if (-not $hasCredentials) {
        Write-Host "No active AWS credentials found. Starting login..."
    }

    $configuration = if ([string]::IsNullOrWhiteSpace($Region)) {
        Initialize-AWSDefaultConfiguration -ErrorAction Stop
    } else {
        Initialize-AWSDefaultConfiguration -Region $Region -ErrorAction Stop
    }

    $accountId = $null
    if (Get-Command -Name 'Get-STSCallerIdentity' -ErrorAction SilentlyContinue) {
        try {
            $callerIdentity = Get-STSCallerIdentity -ErrorAction Stop
            if ($callerIdentity.Account) {
                $accountId = $callerIdentity.Account
            }
        } catch {
            $accountId = $null
        }
    }

    $profileName = if ($configuration.Name) {
        $configuration.Name
    } elseif ($configuration.ProfileName) {
        $configuration.ProfileName
    } else {
        $null
    }

    [pscustomobject]@{
        PSTypeName   = 'PSCumulus.ConnectionResult'
        Provider     = 'AWS'
        Connected    = $true
        Region       = if ($Region) { $Region } else { $configuration.Region }
        ProfileName  = $profileName
        AccountId    = $accountId
        Account      = if ($accountId) { $accountId } elseif ($profileName) { $profileName } else { $configuration.Name }
        StoreAs      = $configuration.ProfileLocation
    }
}
