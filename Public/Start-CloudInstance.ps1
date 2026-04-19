function Start-CloudInstance {
    <#
        .SYNOPSIS
            Starts a compute instance on a selected cloud provider.

        .DESCRIPTION
            Routes instance start requests to the matching provider backend and
            returns a normalized cloud record confirming the start operation.

            Use -Wait to block until the instance reaches the Running state.

        .EXAMPLE
            Start-CloudInstance -Provider Azure -Name 'web-server-01' -ResourceGroup 'prod-rg'

            Starts an Azure VM.

        .EXAMPLE
            Start-CloudInstance -Provider AWS -InstanceId 'i-0123456789abcdef0' -Region 'us-east-1'

            Starts an AWS EC2 instance.

        .EXAMPLE
            Start-CloudInstance -Provider GCP -Name 'gcp-vm-01' -Zone 'us-central1-a' -Project 'my-project'

            Starts a GCP compute instance.

        .EXAMPLE
            Get-CloudInstance -ResourceGroup 'prod-rg' -Name 'web-server-01' | Start-CloudInstance

            Starts the Azure VM using piped PSCumulus instance output.

        .EXAMPLE
            Start-CloudInstance -Provider Azure -Name 'web-server-01' -ResourceGroup 'prod-rg' -Wait -TimeoutSeconds 600

            Starts an Azure VM and waits up to 10 minutes for it to reach Running state.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Azure', SupportsShouldProcess)]
    [OutputType([pscustomobject])]
    param(
        # A PSCumulus cloud record piped from Get-CloudInstance.
        [Parameter(Mandatory, ParameterSetName = 'Piped', ValueFromPipeline)]
        [psobject]$InputObject,

        # A cloud path string (e.g., 'Azure:\prod-rg\Instances\web-server-01')
        [Parameter(Mandatory, ParameterSetName = 'Path', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        # The cloud provider to target.
        [Parameter(ParameterSetName = 'Azure', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'AWS', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'GCP', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Piped', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Path', ValueFromPipelineByPropertyName)]
        [string]$Provider,

        # The instance name (Azure and GCP).
        [Parameter(Mandatory, ParameterSetName = 'Azure', ValueFromPipelineByPropertyName)]
        [Parameter(Mandatory, ParameterSetName = 'GCP', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Piped', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        # The Azure resource group containing the target VM.
        [Parameter(Mandatory, ParameterSetName = 'Azure', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Piped', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroup,

        # The AWS EC2 instance identifier.
        [Parameter(Mandatory, ParameterSetName = 'AWS', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Piped', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$InstanceId,

        # The AWS region where the instance resides.
        [Parameter(ParameterSetName = 'AWS', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Piped', ValueFromPipelineByPropertyName)]
        [string]$Region,

        # The GCP project containing the target instance.
        [Parameter(Mandatory, ParameterSetName = 'GCP', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Piped', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Project,

        # The GCP zone where the instance resides.
        [Parameter(Mandatory, ParameterSetName = 'GCP', ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Piped', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Zone,

        # Wait for the instance to reach the Running state before returning.
        [Parameter(ParameterSetName = 'Azure')]
        [Parameter(ParameterSetName = 'AWS')]
        [Parameter(ParameterSetName = 'GCP')]
        [Parameter(ParameterSetName = 'Piped')]
        [Parameter(ParameterSetName = 'Path')]
        [switch]$Wait,

        # Maximum time to wait for the instance to reach the target state (in seconds).
        [Parameter(ParameterSetName = 'Azure')]
        [Parameter(ParameterSetName = 'AWS')]
        [Parameter(ParameterSetName = 'GCP')]
        [Parameter(ParameterSetName = 'Piped')]
        [Parameter(ParameterSetName = 'Path')]
        [int]$TimeoutSeconds = 300,

        # Polling interval to check instance status (in seconds).
        [Parameter(ParameterSetName = 'Azure')]
        [Parameter(ParameterSetName = 'AWS')]
        [Parameter(ParameterSetName = 'GCP')]
        [Parameter(ParameterSetName = 'Piped')]
        [Parameter(ParameterSetName = 'Path')]
        [int]$PollingIntervalSeconds = 5,

        # Pass the input record through to the pipeline after starting the instance.
        [Parameter(ParameterSetName = 'Azure')]
        [Parameter(ParameterSetName = 'AWS')]
        [Parameter(ParameterSetName = 'GCP')]
        [Parameter(ParameterSetName = 'Piped')]
        [Parameter(ParameterSetName = 'Path')]
        [switch]$PassThru
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Path') {
            $cloudPath = [CloudPath]::Parse($Path)

            if ($cloudPath.Depth -ne [CloudPathDepth]::Resource) {
                throw [System.ArgumentException]::new(
                    "Path must resolve to a specific resource. Got depth: $($cloudPath.Depth)"
                )
            }

            if ($cloudPath.Kind -ne 'Instances') {
                throw [System.ArgumentException]::new(
                    "Start-CloudInstance is only supported for Instances. Got kind: $($cloudPath.Kind)"
                )
            }

            $resolvedProvider = $cloudPath.Provider
            $argumentMap = @{}

            switch ($resolvedProvider) {
                'Azure' {
                    $argumentMap.Name          = $cloudPath.ResourceName
                    $argumentMap.ResourceGroup = $cloudPath.Scope
                }
                'AWS' {
                    $argumentMap.InstanceId = $cloudPath.ResourceName
                    $argumentMap.Region      = $cloudPath.Scope
                }
                'GCP' {
                    $argumentMap.Name    = $cloudPath.ResourceName
                    $argumentMap.Project = $cloudPath.Scope

                    $lookupRecords = Get-GCPInstanceData -Project $cloudPath.Scope -Name $cloudPath.ResourceName -ErrorAction SilentlyContinue
                    if (-not $lookupRecords) {
                        throw [System.InvalidOperationException]::new(
                            "Instance '$($cloudPath.ResourceName)' not found in project '$($cloudPath.Scope)'."
                        )
                    }
                    $argumentMap.Zone = $lookupRecords.Zone
                }
            }

            $target = $cloudPath.ToString()
            $commandMap = @{
                Azure = 'Start-AzureInstance'
                AWS   = 'Start-AWSInstance'
                GCP   = 'Start-GCPInstance'
            }

            if ($PSCmdlet.ShouldProcess($target, 'Start-CloudInstance')) {
                Invoke-CloudProvider -Provider $resolvedProvider -CommandMap $commandMap -ArgumentMap $argumentMap

                $lastRecord = $null

                if ($Wait -and -not $WhatIfPreference) {
                    $startTime = Get-Date
                    $targetStatus = 'Running'

                    while ($true) {
                        $elapsed = ((Get-Date) - $startTime).TotalSeconds

                        if ($elapsed -ge $TimeoutSeconds) {
                            throw [System.TimeoutException]::new(
                                "Instance did not reach '$targetStatus' state within $TimeoutSeconds seconds."
                            )
                        }

                        $currentRecord = $null
                        $currentStatus = 'Unknown'

                        switch ($resolvedProvider) {
                            'Azure' {
                                $currentRecord = Get-AzureInstanceData -ResourceGroup $argumentMap.ResourceGroup -Name $argumentMap.Name -ErrorAction SilentlyContinue | Select-Object -First 1
                            }
                            'AWS' {
                                $currentRecord = Get-AWSInstanceData -Region $argumentMap.Region -Name $argumentMap.InstanceId -ErrorAction SilentlyContinue | Select-Object -First 1
                            }
                            'GCP' {
                                $currentRecord = Get-GCPInstanceData -Project $argumentMap.Project -Name $argumentMap.Name -ErrorAction SilentlyContinue | Select-Object -First 1
                            }
                        }

                        if ($currentRecord) {
                            $currentStatus = $currentRecord.Status
                            $lastRecord = $currentRecord
                        }

                        Write-Progress -Activity "Waiting for instance to reach $targetStatus" -Status "Current status: $currentStatus - ${elapsed}s elapsed" -PercentComplete ([int] (($elapsed / $TimeoutSeconds) * 100))

                        if ($currentStatus -eq $targetStatus) {
                            Write-Progress -Activity "Waiting for instance to reach $targetStatus" -Completed
                            break
                        }

                        Start-Sleep -Seconds $PollingIntervalSeconds
                    }
                }

                if ($PassThru) {
                    if ($lastRecord) { Write-Output $lastRecord }
                    elseif ($InputObject) { Write-Output $InputObject }
                }
            }
            return
        }

        $resolvedInput = Resolve-CloudInstanceInput `
            -InputObject $InputObject `
            -Provider $Provider `
            -Name $Name `
            -ResourceGroup $ResourceGroup `
            -InstanceId $InstanceId `
            -Region $Region `
            -Project $Project `
            -Zone $Zone

        $resolvedProvider = if ($PSCmdlet.ParameterSetName -eq 'Piped') {
            Resolve-CloudProvider -Provider $resolvedInput.Provider
        } else {
            Resolve-CloudProvider -Provider $resolvedInput.Provider -ParameterSetName $PSCmdlet.ParameterSetName
        }

        $commandMap = @{
            Azure = 'Start-AzureInstance'
            AWS   = 'Start-AWSInstance'
            GCP   = 'Start-GCPInstance'
        }

        $argumentMap = @{}

        switch ($resolvedProvider) {
            'Azure' {
                $argumentMap.Name          = $resolvedInput.Name
                $argumentMap.ResourceGroup = $resolvedInput.ResourceGroup
            }
            'AWS' {
                $argumentMap.InstanceId = $resolvedInput.InstanceId
                if (-not [string]::IsNullOrWhiteSpace($resolvedInput.Region)) {
                    $argumentMap.Region = $resolvedInput.Region
                }
            }
            'GCP' {
                $argumentMap.Name    = $resolvedInput.Name
                $argumentMap.Zone    = $resolvedInput.Zone
                $argumentMap.Project = $resolvedInput.Project
            }
        }

        $target = switch ($resolvedProvider) {
            'Azure' { "$($resolvedInput.Name) in resource group $($resolvedInput.ResourceGroup)" }
            'AWS'   { $resolvedInput.InstanceId }
            'GCP'   { "$($resolvedInput.Name) in zone $($resolvedInput.Zone) ($($resolvedInput.Project))" }
        }

        if ($PSCmdlet.ShouldProcess($target, 'Start-CloudInstance')) {
            Invoke-CloudProvider -Provider $resolvedProvider -CommandMap $commandMap -ArgumentMap $argumentMap

            if ($Wait -and -not $WhatIfPreference) {
                $startTime = Get-Date
                $targetStatus = 'Running'
                $lastRecord = $null

                while ($true) {
                    $elapsed = ((Get-Date) - $startTime).TotalSeconds

                    if ($elapsed -ge $TimeoutSeconds) {
                        throw [System.TimeoutException]::new(
                            "Instance did not reach '$targetStatus' state within $TimeoutSeconds seconds."
                        )
                    }

                    $currentRecord = $null
                    $currentStatus = 'Unknown'

                    switch ($resolvedProvider) {
                        'Azure' {
                            $currentRecord = Get-AzureInstanceData -ResourceGroup $argumentMap.ResourceGroup -Name $argumentMap.Name -ErrorAction SilentlyContinue | Select-Object -First 1
                        }
                        'AWS' {
                            $currentRecord = Get-AWSInstanceData -Region $argumentMap.Region -Name $argumentMap.InstanceId -ErrorAction SilentlyContinue | Select-Object -First 1
                        }
                        'GCP' {
                            $currentRecord = Get-GCPInstanceData -Project $argumentMap.Project -Name $argumentMap.Name -ErrorAction SilentlyContinue | Select-Object -First 1
                        }
                    }

                    if ($currentRecord) {
                        $currentStatus = $currentRecord.Status
                        $lastRecord = $currentRecord
                    }

                    Write-Progress -Activity "Waiting for instance to reach $targetStatus" -Status "Current status: $currentStatus - ${elapsed}s elapsed" -PercentComplete ([int] (($elapsed / $TimeoutSeconds) * 100))

                    if ($currentStatus -eq $targetStatus) {
                        Write-Progress -Activity "Waiting for instance to reach $targetStatus" -Completed
                        break
                    }

                    Start-Sleep -Seconds $PollingIntervalSeconds
                }
            }

            if ($PassThru) {
                if ($lastRecord) { Write-Output $lastRecord }
                elseif ($InputObject) { Write-Output $InputObject }
            }
        }
    }
}
