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

# Azure Disk Record
class AzureDiskRecord : CloudRecord {
    [string]$ResourceGroup
    [int]$DiskSizeGB
    [string]$Sku
    [string]$OsType

    AzureDiskRecord() : base() {
        $this.PSObject.TypeNames.Insert(0, 'PSCumulus.AzureDiskRecord')
    }

    static [AzureDiskRecord] FromAzDisk([object]$disk) {
        $record = [AzureDiskRecord]::new()
        $status = if ($disk.DiskState) { $disk.DiskState.ToString() } else { $null }
        $resolvedOsType = if ($disk.OsType) { $disk.OsType.ToString() } else { $null }

        $record.Kind = 'Disk'
        $record.Provider = [CloudProvider]::Azure.ToString()
        $record.Name = $disk.Name
        $record.Region = $disk.Location
        $record.Status = $status
        $record.Size = "$($disk.DiskSizeGB) GB"
        $record.CreatedAt = $disk.TimeCreated
        $record.ResourceGroup = $disk.ResourceGroupName
        $record.DiskSizeGB = $disk.DiskSizeGB
        $record.Sku = $disk.Sku.Name
        $record.OsType = $resolvedOsType
        $record.Metadata = @{
            ResourceGroup = $disk.ResourceGroupName
            DiskSizeGB    = $disk.DiskSizeGB
            OsType        = $resolvedOsType
            Sku           = $disk.Sku.Name
        }

        return $record
    }
}

# AWS Disk Record
class AWSDiskRecord : CloudRecord {
    [string]$VolumeId
    [string]$VolumeType
    [bool]$Encrypted
    [string]$InstanceId

    AWSDiskRecord() : base() {
        $this.PSObject.TypeNames.Insert(0, 'PSCumulus.AWSDiskRecord')
    }

    static [AWSDiskRecord] FromEC2Volume([object]$volume) {
        $record = [AWSDiskRecord]::new()
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

        $record.Kind = 'Disk'
        $record.Provider = [CloudProvider]::AWS.ToString()
        $record.Name = $resolvedName
        $record.Region = $volume.AvailabilityZone
        $record.Status = $volume.State.Value
        $record.Size = "$($volume.Size) GB"
        $record.CreatedAt = $volume.CreateTime
        $record.VolumeId = $volume.VolumeId
        $record.VolumeType = $volume.VolumeType.Value
        $record.Encrypted = $volume.Encrypted
        $record.InstanceId = $attachedInstanceId
        $record.Metadata = @{
            VolumeId   = $volume.VolumeId
            VolumeType = $volume.VolumeType.Value
            Encrypted  = $volume.Encrypted
            InstanceId = $attachedInstanceId
        }

        return $record
    }
}

# GCP Disk Record
class GCPDiskRecord : CloudRecord {
    [string]$Project
    [string]$Zone
    [string]$DiskType
    [int]$SizeGb

    GCPDiskRecord() : base() {
        $this.PSObject.TypeNames.Insert(0, 'PSCumulus.GCPDiskRecord')
    }

    static [GCPDiskRecord] FromGCloudJson([object]$disk, [string]$project) {
        $record = [GCPDiskRecord]::new()
        $zoneName = if ($disk.zone) {
            ($disk.zone -split '/')[-1]
        } else {
            $null
        }

        $resolvedDiskType = if ($disk.type) {
            ($disk.type -split '/')[-1]
        } else {
            $null
        }

        $status = if ($disk.status) {
            (Get-Culture).TextInfo.ToTitleCase($disk.status.ToLower())
        } else {
            $null
        }

        $createdAt = $null
        if (-not [string]::IsNullOrWhiteSpace($disk.creationTimestamp)) {
            $createdAt = [datetime]::Parse($disk.creationTimestamp)
        }

        $record.Kind = 'Disk'
        $record.Provider = [CloudProvider]::GCP.ToString()
        $record.Name = $disk.name
        $record.Region = $zoneName
        $record.Status = $status
        $record.Size = "$($disk.sizeGb) GB"
        $record.CreatedAt = $createdAt
        $record.Project = $project
        $record.Zone = $zoneName
        $record.DiskType = $resolvedDiskType
        $record.SizeGb = $disk.sizeGb
        $record.Metadata = @{
            Project  = $project
            Zone     = $zoneName
            DiskType = $resolvedDiskType
            SizeGb   = $disk.sizeGb
        }

        return $record
    }
}

