function Connect-GCPBackend {
    [CmdletBinding()]
    param(
        [string]$Project
    )

    try {
        $activeAccount = Assert-GCloudAuthenticated
    } catch [System.InvalidOperationException] {
        Write-Host "No active GCP session found. Starting login..."
        Invoke-GCloudLogin
        $activeAccount = Assert-GCloudAuthenticated
    }

    $resolvedProject = Get-GCloudProject -Project $Project

    [pscustomobject]@{
        PSTypeName   = 'PSCumulus.ConnectionResult'
        Provider     = 'GCP'
        Connected    = $true
        Account      = $activeAccount.account
        Project      = $resolvedProject
    }
}
