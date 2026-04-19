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

enum CloudDiskStatus {
    Unknown
    Available
    Attached
    Busy
    Failed
}

enum CloudStorageStatus {
    Unknown
    Available
    Configured
    Failed
}

enum CloudNetworkStatus {
    Unknown
    Available
    Failed
}

enum CloudFunctionStatus {
    Unknown
    Active
    Inactive
    Failed
}

enum CloudSnapshotStatus {
    Unknown
    Available
    Creating
    Deleting
    Error
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

class CloudDiskStatusMap {
    static [object] FromAzure([string]$diskState) {
        if ([string]::IsNullOrWhiteSpace($diskState)) {
            return $null
        }

        switch ($diskState.Trim().ToUpperInvariant()) {
            'ATTACHED'     { return [CloudDiskStatus]::Attached }
            'UNATTACHED'   { return [CloudDiskStatus]::Available }
            'ACTIVESAS'    { return [CloudDiskStatus]::Busy }
            'READY'        { return [CloudDiskStatus]::Available }
            default        { return [CloudDiskStatus]::Unknown }
        }

        return [CloudDiskStatus]::Unknown
    }

    static [object] FromAws([string]$volumeState) {
        if ([string]::IsNullOrWhiteSpace($volumeState)) {
            return $null
        }

        switch ($volumeState.Trim().ToLowerInvariant()) {
            'available'    { return [CloudDiskStatus]::Available }
            'in-use'       { return [CloudDiskStatus]::Attached }
            'creating'     { return [CloudDiskStatus]::Busy }
            'deleting'     { return [CloudDiskStatus]::Busy }
            'deleted'      { return [CloudDiskStatus]::Unknown }
            'error'        { return [CloudDiskStatus]::Failed }
            default        { return [CloudDiskStatus]::Unknown }
        }

        return [CloudDiskStatus]::Unknown
    }

    static [object] FromGcp([string]$diskStatus) {
        if ([string]::IsNullOrWhiteSpace($diskStatus)) {
            return $null
        }

        switch ($diskStatus.Trim().ToUpperInvariant()) {
            'READY'        { return [CloudDiskStatus]::Available }
            'CREATING'     { return [CloudDiskStatus]::Busy }
            'DELETING'     { return [CloudDiskStatus]::Busy }
            'RESTORING'    { return [CloudDiskStatus]::Busy }
            'FAILED'       { return [CloudDiskStatus]::Failed }
            default        { return [CloudDiskStatus]::Unknown }
        }

        return [CloudDiskStatus]::Unknown
    }
}

class CloudStorageStatusMap {
    static [object] FromAzure([string]$provisioningState, [string]$statusOfPrimary) {
        $stateToCheck = if (-not [string]::IsNullOrWhiteSpace($statusOfPrimary)) { $statusOfPrimary } elseif (-not [string]::IsNullOrWhiteSpace($provisioningState)) { $provisioningState } else { $null }

        if ([string]::IsNullOrWhiteSpace($stateToCheck)) {
            return $null
        }

        switch ($stateToCheck.Trim().ToUpperInvariant()) {
            'SUCCEEDED'    { return [CloudStorageStatus]::Available }
            'AVAILABLE'    { return [CloudStorageStatus]::Available }
            'CREATING'     { return [CloudStorageStatus]::Unknown }
            'DELETING'     { return [CloudStorageStatus]::Unknown }
            'RESOLVINGDNS' { return [CloudStorageStatus]::Unknown }
            default        { return [CloudStorageStatus]::Unknown }
        }

        return [CloudStorageStatus]::Unknown
    }

    static [object] FromAws([string]$bucketStatus) {
        if ([string]::IsNullOrWhiteSpace($bucketStatus)) {
            return $null
        }

        switch ($bucketStatus.Trim().ToLowerInvariant()) {
            'available'    { return [CloudStorageStatus]::Available }
            default        { return [CloudStorageStatus]::Unknown }
        }

        return [CloudStorageStatus]::Unknown
    }

