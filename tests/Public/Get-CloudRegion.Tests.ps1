Describe 'Get-CloudRegion' {
    BeforeAll {
        $ModulePath = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent | Join-Path -ChildPath 'PSCumulus.psd1'
        Import-Module $ModulePath -Force
    }

    Context 'Parameter validation' {
        It 'Should accept -Provider parameter' {
            { Get-CloudRegion -Provider Azure } | Should -Not -Throw
        }

        It 'Should work without -Provider parameter' {
            { Get-CloudRegion } | Should -Not -Throw
        }
    }

    Context 'Output shape' {
        It 'Should return PSCumulus.CloudRegion objects' {
            $result = Get-CloudRegion -Provider Azure | Select-Object -First 1
            $result.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRegion'
        }

        It 'Should return objects with Provider and Name properties' {
            $result = Get-CloudRegion -Provider AWS | Select-Object -First 1
            $result.Provider | Should -Not -BeNullOrEmpty
            $result.Name | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Provider filtering' {
        It 'Should return only Azure regions when Provider is Azure' {
            $result = Get-CloudRegion -Provider Azure
            $result | ForEach-Object { $_.Provider } | Should -Not -Contain 'AWS'
            $result | ForEach-Object { $_.Provider } | Should -Not -Contain 'GCP'
        }

        It 'Should return regions from all providers when Provider is omitted' {
            $result = Get-CloudRegion
            $providers = ($result | Select-Object -ExpandProperty Provider -Unique)
            $providers.Count | Should -Be 3
        }
    }

    Context 'Region counts' {
        It 'Should return expected number of Azure regions' {
            $result = Get-CloudRegion -Provider Azure
            $result.Count | Should -BeGreaterOrEqual 40
        }

        It 'Should return expected number of AWS regions' {
            $result = Get-CloudRegion -Provider AWS
            $result.Count | Should -BeGreaterOrEqual 20
        }

        It 'Should return expected number of GCP regions' {
            $result = Get-CloudRegion -Provider GCP
            $result.Count | Should -BeGreaterOrEqual 30
        }
    }
}
