function Connect-AzureBackend {
    [CmdletBinding()]
    param(
        [string]$Tenant,
        [string]$Subscription
    )

    Assert-CommandAvailable `
        -CommandName 'Connect-AzAccount' `
        -InstallHint "Install the Az.Accounts module with: Install-Module Az.Accounts -Scope CurrentUser"

    $existingContext = Get-AzContext -ErrorAction SilentlyContinue

    if (-not $existingContext) {
        Write-Host "No active Azure session found. Starting login..."
        $connectParams = @{
            ErrorAction = 'Stop'
        }

        if (-not [string]::IsNullOrWhiteSpace($Tenant)) {
            $connectParams.Tenant = $Tenant
        }

        if (-not [string]::IsNullOrWhiteSpace($Subscription)) {
            $connectParams.Subscription = $Subscription
        }

        $loginResult = Connect-AzAccount @connectParams
        $azContext = Get-AzContext -ErrorAction SilentlyContinue

        if (-not $azContext -and $loginResult.Context) {
            $azContext = $loginResult.Context
        }

        if (-not $azContext) {
            throw [System.InvalidOperationException]::new(
                'Azure login completed, but no active context was found.'
            )
        }
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
        SubscriptionId = $azContext.Subscription.Id
        Account       = $azContext.Account.Id
    }
}
