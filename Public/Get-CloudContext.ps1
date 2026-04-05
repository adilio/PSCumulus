function Get-CloudContext {
    <#
        .SYNOPSIS
            Returns the current PSCumulus session context for all connected providers.

        .DESCRIPTION
            Shows all cloud providers that have been connected in this session, along with
            the active account, scope, and region for each. IsActive indicates which provider
            was last connected with Connect-Cloud.

        .EXAMPLE
            Get-CloudContext

            Returns context entries for all providers connected in this session.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    process {
        foreach ($provider in 'Azure', 'AWS', 'GCP') {
            $entry = $script:PSCumulusContext.Providers[$provider]

            if ($null -eq $entry) { continue }

            [pscustomobject]@{
                PSTypeName  = 'PSCumulus.CloudContext'
                Provider    = $provider
                IsActive    = ($script:PSCumulusContext.ActiveProvider -eq $provider)
                Account     = $entry.Account
                Scope       = $entry.Scope
                Region      = $entry.Region
                ConnectedAt = $entry.ConnectedAt
            }
        }
    }
}
