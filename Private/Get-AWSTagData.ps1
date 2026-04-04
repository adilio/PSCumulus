function Get-AWSTagData {
    [CmdletBinding()]
    param(
        [string]$ResourceId
    )

    Assert-CommandAvailable `
        -CommandName 'Get-EC2Tag' `
        -InstallHint "Install the AWS.Tools.EC2 module with: Install-Module AWS.Tools.EC2 -Scope CurrentUser"

    $tagFilter = @{ Name = 'resource-id'; Values = @($ResourceId) }
    $tagObjects = Get-EC2Tag -Filter $tagFilter -ErrorAction Stop

    $tags = @{}
    foreach ($tag in $tagObjects) {
        $tags[$tag.Key] = $tag.Value
    }

    ConvertTo-CloudRecord `
        -Name $ResourceId `
        -Provider AWS `
        -Metadata @{
            ResourceId = $ResourceId
            Tags       = $tags
        }
}
