function ConvertFrom-AzurePowerState {
    [CmdletBinding()]
    param(
        [string]$PowerState
    )

    if ([string]::IsNullOrWhiteSpace($PowerState)) {
        return $null
    }

    if ($PowerState -like 'VM *') {
        return (Get-Culture).TextInfo.ToTitleCase($PowerState.Substring(3).ToLowerInvariant())
    }

    (Get-Culture).TextInfo.ToTitleCase($PowerState.ToLowerInvariant())
}
