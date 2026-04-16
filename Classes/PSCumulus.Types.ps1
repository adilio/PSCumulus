enum CloudProvider {
    Azure
    AWS
    GCP
}

enum CloudInstanceStatus {
    Unknown
    Pending
    Starting
    Running
    Stopping
    Stopped
    Suspending
    Suspended
    Terminating
    Terminated
}

class CloudInstanceStatusMap {
    static [object] FromAws([string]$stateName) {
        if ([string]::IsNullOrWhiteSpace($stateName)) {
            return $null
        }

        switch ($stateName.Trim().ToLowerInvariant()) {
            'pending'       { return [CloudInstanceStatus]::Pending }
            'running'       { return [CloudInstanceStatus]::Running }
            'stopping'      { return [CloudInstanceStatus]::Stopping }
            'stopped'       { return [CloudInstanceStatus]::Stopped }
            'shutting-down' { return [CloudInstanceStatus]::Terminating }
            'terminated'    { return [CloudInstanceStatus]::Terminated }
            default         { return [CloudInstanceStatus]::Unknown }
        }

        return [CloudInstanceStatus]::Unknown
    }

    static [object] FromAzure([string]$powerState) {
        if ([string]::IsNullOrWhiteSpace($powerState)) {
            return $null
        }

        $normalized = $powerState.Trim()
        if ($normalized.StartsWith('VM ', [System.StringComparison]::OrdinalIgnoreCase)) {
            $normalized = $normalized.Substring(3)
        }

        switch ($normalized.ToLowerInvariant()) {
            'starting'     { return [CloudInstanceStatus]::Starting }
            'running'      { return [CloudInstanceStatus]::Running }
            'stopping'     { return [CloudInstanceStatus]::Stopping }
            'deallocating' { return [CloudInstanceStatus]::Stopping }
            'stopped'      { return [CloudInstanceStatus]::Stopped }
            'deallocated'  { return [CloudInstanceStatus]::Stopped }
            default        { return [CloudInstanceStatus]::Unknown }
        }

        return [CloudInstanceStatus]::Unknown
    }

    static [object] FromGcp([string]$status) {
        if ([string]::IsNullOrWhiteSpace($status)) {
            return $null
        }

        switch ($status.Trim().ToUpperInvariant()) {
            'PROVISIONING' { return [CloudInstanceStatus]::Pending }
            'STAGING'      { return [CloudInstanceStatus]::Pending }
            'RUNNING'      { return [CloudInstanceStatus]::Running }
            'STOPPING'     { return [CloudInstanceStatus]::Stopping }
            'SUSPENDING'   { return [CloudInstanceStatus]::Suspending }
            'SUSPENDED'    { return [CloudInstanceStatus]::Suspended }
            'TERMINATED'   { return [CloudInstanceStatus]::Stopped }
            default        { return [CloudInstanceStatus]::Unknown }
        }

        return [CloudInstanceStatus]::Unknown
    }
}

class CloudTagHelper {
    static [hashtable] CopyHashtable([hashtable]$tags) {
        $result = @{}

        if ($null -eq $tags) {
            return $result
        }

        foreach ($entry in $tags.GetEnumerator()) {
            $result[$entry.Key] = $entry.Value
        }

        return $result
    }

    static [hashtable] FromAwsTags([object[]]$tagArray) {
        $result = @{}

        foreach ($tag in @($tagArray)) {
            if ($null -eq $tag) {
                continue
            }

            $key = $tag.Key
            if ([string]::IsNullOrWhiteSpace($key)) {
                continue
            }

            $result[$key] = $tag.Value
        }

        return $result
    }

    static [hashtable] FromAzureTags([hashtable]$tags) {
        return [CloudTagHelper]::CopyHashtable($tags)
    }

