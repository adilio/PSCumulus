function Update-CloudContextActiveProvider {
    [CmdletBinding()]
    param(
        [string]$PreferredProvider
    )

    if (-not [string]::IsNullOrWhiteSpace($PreferredProvider) -and $script:PSCumulusContext.Providers.ContainsKey($PreferredProvider)) {
        if ($script:PSCumulusContext.Providers[$PreferredProvider]) {
            $script:PSCumulusContext.ActiveProvider = $PreferredProvider
            return $PreferredProvider
        }
    }

    $activeEntry = $script:PSCumulusContext.Providers.GetEnumerator() |
        Where-Object { $_.Value } |
        Sort-Object -Property { $_.Value.ConnectedAt } -Descending |
        Select-Object -First 1

    if ($activeEntry) {
        $script:PSCumulusContext.ActiveProvider = $activeEntry.Key
        return $activeEntry.Key
    }

    $script:PSCumulusContext.ActiveProvider = $null
    return $null
}
