function Get-AWSImageData {
    [CmdletBinding()]
    [OutputType([AWSImageRecord])]
    param(
        [string]$Region
    )

    Assert-CommandAvailable `
        -CommandName 'Get-EC2Image' `
        -InstallHint "Install the AWS.Tools.EC2 module with: Install-Module AWS.Tools.EC2 -Scope CurrentUser"

    # -Owner self restricts the listing to the caller's own AMIs; without it
    # EC2 returns the full public AMI catalog.
    $images = if ([string]::IsNullOrWhiteSpace($Region)) {
        Get-EC2Image -Owner self -ErrorAction Stop
    } else {
        Get-EC2Image -Owner self -Region $Region -ErrorAction Stop
    }

    foreach ($image in $images) {
        [AWSImageRecord]::FromEC2Image($image)
    }
}
