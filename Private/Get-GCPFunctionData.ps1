function Get-GCPFunctionData {
    [CmdletBinding()]
    param(
        [string]$Project
    )

    $null = Assert-GCloudAuthenticated
    $resolvedProject = Get-GCloudProject -Project $Project
    $functions = Invoke-GCloudJson -Arguments @('functions', 'list', "--project=$resolvedProject")

    foreach ($function in $functions) {
        # Name is in the form "projects/proj/locations/REGION/functions/NAME"
        $nameParts = $function.name -split '/'
        $shortName = $nameParts[-1]
        $region    = if ($nameParts.Count -ge 4) { $nameParts[-3] } else { $null }

        # gen1 uses 'status', gen2 uses 'state'
        $rawStatus = if ($function.state) { $function.state } elseif ($function.status) { $function.status } else { $null }
        $status = if ($rawStatus) {
            (Get-Culture).TextInfo.ToTitleCase($rawStatus.ToLower())
        } else {
            $null
        }

        $params = @{
            Name     = $shortName
            Provider = 'GCP'
            Region   = $region
            Metadata = @{
                Project    = $resolvedProject
                Runtime    = $function.runtime
                EntryPoint = $function.entryPoint
                FullName   = $function.name
            }
        }

        if ($status) { $params.Status = $status }
        if ($function.runtime) { $params.Size = $function.runtime }

        if (-not [string]::IsNullOrWhiteSpace($function.updateTime)) {
            $params.CreatedAt = [datetime]::Parse($function.updateTime)
        }

        ConvertTo-CloudRecord @params
    }
}
