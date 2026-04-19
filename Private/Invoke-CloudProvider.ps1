function Invoke-CloudProvider {
    <#
        .SYNOPSIS
            Central dispatcher for provider-specific backend commands.

        .DESCRIPTION
            Wraps backend calls with error handling and adds PSCumulus context to
            exceptions. Use this from all public commands to ensure consistent error
            messages across providers.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Azure', 'AWS', 'GCP')]
        [string]$Provider,

        [Parameter(Mandatory)]
        [hashtable]$CommandMap,

        [hashtable]$ArgumentMap = @{},

        # The caller's PSCmdlet object for error reporting. If not provided,
        # errors are thrown as InvalidOperationException.
        [System.Management.Automation.PSCmdlet]$CallerPSCmdlet
    )

    $commandName = $CommandMap[$Provider]

    if (-not $commandName) {
        throw [System.InvalidOperationException]::new(
            "No command mapping exists for provider '$Provider'."
        )
    }

    try {
        $null = Get-Command -Name $commandName -ErrorAction Stop
    } catch {
        $errorRecord = $_
        throw [System.Management.Automation.CommandNotFoundException]::new(
            "Mapped command '$commandName' was not found for provider '$Provider'.",
            $errorRecord.Exception
        )
    }

    try {
        & $commandName @ArgumentMap
    } catch {
        $originalException = $_.Exception
        $errorMessage = "$Provider backend call failed: $($originalException.Message). " +
            "If this looks like an auth error, run Test-CloudConnection -Provider $Provider or Connect-Cloud -Provider $Provider."

        if ($CallerPSCmdlet) {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Management.Automation.PSInvalidOperationException]::new($errorMessage, $originalException),
                'PSCumulusBackendError',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $Provider
            )
            $CallerPSCmdlet.ThrowTerminatingError($errorRecord)
        } else {
            throw [System.InvalidOperationException]::new($errorMessage, $originalException)
        }
    }
}
