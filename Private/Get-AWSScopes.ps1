function Get-AWSScopes {
    <#
        .SYNOPSIS
            Returns the AWS region from the current session context.

        .DESCRIPTION
            Get-AWSScopes returns the region from the stored AWS session
            context, which serves as the scope node in the cloud provider drive.
    #>
    [CmdletBinding()]
    param()

    $ctx = $script:PSCumulusContext.Providers['AWS']
    if ($ctx -and $ctx.Region) {
        @($ctx.Region)
    }
}
