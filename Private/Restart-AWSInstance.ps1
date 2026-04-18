function Restart-AWSInstance {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'This internal helper is invoked only by Restart-CloudInstance, which implements ShouldProcess.'
    )]
    [CmdletBinding()]
    [OutputType([AWSCloudRecord])]
    param(
        [Parameter(Mandatory)]
        [string]$InstanceId,

        [string]$Region
    )

    Assert-CommandAvailable `
        -CommandName 'Restart-EC2Instance' `
        -InstallHint "Install the AWS.Tools.EC2 module with: Install-Module AWS.Tools.EC2 -Scope CurrentUser"

    $restartParams = @{
        InstanceId = $InstanceId
        ErrorAction = 'Stop'
    }

    Restart-EC2Instance @restartParams

    $record = [AWSCloudRecord]::new()
    $record.Kind = 'Instance'
    $record.Provider = [CloudProvider]::AWS.ToString()
    $record.Name = $InstanceId
    $record.Region = $Region
    $record.Status = 'Stopping'
    $record.InstanceId = $InstanceId
    $record.Metadata = @{
        InstanceId = $InstanceId
    }

    return $record
}