    static [hashtable] FromGcpLabels([object]$labels) {
        $result = @{}

        if ($null -eq $labels) {
            return $result
        }

        if ($labels -is [hashtable]) {
            return [CloudTagHelper]::CopyHashtable($labels)
        }

        foreach ($property in $labels.PSObject.Properties) {
            $result[$property.Name] = $property.Value
        }

        return $result
    }

    static [object[]] ToAwsTags([hashtable]$tags) {
        $result = New-Object System.Collections.Generic.List[object]

        foreach ($entry in ([CloudTagHelper]::CopyHashtable($tags)).GetEnumerator()) {
            $result.Add([pscustomobject]@{
                Key   = $entry.Key
                Value = $entry.Value
            })
        }

        return $result.ToArray()
    }

    static [hashtable] ToAzureTags([hashtable]$tags) {
        return [CloudTagHelper]::CopyHashtable($tags)
    }

    static [hashtable] ToGcpLabels([hashtable]$tags) {
        $result = @{}

        foreach ($entry in ([CloudTagHelper]::CopyHashtable($tags)).GetEnumerator()) {
            $key = [string]$entry.Key
            if ($key -cnotmatch '^[a-z][a-z0-9_-]{0,62}$') {
                throw [System.ArgumentException]::new(
                    "GCP label key '$key' is invalid. Label keys must match ^[a-z][a-z0-9_-]{0,62}$."
                )
            }

            $result[$key] = $entry.Value
        }

        return $result
    }
}

class CloudRecord {
    [string]$Name
    [string]$Provider
    [string]$Region
    [string]$Status
    [string]$Size
    [Nullable[datetime]]$CreatedAt
    [string]$PrivateIpAddress
    [string]$PublicIpAddress
    [hashtable]$Tags
    [hashtable]$Metadata
    [string]$Kind

    CloudRecord() {
        $this.Tags = @{}
        $this.Metadata = @{}
        $this.PSObject.TypeNames.Insert(0, 'PSCumulus.CloudRecord')
    }
}

class AzureCloudRecord : CloudRecord {
    [string]$ResourceGroup
    [string]$VmId
    [string]$OsType

    AzureCloudRecord() : base() {
        $this.PSObject.TypeNames.Insert(0, 'PSCumulus.AzureCloudRecord')
    }

    static [AzureCloudRecord] FromAzVM([object]$vm, [object]$addressData) {
        $record = [AzureCloudRecord]::new()
        $powerState = $null

        if ($vm.Statuses) {
            $powerState = $vm.Statuses |
                Where-Object { $_.Code -like 'PowerState/*' } |
                Select-Object -First 1 -ExpandProperty DisplayStatus
        }

        $normalizedStatus = [CloudInstanceStatusMap]::FromAzure($powerState)
        if ($null -eq $normalizedStatus) {
            $normalizedStatus = [CloudInstanceStatus]::Unknown
        }

        $resolvedOsType = $null
        if ($vm.StorageProfile -and $vm.StorageProfile.OsDisk -and $vm.StorageProfile.OsDisk.OsType) {
            $resolvedOsType = $vm.StorageProfile.OsDisk.OsType.ToString()
        }

        $record.Kind = 'Instance'
        $record.Provider = [CloudProvider]::Azure.ToString()
        $record.Name = $vm.Name
        $record.Region = $vm.Location
        $record.Status = $normalizedStatus.ToString()
        $record.Size = $vm.HardwareProfile.VmSize
        $record.PrivateIpAddress = $addressData.PrivateIpAddress
        $record.PublicIpAddress = $addressData.PublicIpAddress
        $record.Tags = [CloudTagHelper]::FromAzureTags($vm.Tags)
        $record.ResourceGroup = $vm.ResourceGroupName
        $record.VmId = $vm.VmId
        $record.OsType = $resolvedOsType
        $record.Metadata = @{
            NativeStatus = $powerState
        }

        return $record
    }
}

class AWSCloudRecord : CloudRecord {
    [string]$InstanceId
    [string]$VpcId
    [string]$SubnetId

