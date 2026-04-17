function Get-AWSDiskData {
    [CmdletBinding()]
    [OutputType([AWSDiskRecord])]
    param(
        [string]$Region
    )

    Assert-CommandAvailable `
        -CommandName 'Get-EC2Volume' `
        -InstallHint "Install the AWS.Tools.EC2 module with: Install-Module AWS.Tools.EC2 -Scope CurrentUser"

    $volumes = if ([string]::IsNullOrWhiteSpace($Region)) {
        Get-EC2Volume -ErrorAction Stop
    } else {
        Get-EC2Volume -Region $Region -ErrorAction Stop
    }

    foreach ($volume in $volumes) {
        [AWSDiskRecord]::FromEC2Volume($volume)
    }
}
