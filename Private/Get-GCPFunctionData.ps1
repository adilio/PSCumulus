function Get-GCPFunctionData {
    [CmdletBinding()]
    [OutputType([GCPFunctionRecord])]
    param(
        [string]$Project
    )

    $null = Assert-GCloudAuthenticated
    $resolvedProject = Get-GCloudProject -Project $Project
    $functions = Invoke-GCloudJson -Arguments @('functions', 'list', "--project=$resolvedProject")

    foreach ($function in $functions) {
        [GCPFunctionRecord]::FromGCloudJson($function, $resolvedProject)
    }
}
