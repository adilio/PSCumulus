function Get-AWSTagData {
    [CmdletBinding()]
    [OutputType([AWSTagRecord])]
    param(
        [string]$ResourceId
    )

    Assert-CommandAvailable `
        -CommandName 'Get-EC2Tag' `
        -InstallHint "Install the AWS.Tools.EC2 module with: Install-Module AWS.Tools.EC2 -Scope CurrentUser"

    $tagFilter = @{ Name = 'resource-id'; Values = @($ResourceId) }
    $tagObjects = Get-EC2Tag -Filter $tagFilter -ErrorAction Stop

    [AWSTagRecord]::FromEC2Tags($tagObjects, $ResourceId)
}
