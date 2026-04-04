function Start-AWSInstance {
    [CmdletBinding()]
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

    ConvertTo-CloudRecord `
        -Name $InstanceId `
        -Provider AWS `
        -Region $Region `
        -Status 'Starting' `
        -Metadata @{
            InstanceId = $InstanceId
        }
}
