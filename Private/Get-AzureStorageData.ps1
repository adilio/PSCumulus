function Get-AzureStorageData {
    [CmdletBinding()]
    param(
        [string]$ResourceGroup
    )

    Assert-CommandAvailable `
        -CommandName 'Get-AzStorageAccount' `
        -InstallHint "Install the Az.Storage module with: Install-Module Az.Storage -Scope CurrentUser"

    $accounts = if ([string]::IsNullOrWhiteSpace($ResourceGroup)) {
        Get-AzStorageAccount -ErrorAction Stop
    } else {
        Get-AzStorageAccount -ResourceGroupName $ResourceGroup -ErrorAction Stop
    }

    foreach ($account in $accounts) {
        $status = if ($account.StatusOfPrimary) {
            $account.StatusOfPrimary.ToString()
        } else {
            $null
        }

        $params = @{
            Name     = $account.StorageAccountName
            Provider = 'Azure'
            Region   = $account.PrimaryLocation
            Size     = $account.Sku.Name
            Metadata = @{
                ResourceGroup = $account.ResourceGroupName
                Kind          = if ($account.Kind) { $account.Kind.ToString() } else { $null }
                AccessTier    = if ($account.AccessTier) { $account.AccessTier.ToString() } else { $null }
            }
        }

        if ($status) { $params.Status = $status }
        if ($account.CreationTime) { $params.CreatedAt = $account.CreationTime }

        ConvertTo-CloudRecord @params
    }
}
