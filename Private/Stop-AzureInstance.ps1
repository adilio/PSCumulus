function Stop-AzureInstance {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'This internal helper is invoked only by Stop-CloudInstance, which implements ShouldProcess.'
    )]
    [CmdletBinding()]
    [OutputType([AzureCloudRecord])]
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

    $record = [AzureCloudRecord]::new()
    $record.Kind = 'Instance'
    $record.Provider = [CloudProvider]::Azure.ToString()
    $record.Name = $Name
    $record.Status = 'Stopping'
    $record.ResourceGroup = $ResourceGroup
    $record.Metadata = @{
        ResourceGroup = $ResourceGroup
    }

    return $record
}
