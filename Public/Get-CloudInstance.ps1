function Get-CloudInstance {
    <#
        .SYNOPSIS
            Gets compute instances from a selected cloud provider.

        .DESCRIPTION
            Routes instance inventory requests to the matching provider backend and
            returns normalized cloud record objects.

            Use -All to query every provider that has an established session context,
            returning instances from all connected clouds in one pipeline.

        .EXAMPLE
            Get-CloudInstance -Provider Azure -ResourceGroup 'prod-rg'

            Gets Azure instances scoped to a resource group.

        .EXAMPLE
            Get-CloudInstance -Provider Azure -ResourceGroup 'prod-rg' -Name 'web-server-01'

            Gets the Azure instance named web-server-01 within the resource group.

        .EXAMPLE
            Get-CloudInstance -Provider AWS -Region 'us-east-1'

            Gets AWS instances for a region.

        .EXAMPLE
            Get-CloudInstance -Provider AWS -Region 'us-east-1' -Name 'app-server-01'

            Gets the AWS instance with the matching Name tag or InstanceId.

        .EXAMPLE
            Get-CloudInstance -Provider GCP -Project 'my-project'

            Gets GCP instances for a project.

        .EXAMPLE
            Get-CloudInstance -Provider GCP -Project 'my-project' -Name 'gcp-vm-01'

            Gets the GCP instance with the matching instance name.

        .EXAMPLE
            Get-CloudInstance -All

            Gets instances from all providers with an established session context.
            Use after Connect-Cloud -Provider AWS, Azure, GCP.

        .EXAMPLE
            Get-CloudInstance -All | Where-Object { $_.Tags['environment'] -eq 'prod' }

            Gets all prod-tagged instances across every connected cloud.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Azure')]
    [OutputType([pscustomobject])]
    param(
        # The cloud provider to query.
        [Parameter(ParameterSetName = 'Azure')]
        [Parameter(ParameterSetName = 'AWS')]
        [Parameter(ParameterSetName = 'GCP')]
        [string]$Provider,

        # The Azure resource group containing the target instances.
        [Parameter(Mandatory, ParameterSetName = 'Azure')]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroup,

        # The instance name to filter within the selected scope.
        [Parameter(ParameterSetName = 'Azure')]
        [Parameter(ParameterSetName = 'AWS')]
        [Parameter(ParameterSetName = 'GCP')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        # The AWS region to query for instances.
        [Parameter(Mandatory, ParameterSetName = 'AWS')]
        [ValidateNotNullOrEmpty()]
        [string]$Region,

        # The GCP project to query for instances.
        [Parameter(Mandatory, ParameterSetName = 'GCP')]
        [ValidateNotNullOrEmpty()]
        [string]$Project,

        # Query all providers with an established session context.
        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch]$All
    )

    process {
        $commandMap = @{
            Azure = 'Get-AzureInstanceData'
            AWS   = 'Get-AWSInstanceData'
            GCP   = 'Get-GCPInstanceData'
        }

        if ($PSCmdlet.ParameterSetName -eq 'All') {
            foreach ($providerName in 'Azure', 'AWS', 'GCP') {
                $ctx = $script:PSCumulusContext.Providers[$providerName]
                if ($null -eq $ctx) { continue }

                $argumentMap = @{}

                if ($providerName -eq 'AWS' -and -not [string]::IsNullOrWhiteSpace($ctx.Region)) {
                    $argumentMap.Region = $ctx.Region
                }

                if ($providerName -eq 'GCP' -and -not [string]::IsNullOrWhiteSpace($ctx.Scope)) {
                    $argumentMap.Project = $ctx.Scope
                }

                Invoke-CloudProvider -Provider $providerName -CommandMap $commandMap -ArgumentMap $argumentMap
            }

            return
        }

        $resolvedProvider = Resolve-CloudProvider -Provider $Provider -ParameterSetName $PSCmdlet.ParameterSetName

        $argumentMap = @{}

        if ($resolvedProvider -eq 'Azure' -and $PSBoundParameters.ContainsKey('ResourceGroup')) {
            $argumentMap.ResourceGroup = $ResourceGroup
        }

        if ($resolvedProvider -eq 'Azure' -and $PSBoundParameters.ContainsKey('Name')) {
            $argumentMap.Name = $Name
        }

        if ($resolvedProvider -eq 'AWS' -and $PSBoundParameters.ContainsKey('Region')) {
            $argumentMap.Region = $Region
        }

        if ($resolvedProvider -eq 'AWS' -and $PSBoundParameters.ContainsKey('Name')) {
            $argumentMap.Name = $Name
        }

        if ($resolvedProvider -eq 'GCP' -and $PSBoundParameters.ContainsKey('Project')) {
            $argumentMap.Project = $Project
        }

        if ($resolvedProvider -eq 'GCP' -and $PSBoundParameters.ContainsKey('Name')) {
            $argumentMap.Name = $Name
        }

        Invoke-CloudProvider -Provider $resolvedProvider -CommandMap $commandMap -ArgumentMap $argumentMap
    }
}
