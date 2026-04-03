BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Get-CloudStorage' {

    Context 'parameter validation' {
        It 'requires -Provider' {
            { Get-CloudStorage } | Should -Throw
        }

        It 'rejects an invalid provider name' {
            { Get-CloudStorage -Provider Oracle -Region 'us-east-1' } | Should -Throw
        }
    }

    Context 'Azure routing' {
        It 'throws the not-implemented message for Azure' {
            { Get-CloudStorage -Provider Azure -ResourceGroup 'prod-rg' } |
                Should -Throw 'Get-AzureStorageData is not implemented yet.'
        }
    }

    Context 'AWS routing' {
        It 'throws the not-implemented message for AWS' {
            { Get-CloudStorage -Provider AWS -Region 'us-east-1' } |
                Should -Throw 'Get-AWSStorageData is not implemented yet.'
        }
    }

    Context 'GCP routing' {
        It 'throws the not-implemented message for GCP' {
            { Get-CloudStorage -Provider GCP -Project 'my-project' } |
                Should -Throw 'Get-GCPStorageData is not implemented yet.'
        }
    }
}
