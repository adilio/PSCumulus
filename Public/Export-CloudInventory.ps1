function Export-CloudInventory {
    <#
        .SYNOPSIS
            Exports all connected cloud inventory to a file.

        .DESCRIPTION
            Exports a point-in-time snapshot of every resource across every connected cloud
            to a file in JSON or CSV format. Useful for compliance audits, before/after snapshots,
            and inventory diffing.

        .EXAMPLE
            Export-CloudInventory -Path 'inventory.json'

            Exports all resources from all connected providers to inventory.json (JSON format).

        .EXAMPLE
            Export-CloudInventory -Path 'inventory.csv' -Format Csv

            Exports all resources to inventory.csv in CSV format.

        .EXAMPLE
            Export-CloudInventory -Path 'azure-inventory.json' -Provider Azure -Kind Instance, Disk

            Exports only Azure instances and disks to azure-inventory.json.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.IO.FileInfo])]
    param(
        # The output file path.
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,

        # The output format.
        [ValidateSet('Json', 'Csv')]
        [string]$Format = 'Json',

        # The resource kinds to include.
        [ValidateSet('Instance', 'Disk', 'Storage', 'Network', 'Function')]
        [string[]]$Kind = @('Instance', 'Disk', 'Storage', 'Network', 'Function'),

        # Limit to specific providers.
        [ValidateSet('Azure', 'AWS', 'GCP')]
        [string[]]$Provider
    )

    process {
        # Resolve provider list
        $providersToExport = if ($Provider) {
            $Provider | Where-Object { $script:PSCumulusContext.Providers[$_] }
        } else {
            @('Azure', 'AWS', 'GCP') | Where-Object { $script:PSCumulusContext.Providers[$_] }
        }

        # Build (provider, kind) matrix and collect records
        $inventory = [ordered]@{}

        $azureRgCacheLoaded = $false

        try {
            foreach ($providerName in $providersToExport) {
                foreach ($kindName in $Kind) {
                    $key = "$providerName/$kindName"
                    $commandName = "Get-Cloud$kindName"
                    $scopeParameterSets = [System.Collections.Generic.List[hashtable]]::new()

                    # Add provider-specific scope from context
                    $ctx = $script:PSCumulusContext.Providers[$providerName]
                    $skipProvider = $false

                    switch ($providerName) {
                        'Azure' {
                            if (-not $azureRgCacheLoaded) {
                                $azureRgCacheLoaded = $true
                                if (Get-Command Get-AzResourceGroup -ErrorAction SilentlyContinue) {
                                    $script:__PSCumulusInventoryAzureRgCache = @(Get-AzResourceGroup -ErrorAction SilentlyContinue)
                                } else {
                                    $script:__PSCumulusInventoryAzureRgCache = @()
                                }
                            }

                            if ($script:__PSCumulusInventoryAzureRgCache.Count -gt 0) {
                                foreach ($rg in $script:__PSCumulusInventoryAzureRgCache) {
                                    if (-not [string]::IsNullOrWhiteSpace($rg.ResourceGroupName)) {
                                        $scopeParameterSets.Add(@{ ResourceGroup = $rg.ResourceGroupName })
                                    }
                                }
                            } else {
                                Write-Verbose "Export-CloudInventory: no resource groups returned for Azure subscription $($ctx.SubscriptionId); skipping."
                                $skipProvider = $true
                            }
                            break
                        }
                        'AWS' {
                            if ($ctx.Region) {
                                $scopeParameterSets.Add(@{ Region = $ctx.Region })
                            } else {
                                Write-Verbose "Export-CloudInventory: no region found for AWS context; skipping."
                                $skipProvider = $true
                            }
                            break
                        }
                        'GCP' {
                            if ($ctx.Project) {
                                $scopeParameterSets.Add(@{ Project = $ctx.Project })
                            } else {
                                Write-Verbose "Export-CloudInventory: no project found for GCP context; skipping."
                                $skipProvider = $true
                            }
                            break
                        }
                    }

                    if ($skipProvider) {
                        continue
                    }

                    $mergedRecords = [System.Collections.Generic.List[psobject]]::new()
                    foreach ($scopeParams in $scopeParameterSets) {
                        try {
                            $commandParams = @{ Provider = $providerName }
                            foreach ($paramName in $scopeParams.Keys) {
                                $commandParams[$paramName] = $scopeParams[$paramName]
                            }

                            $records = & $commandName @commandParams -ErrorAction SilentlyContinue
                            foreach ($record in @($records)) {
                                if ($null -ne $record) {
                                    $mergedRecords.Add($record)
                                }
                            }
                        } catch {
                            Write-Verbose "Export-CloudInventory: Failed to query $key`: $_"
                        }
                    }

                    $inventory[$key] = @($mergedRecords)
                }
            }
        } finally {
            Remove-Variable -Scope Script -Name __PSCumulusInventoryAzureRgCache -ErrorAction SilentlyContinue -WhatIf:$false
        }

        # Export based on format
        if ($PSCmdlet.ShouldProcess($Path, 'Export cloud inventory')) {
            if ($Format -eq 'Json') {
                $json = $inventory | ConvertTo-Json -Depth 8
                $json | Out-File -FilePath $Path -Encoding utf8 -Force
            } else {
                # CSV format: flatten each record
                $flatRecords = [System.Collections.Generic.List[pscustomobject]]::new()

                foreach ($key in $inventory.Keys) {
                    $parts = $key -split '/'
                    $providerName = $parts[0]
                    $kindName = $parts[1]

                    foreach ($record in $inventory[$key]) {
                        $flat = [PSCustomObject]@{
                            Provider    = $providerName
                            Kind        = $kindName
                            Name        = $record.Name
                            Id          = $record.Id
                            Status      = $record.Status
                            Tags        = if ($record.Tags) { ($record.Tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ';' } else { $null }
                            Metadata    = if ($record.Metadata) { ($record.Metadata.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ';' } else { $null }
                        }

                        # Add provider-specific properties
                        switch ($providerName) {
                            'Azure' {
                                if ($record.PSObject.Properties.Match('ResourceGroup').Count) {
                                    $flat | Add-Member -MemberType NoteProperty -Name 'ResourceGroup' -Value $record.ResourceGroup -Force
                                }
                            }
                            'AWS' {
                                if ($record.PSObject.Properties.Match('Region').Count) {
                                    $flat | Add-Member -MemberType NoteProperty -Name 'Region' -Value $record.Region -Force
                                }
                                if ($record.PSObject.Properties.Match('InstanceId').Count) {
                                    $flat | Add-Member -MemberType NoteProperty -Name 'InstanceId' -Value $record.InstanceId -Force
                                }
                            }
                            'GCP' {
                                if ($record.PSObject.Properties.Match('Project').Count) {
                                    $flat | Add-Member -MemberType NoteProperty -Name 'Project' -Value $record.Project -Force
                                }
                                if ($record.PSObject.Properties.Match('Zone').Count) {
                                    $flat | Add-Member -MemberType NoteProperty -Name 'Zone' -Value $record.Zone -Force
                                }
                            }
                        }

                        $flatRecords.Add($flat)
                    }
                }

                $flatRecords | Export-Csv -Path $Path -NoTypeInformation -Encoding utf8 -Force
            }

            Get-Item -Path $Path
        }
    }
}
