function Stop-GCPInstance {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'This internal helper is invoked only by Stop-CloudInstance, which implements ShouldProcess.'
    )]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Zone,

        [string]$Project
    )

    $null = Assert-GCloudAuthenticated
    $resolvedProject = Get-GCloudProject -Project $Project

    $null = Invoke-GCloudJson -Arguments @(
        'compute', 'instances', 'stop', $Name,
        "--zone=$Zone",
        "--project=$resolvedProject"
    )

    ConvertTo-CloudRecord `
        -Name $Name `
        -Provider GCP `
        -Region $Zone `
        -Status 'Stopping' `
        -Metadata @{
            Project = $resolvedProject
            Zone    = $Zone
        }
}
