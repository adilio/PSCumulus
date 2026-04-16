function ConvertFrom-AzurePowerState {
    [CmdletBinding()]
    param(
        [string]$PowerState
    )

    $status = [CloudInstanceStatusMap]::FromAzure($PowerState)
    if ($null -eq $status) {
        return $null
    }

    $status.ToString()
}
