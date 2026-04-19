function Get-CloudContext {
    <#
        .SYNOPSIS
            Returns the current PSCumulus session context for all connected providers.

        .DESCRIPTION
            Shows all cloud providers that have been connected in this session, along with
            the active account, scope, and region for each. ConnectionState shows whether a
            provider is the current active session context or simply connected in the session.
            IsActive is retained as a compatibility flag and is only populated for the current
            provider.

            Use -Provider to filter the output to a specific provider.

        .EXAMPLE
            Get-CloudContext

            Returns context entries for all providers connected in this session.

        .EXAMPLE
            Get-CloudContext -Provider Azure

            Returns context entry only for Azure.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        # Filter to a specific provider.
        [Parameter()]
        [ValidateSet('Azure', 'AWS', 'GCP')]
        [string]$Provider
    )

    process {
        $activeProvider = Get-CurrentCloudProvider
        $providers = if ($Provider) { @($Provider) } else { @('Azure', 'AWS', 'GCP') }

        foreach ($provider in $providers) {
            $entry = $script:PSCumulusContext.Providers[$provider]

            if ($null -eq $entry) { continue }

            $expiresAt = $null
            $warningThreshold = [TimeSpan]::FromMinutes(5)

            try {
                switch ($provider) {
                    'Azure' {
                        $azContext = Get-AzContext -ErrorAction SilentlyContinue
                        if ($azContext -and $azContext.Token -and $azContext.Token.ExpiresOn) {
                            $expiresAt = $azContext.Token.ExpiresOn.LocalDateTime
                            $timeToExpiry = $expiresAt - [DateTime]::Now

                            if ($timeToExpiry -le $warningThreshold -and $timeToExpiry -gt [TimeSpan]::Zero) {
                                Write-Warning "Azure credentials for $($entry.Account) will expire in $($timeToExpiry.Minutes) minutes at $($expiresAt:HH:mm)."
                            } elseif ($timeToExpiry -le [TimeSpan]::Zero) {
                                Write-Warning "Azure credentials for $($entry.Account) have expired. Please run Connect-Cloud -Provider Azure."
                            }
                        }
                    }
                    'AWS' {
                        $awsProfile = Get-AWSCredential -ListProfileDetail -ErrorAction SilentlyContinue |
                            Where-Object { $_.ProfileName -eq $entry.Account }
                        if ($awsProfile -and $awsProfile.Expiration) {
                            $expiresAt = $awsProfile.Expiration.ToLocalTime()
                            $timeToExpiry = $expiresAt - [DateTime]::Now

                            if ($timeToExpiry -le $warningThreshold -and $timeToExpiry -gt [TimeSpan]::Zero) {
                                Write-Warning "AWS credentials for profile $($entry.Account) will expire in $($timeToExpiry.Minutes) minutes at $($expiresAt:HH:mm)."
                            } elseif ($timeToExpiry -le [TimeSpan]::Zero) {
                                Write-Warning "AWS credentials for profile $($entry.Account) have expired. Please run Connect-Cloud -Provider AWS."
                            }
                        }
                    }
                    'GCP' {
                        $gcloudAuth = gcloud auth list --format=json 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue
                        $activeAccount = $gcloudAuth | Where-Object { $_.status -eq 'ACTIVE' } | Select-Object -First 1
                        if (-not $activeAccount) {
                            Write-Warning "GCP credentials for $($entry.Account) are not active. Please run Connect-Cloud -Provider GCP."
                        }
                        # GCP access tokens are opaque; there is no reliable expiry without an extra API call.
                        # We leave $expiresAt null and surface status only via the warning above.
                    }
                }
            } catch {
                Write-Verbose "Failed to retrieve credential expiry for $provider`: $_"
            }

            [pscustomobject]@{
                PSTypeName  = 'PSCumulus.CloudContext'
                Provider    = $provider
                ConnectionState = if ($activeProvider -eq $provider) { 'Current' } else { 'Connected' }
                IsActive    = if ($activeProvider -eq $provider) { $true } else { $null }
                Account     = $entry.Account
                Scope       = $entry.Scope
                Region      = $entry.Region
                ConnectedAt = $entry.ConnectedAt
                ExpiresAt   = $expiresAt
            }
        }
    }
}
