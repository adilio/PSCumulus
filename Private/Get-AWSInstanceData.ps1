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

    foreach ($reservation in $instanceResponse.Reservations) {
        foreach ($instance in $reservation.Instances) {
            $nameTag = $instance.Tags |
                Where-Object { $_.Key -eq 'Name' } |
                Select-Object -First 1 -ExpandProperty Value

            $resolvedName = if ([string]::IsNullOrWhiteSpace($nameTag)) {
                $instance.InstanceId
            } else {
                $nameTag
            }

            if (-not [string]::IsNullOrWhiteSpace($Name) -and $resolvedName -ne $Name -and $instance.InstanceId -ne $Name) {
                continue
            }

            $tagHashtable = @{}
            foreach ($tag in $instance.Tags) {
                $tagHashtable[$tag.Key] = $tag.Value
            }

            ConvertTo-CloudRecord `
                -Name $resolvedName `
                -Provider AWS `
                -Region $instance.Placement.AvailabilityZone `
                -Status (ConvertFrom-AWSInstanceState -StateName $instance.State.Name.Value) `
                -Size $instance.InstanceType.Value `
                -CreatedAt $instance.LaunchTime `
                -PrivateIpAddress $instance.PrivateIpAddress `
                -PublicIpAddress $instance.PublicIpAddress `
                -Tags $tagHashtable `
                -Metadata @{
                    InstanceId       = $instance.InstanceId
                    PrivateIpAddress = $instance.PrivateIpAddress
                    PublicIpAddress  = $instance.PublicIpAddress
                    VpcId            = $instance.VpcId
                    SubnetId         = $instance.SubnetId
                }
        }
    }
}
