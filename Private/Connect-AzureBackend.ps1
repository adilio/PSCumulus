function Connect-AzureBackend {
    [CmdletBinding()]
    param()

    Assert-CommandAvailable `
        -CommandName 'Connect-AzAccount' `
        -InstallHint "Install the Az.Accounts module with: Install-Module Az.Accounts -Scope CurrentUser"

    $existingContext = Get-AzContext -ErrorAction SilentlyContinue

    if (-not $existingContext) {
        Write-Host "No active Azure session found. Starting login..."
        $loginResult = Connect-AzAccount -ErrorAction Stop
        $azContext = $loginResult.Context
    } else {
        $azContext = $existingContext
    }

    [pscustomobject]@{
        PSTypeName    = 'PSCumulus.ConnectionResult'
        Provider      = 'Azure'
        Connected     = $true
        ContextName   = $azContext.Name
        TenantId      = $azContext.Tenant.Id
        Subscription  = $azContext.Subscription.Name
        Account       = $azContext.Account.Id
    }
}
