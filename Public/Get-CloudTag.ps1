function Get-CloudTag {
    <#
        .SYNOPSIS
            Gets resource tags or labels from a selected cloud provider.

        .DESCRIPTION
            Routes resource metadata requests to the matching provider backend for
            Azure, AWS, or GCP.

        .EXAMPLE
            Get-CloudTag -Provider Azure -ResourceId '/subscriptions/.../virtualMachines/vm01'

            Gets Azure tags for a resource identifier.

        .EXAMPLE
            Get-CloudTag -Provider AWS -ResourceId 'i-0123456789abcdef0'

            Gets AWS tags for a resource identifier.

        .EXAMPLE
            Get-CloudTag -Provider GCP -Project 'my-project' -Resource 'instances/vm-01'

            Gets GCP labels for a project-scoped resource.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        # The cloud provider to query.
        [Parameter()]
        [string]$Provider,

        # The provider resource identifier for Azure or AWS.
        [string]$ResourceId,

        # The GCP project containing the target resource.
        [string]$Project,

        # The GCP resource path used to resolve labels.
        [string]$Resource
    )

    process {
        $resolvedProvider = Resolve-CloudTagProvider -Provider $Provider -Project $Project -Resource $Resource

        Assert-CloudTagArgument -Provider $resolvedProvider -ResourceId $ResourceId -Project $Project -Resource $Resource

        $commandMap = @{
            Azure = 'Get-AzureTagData'
            AWS   = 'Get-AWSTagData'
            GCP   = 'Get-GCPTagData'
        }

        $argumentMap = @{}

        if ($resolvedProvider -eq 'Azure' -and $PSBoundParameters.ContainsKey('ResourceId')) {
            $argumentMap.ResourceId = $ResourceId
        }

        if ($resolvedProvider -eq 'AWS' -and $PSBoundParameters.ContainsKey('ResourceId')) {
            $argumentMap.ResourceId = $ResourceId
        }

        if ($resolvedProvider -eq 'GCP') {
            if ($PSBoundParameters.ContainsKey('Project')) {
                $argumentMap.Project = $Project
            }

            if ($PSBoundParameters.ContainsKey('Resource')) {
                $argumentMap.Resource = $Resource
            }
        }

        Invoke-CloudProvider -Provider $resolvedProvider -CommandMap $commandMap -ArgumentMap $argumentMap
    }
}
