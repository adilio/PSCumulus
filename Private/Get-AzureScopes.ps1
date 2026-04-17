function Get-AzureScopes {
    <#
        .SYNOPSIS
            Returns Azure resource groups as scope nodes.

        .DESCRIPTION
            Get-AzureScopes retrieves all resource groups for the current
            Azure subscription, which serve as the scope nodes in the
            cloud provider drive.
    #>
    [CmdletBinding()]
    param()

    Assert-CommandAvailable `
        -CommandName 'Get-AzResourceGroup' `
        -InstallHint "Install the Az.Resources module with: Install-Module Az.Resources -Scope CurrentUser"

    (Get-AzResourceGroup -ErrorAction Stop).ResourceGroupName
}
