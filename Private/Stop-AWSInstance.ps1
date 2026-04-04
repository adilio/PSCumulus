function Stop-AWSInstance {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'This internal helper is invoked only by Stop-CloudInstance, which implements ShouldProcess.'
    )]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$InstanceId,

        [string]$Region
    )

    Assert-CommandAvailable `
        -CommandName 'Stop-EC2Instance' `
        -InstallHint "Install the AWS.Tools.EC2 module with: Install-Module AWS.Tools.EC2 -Scope CurrentUser"

    $stopParams = @{ InstanceId = $InstanceId }
    if (-not [string]::IsNullOrWhiteSpace($Region)) {
        $stopParams.Region = $Region
    }

    $null = Stop-EC2Instance @stopParams -ErrorAction Stop

    ConvertTo-CloudRecord `
        -Name $InstanceId `
        -Provider AWS `
        -Region $Region `
        -Status 'Stopping' `
        -Metadata @{
            InstanceId = $InstanceId
        }
}
