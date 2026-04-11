function Connect-Cloud {
    <#
        .SYNOPSIS
            Prepares a ready-to-use cloud session for the specified provider.

        .DESCRIPTION
            Connect-Cloud is the session readiness command for PSCumulus. It checks whether
            the provider tools are installed, detects whether an active authentication session
            already exists, triggers the provider-native login flow if one is needed, and stores
            a normalized session context for the current PowerShell session.

            After Connect-Cloud completes, the active provider is remembered so that later
            commands can omit -Provider when the intent is unambiguous.

            Pass an array to -Provider to connect multiple providers in one call:

                Connect-Cloud -Provider AWS, Azure, GCP

            Per-provider context (account identity, scope, region, and connection time) is
            stored separately for each provider. Use Get-CloudContext to inspect all established
            sessions.

        .EXAMPLE
            Connect-Cloud -Provider Azure

            Checks for an existing Azure session. If none is found, triggers
            Connect-AzAccount interactively, then stores the session context.

        .EXAMPLE
            Connect-Cloud -Provider AWS -Region 'us-east-1'

            Checks for existing AWS credentials. If none are found, triggers
            the AWS configuration flow, then stores the session context.

        .EXAMPLE
            Connect-Cloud -Provider GCP -Project 'my-project'

            Checks for an active gcloud account. If none is found, triggers
            gcloud auth application-default login, then stores the session context.

        .EXAMPLE
            Connect-Cloud -Provider AWS, Azure, GCP

            Connects all three providers in sequence. Each gets its own stored context.
            ActiveProvider is set to the last provider connected.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Azure')]
    [OutputType([pscustomobject])]
    param(
        # The cloud provider or providers to connect to.
        [Parameter(Mandatory, ParameterSetName = 'Azure')]
        [Parameter(Mandatory, ParameterSetName = 'AWS')]
        [Parameter(Mandatory, ParameterSetName = 'GCP')]
        [ValidateSet('Azure', 'AWS', 'GCP')]
        [string[]]$Provider,

        # The AWS region to target for the connection context.
        [Parameter(Mandatory, ParameterSetName = 'AWS')]
        [ValidateNotNullOrEmpty()]
        [string]$Region,

        # The GCP project to target for the connection context.
        [Parameter(Mandatory, ParameterSetName = 'GCP')]
        [ValidateNotNullOrEmpty()]
        [string]$Project
    )

    process {
        $commandMap = @{
            Azure = 'Connect-AzureBackend'
            AWS   = 'Connect-AWSBackend'
            GCP   = 'Connect-GCPBackend'
        }

        foreach ($p in $Provider) {
            $argumentMap = @{}

            if ($p -eq 'AWS' -and $PSBoundParameters.ContainsKey('Region')) {
                $argumentMap.Region = $Region
            }

            if ($p -eq 'GCP' -and $PSBoundParameters.ContainsKey('Project')) {
                $argumentMap.Project = $Project
            }

            $result = Invoke-CloudProvider -Provider $p -CommandMap $commandMap -ArgumentMap $argumentMap

            $scope = switch ($p) {
                'Azure' { $result.Subscription }
                'AWS'   { $result.ProfileName }
                'GCP'   { $result.Project }
            }

            $script:PSCumulusContext.ActiveProvider = $p
            $script:PSCumulusContext.Providers[$p] = @{
                Account     = $result.Account
                Scope       = $scope
                Region      = $result.Region
                ConnectedAt = Get-Date
            }

            $result
        }
    }
}
