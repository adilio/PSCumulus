function Get-GCPImageData {
    [CmdletBinding()]
    [OutputType([GCPImageRecord])]
    param(
        [string]$Project
    )

    $null = Assert-GCloudAuthenticated
    $resolvedProject = Get-GCloudProject -Project $Project

    # --no-standard-images plus an explicit --project keeps the listing to the
    # caller's own images; the default view includes Google's public OS image
    # projects, which would swamp the normalized inventory.
    $images = Invoke-GCloudJson -Arguments @('compute', 'images', 'list', '--no-standard-images', "--project=$resolvedProject")

    foreach ($image in $images) {
        [GCPImageRecord]::FromGCloudJson($image, $resolvedProject)
    }
}