# Azure Storage Record
class AzureStorageRecord : CloudRecord {
    [string]$ResourceGroup
    [string]$AccountName

    AzureStorageRecord() : base() {
        $this.PSObject.TypeNames.Insert(0, 'PSCumulus.AzureStorageRecord')
    }

    static [AzureStorageRecord] FromAzStorageAccount([object]$account) {
        $record = [AzureStorageRecord]::new()

        $record.Kind = 'Storage'
        $record.Provider = [CloudProvider]::Azure.ToString()
        $record.Name = $account.StorageAccountName
        $record.Region = if ($account.PrimaryLocation) { $account.PrimaryLocation } elseif ($account.Location) { $account.Location } else { $null }
        $record.Status = if ($account.StatusOfPrimary) { $account.StatusOfPrimary.ToString() } elseif ($account.ProvisioningState) { $account.ProvisioningState.ToString() } else { $null }
        $record.Size = if ($account.Sku) { $account.Sku.Name.ToString() } else { $null }
        $record.CreatedAt = $account.CreationTime
        $record.ResourceGroup = $account.ResourceGroupName
        $record.AccountName = $account.StorageAccountName
        $record.Tags = [CloudTagHelper]::FromAzureTags($account.Tags)
        $record.Metadata = @{
            ResourceGroup = $account.ResourceGroupName
            AccountName   = $account.StorageAccountName
        }

        return $record
    }
}

# AWS Storage Record
class AWSStorageRecord : CloudRecord {
    [string]$BucketName

    AWSStorageRecord() : base() {
        $this.PSObject.TypeNames.Insert(0, 'PSCumulus.AWSStorageRecord')
    }

    static [AWSStorageRecord] FromS3Bucket([object]$bucket, [string]$bucketRegion) {
        $record = [AWSStorageRecord]::new()

        $record.Kind = 'Storage'
        $record.Provider = [CloudProvider]::AWS.ToString()
        $record.Name = $bucket.BucketName
        $record.Region = $bucketRegion
        $record.Status = 'Available'
        $record.CreatedAt = $bucket.CreationDate
        $record.BucketName = $bucket.BucketName
        $record.Metadata = @{
            BucketName = $bucket.BucketName
        }

        return $record
    }
}

# GCP Storage Record
class GCPStorageRecord : CloudRecord {
    [string]$BucketName
    [string]$Project
    [string]$StorageClass
    [string]$Location

    GCPStorageRecord() : base() {
        $this.PSObject.TypeNames.Insert(0, 'PSCumulus.GCPStorageRecord')
    }

    static [GCPStorageRecord] FromGCloudJson([object]$bucket, [string]$project) {
        $record = [GCPStorageRecord]::new()

        # Bucket names may be prefixed with "gs://" in some output formats
        $resolvedBucketName = if ($bucket.name) {
            $bucket.name -replace '^gs://', ''
        } else {
            $null
        }

        $createdAt = $null
        if (-not [string]::IsNullOrWhiteSpace($bucket.timeCreated)) {
            $createdAt = [datetime]::Parse($bucket.timeCreated)
        }

        $record.Kind = 'Storage'
        $record.Provider = [CloudProvider]::GCP.ToString()
        $record.Name = $resolvedBucketName
        $record.Region = $bucket.location
        $record.Status = if ($bucket.lifecycle) { 'Configured' } else { 'Available' }
        $record.Size = if ($bucket.storageClass) { $bucket.storageClass } else { $null }
        $record.CreatedAt = $createdAt
        $record.BucketName = $resolvedBucketName
        $record.Project = $project
        $record.StorageClass = if ($bucket.storageClass) { $bucket.storageClass } else { $null }
        $record.Location = $bucket.location
        $record.Tags = [CloudTagHelper]::FromGcpLabels($bucket.labels)
        $record.Metadata = @{
            BucketName   = $resolvedBucketName
            Project      = $project
            StorageClass = $bucket.storageClass
            Location     = $bucket.location
        }

        return $record
    }
}

# Azure Network Record
class AzureNetworkRecord : CloudRecord {
    [string]$ResourceGroup
    [string]$AddressSpace
    [string]$VnetId

    AzureNetworkRecord() : base() {
        $this.PSObject.TypeNames.Insert(0, 'PSCumulus.AzureNetworkRecord')
    }

