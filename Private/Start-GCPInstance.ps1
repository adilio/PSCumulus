function Start-GCPInstance {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'This internal helper is invoked only by Start-CloudInstance, which implements ShouldProcess.'
    )]
    [CmdletBinding()]
    [OutputType([GCPCloudRecord])]
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

    $record = [GCPCloudRecord]::new()
    $record.Kind = 'Instance'
    $record.Provider = [CloudProvider]::GCP.ToString()
    $record.Name = $Name
    $record.Region = $Zone
    $record.Status = 'Starting'
    $record.Project = $resolvedProject
    $record.Zone = $Zone
    $record.Metadata = @{
        Project = $resolvedProject
        Zone    = $Zone
    }

    return $record
}
