BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Assert-CommandAvailable' {

    It 'does not throw when the command exists' {
        InModuleScope PSCumulus {
            # Get-Item is guaranteed to exist in any PowerShell session
            { Assert-CommandAvailable -CommandName 'Get-Item' -InstallHint 'unused hint' } |
                Should -Not -Throw
        }
    }

    It 'throws CommandNotFoundException when the command is missing' {
        InModuleScope PSCumulus {
            { Assert-CommandAvailable -CommandName 'Invoke-NonExistentCommand-XYZ' -InstallHint 'Install Foo.' } |
                Should -Throw
        }
    }

    It 'includes the install hint in the error message' {
        InModuleScope PSCumulus {
            $hint = 'Install the Foo module with: Install-Module Foo'
            try {
                Assert-CommandAvailable -CommandName 'Invoke-NonExistentCommand-XYZ' -InstallHint $hint
            } catch {
                $_.Exception.Message | Should -BeLike "*$hint*"
            }
        }
    }

    It 'includes the command name in the error message' {
        InModuleScope PSCumulus {
            try {
                Assert-CommandAvailable -CommandName 'Invoke-Missing-ABC' -InstallHint 'hint'
            } catch {
                $_.Exception.Message | Should -BeLike "*Invoke-Missing-ABC*"
            }
        }
    }
}
