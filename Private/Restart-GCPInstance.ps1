function Restart-GCPInstance {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'This internal helper is invoked only by Restart-CloudInstance, which implements ShouldProcess.'
    )]
    [CmdletBinding()]
    [OutputType([GCPCloudRecord])]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Zone,

        [Parameter(Mandatory)]
        [string]$Project
    )

    Assert-CommandAvailable `
        -CommandName 'gcloud' `
        -InstallHint "Install the Google Cloud SDK: https://cloud.google.com/sdk/docs/install"

    $null = Invoke-GCloudJson -Arguments @('compute', 'instances', 'reset', $Name, '--zone', $Zone, '--project', $Project) -ErrorAction Stop

    $record = [GCPCloudRecord]::new()
    $record.Kind = 'Instance'
    $record.Provider = [CloudProvider]::GCP.ToString()
    $record.Name = $Name
    $record.Region = $Zone
    $record.Status = 'Running'
    $record.Project = $Project
    $record.Zone = $Zone
    $record.Metadata = @{
        Project = $Project
        Zone = $Zone
    }

    return $record
}
