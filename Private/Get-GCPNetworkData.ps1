function Get-GCPNetworkData {
    [CmdletBinding()]
    [OutputType([GCPNetworkRecord])]
    param(
        [string]$Project
    )

    $null = Assert-GCloudAuthenticated
    $resolvedProject = Get-GCloudProject -Project $Project
    $networks = Invoke-GCloudJson -Arguments @('compute', 'networks', 'list', "--project=$resolvedProject")

    foreach ($network in $networks) {
        [GCPNetworkRecord]::FromGCloudJson($network, $resolvedProject)
    }
}
