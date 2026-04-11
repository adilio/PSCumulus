function Get-GCPInstanceData {
    [CmdletBinding()]
    param(
        [string]$Project
    )

    $null = Assert-GCloudAuthenticated
    $resolvedProject = Get-GCloudProject -Project $Project
    $instances = Invoke-GCloudJson -Arguments @('compute', 'instances', 'list', "--project=$resolvedProject")

    foreach ($instance in $instances) {
        $zoneName = if ($instance.zone) {
            ($instance.zone -split '/')[-1]
        } else {
            $null
        }

        $machineType = if ($instance.machineType) {
            ($instance.machineType -split '/')[-1]
        } else {
            $null
        }

        $createdAt = $null

        if (-not [string]::IsNullOrWhiteSpace($instance.creationTimestamp)) {
            $createdAt = [datetime]::Parse($instance.creationTimestamp)
        }

        $networkInterfaces = @($instance.networkInterfaces)
        $primaryInterface = $networkInterfaces | Select-Object -First 1
        $accessConfigs = @($primaryInterface.accessConfigs)
        $primaryAccessConfig = $accessConfigs | Select-Object -First 1

        $tagHashtable = @{}
        if ($instance.labels) {
            $instance.labels.PSObject.Properties | ForEach-Object {
                $tagHashtable[$_.Name] = $_.Value
            }
        }

        ConvertTo-CloudRecord `
            -Name $instance.name `
            -Provider GCP `
            -Region $zoneName `
            -Status (ConvertFrom-GCPInstanceStatus -Status $instance.status) `
            -Size $machineType `
            -CreatedAt $createdAt `
            -Tags $tagHashtable `
            -Metadata @{
                Project          = $resolvedProject
                Id               = $instance.id
                Zone             = $zoneName
                PrivateIpAddress = $primaryInterface.networkIP
                PublicIpAddress  = $primaryAccessConfig.natIP
                Labels           = $instance.labels
            }
    }
}
