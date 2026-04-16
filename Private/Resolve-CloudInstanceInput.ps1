function Resolve-CloudInstanceInput {
    [CmdletBinding()]
    param(
        [psobject]$InputObject,
        [string]$Provider,
        [string]$Name,
        [string]$ResourceGroup,
        [string]$InstanceId,
        [string]$Region,
        [string]$Project,
        [string]$Zone
    )

    if ($InputObject) {
        if ([string]::IsNullOrWhiteSpace($Provider) -and $InputObject.PSObject.Properties['Provider']) {
            $Provider = $InputObject.Provider
        }

        $metadata = $null
        if ($InputObject.PSObject.Properties['Metadata']) {
            $metadata = $InputObject.Metadata
        }

        switch ($Provider) {
            'Azure' {
                if ([string]::IsNullOrWhiteSpace($Name) -and $InputObject.PSObject.Properties['Name']) {
                    $Name = $InputObject.Name
                }

                if ([string]::IsNullOrWhiteSpace($ResourceGroup) -and $InputObject.PSObject.Properties['ResourceGroup']) {
                    $ResourceGroup = $InputObject.ResourceGroup
                }

                if ([string]::IsNullOrWhiteSpace($ResourceGroup) -and $metadata -and $metadata.ResourceGroup) {
                    $ResourceGroup = $metadata.ResourceGroup
                }
            }
            'AWS' {
                if ([string]::IsNullOrWhiteSpace($InstanceId) -and $InputObject.PSObject.Properties['InstanceId']) {
                    $InstanceId = $InputObject.InstanceId
                }

                if ([string]::IsNullOrWhiteSpace($InstanceId) -and $metadata -and $metadata.InstanceId) {
                    $InstanceId = $metadata.InstanceId
                }

                if ([string]::IsNullOrWhiteSpace($InstanceId) -and $metadata -and $metadata.Id) {
                    $InstanceId = $metadata.Id
                }

                if ([string]::IsNullOrWhiteSpace($Name) -and $InputObject.PSObject.Properties['Name']) {
                    $Name = $InputObject.Name
                }
            }
            'GCP' {
                if ([string]::IsNullOrWhiteSpace($Name) -and $InputObject.PSObject.Properties['Name']) {
                    $Name = $InputObject.Name
                }

                if ([string]::IsNullOrWhiteSpace($Project) -and $InputObject.PSObject.Properties['Project']) {
                    $Project = $InputObject.Project
                }

                if ([string]::IsNullOrWhiteSpace($Project) -and $metadata -and $metadata.Project) {
                    $Project = $metadata.Project
                }

                if ([string]::IsNullOrWhiteSpace($Zone) -and $InputObject.PSObject.Properties['Zone']) {
                    $Zone = $InputObject.Zone
                }

                if ([string]::IsNullOrWhiteSpace($Zone) -and $metadata -and $metadata.Zone) {
                    $Zone = $metadata.Zone
                }
            }
            default {
                if ([string]::IsNullOrWhiteSpace($Name) -and $InputObject.PSObject.Properties['Name']) {
                    $Name = $InputObject.Name
                }
            }
        }
    }

    [pscustomobject]@{
        Provider      = $Provider
        Name          = $Name
        ResourceGroup = $ResourceGroup
        InstanceId    = $InstanceId
        Region        = $Region
        Project       = $Project
        Zone          = $Zone
    }
}