    static [AzureNetworkRecord] FromAzVirtualNetwork([object]$vnet) {
        $record = [AzureNetworkRecord]::new()

        $addressSpaces = if ($vnet.AddressSpace -and $vnet.AddressSpace.AddressPrefixes) {
            $vnet.AddressSpace.AddressPrefixes
        } else {
            @()
        }

        $addressSpaceString = if ($addressSpaces.Count -gt 0) {
            $addressSpaces -join ', '
        } else {
            $null
        }

        $firstAddressPrefix = if ($addressSpaces.Count -gt 0) {
            $addressSpaces[0]
        } else {
            $null
        }

        $subnetCount = if ($vnet.Subnets) {
            @($vnet.Subnets).Count
        } else {
            0
        }

        $record.Kind = 'Network'
        $record.Provider = [CloudProvider]::Azure.ToString()
        $record.Name = $vnet.Name
        $record.Region = $vnet.Location
        $record.Status = if ($vnet.ProvisioningState) { $vnet.ProvisioningState.ToString() } else { $null }
        $record.Size = $firstAddressPrefix
        $record.ResourceGroup = $vnet.ResourceGroupName
        $record.AddressSpace = $addressSpaceString
        $record.VnetId = $vnet.Id
        $record.Tags = [CloudTagHelper]::FromAzureTags($vnet.Tags)
        $record.Metadata = @{
            ResourceGroup = $vnet.ResourceGroupName
            AddressSpace  = $addressSpaceString
            VnetId        = $vnet.Id
            SubnetCount   = $subnetCount
        }

        return $record
    }
}

# AWS Network Record
class AWSNetworkRecord : CloudRecord {
    [string]$VpcId
    [string]$CidrBlock
    [bool]$IsDefault

    AWSNetworkRecord() : base() {
        $this.PSObject.TypeNames.Insert(0, 'PSCumulus.AWSNetworkRecord')
    }

    static [AWSNetworkRecord] FromEC2Vpc([object]$vpc) {
        $record = [AWSNetworkRecord]::new()

        $nameTag = $vpc.Tags |
            Where-Object { $_.Key -eq 'Name' } |
            Select-Object -First 1 -ExpandProperty Value

        $resolvedName = if ([string]::IsNullOrWhiteSpace($nameTag)) {
            $vpc.VpcId
        } else {
            $nameTag
        }

        $cidrBlocks = if ($vpc.CidrBlockAssociations) {
            ($vpc.CidrBlockAssociations | Where-Object { $_.CidrBlockState.State -eq 'associated' } |
                ForEach-Object { $_.CidrBlock }) -join ', '
        } elseif ($vpc.CidrBlock) {
            $vpc.CidrBlock
        } else {
            $null
        }

        $status = if ($vpc.State) {
            if ($vpc.State.Value) {
                $vpc.State.Value
            } else {
                $vpc.State.ToString()
            }
        } else {
            'Available'
        }

        $record.Kind = 'Network'
        $record.Provider = [CloudProvider]::AWS.ToString()
        $record.Name = $resolvedName
        $record.Region = if ($vpc.RegionName) { $vpc.RegionName } else { $null }
        $record.Status = $status
        $record.Size = $cidrBlocks
        $record.VpcId = $vpc.VpcId
        $record.CidrBlock = $cidrBlocks
        $record.IsDefault = $vpc.IsDefault
        $record.Tags = [CloudTagHelper]::FromAwsTags($vpc.Tags)
        $record.Metadata = @{
            VpcId    = $vpc.VpcId
            CidrBlock = $cidrBlocks
            IsDefault = $vpc.IsDefault
        }

        return $record
    }
}

# GCP Network Record
class GCPNetworkRecord : CloudRecord {
    [string]$Project
    [string]$NetworkName
    [string]$VpcId

    GCPNetworkRecord() : base() {
        $this.PSObject.TypeNames.Insert(0, 'PSCumulus.GCPNetworkRecord')
    }

    static [GCPNetworkRecord] FromGCloudJson([object]$network, [string]$project) {
        $record = [GCPNetworkRecord]::new()

        $createdAt = $null
        if (-not [string]::IsNullOrWhiteSpace($network.creationTimestamp)) {
            $createdAt = [datetime]::Parse($network.creationTimestamp)
        }

        $subnetworkMode = if ($network.autoCreateSubnetworks) { 'auto' } else { 'custom' }

        $record.Kind = 'Network'
        $record.Provider = [CloudProvider]::GCP.ToString()
        $record.Name = $network.name
        $record.Region = 'global'
        $record.Status = 'Available'
        $record.CreatedAt = $createdAt
        $record.Project = $project
        $record.NetworkName = $network.name
        $record.VpcId = if ($network.id) { $network.id.ToString() } else { $null }
        $record.Metadata = @{
            Project        = $project
            NetworkName    = $network.name
            VpcId          = if ($network.id) { $network.id.ToString() } else { $null }
            SubnetworkMode = $subnetworkMode
        }

        return $record
    }
}

