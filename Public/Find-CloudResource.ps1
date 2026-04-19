function Find-CloudResource {
    <#
        .SYNOPSIS
            Searches for cloud resources by name across providers and resource kinds.

        .DESCRIPTION
            Find-CloudResource performs a cross-kind, cross-cloud search for resources by name.
            Use this when you know a resource name but not whether it's a VM, disk, storage account,
            network, or function, or when you need to search multiple clouds simultaneously.

            Wildcards are supported in the -Name parameter.

        .EXAMPLE
            Find-CloudResource -Name 'payment-svc-03'

            Searches all providers and all resource kinds for 'payment-svc-03'.

        .EXAMPLE
            Find-CloudResource -Name 'prod-*' -Provider Azure, AWS

            Searches Azure and AWS for any resource starting with 'prod-'.

        .EXAMPLE
            Find-CloudResource -Name 'web-*' -Kind Instance, Network

            Searches for instances and networks with names starting with 'web-'.

        .EXAMPLE
            Find-CloudResource -Name '*test*' -Provider GCP -Kind Storage

            Searches GCP storage resources for names containing 'test'.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        # The resource name to search for. Wildcards are supported.
        [Parameter(Mandatory, Position = 0)]
        [SupportsWildcards()]
        [string]$Name,

        # Limit search to specific providers. If not specified, searches all connected providers.
        [ValidateSet('Azure', 'AWS', 'GCP')]
        [string[]]$Provider,

        # Limit search to specific resource kinds. If not specified, searches all kinds.
        [ValidateSet('Instance', 'Disk', 'Storage', 'Network', 'Function')]
        [string[]]$Kind
    )

    process {
        # Resolve provider list
        $providersToSearch = if ($Provider) {
            $Provider | Where-Object { $script:PSCumulusContext.Providers[$_] }
        } else {
            @('Azure', 'AWS', 'GCP') | Where-Object { $script:PSCumulusContext.Providers[$_] }
        }

        # Resolve kind list
        $kindsToSearch = if ($Kind) { $Kind } else { @('Instance', 'Disk', 'Storage', 'Network', 'Function') }

        $results = [System.Collections.Generic.List[psobject]]::new()

        foreach ($providerName in $providersToSearch) {
            foreach ($kindName in $kindsToSearch) {
                $commandName = "Get-Cloud$kindName"
                $commandParams = @{ Provider = $providerName }

                # Add provider-specific scope parameters from context
                $ctx = $script:PSCumulusContext.Providers[$providerName]

                switch ($providerName) {
                    'Azure' {
                        if ($ctx.ResourceGroup) {
                            $commandParams.ResourceGroup = $ctx.ResourceGroup
                        } else {
                            # Skip if no resource group in context
                            continue
                        }
                    }
                    'AWS' {
                        if ($ctx.Region) {
                            $commandParams.Region = $ctx.Region
                        } else {
                            # Skip if no region in context
                            continue
                        }
                    }
                    'GCP' {
                        if ($ctx.Project) {
                            $commandParams.Project = $ctx.Project
                        } else {
                            # Skip if no project in context
                            continue
                        }
                    }
                }

                try {
                    $kindResults = & $commandName @commandParams -ErrorAction SilentlyContinue

                    if ($kindResults) {
                        foreach ($result in $kindResults) {
                            # Add Kind property if not already present
                            if (-not $result.PSObject.Properties.Match('Kind').Count) {
                                $result | Add-Member -MemberType NoteProperty -Name 'Kind' -Value $kindName -Force
                            }

                            # Filter by name
                            if ($result.Name -like $Name) {
                                $results.Add($result)
                            }
                        }
                    }
                } catch {
                    Write-Verbose "Find-CloudResource: Failed to query $providerName $kindName`: $_"
                }
            }
        }

        $results
    }
}
