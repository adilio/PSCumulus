Describe 'PSCumulus module scaffold' {
    BeforeAll {
        Import-Module (Join-Path $PSScriptRoot '..' 'PSCumulus.psd1') -Force
    }

    It 'exports the expected public functions' {
        $commands = Get-Command -Module PSCumulus | Select-Object -ExpandProperty Name

        $commands | Should -Contain 'Connect-Cloud'
        $commands | Should -Contain 'Get-CloudInstance'
        $commands | Should -Contain 'Get-CloudStorage'
        $commands | Should -Contain 'Get-CloudTag'
    }

    It 'loads the shared provider invoker helper' {
        Get-Command -Name Invoke-CloudProvider | Select-Object -ExpandProperty Name |
            Should -Be 'Invoke-CloudProvider'
    }

    It 'does not export module variables by default' {
        $manifest = Import-PowerShellDataFile (Join-Path $PSScriptRoot '..' 'PSCumulus.psd1')

        $manifest.VariablesToExport | Should -BeEmpty
    }

    It 'declares output metadata for public commands' {
        (Get-Command Connect-Cloud).OutputType.Name | Should -Contain 'pscustomobject'
        (Get-Command Get-CloudInstance).OutputType.Name | Should -Contain 'pscustomobject'
        (Get-Command Get-CloudStorage).OutputType.Name | Should -Contain 'pscustomobject'
        (Get-Command Get-CloudTag).OutputType.Name | Should -Contain 'pscustomobject'
    }

    It 'enforces provider-specific instance parameter usage' {
        { Get-CloudInstance -Provider Azure } |
            Should -Throw
    }

    It 'routes storage calls through provider mappings' {
        { Get-CloudStorage -Provider Azure -ResourceGroup prod-rg } |
            Should -Throw 'Get-AzureStorageData is not implemented yet.'
    }

    It 'routes tag calls through provider mappings' {
        { Get-CloudTag -Provider AWS -ResourceId i-1234567890 } |
            Should -Throw 'Get-AWSTagData is not implemented yet.'
    }

    It 'requires project and resource for GCP tag lookups' {
        { Get-CloudTag -Provider GCP -Project my-project } |
            Should -Throw "Provider 'GCP' requires both -Project and -Resource."
    }
}
