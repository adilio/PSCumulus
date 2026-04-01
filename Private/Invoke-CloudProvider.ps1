function Invoke-CloudProvider {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Azure', 'AWS', 'GCP')]
        [string]$Provider,

        [Parameter(Mandatory)]
        [hashtable]$CommandMap,

        [hashtable]$ArgumentMap = @{}
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

    & $commandName @ArgumentMap
}
