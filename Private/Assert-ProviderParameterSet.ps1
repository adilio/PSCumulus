function Assert-ProviderParameterSet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Azure', 'AWS', 'GCP')]
        [string]$Provider,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ParameterSetName
    )

    $expectedProvider = switch ($ParameterSetName) {
        'Azure'   { 'Azure' }
        'AWS'     { 'AWS' }
        'GCP'     { 'GCP' }
        'AzureTag' { 'Azure' }
        'AWSTag'   { 'AWS' }
        'GCPTag'   { 'GCP' }
        default   { $null }
    }

    if (-not $expectedProvider) {
        throw [System.InvalidOperationException]::new(
            "Unsupported parameter set '$ParameterSetName'."
        )
    }

    if ($Provider -ne $expectedProvider) {
        throw [System.ArgumentException]::new(
            "Provider '$Provider' does not match parameter set '$ParameterSetName'."
        )
    }
}

