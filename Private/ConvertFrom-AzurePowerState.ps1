function ConvertFrom-AzurePowerState {
    [CmdletBinding()]
    param(
        [string]$PowerState
    )

    if ([string]::IsNullOrWhiteSpace($PowerState)) {
        return $null
    }

    if ($PowerState -like 'VM *') {
        return $PowerState.Substring(3)
    }

    $PowerState
}

