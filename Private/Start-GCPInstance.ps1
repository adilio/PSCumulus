function Start-GCPInstance {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'This internal helper is invoked only by Start-CloudInstance, which implements ShouldProcess.'
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
        'compute', 'instances', 'start', $Name,
        "--zone=$Zone",
        "--project=$resolvedProject"
    )

    ConvertTo-CloudRecord `
        -Name $Name `
        -Provider GCP `
        -Region $Zone `
        -Status 'Starting' `
        -Metadata @{
            Project = $resolvedProject
            Zone    = $Zone
        }
}
