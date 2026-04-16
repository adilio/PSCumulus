function ConvertFrom-GCPInstanceStatus {
    [CmdletBinding()]
    param(
        [string]$Status
    )

    $normalizedStatus = [CloudInstanceStatusMap]::FromGcp($Status)
    if ($null -eq $normalizedStatus) {
        return $null
    }

    $normalizedStatus.ToString()
}
