BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Connect-AWSBackend' {

    Context 'when AWS.Tools.Common is not installed' {
        It 'throws when Initialize-AWSDefaultConfiguration is unavailable' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {
                    throw [System.Management.Automation.CommandNotFoundException]::new(
                        "Required command 'Initialize-AWSDefaultConfiguration' was not found."
                    )
                }

                { Connect-AWSBackend } | Should -Throw
            }
        }
    }

    Context 'successful connection' {
        BeforeEach {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Initialize-AWSDefaultConfiguration {
                    [pscustomobject]@{
                        Name            = 'default'
                        Region          = 'us-east-1'
                        ProfileLocation = $null
                    }
                }
            }
        }

        It 'returns a PSCumulus.ConnectionResult object' {
            $result = InModuleScope PSCumulus { Connect-AWSBackend }
            $result.PSObject.TypeNames | Should -Contain 'PSCumulus.ConnectionResult'
        }

        It 'sets Provider to AWS' {
            $result = InModuleScope PSCumulus { Connect-AWSBackend }
            $result.Provider | Should -Be 'AWS'
        }

        It 'sets Connected to true' {
            $result = InModuleScope PSCumulus { Connect-AWSBackend }
            $result.Connected | Should -Be $true
        }

        It 'uses the supplied Region in the result' {
            $result = InModuleScope PSCumulus { Connect-AWSBackend -Region 'eu-west-1' }
            $result.Region | Should -Be 'eu-west-1'
        }

        It 'calls Initialize-AWSDefaultConfiguration with Region when provided' {
            $null = InModuleScope PSCumulus { Connect-AWSBackend -Region 'ap-southeast-1' }

            Should -Invoke Initialize-AWSDefaultConfiguration -ModuleName PSCumulus -Times 1 -ParameterFilter {
                $Region -eq 'ap-southeast-1'
            }
        }

        It 'calls Initialize-AWSDefaultConfiguration without Region when omitted' {
            $null = InModuleScope PSCumulus { Connect-AWSBackend }

            Should -Invoke Initialize-AWSDefaultConfiguration -ModuleName PSCumulus -Times 1 -ParameterFilter {
                -not $Region
            }
        }
    }
}
