function Get-AWSInstanceData {
    [CmdletBinding()]
    param(
        [string]$Region,
        [string]$Name
    )

    Assert-CommandAvailable `
        -CommandName 'Get-EC2Instance' `
        -InstallHint "Install the AWS.Tools.EC2 module with: Install-Module AWS.Tools.EC2 -Scope CurrentUser"

    $instanceResponse = if ([string]::IsNullOrWhiteSpace($Region)) {
        Get-EC2Instance -ErrorAction Stop
    } else {
        Get-EC2Instance -Region $Region -ErrorAction Stop
    }

    $reservations = if ($instanceResponse.PSObject.Properties.Match('Reservations').Count -gt 0) {
        $instanceResponse.Reservations
    } else {
        $instanceResponse
    }

    foreach ($reservation in @($reservations)) {
        foreach ($instance in @($reservation.Instances)) {
            $resolvedRecord = [AWSCloudRecord]::FromEC2Instance($instance)

            if (-not [string]::IsNullOrWhiteSpace($Name) -and $resolvedRecord.Name -ne $Name -and $resolvedRecord.InstanceId -ne $Name) {
                continue
            }

            $resolvedRecord
        }
    }
}