    AWSCloudRecord() : base() {
        $this.PSObject.TypeNames.Insert(0, 'PSCumulus.AWSCloudRecord')
    }

    static [AWSCloudRecord] FromEC2Instance([object]$instance) {
        $record = [AWSCloudRecord]::new()
        $nameTag = $instance.Tags |
            Where-Object { $_.Key -eq 'Name' } |
            Select-Object -First 1 -ExpandProperty Value

        $resolvedName = if ([string]::IsNullOrWhiteSpace($nameTag)) {
            $instance.InstanceId
        } else {
            $nameTag
        }

        $nativeStatus = $null
        if ($instance.State -and $instance.State.Name) {
            $nativeStatus = $instance.State.Name.Value
        }

        $normalizedStatus = [CloudInstanceStatusMap]::FromAws($nativeStatus)
        if ($null -eq $normalizedStatus) {
            $normalizedStatus = [CloudInstanceStatus]::Unknown
        }

        $record.Kind = 'Instance'
        $record.Provider = [CloudProvider]::AWS.ToString()
        $record.Name = $resolvedName
        $record.Region = $instance.Placement.AvailabilityZone
        $record.Status = $normalizedStatus.ToString()
        $record.Size = $instance.InstanceType.Value
        $record.CreatedAt = $instance.LaunchTime
        $record.PrivateIpAddress = $instance.PrivateIpAddress
        $record.PublicIpAddress = $instance.PublicIpAddress
        $record.Tags = [CloudTagHelper]::FromAwsTags($instance.Tags)
        $record.InstanceId = $instance.InstanceId
        $record.VpcId = $instance.VpcId
        $record.SubnetId = $instance.SubnetId
        $record.Metadata = @{
            NativeStatus = $nativeStatus
        }

        return $record
    }
}

class GCPCloudRecord : CloudRecord {
    [string]$Project
    [string]$Zone
    [string]$Id

    GCPCloudRecord() : base() {
        $this.PSObject.TypeNames.Insert(0, 'PSCumulus.GCPCloudRecord')
    }

    static [GCPCloudRecord] FromGCloudJson([object]$instance, [string]$project) {
        $record = [GCPCloudRecord]::new()
        $zoneName = $null
        $machineType = $null
        $createdAt = $null
        $primaryInterface = $null
        $primaryAccessConfig = $null

        if ($instance.zone) {
            $zoneName = ($instance.zone -split '/')[-1]
        }

        if ($instance.machineType) {
            $machineType = ($instance.machineType -split '/')[-1]
        }

        if (-not [string]::IsNullOrWhiteSpace($instance.creationTimestamp)) {
            $createdAt = [datetime]::Parse($instance.creationTimestamp)
        }

        $networkInterfaces = @($instance.networkInterfaces)
        $primaryInterface = $networkInterfaces | Select-Object -First 1
        $accessConfigs = @($primaryInterface.accessConfigs)
        $primaryAccessConfig = $accessConfigs | Select-Object -First 1

        $normalizedStatus = [CloudInstanceStatusMap]::FromGcp($instance.status)
        if ($null -eq $normalizedStatus) {
            $normalizedStatus = [CloudInstanceStatus]::Unknown
        }

        $record.Kind = 'Instance'
        $record.Provider = [CloudProvider]::GCP.ToString()
        $record.Name = $instance.name
        $record.Region = $zoneName
        $record.Status = $normalizedStatus.ToString()
        $record.Size = $machineType
        $record.CreatedAt = $createdAt
        $record.PrivateIpAddress = $primaryInterface.networkIP
        $record.PublicIpAddress = $primaryAccessConfig.natIP
        $record.Tags = [CloudTagHelper]::FromGcpLabels($instance.labels)
        $record.Project = $project
        $record.Zone = $zoneName
        $record.Id = $instance.id
        $record.Metadata = @{
            NativeStatus = $instance.status
        }

        return $record
    }
}
