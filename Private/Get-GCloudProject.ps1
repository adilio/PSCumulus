function Get-GCloudProject {
    [CmdletBinding()]
    param(
        [string]$Project
    )

    if (-not [string]::IsNullOrWhiteSpace($Project)) {
        return $Project
    }

    $config = Invoke-GCloudJson -Arguments @('config', 'list')
    $configuredProject = $config.core.project

    if ([string]::IsNullOrWhiteSpace($configuredProject)) {
        throw [System.ArgumentException]::new(
            "No GCP project was supplied and no default gcloud project is configured. Pass -Project or run 'gcloud config set project <project-id>'."
        )
    }

    $configuredProject
}

