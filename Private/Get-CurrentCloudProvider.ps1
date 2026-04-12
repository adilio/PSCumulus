function Get-CurrentCloudProvider {
    [CmdletBinding()]
    param()

    $null = Update-CloudContextActiveProvider
    $script:PSCumulusContext.ActiveProvider
}
