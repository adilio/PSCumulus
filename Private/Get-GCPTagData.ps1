function Get-GCPTagData {
    [CmdletBinding()]
    param(
        [string]$Project,
        [string]$Resource
    )

    $null = Assert-GCloudAuthenticated
    $resolvedProject = Get-GCloudProject -Project $Project

    # Resource is in the form "instances/vm-01" or "disks/my-disk"
    $parts = $Resource -split '/', 2
    $resourceType = $parts[0]
    $resourceName = if ($parts.Count -gt 1) { $parts[1] } else { $Resource }

    # List resources filtered by name to avoid requiring a zone argument
    $resourceList = Invoke-GCloudJson -Arguments @(
        'compute', $resourceType, 'list',
        "--filter=name=$resourceName",
        "--project=$resolvedProject"
    )

    $resourceData = $resourceList | Select-Object -First 1

    $labels = @{}
    if ($resourceData -and $resourceData.labels) {
        $resourceData.labels.PSObject.Properties | ForEach-Object {
            $labels[$_.Name] = $_.Value
        }
    }

    ConvertTo-CloudRecord `
        -Name $resourceName `
        -Provider GCP `
        -Metadata @{
            Project  = $resolvedProject
            Resource = $Resource
            Labels   = $labels
        }
}
