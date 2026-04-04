function Get-CurrentCloudProvider {
    [CmdletBinding()]
    param()

    $script:PSCumulusContext.Provider
}
