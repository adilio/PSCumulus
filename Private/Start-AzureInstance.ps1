function Start-AzureInstance {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'This internal helper is invoked only by Start-CloudInstance, which implements ShouldProcess.'
    )]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$ResourceGroup
    )

    Assert-CommandAvailable `
        -CommandName 'Start-AzVM' `
        -InstallHint "Install the Az.Compute module with: Install-Module Az.Compute -Scope CurrentUser"

    $null = Start-AzVM -ResourceGroupName $ResourceGroup -Name $Name -ErrorAction Stop

    ConvertTo-CloudRecord `
        -Name $Name `
        -Provider Azure `
        -Status 'Starting' `
        -Metadata @{
            ResourceGroup = $ResourceGroup
        }
}
