function Get-AWSFunctionData {
    [CmdletBinding()]
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
        $runtime = if ($function.Runtime) { $function.Runtime.Value } else { $null }

        $params = @{
            Name     = $function.FunctionName
            Provider = 'AWS'
            Region   = $Region
            Status   = 'Active'
            Metadata = @{
                FunctionArn = $function.FunctionArn
                Runtime     = $runtime
                Handler     = $function.Handler
                MemorySize  = $function.MemorySize
                Timeout     = $function.Timeout
            }
        }

        if ($runtime) { $params.Size = $runtime }

        if (-not [string]::IsNullOrWhiteSpace($function.LastModified)) {
            $params.CreatedAt = [datetime]::Parse($function.LastModified)
        }

        ConvertTo-CloudRecord @params
    }
}
