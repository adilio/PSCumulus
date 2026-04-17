function Get-AWSFunctionData {
    [CmdletBinding()]
    [OutputType([AWSFunctionRecord])]
    param(
        [string]$Region
    )

    Assert-CommandAvailable `
        -CommandName 'Get-LMFunctionList' `
        -InstallHint "Install the AWS.Tools.Lambda module with: Install-Module AWS.Tools.Lambda -Scope CurrentUser"

    $functions = if ([string]::IsNullOrWhiteSpace($Region)) {
        Get-LMFunctionList -ErrorAction Stop
    } else {
        Get-LMFunctionList -Region $Region -ErrorAction Stop
    }

    foreach ($function in $functions) {
        [AWSFunctionRecord]::FromLambdaFunction($function, $Region)
    }
}
