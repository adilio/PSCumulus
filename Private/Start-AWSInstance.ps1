function Start-AWSInstance {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'This internal helper is invoked only by Start-CloudInstance, which implements ShouldProcess.'
    )]
    [CmdletBinding()]
    [OutputType([AWSCloudRecord])]
    param(
        [Parameter(Mandatory)]
        [string]$InstanceId,

        [string]$Region
    )

    Assert-CommandAvailable `
        -CommandName 'Start-EC2Instance' `
        -InstallHint "Install the AWS.Tools.EC2 module with: Install-Module AWS.Tools.EC2 -Scope CurrentUser"

    $startParams = @{ InstanceId = $InstanceId }
    if (-not [string]::IsNullOrWhiteSpace($Region)) {
        $startParams.Region = $Region
    }

    $null = Start-EC2Instance @startParams -ErrorAction Stop

    $record = [AWSCloudRecord]::new()
    $record.Kind = 'Instance'
    $record.Provider = [CloudProvider]::AWS.ToString()
    $record.Name = $InstanceId
    $record.Region = $Region
    $record.Status = 'Starting'
    $record.InstanceId = $InstanceId
    $record.Metadata = @{
        InstanceId = $InstanceId
    }

    return $record
}
