function Set-CloudTag {
    <#
        .SYNOPSIS
            Sets tags or labels on a cloud resource across Azure, AWS, or GCP.

        .DESCRIPTION
            Set-CloudTag applies tags (Azure), tags (AWS), or labels (GCP) to cloud resources.
            For Azure, you can specify a VM by Name/ResourceGroup or any resource by ResourceId.
            For AWS, provide the ResourceId and Region. For GCP, provide the Project and Resource.
            You can also pipe CloudRecord objects from other PSCumulus commands, or address a
            resource by CloudPath with -Path (resolved through Get-CloudResource).

        .EXAMPLE
            Set-CloudTag -Name 'vm01' -ResourceGroup 'rg-test' -Tags @{Environment='Dev'; Owner='TeamA'}

            Tags an Azure VM by name and resource group.

        .EXAMPLE
            Set-CloudTag -AzureResourceId '/subscriptions/123/resourceGroups/rg/providers/Microsoft.Compute/disks/disk01' -Tags @{Backup='Weekly'}

            Tags an Azure disk using its full resource ID (AzureById parameter set).

        .EXAMPLE
            Set-CloudTag -ResourceId 'i-1234567890abcdef0' -Region 'us-east-1' -Tags @{Environment='Prod'}

            Tags an AWS EC2 instance by its resource ID.

        .EXAMPLE
            Set-CloudTag -Project 'my-project' -Resource 'projects/my/zones/us-central1-a/instances/vm01' -Tags @{Owner='Ops'}

            Tags a GCP compute instance.

        .EXAMPLE
            Get-CloudDisk -Provider Azure | Set-CloudTag -Tags @{Encrypted='AES256'}

            Tags all Azure disks returned from Get-CloudDisk (piped input).

        .EXAMPLE
            Set-CloudTag -Path 'Azure:\prod-rg\Instances\web-01' -Tags @{Environment='Prod'}

            Resolves the CloudPath through Get-CloudResource and tags the matching resource.
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Piped',
        SupportsShouldProcess = $true
    )]
    [OutputType([pscustomobject])]
    param(
        # The Azure VM name when tagging by name and resource group.
        [Parameter(Mandatory, ParameterSetName = 'AzureByName')]
        [string]$Name,

        # The Azure resource group containing the VM.
        [Parameter(Mandatory, ParameterSetName = 'AzureByName')]
        [string]$ResourceGroup,

        # The full Azure resource id to tag.
        [Parameter(Mandatory, ParameterSetName = 'AzureById')]
        [string]$AzureResourceId,

        # The AWS resource id to tag.
        [Parameter(Mandatory, ParameterSetName = 'AWS')]
        [string]$ResourceId,

        # The AWS region containing the resource.
        [Parameter(Mandatory, ParameterSetName = 'AWS')]
        [string]$Region,

        # The GCP project containing the resource.
        [Parameter(Mandatory, ParameterSetName = 'GCP')]
        [string]$Project,

        # The GCP resource path to label.
        [Parameter(Mandatory, ParameterSetName = 'GCP')]
        [string]$Resource,

        # A PSCumulus cloud record or object with Provider and Name properties.
        [Parameter(Mandatory, ValueFromPipeline = $true, ParameterSetName = 'Piped')]
        [psobject]$InputObject,

        # A CloudPath addressing the resource(s) to tag (resolved via Get-CloudResource).
        [Parameter(Mandatory, ParameterSetName = 'Path')]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        # The tags or labels to apply.
        [Parameter(Mandatory)]
        [hashtable]$Tags,

        # Merge the supplied tags with existing tags instead of replacing them.
        [switch]$Merge
    )

    begin {
        $results = [System.Collections.Generic.List[psobject]]::new()

        $mapRecordToTarget = {
            param($record)

            if (-not $record.Provider -or -not $record.Name) {
                throw [System.ArgumentException]::new(
                    "Set-CloudTag requires a PSCumulus CloudRecord, or any object with non-null Provider and Name properties."
                )
            }

            $target = @{
                Provider = $record.Provider
                Name     = $record.Name
                InputObj = $record
            }

            switch ($record.Provider) {
                'Azure' {
                    $target.ResourceGroup = $record.ResourceGroup
                    $target.ResourceId = $record.Id
                }
                'AWS' {
                    $target.ResourceId = if ($record.PSObject.Properties['InstanceId'] -and $record.InstanceId) {
                        $record.InstanceId
                    } else {
                        $record.Id
                    }
                    $target.Region = $record.Region
                }
                'GCP' {
                    $target.Project = $record.Project
                    $target.Resource = $record.Id
                }
            }

            $target
        }
    }

    process {
        $targetInfo = $null
        $targetInfos = [System.Collections.Generic.List[hashtable]]::new()

        switch ($PSCmdlet.ParameterSetName) {
            'AzureByName' {
                $subscriptionId = $script:PSCumulusContext.Providers['Azure'].SubscriptionId
                $targetInfo = @{
                    Provider      = 'Azure'
                    Name          = $Name
                    ResourceGroup = $ResourceGroup
                    ResourceId    = "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Compute/virtualMachines/$Name"
                }
            }

            'AzureById' {
                $targetInfo = @{
                    Provider   = 'Azure'
                    ResourceId = $AzureResourceId
                    Name       = ($AzureResourceId -split '/')[-1]
                }
            }

            'AWS' {
                $targetInfo = @{
                    Provider   = 'AWS'
                    ResourceId = $ResourceId
                    Region     = $Region
                }
            }

            'GCP' {
                $targetInfo = @{
                    Provider = 'GCP'
                    Project  = $Project
                    Resource = $Resource
                    Name     = $Resource -replace '.*/instances/'
                }
            }

            'Piped' {
                $targetInfo = & $mapRecordToTarget $InputObject
            }

            'Path' {
                foreach ($record in @(Get-CloudResource -Path $Path)) {
                    if ($record) {
                        $targetInfos.Add((& $mapRecordToTarget $record))
                    }
                }
            }
        }

        if ($targetInfo) {
            $targetInfos.Add($targetInfo)
        }

        foreach ($targetInfo in $targetInfos) {
            $targetDisplay = switch ($targetInfo.Provider) {
                'Azure' {
                    if ($targetInfo.ResourceGroup) {
                        "$($targetInfo.Name) (ResourceGroup: $($targetInfo.ResourceGroup))"
                    } else {
                        $targetInfo.ResourceId
                    }
                }
                'AWS' { "$($targetInfo.ResourceId) (Region: $($targetInfo.Region))" }
                'GCP' { "$($targetInfo.Name) (Project: $($targetInfo.Project))" }
            }

            if ($PSCmdlet.ShouldProcess($targetDisplay, "Set tags $($Tags.Keys -join ', ')")) {
                $result = switch ($targetInfo.Provider) {
                    'Azure' { Set-AzureTag -ResourceId $targetInfo.ResourceId -Tags $Tags -Merge:$Merge }
                    'AWS'   { Set-AWSTag -ResourceId $targetInfo.ResourceId -Tags $Tags -Merge:$Merge -Region $targetInfo.Region }
                    'GCP'   { Set-GCPTag -Project $targetInfo.Project -Resource $targetInfo.Resource -Tags $Tags -Merge:$Merge }
                }

                if ($result) {
                    $results.Add($result)
                }
            }
        }
    }

    end {
        $results | Write-Output
    }
}