# Azure Function Record
class AzureFunctionRecord : CloudRecord {
    [string]$ResourceGroup
    [string]$Runtime

    AzureFunctionRecord() : base() {
        $this.PSObject.TypeNames.Insert(0, 'PSCumulus.AzureFunctionRecord')
    }

    static [AzureFunctionRecord] FromAzFunctionApp([object]$functionApp) {
        $record = [AzureFunctionRecord]::new()

        $resolvedRuntime = if ($functionApp.Runtime) {
            $functionApp.Runtime
        } elseif ($functionApp.Config -and $functionApp.Config.FunctionAppRuntime) {
            $functionApp.Config.FunctionAppRuntime
        } else {
            $null
        }

        $record.Kind = 'Function'
        $record.Provider = [CloudProvider]::Azure.ToString()
        $record.Name = $functionApp.Name
        $record.Region = $functionApp.Location
        $record.Status = if ($functionApp.State) { $functionApp.State.ToString() } else { 'Running' }
        $record.Size = $resolvedRuntime
        $record.ResourceGroup = $functionApp.ResourceGroupName
        $record.Runtime = $resolvedRuntime
        $record.Tags = [CloudTagHelper]::FromAzureTags($functionApp.Tags)
        $record.Metadata = @{
            ResourceGroup  = $functionApp.ResourceGroupName
            Runtime        = $resolvedRuntime
            RuntimeVersion = if ($functionApp.RuntimeVersion) { $functionApp.RuntimeVersion } else { $null }
        }

        return $record
    }
}

# AWS Function Record
class AWSFunctionRecord : CloudRecord {
    [string]$FunctionName
    [string]$Runtime

    AWSFunctionRecord() : base() {
        $this.PSObject.TypeNames.Insert(0, 'PSCumulus.AWSFunctionRecord')
    }

    static [AWSFunctionRecord] FromLambdaFunction([object]$function, [string]$region) {
        $record = [AWSFunctionRecord]::new()

        $resolvedRegion = if (-not [string]::IsNullOrWhiteSpace($region)) {
            $region
        } elseif ($function.FunctionArn) {
            ($function.FunctionArn -split ':')[3]
        } else {
            $null
        }

        $runtimeValue = if ($function.Runtime) {
            if ($function.Runtime -is [string]) {
                $function.Runtime
            } elseif ($function.Runtime.Value) {
                $function.Runtime.Value
            } else {
                $null
            }
        } else {
            $null
        }

        $record.Kind = 'Function'
        $record.Provider = [CloudProvider]::AWS.ToString()
        $record.Name = $function.FunctionName
        $record.Region = $resolvedRegion
        $record.Status = if ($function.State) { (Get-Culture).TextInfo.ToTitleCase($function.State.ToLower()) } else { 'Active' }
        $record.Size = $runtimeValue
        $record.CreatedAt = $function.LastModified
        $record.FunctionName = $function.FunctionName
        $record.Runtime = $runtimeValue
        $record.Tags = [CloudTagHelper]::FromAwsTags($function.Tags)
        $record.Metadata = @{
            FunctionName = $function.FunctionName
            Runtime      = $runtimeValue
            FunctionArn  = $function.FunctionArn
        }

        return $record
    }
}

# GCP Function Record
class GCPFunctionRecord : CloudRecord {
    [string]$Project
    [string]$Runtime
    [string]$EntryPoint

    GCPFunctionRecord() : base() {
        $this.PSObject.TypeNames.Insert(0, 'PSCumulus.GCPFunctionRecord')
    }

