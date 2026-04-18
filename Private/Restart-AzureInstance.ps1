function Restart-AzureInstance {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'This internal helper is invoked only by Restart-CloudInstance, which implements ShouldProcess.'
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
        -CommandName 'Restart-AzVM' `
        -InstallHint "Install the Az.Compute module with: Install-Module Az.Compute -Scope CurrentUser"

    $null = Restart-AzVM -ResourceGroupName $ResourceGroup -Name $Name -ErrorAction Stop

    $record = [AzureCloudRecord]::new()
    $record.Kind = 'Instance'
    $record.Provider = [CloudProvider]::Azure.ToString()
    $record.Name = $Name
    $record.Status = 'Starting'
    $record.ResourceGroup = $ResourceGroup
    $record.Metadata = @{
        ResourceGroup = $ResourceGroup
    }

    return $record
}
