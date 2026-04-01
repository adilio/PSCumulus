function Connect-GCPBackend {
    [CmdletBinding()]
    param(
        [string]$Project
    )

    $activeAccount = Assert-GCloudAuthenticated
    $resolvedProject = Get-GCloudProject -Project $Project

    [pscustomobject]@{
        PSTypeName   = 'PSCumulus.ConnectionResult'
        Provider     = 'GCP'
        Connected    = $true
        Account      = $activeAccount.account
        Project      = $resolvedProject
    }
}
