function Disconnect-Cloud {
    <#
        .SYNOPSIS
            Clears PSCumulus session context for a specific cloud provider.

        .DESCRIPTION
            Disconnect-Cloud removes the stored PSCumulus session context for one provider
            from the current PowerShell session. The command is scoped to the selected
            provider and can optionally verify account or scope details before clearing
            the stored context.

            This does not sign you out of the provider itself. It only clears PSCumulus's
            remembered session state.

        .EXAMPLE
            Disconnect-Cloud -Provider Azure

            Clears the stored Azure context for the current shell.

        .EXAMPLE
            Disconnect-Cloud -Provider AWS -AccountId '123456789012'

            Clears the stored AWS context only if it matches the supplied account id.

        .EXAMPLE
            Disconnect-Cloud -Provider GCP -Project 'my-project'

            Clears the stored GCP context only if it matches the supplied project.

        .EXAMPLE
            Disconnect-Cloud -Provider GCP -AccountEmail 'adil@example.com'

            Clears the stored GCP context only if it matches the supplied account email.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([pscustomobject])]
    param(
        # The provider context to clear.
        [Parameter(Mandatory)]
        [ValidateSet('Azure', 'AWS', 'GCP')]
        [string]$Provider,

        # Only disconnect Azure if the stored tenant id matches this value.
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,

        # Only disconnect Azure if the stored subscription name or id matches this value.
        [ValidateNotNullOrEmpty()]
        [string]$Subscription,

        # Only disconnect AWS if the stored account id matches this value.
        [ValidateNotNullOrEmpty()]
        [string]$AccountId,

        # Only disconnect AWS if the stored profile name matches this value.
        [ValidateNotNullOrEmpty()]
        [string]$ProfileName,

        # Only disconnect AWS if the stored region matches this value.
        [ValidateNotNullOrEmpty()]
        [string]$Region,

        # Only disconnect GCP if the stored project matches this value.
        [ValidateNotNullOrEmpty()]
        [string]$Project,

        # Only disconnect GCP if the stored account email matches this value.
        [ValidateNotNullOrEmpty()]
        [string]$AccountEmail
    )

    process {
        $context = $script:PSCumulusContext.Providers[$Provider]
        if (-not $context) {
            throw [System.InvalidOperationException]::new(
                "No stored PSCumulus context exists for provider '$Provider'."
            )
        }

        $contextMatches = $true

        $providerSpecificParams = switch ($Provider) {
            'Azure' { @('TenantId', 'Subscription') }
            'AWS'   { @('AccountId', 'ProfileName', 'Region') }
            'GCP'   { @('Project', 'AccountEmail') }
        }

        $unsupportedParams = $PSBoundParameters.Keys |
            Where-Object { $_ -notin @('Provider', 'WhatIf', 'Confirm') -and $_ -notin $providerSpecificParams }

        if ($unsupportedParams) {
            throw [System.ArgumentException]::new(
                "Provider '$Provider' does not accept the following disconnect filter(s): $($unsupportedParams -join ', ')."
            )
        }

        switch ($Provider) {
            'Azure' {
                if ($PSBoundParameters.ContainsKey('TenantId') -and $context.TenantId -ne $TenantId) {
                    $contextMatches = $false
                }

                if ($PSBoundParameters.ContainsKey('Subscription')) {
                    $subscriptionMatch = $context.Subscription -eq $Subscription -or $context.SubscriptionId -eq $Subscription
                    if (-not $subscriptionMatch) {
                        $contextMatches = $false
                    }
                }

                if ($PSBoundParameters.ContainsKey('AccountEmail') -and $context.Account -ne $AccountEmail) {
                    $contextMatches = $false
                }
            }
            'AWS' {
                if ($PSBoundParameters.ContainsKey('AccountId')) {
                    $accountMatch = $context.AccountId -eq $AccountId -or $context.Account -eq $AccountId
                    if (-not $accountMatch) {
                        $contextMatches = $false
                    }
                }

                if ($PSBoundParameters.ContainsKey('ProfileName') -and $context.ProfileName -ne $ProfileName -and $context.Scope -ne $ProfileName) {
                    $contextMatches = $false
                }

                if ($PSBoundParameters.ContainsKey('Region') -and $context.Region -ne $Region) {
                    $contextMatches = $false
                }
            }
            'GCP' {
                if ($PSBoundParameters.ContainsKey('Project') -and $context.Project -ne $Project -and $context.Scope -ne $Project) {
                    $contextMatches = $false
                }

                if ($PSBoundParameters.ContainsKey('AccountEmail') -and $context.Account -ne $AccountEmail) {
                    $contextMatches = $false
                }
            }
        }

        if (-not $contextMatches) {
            throw [System.InvalidOperationException]::new(
                "The stored $Provider context does not match the supplied disconnect filters."
            )
        }

        $summary = switch ($Provider) {
            'Azure' {
                if ($context.Subscription) {
                    $context.Subscription
                } elseif ($context.SubscriptionId) {
                    $context.SubscriptionId
                } elseif ($context.Account) {
                    $context.Account
                } else {
                    $null
                }
            }
            'AWS' {
                if ($context.AccountId) {
                    $context.AccountId
                } elseif ($context.Account) {
                    $context.Account
                } elseif ($context.ProfileName) {
                    $context.ProfileName
                } elseif ($context.Scope) {
                    $context.Scope
                } else {
                    $null
                }
            }
            'GCP' {
                if ($context.Project) {
                    $context.Project
                } elseif ($context.Scope) {
                    $context.Scope
                } elseif ($context.Account) {
                    $context.Account
                } else {
                    $null
                }
            }
        }

        $target = if ($summary) {
            "$Provider / $summary"
        } else {
            $Provider
        }

        if ($PSCmdlet.ShouldProcess($target, 'Disconnect-Cloud')) {
            $script:PSCumulusContext.Providers[$Provider] = $null
            $null = Update-CloudContextActiveProvider

            [pscustomobject]@{
                PSTypeName   = 'PSCumulus.ConnectionResult'
                Provider     = $Provider
                Connected    = $false
                ContextName  = $context.ContextName
                Account      = $context.Account
                Scope        = $context.Scope
                Region       = $context.Region
                TenantId     = $context.TenantId
                Subscription = $context.Subscription
                SubscriptionId = $context.SubscriptionId
                AccountId    = $context.AccountId
                ProfileName  = $context.ProfileName
                Project      = $context.Project
            }
        }
    }
}
