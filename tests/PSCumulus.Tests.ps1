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

    It 'routes storage calls through provider mappings' {
        { Get-CloudStorage -Provider Azure } |
            Should -Throw 'Get-AzureStorageData is not implemented yet.'
    }

    It 'routes tag calls through provider mappings' {
        { Get-CloudTag -Provider AWS -ResourceId i-1234567890 } |
            Should -Throw 'Get-AWSTagData is not implemented yet.'
    }
}
