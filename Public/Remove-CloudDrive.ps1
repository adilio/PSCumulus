function Remove-CloudDrive {
    <#
        .SYNOPSIS
            Removes a cloud provider PSDrive.

        .DESCRIPTION
            Remove-CloudDrive removes a PSDrive created by New-CloudDrive.
            Supports ShouldProcess for confirmation.

        .PARAMETER Provider
            The cloud provider whose drive to remove (Azure, AWS, or GCP).

        .EXAMPLE
            Remove-CloudDrive -Provider Azure

            Removes the Azure:\ drive.

        .EXAMPLE
            Remove-CloudDrive -Provider AWS -WhatIf

            Shows what would happen without removing the drive.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Azure', 'AWS', 'GCP')]
        [string]$Provider
    )

    $drive = Get-PSDrive -Name $Provider -ErrorAction SilentlyContinue
    if ($drive -and $PSCmdlet.ShouldProcess("${Provider}:\", 'Remove-CloudDrive')) {
        Remove-PSDrive -Name $Provider
    }
}
