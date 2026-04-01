function Invoke-GCloudJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Arguments
    )

    Assert-CommandAvailable `
        -CommandName 'gcloud' `
        -InstallHint "Install the Google Cloud CLI from https://cloud.google.com/sdk/docs/install"

    $gcloudArguments = @($Arguments + '--format=json' + '--quiet')
    $output = & gcloud @gcloudArguments 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        $message = ($output | Out-String).Trim()

        if ([string]::IsNullOrWhiteSpace($message)) {
            $message = "gcloud exited with code $exitCode."
        }

        throw [System.InvalidOperationException]::new($message)
    }

    $json = ($output | Out-String).Trim()

    if ([string]::IsNullOrWhiteSpace($json)) {
        return $null
    }

    $json | ConvertFrom-Json -Depth 100
}

