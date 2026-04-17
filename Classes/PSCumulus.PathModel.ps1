enum CloudPathDepth {
    Root
    Scope
    Kind
    Resource
}

class CloudPath {
    [string]$Provider
    [string]$Scope
    [string]$Kind
    [string]$ResourceName
    [CloudPathDepth]$Depth

    CloudPath() {}

    [string] ToString() {
        switch ($this.Depth) {
            'Root'     { return "$($this.Provider):\" }
            'Scope'    { return "$($this.Provider):\$($this.Scope)" }
            'Kind'     { return "$($this.Provider):\$($this.Scope)\$($this.Kind)" }
            'Resource' { return "$($this.Provider):\$($this.Scope)\$($this.Kind)\$($this.ResourceName)" }
        }
        return ''
    }

    static [CloudPath] Parse([string]$path) {
        if ([string]::IsNullOrWhiteSpace($path)) {
            throw [System.ArgumentException]::new('Path cannot be null or empty.', 'path')
        }

        $result = [CloudPath]::new()

        if (-not $path.Contains(':')) {
            throw [System.ArgumentException]::new("Path must contain a provider separator ':'. Got: '$path'", 'path')
        }

        $providerPart, $remainder = $path -split ':', 2

        $providerName = $providerPart.Trim()
        $validProviders = @('Azure', 'AWS', 'GCP')

        $matchedProvider = $validProviders | Where-Object { $_ -eq $providerName } | Select-Object -First 1

        if (-not $matchedProvider) {
            $matchedProvider = $validProviders | Where-Object {
                $providerName.Length -ge 2 -and
                $_ -eq $providerName.Substring(0, 1).ToUpper() + $providerName.Substring(1).ToLower()
            } | Select-Object -First 1
        }

        if (-not $matchedProvider) {
            throw [System.ArgumentException]::new("Invalid provider '$providerName'. Must be one of: Azure, AWS, GCP.", 'path')
        }

        $result.Provider = $matchedProvider

        if ([string]::IsNullOrWhiteSpace($remainder)) {
            $result.Depth = [CloudPathDepth]::Root
            return $result
        }

        $remainder = $remainder.Trim()
        if ($remainder.StartsWith('\')) {
            $remainder = $remainder.Substring(1)
        }
        if ($remainder.EndsWith('\')) {
            $remainder = $remainder.Substring(0, $remainder.Length - 1)
        }

        if ([string]::IsNullOrWhiteSpace($remainder)) {
            $result.Depth = [CloudPathDepth]::Root
            return $result
        }

        $segments = $remainder -split '\\'

        if ($segments.Count -ge 1) {
            $result.Scope = $segments[0]
            $result.Depth = [CloudPathDepth]::Scope
        }

        if ($segments.Count -ge 2) {
            $kindSegment = $segments[1]
            $validKinds = @{
                'Instance'  = 'Instances'
                'Instances' = 'Instances'
                'Disk'      = 'Disks'
                'Disks'     = 'Disks'
                'Storage'   = 'Storage'
                'Network'   = 'Networks'
                'Networks'  = 'Networks'
                'Function'  = 'Functions'
                'Functions' = 'Functions'
                'Tag'       = 'Tags'
                'Tags'      = 'Tags'
            }

            $canonicalKind = if ($validKinds.ContainsKey($kindSegment)) {
                $validKinds[$kindSegment]
            } else {
                throw [System.ArgumentException]::new("Invalid kind '$kindSegment'. Must be one of: Instances, Disks, Storage, Networks, Functions, Tags.", 'path')
            }

            $result.Kind = $canonicalKind
            $result.Depth = [CloudPathDepth]::Kind
        }

        if ($segments.Count -ge 3) {
            $result.ResourceName = $segments[2]
            $result.Depth = [CloudPathDepth]::Resource
        }

        if ($segments.Count -gt 3) {
            throw [System.ArgumentException]::new("Path has too many segments. Maximum 3 segments after provider. Got: $($segments.Count)", 'path')
        }

        return $result
    }

    static [bool] IsValid([string]$path) {
        try {
            $null = [CloudPath]::Parse($path)
            return $true
        } catch {
            return $false
        }
    }
}

class CloudPathResolver {
    static [hashtable] Resolve([CloudPath]$cloudPath) {
        if ($null -eq $cloudPath) {
            throw [System.ArgumentNullException]::new('cloudPath')
        }

        $result = @{
            CommandName = $null
            ArgumentMap = @{}
        }

        $backendCommand = [CloudPathResolver]::GetBackendCommand($cloudPath.Provider, $cloudPath.Kind)
        $result.CommandName = $backendCommand

        $scopeArgs = [CloudPathResolver]::GetScopeArgument($cloudPath.Provider, $cloudPath.Scope)
        foreach ($key in $scopeArgs.Keys) {
            $result.ArgumentMap[$key] = $scopeArgs[$key]
        }

        if ($cloudPath.Depth -eq [CloudPathDepth]::Resource) {
            switch ($cloudPath.Provider) {
                'Azure' {
                    $result.ArgumentMap['Name'] = $cloudPath.ResourceName
                }
                'AWS' {
                    $result.ArgumentMap['Name'] = $cloudPath.ResourceName
                }
                'GCP' {
                    $result.ArgumentMap['Name'] = $cloudPath.ResourceName
                }
            }
        }

        return $result
    }

    static [string] GetBackendCommand([string]$provider, [string]$kind) {
        $kindToCommand = @{
            'Instances' = 'Instance'
            'Disks'     = 'Disk'
            'Storage'   = 'Storage'
            'Network'   = 'Network'
            'Functions' = 'Function'
            'Tags'      = 'Tag'
        }

        $commandKind = if ($kind -and $kindToCommand.ContainsKey($kind)) {
            $kindToCommand[$kind]
        } else {
            throw [System.ArgumentException]::new("Invalid or missing kind '$kind'.")
        }

        return "Get-$provider${commandKind}Data"
    }

    static [hashtable] GetScopeArgument([string]$provider, [string]$scope) {
        $result = switch ($provider) {
            'Azure' { @{ ResourceGroup = $scope } }
            'AWS'   { @{ Region = $scope } }
            'GCP'   { @{ Project = $scope } }
            default { throw [System.ArgumentException]::new("Invalid provider '$provider'.") }
        }
        return $result
    }
}
