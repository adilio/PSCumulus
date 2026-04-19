function Test-CloudConnection {
    <#
        .SYNOPSIS
            Tests the validity of stored cloud provider credentials.

        .DESCRIPTION
            Tests whether stored credentials for cloud providers are still valid.
            Makes a lightweight read-only API call to verify authentication.
            Returns connection test results without throwing on auth failure.

            When run without parameters, defaults to testing all providers (equivalent to -All).

        .EXAMPLE
            Test-CloudConnection -Provider Azure

            Tests Azure credentials validity.

        .EXAMPLE
            Test-CloudConnection -All

            Tests all stored provider credentials.

        .EXAMPLE
            Test-CloudConnection

            Tests all stored provider credentials (equivalent to -All).

        .EXAMPLE
            Test-CloudConnection -All | Where-Object { -not $_.Connected }

            Shows all providers with invalid or expired credentials.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'All', Justification='Parameter is used via ParameterSetName mechanism')]
    param(
        # The cloud provider to test.
        [Parameter()]
        [ValidateSet('Azure', 'AWS', 'GCP')]
        [string]$Provider,

        # Test all providers with stored credentials.
        [Parameter(ParameterSetName = 'All')]
        [switch]$All
    )

    process {
        $providersToTest = if ($PSCmdlet.ParameterSetName -eq 'All') {
            @('Azure', 'AWS', 'GCP')
        } elseif ($Provider) {
            @($Provider)
        } else {
            # Default to -All when neither -Provider nor -All is supplied
            @('Azure', 'AWS', 'GCP')
        }

        foreach ($providerName in $providersToTest) {
            $ctx = $script:PSCumulusContext.Providers[$providerName]
            $connected = $false
            $message = 'No session context found'

            if ($null -ne $ctx) {
                try {
                    switch ($providerName) {
                        'Azure' {
                            Assert-CommandAvailable -CommandName 'Get-AzContext' -InstallHint '' -ErrorAction SilentlyContinue
                            $azContext = Get-AzContext -ErrorAction SilentlyContinue
                            if ($null -ne $azContext -and $null -ne $azContext.Account) {
                                $connected = $true
                                $message = "Connected as $($azContext.Account.Id)"
                            } else {
                                $message = 'Azure session not connected'
                            }
                        }
                        'AWS' {
                            Assert-CommandAvailable -CommandName 'Get-AWSCredential' -InstallHint '' -ErrorAction SilentlyContinue
                            $cred = Get-AWSCredential -ListStored -ErrorAction SilentlyContinue | Select-Object -First 1
                            if ($null -ne $cred) {
                                $connected = $true
                                $message = "Credential stored: $($cred.ProfileName)"
                            } else {
                                $message = 'No AWS credentials found'
                            }
                        }
                        'GCP' {
                            Assert-CommandAvailable -CommandName 'gcloud' -InstallHint '' -ErrorAction SilentlyContinue
                            $gcloudAuth = gcloud auth list --format=json 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue
                            if ($null -ne $gcloudAuth -and $gcloudAuth.Count -gt 0) {
                                $activeAccount = $gcloudAuth | Where-Object { $_.Status -eq 'ACTIVE' } | Select-Object -First 1
                                if ($null -ne $activeAccount) {
                                    $connected = $true
                                    $message = "Authenticated as $($activeAccount.Account)"
                                } else {
                                    $message = 'No active GCP account'
                                }
                            } else {
                                $message = 'GCP authentication check failed'
                            }
                        }
                    }
                } catch {
                    $message = "Connection test failed: $($_.Exception.Message)"
                }
            }

            [pscustomobject]@{
                PSTypeName  = 'PSCumulus.ConnectionTestResult'
                Provider    = $providerName
                Connected   = $connected
                Message     = $message
            }
        }
    }
}
