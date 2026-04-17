function New-CloudDrive {
    <#
        .SYNOPSIS
            Creates a PSDrive for cloud resource navigation.

        .DESCRIPTION
            New-CloudDrive creates a PowerShell drive using SHiPS that allows
            navigation of cloud resources using the familiar file system path syntax.
            Requires PowerShell 7+ and the SHiPS module.

        .PARAMETER Provider
            The cloud provider to create a drive for (Azure, AWS, or GCP).

        .EXAMPLE
            New-CloudDrive -Provider Azure

            Creates an Azure:\ drive for navigating Azure resources.

        .EXAMPLE
            New-CloudDrive -Provider AWS

            Creates an AWS:\ drive for navigating AWS resources.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Azure', 'AWS', 'GCP')]
        [string]$Provider
    )

    if (-not (Get-Module SHiPS -ListAvailable)) {
        throw [System.InvalidOperationException]::new(
            "SHiPS module is required for cloud drives. Install with: Install-Module SHiPS -Scope CurrentUser"
        )
    }

    if ($PSVersionTable.PSVersion.Major -lt 7) {
        throw [System.InvalidOperationException]::new(
            "Cloud drives require PowerShell 7 or later."
        )
    }

    $ctx = $script:PSCumulusContext.Providers[$Provider]
    if (-not $ctx) {
        throw [System.InvalidOperationException]::new(
            "No active session for provider '$Provider'. Run Connect-Cloud -Provider $Provider first."
        )
    }

    New-PSDrive -Name $Provider -PSProvider SHiPS -Root "PSCumulus#CloudProviderRoot" -Scope Script
}
