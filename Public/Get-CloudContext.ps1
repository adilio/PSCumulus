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

        .EXAMPLE
            Get-CloudContext

            Returns context entries for all providers connected in this session.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    process {
        $activeProvider = Get-CurrentCloudProvider

        foreach ($provider in 'Azure', 'AWS', 'GCP') {
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
                            $expiresAt = $profile.Expiration.ToLocalTime()
                            $timeToExpiry = $expiresAt - [DateTime]::Now

                            if ($timeToExpiry -le $warningThreshold -and $timeToExpiry -gt [TimeSpan]::Zero) {
                                Write-Warning "AWS credentials for profile $($entry.Account) will expire in $($timeToExpiry.Minutes) minutes at $($expiresAt:HH:mm)."
                            } elseif ($timeToExpiry -le [TimeSpan]::Zero) {
                                Write-Warning "AWS credentials for profile $($entry.Account) have expired. Please run Connect-Cloud -Provider AWS."
                            }
                        }
                    }
                    'GCP' {
                        $tokenInfo = Invoke-GCloudJson -Arguments @('auth', 'print-access-token') -ErrorAction SilentlyContinue
                        if ($tokenInfo) {
                            $tokenBytes = [System.Convert]::FromBase64String($tokenInfo)
                            $tokenJson = [System.Text.Encoding]::UTF8.GetString($tokenBytes)
                            $tokenData = $tokenJson | ConvertFrom-Json -ErrorAction SilentlyContinue

                            if ($tokenData -and $tokenData.exp) {
                                $expiresAt = [DateTimeOffset]::FromUnixTimeSeconds($tokenData.exp).LocalDateTime
                                $timeToExpiry = $expiresAt - [DateTime]::Now

                                if ($timeToExpiry -le $warningThreshold -and $timeToExpiry -gt [TimeSpan]::Zero) {
                                    Write-Warning "GCP credentials for $($entry.Account) will expire in $($timeToExpiry.Minutes) minutes at $($expiresAt:HH:mm)."
                                } elseif ($timeToExpiry -le [TimeSpan]::Zero) {
                                    Write-Warning "GCP credentials for $($entry.Account) have expired. Please run Connect-Cloud -Provider GCP."
                                }
                            }
                        }
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
