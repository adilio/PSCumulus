enum CloudProvider {
    Azure
    AWS
    GCP
}

enum CloudInstanceStatus {
    Unknown
    Pending
    Starting
    Running
    Stopping
    Stopped
    Suspending
    Suspended
    Terminating
    Terminated
}

class CloudInstanceStatusMap {
    static [object] FromAws([string]$stateName) {
        if ([string]::IsNullOrWhiteSpace($stateName)) {
            return $null
        }

        switch ($stateName.Trim().ToLowerInvariant()) {
            'pending'       { return [CloudInstanceStatus]::Pending }
            'running'       { return [CloudInstanceStatus]::Running }
            'stopping'      { return [CloudInstanceStatus]::Stopping }
            'stopped'       { return [CloudInstanceStatus]::Stopped }
            'shutting-down' { return [CloudInstanceStatus]::Terminating }
            'terminated'    { return [CloudInstanceStatus]::Terminated }
            default         { return [CloudInstanceStatus]::Unknown }
        }

        return [CloudInstanceStatus]::Unknown
    }

    static [object] FromAzure([string]$powerState) {
        if ([string]::IsNullOrWhiteSpace($powerState)) {
            return $null
        }

        $normalized = $powerState.Trim()
        if ($normalized.StartsWith('VM ', [System.StringComparison]::OrdinalIgnoreCase)) {
            $normalized = $normalized.Substring(3)
        }

        switch ($normalized.ToLowerInvariant()) {
            'starting'     { return [CloudInstanceStatus]::Starting }
            'running'      { return [CloudInstanceStatus]::Running }
            'stopping'     { return [CloudInstanceStatus]::Stopping }
            'deallocating' { return [CloudInstanceStatus]::Stopping }
            'stopped'      { return [CloudInstanceStatus]::Stopped }
            'deallocated'  { return [CloudInstanceStatus]::Stopped }
            default        { return [CloudInstanceStatus]::Unknown }
        }

        return [CloudInstanceStatus]::Unknown
    }

    static [object] FromGcp([string]$status) {
        if ([string]::IsNullOrWhiteSpace($status)) {
            return $null
        }

        switch ($status.Trim().ToUpperInvariant()) {
            'PROVISIONING' { return [CloudInstanceStatus]::Pending }
            'STAGING'      { return [CloudInstanceStatus]::Pending }
            'RUNNING'      { return [CloudInstanceStatus]::Running }
            'STOPPING'     { return [CloudInstanceStatus]::Stopping }
            'SUSPENDING'   { return [CloudInstanceStatus]::Suspending }
            'SUSPENDED'    { return [CloudInstanceStatus]::Suspended }
            'TERMINATED'   { return [CloudInstanceStatus]::Stopped }
            default        { return [CloudInstanceStatus]::Unknown }
        }

        return [CloudInstanceStatus]::Unknown
    }
}

class CloudTagHelper {
    static [hashtable] CopyHashtable([hashtable]$tags) {
        $result = @{}

        if ($null -eq $tags) {
            return $result
        }

        foreach ($entry in $tags.GetEnumerator()) {
            $result[$entry.Key] = $entry.Value
        }

        return $result
    }

    static [hashtable] FromAwsTags([object[]]$tagArray) {
        $result = @{}

        foreach ($tag in @($tagArray)) {
            if ($null -eq $tag) {
                continue
            }

            $key = $tag.Key
            if ([string]::IsNullOrWhiteSpace($key)) {
                continue
            }

            $result[$key] = $tag.Value
        }

        return $result
    }

    static [hashtable] FromAzureTags([hashtable]$tags) {
        return [CloudTagHelper]::CopyHashtable($tags)
    }

    static [hashtable] FromGcpLabels([object]$labels) {
        $result = @{}

        if ($null -eq $labels) {
            return $result
        }

        if ($labels -is [hashtable]) {
            return [CloudTagHelper]::CopyHashtable($labels)
        }

        foreach ($property in $labels.PSObject.Properties) {
            $result[$property.Name] = $property.Value
        }

        return $result
    }

    static [object[]] ToAwsTags([hashtable]$tags) {
        $result = New-Object System.Collections.Generic.List[object]

        foreach ($entry in ([CloudTagHelper]::CopyHashtable($tags)).GetEnumerator()) {
            $result.Add([pscustomobject]@{
                Key   = $entry.Key
                Value = $entry.Value
            })
        }

        return $result.ToArray()
    }

    static [hashtable] ToAzureTags([hashtable]$tags) {
        return [CloudTagHelper]::CopyHashtable($tags)
    }

    static [hashtable] ToGcpLabels([hashtable]$tags) {
        $result = @{}

        foreach ($entry in ([CloudTagHelper]::CopyHashtable($tags)).GetEnumerator()) {
            $key = [string]$entry.Key
            if ($key -cnotmatch '^[a-z][a-z0-9_-]{0,62}$') {
                throw [System.ArgumentException]::new(
                    "GCP label key '$key' is invalid. Label keys must match ^[a-z][a-z0-9_-]{0,62}$."
                )
            }

            $result[$key] = $entry.Value
        }

        return $result
    }
}
