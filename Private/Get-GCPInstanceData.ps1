function Get-GCPInstanceData {
    [CmdletBinding()]
    param(
        [string]$Project,
        [string]$Name
    )

    $null = Assert-GCloudAuthenticated
    $resolvedProject = Get-GCloudProject -Project $Project
    $instances = Invoke-GCloudJson -Arguments @('compute', 'instances', 'list', "--project=$resolvedProject")

    foreach ($instance in $instances) {
        if (-not [string]::IsNullOrWhiteSpace($Name) -and $instance.name -ne $Name) {
            continue
        }

        [GCPCloudRecord]::FromGCloudJson($instance, $resolvedProject)
    }
}