    static [object] FromGcp([bool]$hasLifecycleRules) {
        if ($hasLifecycleRules) {
            return [CloudStorageStatus]::Configured
        }
        return [CloudStorageStatus]::Available
    }
}

class CloudNetworkStatusMap {
    static [object] FromAzure([string]$provisioningState) {
        if ([string]::IsNullOrWhiteSpace($provisioningState)) {
            return $null
        }

        switch ($provisioningState.Trim().ToUpperInvariant()) {
            'SUCCEEDED'    { return [CloudNetworkStatus]::Available }
            'FAILED'       { return [CloudNetworkStatus]::Failed }
            'UPDATING'     { return [CloudNetworkStatus]::Unknown }
            'DELETING'     { return [CloudNetworkStatus]::Unknown }
            default        { return [CloudNetworkStatus]::Unknown }
        }

        return [CloudNetworkStatus]::Unknown
    }

    static [object] FromAws([string]$vpcState) {
        if ([string]::IsNullOrWhiteSpace($vpcState)) {
            return $null
        }

        switch ($vpcState.Trim().ToLowerInvariant()) {
            'available'    { return [CloudNetworkStatus]::Available }
            default        { return [CloudNetworkStatus]::Unknown }
        }

        return [CloudNetworkStatus]::Unknown
    }

    static [object] FromGcp() {
        return [CloudNetworkStatus]::Available
    }
}

class CloudFunctionStatusMap {
    static [object] FromAzure([string]$functionState) {
        if ([string]::IsNullOrWhiteSpace($functionState)) {
            return $null
        }

        switch ($functionState.Trim().ToUpperInvariant()) {
            'RUNNING'      { return [CloudFunctionStatus]::Active }
            'STOPPED'      { return [CloudFunctionStatus]::Inactive }
            'DISABLED'     { return [CloudFunctionStatus]::Inactive }
            'DEFAULT'      { return [CloudFunctionStatus]::Unknown }
            default        { return [CloudFunctionStatus]::Unknown }
        }

        return [CloudFunctionStatus]::Unknown
    }

    static [object] FromAws([string]$functionState) {
        if ([string]::IsNullOrWhiteSpace($functionState)) {
            return $null
        }

        switch ($functionState.Trim().ToLowerInvariant()) {
            'active'       { return [CloudFunctionStatus]::Active }
            'pending'      { return [CloudFunctionStatus]::Unknown }
            'inactive'     { return [CloudFunctionStatus]::Inactive }
            default        { return [CloudFunctionStatus]::Unknown }
        }

        return [CloudFunctionStatus]::Unknown
    }

