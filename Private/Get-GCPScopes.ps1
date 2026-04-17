function Get-GCPScopes {
    <#
        .SYNOPSIS
            Returns the GCP project from the current session context.

        .DESCRIPTION
            Get-GCPScopes returns the project from the stored GCP session
            context, which serves as the scope node in the cloud provider drive.
    #>
    [CmdletBinding()]
    param()

    $ctx = $script:PSCumulusContext.Providers['GCP']
    if ($ctx -and ($ctx.Project -or $ctx.Scope)) {
        $project = if ($ctx.Project) { $ctx.Project } else { $ctx.Scope }
        @($project)
    }
}
