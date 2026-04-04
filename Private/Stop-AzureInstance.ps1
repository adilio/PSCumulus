function Stop-AzureInstance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$ResourceGroup
    )

    Assert-CommandAvailable `
        -CommandName 'Stop-AzVM' `
        -InstallHint "Install the Az.Compute module with: Install-Module Az.Compute -Scope CurrentUser"

    $null = Stop-AzVM -ResourceGroupName $ResourceGroup -Name $Name -Force -ErrorAction Stop

    ConvertTo-CloudRecord `
        -Name $Name `
        -Provider Azure `
        -Status 'Stopping' `
        -Metadata @{
            ResourceGroup = $ResourceGroup
        }
}
