function Resolve-CloudTagProvider {
    [CmdletBinding()]
    param(
        [string]$Provider,

        [string]$Project,
        [string]$Resource
    )

    if (-not [string]::IsNullOrWhiteSpace($Provider)) {
        if ($Provider -notin @('Azure', 'AWS', 'GCP')) {
            throw [System.ArgumentException]::new(
                "Provider '$Provider' is not supported. Valid values are Azure, AWS, and GCP."
            )
        }

        return $Provider
    }

    if (-not [string]::IsNullOrWhiteSpace($Project) -or -not [string]::IsNullOrWhiteSpace($Resource)) {
        return 'GCP'
    }

    $currentProvider = Get-CurrentCloudProvider

    if (-not [string]::IsNullOrWhiteSpace($currentProvider)) {
        return $currentProvider
    }

    throw [System.ArgumentException]::new(
        "No provider was supplied for tag lookup and no current provider is set. Pass -Provider or run 'Connect-Cloud -Provider <Azure|AWS|GCP>' first."
    )
}
