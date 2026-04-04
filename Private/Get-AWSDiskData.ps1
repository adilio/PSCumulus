function Get-AWSDiskData {
    [CmdletBinding()]
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
        $nameTag = $volume.Tags |
            Where-Object { $_.Key -eq 'Name' } |
            Select-Object -First 1 -ExpandProperty Value

        $resolvedName = if ([string]::IsNullOrWhiteSpace($nameTag)) {
            $volume.VolumeId
        } else {
            $nameTag
        }

        $attachedInstanceId = if ($volume.Attachments -and $volume.Attachments.Count -gt 0) {
            $volume.Attachments[0].InstanceId
        } else {
            $null
        }

        $params = @{
            Name     = $resolvedName
            Provider = 'AWS'
            Region   = $volume.AvailabilityZone
            Status   = $volume.State.Value
            Size     = "$($volume.Size) GB"
            Metadata = @{
                VolumeId   = $volume.VolumeId
                VolumeType = $volume.VolumeType.Value
                Encrypted  = $volume.Encrypted
                InstanceId = $attachedInstanceId
            }
        }

        if ($volume.CreateTime) { $params.CreatedAt = $volume.CreateTime }

        ConvertTo-CloudRecord @params
    }
}
