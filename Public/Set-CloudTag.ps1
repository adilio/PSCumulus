function Set-CloudTag {
    <#
        .SYNOPSIS
            Sets tags or labels on a cloud resource across Azure, AWS, or GCP.

        .DESCRIPTION
            Set-CloudTag applies tags (Azure), tags (AWS), or labels (GCP) to cloud resources.
            For Azure, you can specify a VM by Name/ResourceGroup or any resource by ResourceId.
            For AWS, provide the ResourceId and Region. For GCP, provide the Project and Resource.
            You can also pipe CloudRecord objects from other PSCumulus commands.

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
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'Piped',
        SupportsShouldProcess = $true
    )]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory, ParameterSetName = 'AzureByName')]
        [string]$Name,

        [Parameter(Mandatory, ParameterSetName = 'AzureByName')]
        [string]$ResourceGroup,

        [Parameter(Mandatory, ParameterSetName = 'AzureById')]
        [string]$AzureResourceId,

        [Parameter(Mandatory, ParameterSetName = 'AWS')]
        [string]$ResourceId,

        [Parameter(Mandatory, ParameterSetName = 'AWS')]
        [string]$Region,

        [Parameter(Mandatory, ParameterSetName = 'GCP')]
        [string]$Project,

        [Parameter(Mandatory, ParameterSetName = 'GCP')]
        [string]$Resource,

        [Parameter(Mandatory, ValueFromPipeline = $true, ParameterSetName = 'Piped')]
        [psobject]$InputObject,

        [Parameter(Mandatory)]
        [hashtable]$Tags,

        [switch]$Merge
    )

    begin {
        $results = [System.Collections.Generic.List[psobject]]::new()
    }

    process {
        $targetInfo = $null

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
                if (-not $InputObject.Provider -or -not $InputObject.Name) {
                    throw [System.ArgumentException]::new(
                        "Set-CloudTag requires a PSCumulus CloudRecord, or any object with non-null Provider and Name properties."
                    )
                }

                $targetInfo = @{
                    Provider   = $InputObject.Provider
                    Name       = $InputObject.Name
                    InputObj   = $InputObject
                }
                switch ($InputObject.Provider) {
                    'Azure' {
                        $targetInfo.ResourceGroup = $InputObject.ResourceGroup
                        $targetInfo.ResourceId = $InputObject.Id
                    }
                    'AWS' {
                        $targetInfo.ResourceId = $InputObject.InstanceId
                        $targetInfo.Region = $InputObject.Region
                    }
                    'GCP' {
                        $targetInfo.Project = $InputObject.Project
                        $targetInfo.Resource = $InputObject.Id
                    }
                }
            }
        }

        if ($targetInfo) {
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
