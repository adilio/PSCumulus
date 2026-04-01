function Connect-AzureBackend {
    [CmdletBinding()]
    param()

    Assert-CommandAvailable `
        -CommandName 'Connect-AzAccount' `
        -InstallHint "Install the Az.Accounts module with: Install-Module Az.Accounts -Scope CurrentUser"

    $context = Connect-AzAccount -ErrorAction Stop

    [pscustomobject]@{
        PSTypeName    = 'PSCumulus.ConnectionResult'
        Provider      = 'Azure'
        Connected     = $true
        ContextName   = $context.Context.Name
        TenantId      = $context.Context.Tenant.Id
        Subscription  = $context.Context.Subscription.Name
    }
}
