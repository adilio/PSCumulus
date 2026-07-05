function Get-CloudResource {
    <#
        .SYNOPSIS
            Resolves a CloudPath to live cloud resources.

        .DESCRIPTION
            Get-CloudResource takes a CloudPath string (the same grammar that
            Resolve-CloudPath parses), dispatches to the matching provider backend,
            and returns normalized CloudRecord objects.

            The path must reach at least Kind depth:

                {Provider}:\{Scope}\{Kind}[\{ResourceName}]

            A Kind-depth path (for example 'Azure:\prod-rg\Instances') lists every
            resource of that kind in the scope. A Resource-depth path (for example
            'Azure:\prod-rg\Instances\web-01') returns the single matching resource,
            or writes a non-terminating error when nothing matches.

            The Tags kind is not addressable through Get-CloudResource; use
            Get-CloudTag for tag queries.

        .EXAMPLE
            Get-CloudResource 'Azure:\prod-rg\Instances\web-server-01'

            Returns the normalized record for one Azure VM.

        .EXAMPLE
            Get-CloudResource 'AWS:\us-east-1\Disks'

            Lists every EBS volume in the region as CloudRecord objects.

        .EXAMPLE
            Get-CloudResource 'GCP:\my-project\Functions\resize-images' -Detailed

            Returns a GCP Cloud Function with the detailed view enabled.

        .EXAMPLE
            'Azure:\prod-rg\Storage\proddata01' | Get-CloudResource | Set-CloudTag -Tags @{ owner = 'ops' }

            Resolves a storage account by path and pipes it into tagging.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        # The CloudPath to resolve. Must include at least Provider, Scope, and Kind.
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        # Emit detailed view records.
        [switch]$Detailed
    )

    process {
        $cloudPath = Resolve-CloudPath -Path $Path

        if ($cloudPath.Kind -eq 'Tags') {
            throw [System.ArgumentException]::new(
                "The Tags kind is not addressable through Get-CloudResource. Use Get-CloudTag instead. Path: '$Path'"
            )
        }

        if ($cloudPath.Depth -lt [CloudPathDepth]::Kind) {
            throw [System.ArgumentException]::new(
                "Path must include at least a kind segment ({Provider}:\{Scope}\{Kind}). Got: '$Path'"
            )
        }

        $resolved = [CloudPathResolver]::Resolve($cloudPath)

        $argumentMap = @{}
        foreach ($key in $resolved.ArgumentMap.Keys) {
            $argumentMap[$key] = $resolved.ArgumentMap[$key]
        }

        # Only the instance backends accept -Name; every other kind is filtered
        # client-side after the backend call.
        $backendSupportsName = $cloudPath.Kind -eq 'Instances'
        if (-not $backendSupportsName -and $argumentMap.ContainsKey('Name')) {
            $argumentMap.Remove('Name')
        }

        $commandMap = @{ $cloudPath.Provider = $resolved.CommandName }

        $results = Invoke-CloudProvider `
            -Provider $cloudPath.Provider `
            -CommandMap $commandMap `
            -ArgumentMap $argumentMap `
            -CallerPSCmdlet $PSCmdlet

        if ($cloudPath.Depth -eq [CloudPathDepth]::Resource -and -not $backendSupportsName) {
            $results = @($results) | Where-Object { $_.Name -eq $cloudPath.ResourceName }
        }

        if ($cloudPath.Depth -eq [CloudPathDepth]::Resource -and -not @($results | Where-Object { $_ })) {
            Write-Error -Message ("No {0} resource named '{1}' was found at path '{2}'." -f $cloudPath.Provider, $cloudPath.ResourceName, $Path) `
                -Category ObjectNotFound `
                -TargetObject $Path
            return
        }

        foreach ($record in @($results)) {
            if (-not $record) { continue }

            if ($Detailed -and $record.PSObject.TypeNames[0] -ne 'PSCumulus.CloudRecord.Detailed') {
                $record.PSObject.TypeNames.Insert(0, 'PSCumulus.CloudRecord.Detailed')
            }

            $record
        }
    }
}
