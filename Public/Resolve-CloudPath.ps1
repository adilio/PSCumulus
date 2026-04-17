function Resolve-CloudPath {
    <#
        .SYNOPSIS
            Parses a cloud path string into a structured CloudPath object.

        .DESCRIPTION
            Resolve-CloudPath converts a cloud path string into a structured CloudPath object
            that can be used for path-based operations. The path format is:

                {Provider}:\{Scope}\{Kind}\{ResourceName}

            Where Provider is Azure, AWS, or GCP; Scope is resource group/region/project;
            Kind is Instances, Disks, Storage, Networks, Functions, or Tags; and
            ResourceName is the specific resource name.

        .EXAMPLE
            Resolve-CloudPath 'Azure:\prod-rg\Instances\web-server-01'

            Parses the full Azure instance path.

        .EXAMPLE
            'AWS:\us-east-1\Disks' | Resolve-CloudPath

            Parses an AWS disk container path via pipeline.

        .EXAMPLE
            Resolve-CloudPath 'GCP:\my-project'

            Parses a GCP project scope path.
    #>
    [CmdletBinding()]
    [OutputType([CloudPath])]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    process {
        [CloudPath]::Parse($Path)
    }
}
