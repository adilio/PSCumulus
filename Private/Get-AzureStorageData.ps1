function Get-AzureStorageData {
    [CmdletBinding()]
    [OutputType([AzureStorageRecord])]
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
        [AzureStorageRecord]::FromAzStorageAccount($account)
    }
}
