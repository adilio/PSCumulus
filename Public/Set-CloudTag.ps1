function Set-CloudTag {
    [CmdletBinding(
        DefaultParameterSetName = 'Piped',
        SupportsShouldProcess = $true
    )]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Azure')]
        [string]$Name,

        [Parameter(Mandatory, ParameterSetName = 'Azure')]
        [string]$ResourceGroup,

        [Parameter(Mandatory, ParameterSetName = 'AWS')]
        [string]$ResourceId,

        [Parameter(Mandatory, ParameterSetName = 'AWS')]
        [string]$Region,

        [Parameter(Mandatory, ParameterSetName = 'GCP')]
        [string]$Project,

        [Parameter(Mandatory, ParameterSetName = 'GCP')]
        [string]$Resource,

        [Parameter(Mandatory, ParameterSetName = 'Path')]
        [string]$Path,

        [Parameter(Mandatory, ValueFromPipeline = $true, ParameterSetName = 'Piped')]
        [PSTypeName('PSCumulus.CloudRecord')]
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
            'Azure' {
                $subscriptionId = $script:PSCumulusContext.Providers['Azure'].SubscriptionId
                $targetInfo = @{
                    Provider      = 'Azure'
                    Name          = $Name
                    ResourceGroup = $ResourceGroup
                    ResourceId    = "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Compute/virtualMachines/$Name"
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

            'Path' {
                $cloudRecord = Get-CloudResource -Path $Path
                if ($cloudRecord) {
                    $targetInfo = @{
                        Provider   = $cloudRecord.Provider
                        Name       = $cloudRecord.Name
                        InputObj   = $cloudRecord
                    }
                    switch ($cloudRecord.Provider) {
                        'Azure' {
                            $targetInfo.ResourceGroup = $cloudRecord.ResourceGroup
                            $targetInfo.ResourceId = $cloudRecord.Id
                        }
                        'AWS' {
                            $targetInfo.ResourceId = $cloudRecord.InstanceId
                            $targetInfo.Region = $cloudRecord.Region
                        }
                        'GCP' {
                            $targetInfo.Project = $cloudRecord.Project
                            $targetInfo.Resource = $cloudRecord.Id
                        }
                    }
                }
            }

            'Piped' {
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
                'Azure' { "$($targetInfo.Name) (ResourceGroup: $($targetInfo.ResourceGroup))" }
                'AWS' { "$($targetInfo.ResourceId) (Region: $($targetInfo.Region))" }
                'GCP' { "$($targetInfo.Name) (Project: $($targetInfo.Project))" }
            }

            if ($PSCmdlet.ShouldProcess($targetDisplay, "Set tags $($Tags.Keys -join ', ')")) {
                $result = Invoke-CloudProvider -Provider $targetInfo.Provider -ScriptBlock {
                    param($Target, $TagList, $DoMerge)

                    switch ($Target.Provider) {
                        'Azure' {
                            Set-AzureTag -ResourceId $Target.ResourceId -Tags $TagList -Merge:$DoMerge
                        }
                        'AWS' {
                            Set-AWSTag -ResourceId $Target.ResourceId -Tags $TagList -Merge:$DoMerge -Region $Target.Region
                        }
                        'GCP' {
                            Set-GCPTag -Project $Target.Project -Resource $Target.Resource -Tags $TagList -Merge:$DoMerge
                        }
                    }
                } -ArgumentList $targetInfo, $Tags, $Merge

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
