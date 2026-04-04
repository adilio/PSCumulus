BeforeAll {
    # Stub AWS commands so Pester can create mocks when AWS.Tools is not installed
    if (-not (Get-Command Initialize-AWSDefaultConfiguration -ErrorAction SilentlyContinue)) {
        $script:stubCreatedInitialize = $true
        function global:Initialize-AWSDefaultConfiguration { }
    }

    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

AfterAll {
    if ($script:stubCreatedInitialize) {
        Remove-Item -Path Function:global:Initialize-AWSDefaultConfiguration -ErrorAction SilentlyContinue
    }
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
        It 'returns a PSCumulus.ConnectionResult object' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Initialize-AWSDefaultConfiguration {
                    [pscustomobject]@{ Name = 'default'; Region = 'us-east-1'; ProfileLocation = $null }
                }

                $result = Connect-AWSBackend
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.ConnectionResult'
            }
        }

        It 'sets Provider to AWS' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Initialize-AWSDefaultConfiguration {
                    [pscustomobject]@{ Name = 'default'; Region = 'us-east-1'; ProfileLocation = $null }
                }

                $result = Connect-AWSBackend
                $result.Provider | Should -Be 'AWS'
            }
        }

        It 'sets Connected to true' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Initialize-AWSDefaultConfiguration {
                    [pscustomobject]@{ Name = 'default'; Region = 'us-east-1'; ProfileLocation = $null }
                }

                $result = Connect-AWSBackend
                $result.Connected | Should -Be $true
            }
        }

        It 'uses the supplied Region in the result' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Initialize-AWSDefaultConfiguration {
                    [pscustomobject]@{ Name = 'default'; Region = 'us-east-1'; ProfileLocation = $null }
                }

                $result = Connect-AWSBackend -Region 'eu-west-1'
                $result.Region | Should -Be 'eu-west-1'
            }
        }

        It 'calls Initialize-AWSDefaultConfiguration with Region when provided' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Initialize-AWSDefaultConfiguration {
                    [pscustomobject]@{ Name = 'default'; Region = 'us-east-1'; ProfileLocation = $null }
                }

                $null = Connect-AWSBackend -Region 'ap-southeast-1'
                Should -Invoke Initialize-AWSDefaultConfiguration -Times 1 -ParameterFilter {
                    $Region -eq 'ap-southeast-1'
                }
            }
        }

        It 'calls Initialize-AWSDefaultConfiguration without Region when omitted' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Initialize-AWSDefaultConfiguration {
                    [pscustomobject]@{ Name = 'default'; Region = 'us-east-1'; ProfileLocation = $null }
                }

                $null = Connect-AWSBackend
                Should -Invoke Initialize-AWSDefaultConfiguration -Times 1 -ParameterFilter {
                    -not $Region
                }
            }
        }
    }
}
