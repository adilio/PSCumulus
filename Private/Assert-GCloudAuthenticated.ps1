function Assert-GCloudAuthenticated {
    [CmdletBinding()]
    param()

    $accounts = Invoke-GCloudJson -Arguments @('auth', 'list')

    $activeAccount = $accounts | Where-Object { $_.status -eq 'ACTIVE' } | Select-Object -First 1

    if (-not $activeAccount) {
        throw [System.InvalidOperationException]::new(
            "No active gcloud account found. Run 'gcloud auth login' or 'gcloud auth application-default login' first."
        )
    }

    $activeAccount
}

