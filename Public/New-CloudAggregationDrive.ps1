function New-CloudAggregationDrive {
    <#
        .SYNOPSIS
            Creates a cross-cloud aggregation PSDrive.

        .DESCRIPTION
            New-CloudAggregationDrive creates a Cloud:\ drive that shows all connected
            cloud providers as top-level containers, enabling cross-cloud browsing.
            Requires PowerShell 7+ and the SHiPS module.

        .EXAMPLE
            New-CloudAggregationDrive

            Creates a Cloud:\ drive showing all connected providers.

        .EXAMPLE
            dir Cloud:\Azure\prod-rg\Instances

            Lists Azure instances in the prod-rg resource group via the aggregation drive.
    #>
    [CmdletBinding()]
    param()

    if (-not (Get-Module SHiPS -ListAvailable)) {
        throw [System.InvalidOperationException]::new(
            "SHiPS module is required. Install with: Install-Module SHiPS -Scope CurrentUser"
        )
    }

    if ($PSVersionTable.PSVersion.Major -lt 7) {
        throw [System.InvalidOperationException]::new(
            "Cloud drives require PowerShell 7 or later."
        )
    }

    $connectedProviders = @('Azure', 'AWS', 'GCP') | Where-Object {
        $null -ne $script:PSCumulusContext.Providers[$_]
    }

    if ($connectedProviders.Count -eq 0) {
        throw [System.InvalidOperationException]::new(
            "No cloud providers are connected. Run Connect-Cloud first."
        )
    }

    New-PSDrive -Name Cloud -PSProvider SHiPS -Root "PSCumulus#CloudAggregationRoot" -Scope Script
}