    static [GCPFunctionRecord] FromGCloudJson([object]$function, [string]$project) {
        $record = [GCPFunctionRecord]::new()

        $nameParts = $function.name -split '/'
        $shortName = $nameParts[-1]
        $region = if ($nameParts.Count -ge 4) { $nameParts[-3] } else { $null }

        $rawStatus = if ($function.state) { $function.state } elseif ($function.status) { $function.status } else { $null }
        $status = if ($rawStatus) {
            (Get-Culture).TextInfo.ToTitleCase($rawStatus.ToLower())
        } else {
            $null
        }

        $createdAt = $null
        if (-not [string]::IsNullOrWhiteSpace($function.updateTime)) {
            $createdAt = [datetime]::Parse($function.updateTime)
        }

        $record.Kind = 'Function'
        $record.Provider = [CloudProvider]::GCP.ToString()
        $record.Name = $shortName
        $record.Region = $region
        $record.Status = $status
        $record.Size = if ($function.runtime) { $function.runtime } else { $null }
        $record.CreatedAt = $createdAt
        $record.Project = $project
        $record.Runtime = if ($function.runtime) { $function.runtime } else { $null }
        $record.EntryPoint = if ($function.entryPoint) { $function.entryPoint } else { $null }
        $record.Metadata = @{
            Project    = $project
            Runtime    = $function.runtime
            EntryPoint = $function.entryPoint
            FullName   = $function.name
        }

        return $record
    }
}

# Azure Tag Record
class AzureTagRecord : CloudRecord {
    [string]$ResourceId
    [hashtable]$TagData

    AzureTagRecord() : base() {
        $this.PSObject.TypeNames.Insert(0, 'PSCumulus.AzureTagRecord')
    }

    static [AzureTagRecord] FromAzTag([object]$tagWrapper, [string]$resourceId) {
        $record = [AzureTagRecord]::new()

        $tags = @{}
        if ($tagWrapper.Properties -and $tagWrapper.Properties.TagsProperty) {
            foreach ($kvp in $tagWrapper.Properties.TagsProperty.GetEnumerator()) {
                $tags[$kvp.Key] = $kvp.Value
            }
        }

        $resourceName = ($resourceId -split '/')[-1]

        $record.Kind = 'Tag'
        $record.Provider = [CloudProvider]::Azure.ToString()
        $record.Name = $resourceName
        $record.Status = if ($tagWrapper.Properties) { 'Tagged' } else { 'No Tags' }
        $record.ResourceId = $resourceId
        $record.TagData = $tags
        $record.Tags = $tags
        $record.Metadata = @{
            ResourceId = $resourceId
            Tags       = $tags
        }

        return $record
    }
}

# AWS Tag Record
class AWSTagRecord : CloudRecord {
    [string]$ResourceId
    [hashtable]$TagData

    AWSTagRecord() : base() {
        $this.PSObject.TypeNames.Insert(0, 'PSCumulus.AWSTagRecord')
    }

    static [AWSTagRecord] FromEC2Tags([object[]]$tagObjects, [string]$resourceId) {
        $record = [AWSTagRecord]::new()

        $tags = @{}
        foreach ($tag in $tagObjects) {
            $tags[$tag.Key] = $tag.Value
        }

        $record.Kind = 'Tag'
        $record.Provider = [CloudProvider]::AWS.ToString()
        $record.Name = $resourceId
        $record.Status = if ($tags.Count -gt 0) { 'Tagged' } else { 'No Tags' }
        $record.ResourceId = $resourceId
        $record.TagData = $tags
        $record.Tags = $tags
        $record.Metadata = @{
            ResourceId = $resourceId
            Tags       = $tags
        }

        return $record
    }
}

# GCP Tag Record
class GCPTagRecord : CloudRecord {
    [string]$Project
    [string]$Resource
    [hashtable]$LabelData

    GCPTagRecord() : base() {
        $this.PSObject.TypeNames.Insert(0, 'PSCumulus.GCPTagRecord')
    }

    static [GCPTagRecord] FromGCloudLabels([object]$labels, [string]$project, [string]$resource) {
        $record = [GCPTagRecord]::new()

        $labelHashtable = @{}
        if ($labels) {
            if ($labels -is [hashtable]) {
                $labelHashtable = $labels
            } else {
                foreach ($property in $labels.PSObject.Properties) {
                    $labelHashtable[$property.Name] = $property.Value
                }
            }
        }

        # Resource is in the form "instances/vm-01" or "disks/my-disk"
        $parts = $resource -split '/', 2
        $resourceName = if ($parts.Count -gt 1) { $parts[1] } else { $resource }

        $record.Kind = 'Tag'
        $record.Provider = [CloudProvider]::GCP.ToString()
        $record.Name = $resourceName
        $record.Status = if ($labelHashtable.Count -gt 0) { 'Labeled' } else { 'No Labels' }
        $record.Project = $project
        $record.Resource = $resource
        $record.LabelData = $labelHashtable
        $record.Tags = $labelHashtable
        $record.Metadata = @{
            Project  = $project
            Resource = $resource
            Labels   = $labelHashtable
        }

        return $record
    }
}
