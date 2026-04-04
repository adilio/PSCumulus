function Assert-CloudTagArgument {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Azure', 'AWS', 'GCP')]
        [string]$Provider,

        [string]$ResourceId,
        [string]$Project,
        [string]$Resource
    )

    switch ($Provider) {
        'Azure' {
            if ([string]::IsNullOrWhiteSpace($ResourceId)) {
                throw [System.ArgumentException]::new(
                    "Provider 'Azure' requires -ResourceId."
                )
            }
        }
        'AWS' {
            if ([string]::IsNullOrWhiteSpace($ResourceId)) {
                throw [System.ArgumentException]::new(
                    "Provider 'AWS' requires -ResourceId."
                )
            }
        }
        'GCP' {
            if ([string]::IsNullOrWhiteSpace($Project) -or [string]::IsNullOrWhiteSpace($Resource)) {
                throw [System.ArgumentException]::new(
                    "Provider 'GCP' requires both -Project and -Resource."
                )
            }
        }
    }
}
