function Remove-CloudAggregationDrive {
    <#
        .SYNOPSIS
            Removes the cross-cloud aggregation PSDrive.

        .DESCRIPTION
            Remove-CloudAggregationDrive removes the Cloud:\ drive created by
            New-CloudAggregationDrive. Supports ShouldProcess for confirmation.

        .EXAMPLE
            Remove-CloudAggregationDrive

            Removes the Cloud:\ drive.

        .EXAMPLE
            Remove-CloudAggregationDrive -WhatIf

            Shows what would happen without removing the drive.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $drive = Get-PSDrive -Name Cloud -ErrorAction SilentlyContinue
    if ($drive -and $PSCmdlet.ShouldProcess('Cloud:\', 'Remove-CloudAggregationDrive')) {
        Remove-PSDrive -Name Cloud
    }
}
