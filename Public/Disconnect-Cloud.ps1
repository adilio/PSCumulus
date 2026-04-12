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
        [Parameter(Mandatory, ParameterSetName = 'Azure')]
        [Parameter(Mandatory, ParameterSetName = 'AWS')]
        [Parameter(Mandatory, ParameterSetName = 'GCP')]
        [ValidateSet('Azure', 'AWS', 'GCP')]
        [string]$Provider,

        [Parameter(ParameterSetName = 'Azure')]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,

        [Parameter(ParameterSetName = 'Azure')]
        [ValidateNotNullOrEmpty()]
        [string]$Subscription,

        [Parameter(ParameterSetName = 'Azure')]
        [ValidateNotNullOrEmpty()]
        [string]$Account,

        [Parameter(ParameterSetName = 'AWS')]
        [ValidateNotNullOrEmpty()]
        [string]$AccountId,

        [Parameter(ParameterSetName = 'AWS')]
        [ValidateNotNullOrEmpty()]
        [string]$ProfileName,

        [Parameter(ParameterSetName = 'AWS')]
        [ValidateNotNullOrEmpty()]
        [string]$Region,

        [Parameter(ParameterSetName = 'GCP')]
        [ValidateNotNullOrEmpty()]
        [string]$Project,

        [Parameter(ParameterSetName = 'GCP')]
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

        $matches = $true

        switch ($Provider) {
            'Azure' {
                if ($PSBoundParameters.ContainsKey('TenantId') -and $context.TenantId -ne $TenantId) {
                    $matches = $false
                }

                if ($PSBoundParameters.ContainsKey('Subscription')) {
                    $subscriptionMatch = $context.Subscription -eq $Subscription -or $context.SubscriptionId -eq $Subscription
                    if (-not $subscriptionMatch) {
                        $matches = $false
                    }
                }

                if ($PSBoundParameters.ContainsKey('AccountEmail') -and $context.Account -ne $AccountEmail) {
                    $matches = $false
                }
            }
            'AWS' {
                if ($PSBoundParameters.ContainsKey('AccountId')) {
                    $accountMatch = $context.AccountId -eq $AccountId -or $context.Account -eq $AccountId
                    if (-not $accountMatch) {
                        $matches = $false
                    }
                }

                if ($PSBoundParameters.ContainsKey('ProfileName') -and $context.ProfileName -ne $ProfileName -and $context.Scope -ne $ProfileName) {
                    $matches = $false
                }

                if ($PSBoundParameters.ContainsKey('Region') -and $context.Region -ne $Region) {
                    $matches = $false
                }
            }
            'GCP' {
                if ($PSBoundParameters.ContainsKey('Project') -and $context.Project -ne $Project -and $context.Scope -ne $Project) {
                    $matches = $false
                }

                if ($PSBoundParameters.ContainsKey('Account') -and $context.Account -ne $Account) {
                    $matches = $false
                }
            }
        }

        if (-not $matches) {
            throw [System.InvalidOperationException]::new(
                "The stored $Provider context does not match the supplied disconnect filters."
            )
        }

        $summary = switch ($Provider) {
            'Azure' { $context.Subscription ?? $context.SubscriptionId ?? $context.Account }
            'AWS'   { $context.AccountId ?? $context.Account ?? $context.ProfileName ?? $context.Scope }
            'GCP'   { $context.Project ?? $context.Scope ?? $context.Account }
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
