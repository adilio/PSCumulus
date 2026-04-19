function Get-CloudRegion {
    <#
        .SYNOPSIS
            Lists supported regions for each cloud provider.

        .DESCRIPTION
            Returns all supported regions for Azure, AWS, or GCP. Use this to discover
            valid region values for Connect-Cloud and other provider-specific commands.

        .EXAMPLE
            Get-CloudRegion

            Returns all regions for all providers.

        .EXAMPLE
            Get-CloudRegion -Provider Azure

            Returns only Azure regions.

        .EXAMPLE
            Get-CloudRegion -Provider AWS | Where-Object { $_.Name -like 'us-*' }

            Returns AWS regions in the US.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        # The cloud provider to list regions for.
        [Parameter()]
        [ValidateSet('Azure', 'AWS', 'GCP')]
        [string]$Provider
    )

    process {
        $providers = if ($Provider) { @($Provider) } else { @('Azure', 'AWS', 'GCP') }

        foreach ($p in $providers) {
            $regions = Get-CloudRegionData -Provider $p

            foreach ($region in $regions) {
                [PSCustomObject]@{
                    PSTypeName = 'PSCumulus.CloudRegion'
                    Provider   = $p
                    Name       = $region
                }
            }
        }
    }
}
