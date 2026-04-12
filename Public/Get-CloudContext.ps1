function Get-CloudContext {
    <#
        .SYNOPSIS
            Returns the current PSCumulus session context for all connected providers.

        .DESCRIPTION
            Shows all cloud providers that have been connected in this session, along with
            the active account, scope, and region for each. IsActive indicates which provider
            is currently active for the session, based on the most recent connected context.

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
                IsActive    = ($activeProvider -eq $provider)
                Account     = $entry.Account
                Scope       = $entry.Scope
                Region      = $entry.Region
                ConnectedAt = $entry.ConnectedAt
            }
        }
    }
}
