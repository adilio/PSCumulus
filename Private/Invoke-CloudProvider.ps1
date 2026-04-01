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
        throw "No command mapping exists for provider '$Provider'."
    }

    $command = Get-Command -Name $commandName -ErrorAction SilentlyContinue

    if (-not $command) {
        throw "Mapped command '$commandName' was not found."
    }

    & $command @ArgumentMap
}

