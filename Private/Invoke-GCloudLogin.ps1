function Invoke-GCloudLogin {
    [CmdletBinding()]
    param()

    & gcloud auth application-default login

    if ($LASTEXITCODE -ne 0) {
        throw [System.InvalidOperationException]::new(
            "GCP login failed or was cancelled. Run 'gcloud auth application-default login' manually to authenticate."
        )
    }
}
