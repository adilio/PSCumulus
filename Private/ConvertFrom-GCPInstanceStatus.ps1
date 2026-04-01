function ConvertFrom-GCPInstanceStatus {
    [CmdletBinding()]
    param(
        [string]$Status
    )

    if ([string]::IsNullOrWhiteSpace($Status)) {
        return $null
    }

    (Get-Culture).TextInfo.ToTitleCase($Status.ToLowerInvariant())
}