    static [object] FromGcp([string]$functionStatus) {
        if ([string]::IsNullOrWhiteSpace($functionStatus)) {
            return $null
        }

        switch ($functionStatus.Trim().ToUpperInvariant()) {
            'ACTIVE'       { return [CloudFunctionStatus]::Active }
            'OFFLINE'      { return [CloudFunctionStatus]::Inactive }
            'DEPLOYING'    { return [CloudFunctionStatus]::Unknown }
            'DEPLOYED'     { return [CloudFunctionStatus]::Active }
            'UNDEPLOYED'   { return [CloudFunctionStatus]::Inactive }
            default        { return [CloudFunctionStatus]::Unknown }
        }

        return [CloudFunctionStatus]::Unknown
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
            ResourceGroup = $vm.ResourceGroupName
            VmId = $vm.VmId
            OsType = $resolvedOsType
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
            InstanceId = $instance.InstanceId
            VpcId = $instance.VpcId
            SubnetId = $instance.SubnetId
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
            Project = $project
            Zone = $zoneName
            Id = $instance.id
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
        $nativeStatus = if ($disk.DiskState) { $disk.DiskState.ToString() } else { $null }
        $normalizedStatus = [CloudDiskStatusMap]::FromAzure($nativeStatus)
        if ($null -eq $normalizedStatus) {
            $normalizedStatus = [CloudDiskStatus]::Unknown
        }
        $resolvedOsType = if ($disk.OsType) { $disk.OsType.ToString() } else { $null }

        $record.Kind = 'Disk'
        $record.Provider = [CloudProvider]::Azure.ToString()
        $record.Name = $disk.Name
        $record.Region = $disk.Location
        $record.Status = $normalizedStatus.ToString()
        $record.Size = "$($disk.DiskSizeGB) GB"
        $record.CreatedAt = $disk.TimeCreated
        $record.ResourceGroup = $disk.ResourceGroupName
        $record.DiskSizeGB = $disk.DiskSizeGB
        $record.Sku = $disk.Sku.Name
        $record.OsType = $resolvedOsType
        $record.Metadata = @{
            NativeStatus   = $nativeStatus
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

        $nativeStatus = if ($volume.State -and $volume.State.Value) { $volume.State.Value } else { $null }
        $normalizedStatus = [CloudDiskStatusMap]::FromAws($nativeStatus)
        if ($null -eq $normalizedStatus) {
            $normalizedStatus = [CloudDiskStatus]::Unknown
        }

        $record.Kind = 'Disk'
        $record.Provider = [CloudProvider]::AWS.ToString()
        $record.Name = $resolvedName
        $record.Region = $volume.AvailabilityZone
        $record.Status = $normalizedStatus.ToString()
        $record.Size = "$($volume.Size) GB"
        $record.CreatedAt = $volume.CreateTime
        $record.VolumeId = $volume.VolumeId
        $record.VolumeType = $volume.VolumeType.Value
        $record.Encrypted = $volume.Encrypted
        $record.InstanceId = $attachedInstanceId
        $record.Metadata = @{
            NativeStatus = $nativeStatus
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

        $nativeStatus = if ($disk.status) { $disk.status } else { $null }
        $normalizedStatus = [CloudDiskStatusMap]::FromGcp($nativeStatus)
        if ($null -eq $normalizedStatus) {
            $normalizedStatus = [CloudDiskStatus]::Unknown
        }

        $createdAt = $null
        if (-not [string]::IsNullOrWhiteSpace($disk.creationTimestamp)) {
            $createdAt = [datetime]::Parse($disk.creationTimestamp)
        }

        $record.Kind = 'Disk'
        $record.Provider = [CloudProvider]::GCP.ToString()
        $record.Name = $disk.name
        $record.Region = $zoneName
        $record.Status = $normalizedStatus.ToString()
        $record.Size = "$($disk.sizeGb) GB"
        $record.CreatedAt = $createdAt
        $record.Project = $project
        $record.Zone = $zoneName
        $record.DiskType = $resolvedDiskType
        $record.SizeGb = $disk.sizeGb
        $record.Metadata = @{
            NativeStatus = $nativeStatus
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

        $nativeStatusOfPrimary = if ($account.StatusOfPrimary) { $account.StatusOfPrimary.ToString() } else { $null }
        $nativeProvisioningState = if ($account.ProvisioningState) { $account.ProvisioningState.ToString() } else { $null }
        $normalizedStatus = [CloudStorageStatusMap]::FromAzure($nativeProvisioningState, $nativeStatusOfPrimary)
        if ($null -eq $normalizedStatus) {
            $normalizedStatus = [CloudStorageStatus]::Unknown
        }

        $record.Kind = 'Storage'
        $record.Provider = [CloudProvider]::Azure.ToString()
        $record.Name = $account.StorageAccountName
        $record.Region = if ($account.PrimaryLocation) { $account.PrimaryLocation } elseif ($account.Location) { $account.Location } else { $null }
        $record.Status = $normalizedStatus.ToString()
        $record.Size = if ($account.Sku) { $account.Sku.Name.ToString() } else { $null }
        $record.CreatedAt = $account.CreationTime
        $record.ResourceGroup = $account.ResourceGroupName
        $record.AccountName = $account.StorageAccountName
        $record.Tags = [CloudTagHelper]::FromAzureTags($account.Tags)
        $record.Metadata = @{
            NativeStatus = $nativeStatusOfPrimary
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

        $normalizedStatus = [CloudStorageStatusMap]::FromAws('available')
        if ($null -eq $normalizedStatus) {
            $normalizedStatus = [CloudStorageStatus]::Available
        }

        $record.Kind = 'Storage'
        $record.Provider = [CloudProvider]::AWS.ToString()
        $record.Name = $bucket.BucketName
        $record.Region = $bucketRegion
        $record.Status = $normalizedStatus.ToString()
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

        $hasLifecycleRules = if ($bucket.lifecycle) { $true } else { $false }
        $normalizedStatus = [CloudStorageStatusMap]::FromGcp($hasLifecycleRules)
        if ($null -eq $normalizedStatus) {
            $normalizedStatus = [CloudStorageStatus]::Available
        }

        $createdAt = $null
        if (-not [string]::IsNullOrWhiteSpace($bucket.timeCreated)) {
            $createdAt = [datetime]::Parse($bucket.timeCreated)
        }

        $record.Kind = 'Storage'
        $record.Provider = [CloudProvider]::GCP.ToString()
        $record.Name = $resolvedBucketName
        $record.Region = $bucket.location
        $record.Status = $normalizedStatus.ToString()
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

        $nativeProvisioningState = if ($vnet.ProvisioningState) { $vnet.ProvisioningState.ToString() } else { $null }
        $normalizedStatus = [CloudNetworkStatusMap]::FromAzure($nativeProvisioningState)
        if ($null -eq $normalizedStatus) {
            $normalizedStatus = [CloudNetworkStatus]::Unknown
        }

        $record.Kind = 'Network'
        $record.Provider = [CloudProvider]::Azure.ToString()
        $record.Name = $vnet.Name
        $record.Region = $vnet.Location
        $record.Status = $normalizedStatus.ToString()
        $record.Size = $firstAddressPrefix
        $record.ResourceGroup = $vnet.ResourceGroupName
        $record.AddressSpace = $addressSpaceString
        $record.VnetId = $vnet.Id
        $record.Tags = [CloudTagHelper]::FromAzureTags($vnet.Tags)
        $record.Metadata = @{
            NativeStatus  = $nativeProvisioningState
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

        $nativeStatus = if ($vpc.State) {
            if ($vpc.State.Value) {
                $vpc.State.Value
            } else {
                $vpc.State.ToString()
            }
        } else {
            $null
        }
        $normalizedStatus = [CloudNetworkStatusMap]::FromAws($nativeStatus)
        if ($null -eq $normalizedStatus) {
            $normalizedStatus = [CloudNetworkStatus]::Available
        }

        $record.Kind = 'Network'
        $record.Provider = [CloudProvider]::AWS.ToString()
        $record.Name = $resolvedName
        $record.Region = if ($vpc.RegionName) { $vpc.RegionName } else { $null }
        $record.Status = $normalizedStatus.ToString()
        $record.Size = $cidrBlocks
        $record.VpcId = $vpc.VpcId
        $record.CidrBlock = $cidrBlocks
        $record.IsDefault = $vpc.IsDefault
        $record.Tags = [CloudTagHelper]::FromAwsTags($vpc.Tags)
        $record.Metadata = @{
            NativeStatus = $nativeStatus
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

        $normalizedStatus = [CloudNetworkStatusMap]::FromGcp()
        if ($null -eq $normalizedStatus) {
            $normalizedStatus = [CloudNetworkStatus]::Available
        }

        $createdAt = $null
        if (-not [string]::IsNullOrWhiteSpace($network.creationTimestamp)) {
            $createdAt = [datetime]::Parse($network.creationTimestamp)
        }

        $subnetworkMode = if ($network.autoCreateSubnetworks) { 'auto' } else { 'custom' }

        $record.Kind = 'Network'
        $record.Provider = [CloudProvider]::GCP.ToString()
        $record.Name = $network.name
        $record.Region = 'global'
        $record.Status = $normalizedStatus.ToString()
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

        $nativeStatus = if ($functionApp.State) { $functionApp.State.ToString() } else { $null }
        $normalizedStatus = [CloudFunctionStatusMap]::FromAzure($nativeStatus)
        if ($null -eq $normalizedStatus) {
            $normalizedStatus = [CloudFunctionStatus]::Unknown
        }

        $record.Kind = 'Function'
        $record.Provider = [CloudProvider]::Azure.ToString()
        $record.Name = $functionApp.Name
        $record.Region = $functionApp.Location
        $record.Status = $normalizedStatus.ToString()
        $record.Size = $resolvedRuntime
        $record.ResourceGroup = $functionApp.ResourceGroupName
        $record.Runtime = $resolvedRuntime
        $record.Tags = [CloudTagHelper]::FromAzureTags($functionApp.Tags)
        $record.Metadata = @{
            NativeStatus    = $nativeStatus
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

        $nativeStatus = if ($function.State) { $function.State } else { $null }
        $normalizedStatus = [CloudFunctionStatusMap]::FromAws($nativeStatus)
        if ($null -eq $normalizedStatus) {
            $normalizedStatus = [CloudFunctionStatus]::Unknown
        }

        $record.Kind = 'Function'
        $record.Provider = [CloudProvider]::AWS.ToString()
        $record.Name = $function.FunctionName
        $record.Region = $resolvedRegion
        $record.Status = $normalizedStatus.ToString()
        $record.Size = $runtimeValue
        $record.CreatedAt = $function.LastModified
        $record.FunctionName = $function.FunctionName
        $record.Runtime = $runtimeValue
        $record.Tags = [CloudTagHelper]::FromAwsTags($function.Tags)
        $record.Metadata = @{
            NativeStatus = $nativeStatus
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

        $nativeStatus = if ($function.state) { $function.state } elseif ($function.status) { $function.status } else { $null }
        $normalizedStatus = [CloudFunctionStatusMap]::FromGcp($nativeStatus)
        if ($null -eq $normalizedStatus) {
            $normalizedStatus = [CloudFunctionStatus]::Unknown
        }

        $createdAt = $null
        if (-not [string]::IsNullOrWhiteSpace($function.updateTime)) {
            $createdAt = [datetime]::Parse($function.updateTime)
        }

        $record.Kind = 'Function'
        $record.Provider = [CloudProvider]::GCP.ToString()
        $record.Name = $shortName
        $record.Region = $region
        $record.Status = $normalizedStatus.ToString()
        $record.Size = if ($function.runtime) { $function.runtime } else { $null }
        $record.CreatedAt = $createdAt
        $record.Project = $project
        $record.Runtime = if ($function.runtime) { $function.runtime } else { $null }
        $record.EntryPoint = if ($function.entryPoint) { $function.entryPoint } else { $null }
        $record.Metadata = @{
            NativeStatus = $nativeStatus
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

# Azure Snapshot Record
class AzureSnapshotRecord : CloudRecord {
    [string]$ResourceGroup
    [string]$SubscriptionId
    [string]$SourceDiskId
    [int]$SizeGB

    AzureSnapshotRecord() : base() {
        $this.PSObject.TypeNames.Insert(0, 'PSCumulus.AzureSnapshotRecord')
    }

    static [AzureSnapshotRecord] FromAzSnapshot([object]$snapshot) {
        $record = [AzureSnapshotRecord]::new()
        $record.Kind = 'Snapshot'
        $record.Provider = [CloudProvider]::Azure.ToString()
        $record.Name = $snapshot.Name
        $record.Id = $snapshot.Id
        $record.Status = [CloudSnapshotStatus]::Available
        $record.ResourceGroup = $snapshot.ResourceGroupName
        $record.SubscriptionId = ($snapshot.Id -split '/')[2]
        $record.SourceDiskId = $snapshot.CreationData.SourceResourceId
        $record.SizeGB = if ($snapshot.DiskSizeGB) { [int]$snapshot.DiskSizeGB } else { 0 }
        $record.Tags = if ($snapshot.Tags) { $snapshot.Tags } else { @{} }
        $record.Metadata = @{
            ResourceGroup  = $record.ResourceGroup
            SubscriptionId = $record.SubscriptionId
            SourceDiskId   = $record.SourceDiskId
            SizeGB         = $record.SizeGB
        }

        return $record
    }
}

# AWS Snapshot Record
class AWSSnapshotRecord : CloudRecord {
    [string]$Region
    [string]$SourceDiskId
    [int]$SizeGB

    AWSSnapshotRecord() : base() {
        $this.PSObject.TypeNames.Insert(0, 'PSCumulus.AWSSnapshotRecord')
    }

    static [AWSSnapshotRecord] FromEc2Snapshot([object]$snapshot) {
        $record = [AWSSnapshotRecord]::new()
        $record.Kind = 'Snapshot'
        $record.Provider = [CloudProvider]::AWS.ToString()
        $record.Name = $snapshot.SnapshotId
        $record.Id = $snapshot.SnapshotId
        $record.Status = [CloudSnapshotStatus]::Available
        $record.Region = $snapshot.AvailabilityZone -replace '[a-z]-\d+$', ''
        $record.SourceDiskId = $snapshot.VolumeId
        $record.SizeGB = if ($snapshot.VolumeSize) { [int]$snapshot.VolumeSize } else { 0 }
        $record.Tags = if ($snapshot.Tags) {
            $tagHash = @{}
            foreach ($tag in $snapshot.Tags) { $tagHash[$tag.Key] = $tag.Value }
            $tagHash
        } else { @{} }
        $record.Metadata = @{
            Region        = $record.Region
            SourceDiskId  = $record.SourceDiskId
            SizeGB        = $record.SizeGB
        }

        return $record
    }
}

# GCP Snapshot Record
class GCPSnapshotRecord : CloudRecord {
    [string]$Project
    [string]$SourceDiskId
    [int]$SizeGB

    GCPSnapshotRecord() : base() {
        $this.PSObject.TypeNames.Insert(0, 'PSCumulus.GCPSnapshotRecord')
    }

    static [GCPSnapshotRecord] FromGcpSnapshot([object]$snapshot, [string]$project) {
        $record = [GCPSnapshotRecord]::new()
        $record.Kind = 'Snapshot'
        $record.Provider = [CloudProvider]::GCP.ToString()
        $record.Name = $snapshot.Name
        $record.Id = $snapshot.SelfLink
        $record.Status = [CloudSnapshotStatus]::Available
        $record.Project = $project
        $record.SourceDiskId = $snapshot.SourceDisk
        $record.SizeGB = if ($snapshot.DiskSizeGb) { [int]$snapshot.DiskSizeGb } else { 0 }
        $record.Tags = if ($snapshot.Labels) { $snapshot.Labels } else { @{} }
        $record.Metadata = @{
            Project       = $project
            SourceDiskId  = $record.SourceDiskId
            SizeGB        = $record.SizeGB
        }

        return $record
    }
}

# Azure Image Record
class AzureImageRecord : CloudRecord {
    [string]$ResourceGroup
    [string]$SubscriptionId
    [string]$Publisher
    [string]$OsType
    [DateTime]$CreatedAt

    AzureImageRecord() : base() {
        $this.PSObject.TypeNames.Insert(0, 'PSCumulus.AzureImageRecord')
    }

    static [AzureImageRecord] FromAzImage([object]$image) {
        $record = [AzureImageRecord]::new()
        $record.Kind = 'Image'
        $record.Provider = [CloudProvider]::Azure.ToString()
        $record.Name = $image.Name
        $record.Id = $image.Id
        $record.Status = 'Available'
        $record.ResourceGroup = $image.ResourceGroupName
        $record.SubscriptionId = ($image.Id -split '/')[2]
        $record.Publisher = if ($image.ImagePlan) { $image.ImagePlan.Publisher } else { $null }
        $record.OsType = if ($image.StorageProfile.OsDisk.OperatingSystemType) { $image.StorageProfile.OsDisk.OperatingSystemType } else { $null }
        $record.CreatedAt = if ($image.TimeCreated) { [DateTime]$image.TimeCreated } else { [DateTime]::MinValue }
        $record.Tags = if ($image.Tags) { $image.Tags } else { @{} }
        $record.Metadata = @{
            ResourceGroup = $record.ResourceGroup
            Publisher    = $record.Publisher
            OsType       = $record.OsType
        }

        return $record
    }
}

# AWS Image Record
class AWSImageRecord : CloudRecord {
    [string]$Region
    [string]$Publisher
    [string]$OsType
    [DateTime]$CreatedAt

    AWSImageRecord() : base() {
        $this.PSObject.TypeNames.Insert(0, 'PSCumulus.AWSImageRecord')
    }

    static [AWSImageRecord] FromEc2Image([object]$image) {
        $record = [AWSImageRecord]::new()
        $record.Kind = 'Image'
        $record.Provider = [CloudProvider]::AWS.ToString()
        $record.Name = $image.Name
        $record.Id = $image.ImageId
        $record.Status = 'Available'
        $record.Region = if ($image.ImageLocation) { ($image.ImageLocation -split '/')[0] } else { $null }
        $record.Publisher = if ($image.OwnerId) { $image.OwnerId } else { $null }
        $record.OsType = if ($image.Platform) { $image.Platform } else { $null }
        $record.CreatedAt = if ($image.CreationDate) { [DateTime]$image.CreationDate } else { [DateTime]::MinValue }
        $record.Tags = if ($image.Tags) {
            $tagHash = @{}
            foreach ($tag in $image.Tags) { $tagHash[$tag.Key] = $tag.Value }
            $tagHash
        } else { @{} }
        $record.Metadata = @{
            Region   = $record.Region
            Publisher = $record.Publisher
            OsType   = $record.OsType
        }

        return $record
    }
}

# GCP Image Record
class GCPImageRecord : CloudRecord {
    [string]$Project
    [string]$Publisher
    [string]$OsType
    [DateTime]$CreatedAt

    GCPImageRecord() : base() {
        $this.PSObject.TypeNames.Insert(0, 'PSCumulus.GCPImageRecord')
    }

    static [GCPImageRecord] FromGcpImage([object]$image, [string]$project) {
        $record = [GCPImageRecord]::new()
        $record.Kind = 'Image'
        $record.Provider = [CloudProvider]::GCP.ToString()
        $record.Name = $image.Name
        $record.Id = $image.SelfLink
        $record.Status = 'Available'
        $record.Project = $project
        $record.Publisher = if ($image.Licenses) { $image.Licenses -join ',' } else { $null }
        $record.OsType = if ($image.DiskSizeGb) { 'Unknown' } else { $null }
        $record.CreatedAt = if ($image.CreationTimestamp) { [DateTime]$image.CreationTimestamp } else { [DateTime]::MinValue }
        $record.Tags = if ($image.Labels) { $image.Labels } else { @{} }
        $record.Metadata = @{
            Project  = $project
            Publisher = $record.Publisher
            OsType   = $record.OsType
        }

        return $record
    }
}
