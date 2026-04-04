BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Assert-CloudTagArgument' {

    Context 'Azure' {
        It 'passes when ResourceId is provided' {
            InModuleScope PSCumulus {
                { Assert-CloudTagArgument -Provider Azure -ResourceId '/subscriptions/abc/virtualMachines/vm1' } |
                    Should -Not -Throw
            }
        }

        It 'throws when ResourceId is missing' {
            InModuleScope PSCumulus {
                { Assert-CloudTagArgument -Provider Azure } |
                    Should -Throw "Provider 'Azure' requires -ResourceId."
            }
        }

        It 'throws when ResourceId is empty string' {
            InModuleScope PSCumulus {
                { Assert-CloudTagArgument -Provider Azure -ResourceId '' } |
                    Should -Throw "Provider 'Azure' requires -ResourceId."
            }
        }

        It 'throws when ResourceId is whitespace' {
            InModuleScope PSCumulus {
                { Assert-CloudTagArgument -Provider Azure -ResourceId '   ' } |
                    Should -Throw "Provider 'Azure' requires -ResourceId."
            }
        }
    }

    Context 'AWS' {
        It 'passes when ResourceId is provided' {
            InModuleScope PSCumulus {
                { Assert-CloudTagArgument -Provider AWS -ResourceId 'i-0123456789abcdef0' } |
                    Should -Not -Throw
            }
        }

        It 'throws when ResourceId is missing' {
            InModuleScope PSCumulus {
                { Assert-CloudTagArgument -Provider AWS } |
                    Should -Throw "Provider 'AWS' requires -ResourceId."
            }
        }

        It 'throws when ResourceId is empty string' {
            InModuleScope PSCumulus {
                { Assert-CloudTagArgument -Provider AWS -ResourceId '' } |
                    Should -Throw "Provider 'AWS' requires -ResourceId."
            }
        }
    }

    Context 'GCP' {
        It 'passes when both Project and Resource are provided' {
            InModuleScope PSCumulus {
                { Assert-CloudTagArgument -Provider GCP -Project 'my-project' -Resource 'instances/vm-01' } |
                    Should -Not -Throw
            }
        }

        It 'throws when Project is missing' {
            InModuleScope PSCumulus {
                { Assert-CloudTagArgument -Provider GCP -Resource 'instances/vm-01' } |
                    Should -Throw "Provider 'GCP' requires both -Project and -Resource."
            }
        }

        It 'throws when Resource is missing' {
            InModuleScope PSCumulus {
                { Assert-CloudTagArgument -Provider GCP -Project 'my-project' } |
                    Should -Throw "Provider 'GCP' requires both -Project and -Resource."
            }
        }

        It 'throws when both Project and Resource are missing' {
            InModuleScope PSCumulus {
                { Assert-CloudTagArgument -Provider GCP } |
                    Should -Throw "Provider 'GCP' requires both -Project and -Resource."
            }
        }

        It 'throws when Project is empty string' {
            InModuleScope PSCumulus {
                { Assert-CloudTagArgument -Provider GCP -Project '' -Resource 'instances/vm-01' } |
                    Should -Throw "Provider 'GCP' requires both -Project and -Resource."
            }
        }
    }
}
