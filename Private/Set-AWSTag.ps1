function Set-AWSTag {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'This internal helper is invoked only by Set-CloudTag, which implements ShouldProcess.'
    )]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ResourceId,

        [Parameter(Mandatory)]
        [hashtable]$Tags,

        [switch]$Merge,

        [string]$Region
    )

    Assert-CommandAvailable `
        -CommandName 'Add-EC2Tag' `
        -InstallHint "Install the AWS.Tools.EC2 module with: Install-Module AWS.Tools.EC2 -Scope CurrentUser"

    if ($Merge) {
        $filter = @{ Name = 'resource-id'; Values = @($ResourceId) }
        $existingTags = Get-EC2Tag -Filter @($filter) -Region $Region -ErrorAction SilentlyContinue

        if ($existingTags) {
            foreach ($tag in $existingTags) {
                $tagKey = $tag.Key
                $tagValue = $tag.Value
                if (-not $Tags.ContainsKey($tagKey)) {
                    $Tags[$tagKey] = $tagValue
                }
            }
        }
    }

    $tagObjects = foreach ($key in $Tags.Keys) {
        [pscustomobject]@{
            Key   = $key
            Value = $Tags[$key]
        }
    }

    New-EC2Tag -Resource $ResourceId -Tag $tagObjects -ErrorAction Stop
}
