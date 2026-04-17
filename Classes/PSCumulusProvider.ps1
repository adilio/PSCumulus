using module SHiPS

class CloudProviderRoot : SHiPSDirectory {
    [string]$ProviderName

    CloudProviderRoot([string]$name) : base($name) {
        $this.ProviderName = $name
    }

    [object[]] GetChildItem() {
        $results = [System.Collections.Generic.List[object]]::new()

        switch ($this.ProviderName) {
            'Azure' {
                $scopes = Get-AzureScopes -ErrorAction SilentlyContinue
                if ($scopes) {
                    foreach ($scope in $scopes) {
                        $results.Add([CloudScopeNode]::new($scope, $this.ProviderName, $scope))
                    }
                }
            }
            'AWS' {
                $scopes = Get-AWSScopes -ErrorAction SilentlyContinue
                if ($scopes) {
                    foreach ($scope in $scopes) {
                        $results.Add([CloudScopeNode]::new($scope, $this.ProviderName, $scope))
                    }
                }
            }
            'GCP' {
                $scopes = Get-GCPScopes -ErrorAction SilentlyContinue
                if ($scopes) {
                    foreach ($scope in $scopes) {
                        $results.Add([CloudScopeNode]::new($scope, $this.ProviderName, $scope))
                    }
                }
            }
        }

        return $results.ToArray()
    }
}

class CloudScopeNode : SHiPSDirectory {
    [string]$ProviderName
    [string]$ScopeName

    CloudScopeNode([string]$name, [string]$providerName, [string]$scopeName) : base($name) {
        $this.ProviderName = $providerName
        $this.ScopeName = $scopeName
    }

    [object[]] GetChildItem() {
        $kinds = @('Instances', 'Disks', 'Storage', 'Networks', 'Functions', 'Tags')
        $results = [System.Collections.Generic.List[object]]::new()

        foreach ($kind in $kinds) {
            $results.Add([CloudKindNode]::new($kind, $this.ProviderName, $this.ScopeName))
        }

        return $results.ToArray()
    }
}

class CloudKindNode : SHiPSDirectory {
    [string]$ProviderName
    [string]$ScopeName
    [string]$KindName

    CloudKindNode([string]$name, [string]$providerName, [string]$scopeName) : base($name) {
        $this.ProviderName = $providerName
        $this.ScopeName = $scopeName
        $this.KindName = $name
    }

    [object[]] GetChildItem() {
        $path = [CloudPath]::new()
        $path.Provider = $this.ProviderName
        $path.Scope = $this.ScopeName
        $path.Kind = $this.KindName
        $path.Depth = [CloudPathDepth]::Kind

        $resolved = [CloudPathResolver]::Resolve($path)

        $records = & $resolved.CommandName @($resolved.ArgumentMap)

        $results = [System.Collections.Generic.List[object]]::new()
        foreach ($record in $records) {
            $results.Add([CloudResourceLeaf]::new($record.Name, $record))
        }

        return $results.ToArray()
    }
}

class CloudResourceLeaf : SHiPSLeaf {
    [object]$Record

    CloudResourceLeaf([string]$name, [object]$record) : base($name) {
        $this.Record = $record
    }
}
