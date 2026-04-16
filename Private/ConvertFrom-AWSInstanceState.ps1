function ConvertFrom-AWSInstanceState {
    [CmdletBinding()]
    param(
        [string]$StateName
    )

    $status = [CloudInstanceStatusMap]::FromAws($StateName)
    if ($null -eq $status) {
        return $null
    }

    $status.ToString()
}
