function ConvertFrom-AWSInstanceState {
    [CmdletBinding()]
    param(
        [string]$StateName
    )

    if ([string]::IsNullOrWhiteSpace($StateName)) {
        return $null
    }

    (Get-Culture).TextInfo.ToTitleCase($StateName.ToLowerInvariant())
}

