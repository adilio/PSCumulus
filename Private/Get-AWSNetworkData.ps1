function Get-AWSNetworkData {
    [CmdletBinding()]
    [OutputType([AWSNetworkRecord])]
    param(
        [string]$Region
    )

    Assert-CommandAvailable `
        -CommandName 'Get-EC2Vpc' `
        -InstallHint "Install the AWS.Tools.EC2 module with: Install-Module AWS.Tools.EC2 -Scope CurrentUser"

    $vpcs = if ([string]::IsNullOrWhiteSpace($Region)) {
        Get-EC2Vpc -ErrorAction Stop
    } else {
        Get-EC2Vpc -Region $Region -ErrorAction Stop
    }

    foreach ($vpc in $vpcs) {
        [AWSNetworkRecord]::FromEC2Vpc($vpc)
    }
}
