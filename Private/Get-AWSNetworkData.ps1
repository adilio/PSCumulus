function Get-AWSNetworkData {
    [CmdletBinding()]
    param(
        [string]$Region
    )

    Assert-CommandAvailable `
        -CommandName 'Get-EC2Vpc' `
        -InstallHint "Install the AWS.Tools.EC2 module with: Install-Module AWS.Tools.EC2 -Scope CurrentUser"

    $vpcs = if ([string]::IsNullOrWhiteSpace($Region)) {
        Get-EC2Vpc -ErrorAction Stop
    } else {
        Get-EC2Vpc -Region $Region -ErrorAction Stop
    }

    foreach ($vpc in $vpcs) {
        $nameTag = $vpc.Tags |
            Where-Object { $_.Key -eq 'Name' } |
            Select-Object -First 1 -ExpandProperty Value

        $resolvedName = if ([string]::IsNullOrWhiteSpace($nameTag)) {
            $vpc.VpcId
        } else {
            $nameTag
        }

        ConvertTo-CloudRecord `
            -Name $resolvedName `
            -Provider AWS `
            -Region $Region `
            -Status $vpc.State.Value `
            -Size $vpc.CidrBlock `
            -Metadata @{
                VpcId     = $vpc.VpcId
                IsDefault = $vpc.IsDefault
                CidrBlock = $vpc.CidrBlock
            }
    }
}
