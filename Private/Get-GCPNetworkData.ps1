function Get-GCPNetworkData {
    [CmdletBinding()]
    param(
        [string]$Project
    )

    $null = Assert-GCloudAuthenticated
    $resolvedProject = Get-GCloudProject -Project $Project
    $networks = Invoke-GCloudJson -Arguments @('compute', 'networks', 'list', "--project=$resolvedProject")

    foreach ($network in $networks) {
        ConvertTo-CloudRecord `
            -Name $network.name `
            -Provider GCP `
            -Region 'global' `
            -Status 'Available' `
            -Metadata @{
                Project               = $resolvedProject
                AutoCreateSubnetworks = $network.autoCreateSubnetworks
                SubnetworkMode        = if ($network.autoCreateSubnetworks) { 'auto' } else { 'custom' }
            }
    }
}
