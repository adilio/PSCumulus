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

            [pscustomobject]@{
                PSTypeName  = 'PSCumulus.CloudContext'
                Provider    = $provider
                ConnectionState = if ($activeProvider -eq $provider) { 'Current' } else { 'Connected' }
                IsActive    = if ($activeProvider -eq $provider) { $true } else { $null }
                Account     = $entry.Account
                Scope       = $entry.Scope
                Region      = $entry.Region
                ConnectedAt = $entry.ConnectedAt
            }
        }
    }
}
