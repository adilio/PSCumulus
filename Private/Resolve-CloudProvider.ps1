function Resolve-CloudProvider {
    [CmdletBinding()]
    param(
        [string]$Provider,

        [string]$ParameterSetName
    )

    if (-not [string]::IsNullOrWhiteSpace($Provider)) {
        if ($Provider -notin @('Azure', 'AWS', 'GCP')) {
            throw [System.ArgumentException]::new(
                "Provider '$Provider' is not supported. Valid values are Azure, AWS, and GCP."
            )
        }

        if (-not [string]::IsNullOrWhiteSpace($ParameterSetName)) {
            Assert-ProviderParameterSet -Provider $Provider -ParameterSetName $ParameterSetName
        }

        return $Provider
    }

    $providerFromParameterSet = switch ($ParameterSetName) {
        'Azure' { 'Azure' }
        'AWS'   { 'AWS' }
        'GCP'   { 'GCP' }
        default { $null }
    }

    if (-not [string]::IsNullOrWhiteSpace($providerFromParameterSet)) {
        return $providerFromParameterSet
    }

    $currentProvider = Get-CurrentCloudProvider

    if (-not [string]::IsNullOrWhiteSpace($currentProvider)) {
        return $currentProvider
    }

    throw [System.ArgumentException]::new(
        "No provider was supplied and no current provider is set. Pass -Provider or run 'Connect-Cloud -Provider <Azure|AWS|GCP>' first."
    )
}
