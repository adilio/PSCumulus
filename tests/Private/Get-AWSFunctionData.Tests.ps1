BeforeAll {
    # Stub AWS Lambda commands so Pester can create mocks when AWS.Tools.Lambda is not installed
    if (-not (Get-Command Get-LMFunctionList -ErrorAction SilentlyContinue)) {
        $script:stubCreatedGetLMFunctionList = $true
        function global:Get-LMFunctionList { param([string]$Region) }
    }

    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

AfterAll {
    if ($script:stubCreatedGetLMFunctionList) {
        Remove-Item -Path Function:global:Get-LMFunctionList -ErrorAction SilentlyContinue
    }
}

Describe 'Get-AWSFunctionData' {

    Context 'when AWS.Tools.Lambda is not installed' {
        It 'throws when Get-LMFunctionList is unavailable' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {
                    throw [System.Management.Automation.CommandNotFoundException]::new(
                        "Required command 'Get-LMFunctionList' was not found."
                    )
                }

                { Get-AWSFunctionData -Region 'us-east-1' } | Should -Throw
            }
        }
    }

    Context 'when functions are returned' {
        BeforeAll {
            $script:mockFunction = [pscustomobject]@{
                FunctionName = 'my-prod-function'
                FunctionArn  = 'arn:aws:lambda:us-east-1:123456789012:function:my-prod-function'
                Runtime      = [pscustomobject]@{ Value = 'dotnet8' }
                Handler      = 'MyAssembly::MyNamespace.MyClass::FunctionHandler'
                MemorySize   = 512
                Timeout      = 30
                LastModified = '2026-03-15T09:00:00.000+0000'
            }
        }

        It 'returns a CloudRecord for each function' {
            InModuleScope PSCumulus -Parameters @{ MockFunction = $script:mockFunction } {
                param($MockFunction)
                Mock Assert-CommandAvailable {}
                Mock Get-LMFunctionList { @($MockFunction) }

                $results = @(Get-AWSFunctionData -Region 'us-east-1')
                $results.Count | Should -Be 1
            }
        }

        It 'maps FunctionName to Name' {
            InModuleScope PSCumulus -Parameters @{ MockFunction = $script:mockFunction } {
                param($MockFunction)
                Mock Assert-CommandAvailable {}
                Mock Get-LMFunctionList { @($MockFunction) }

                $result = Get-AWSFunctionData -Region 'us-east-1'
                $result.Name | Should -Be 'my-prod-function'
            }
        }

        It 'sets Provider to AWS' {
            InModuleScope PSCumulus -Parameters @{ MockFunction = $script:mockFunction } {
                param($MockFunction)
                Mock Assert-CommandAvailable {}
                Mock Get-LMFunctionList { @($MockFunction) }

                $result = Get-AWSFunctionData -Region 'us-east-1'
                $result.Provider | Should -Be 'AWS'
            }
        }

        It 'passes Region through to the record' {
            InModuleScope PSCumulus -Parameters @{ MockFunction = $script:mockFunction } {
                param($MockFunction)
                Mock Assert-CommandAvailable {}
                Mock Get-LMFunctionList { @($MockFunction) }

                $result = Get-AWSFunctionData -Region 'eu-west-1'
                $result.Region | Should -Be 'eu-west-1'
            }
        }

        It 'sets Status to Active' {
            InModuleScope PSCumulus -Parameters @{ MockFunction = $script:mockFunction } {
                param($MockFunction)
                Mock Assert-CommandAvailable {}
                Mock Get-LMFunctionList { @($MockFunction) }

                $result = Get-AWSFunctionData -Region 'us-east-1'
                $result.Status | Should -Be 'Active'
            }
        }

        It 'maps Runtime.Value to Size' {
            InModuleScope PSCumulus -Parameters @{ MockFunction = $script:mockFunction } {
                param($MockFunction)
                Mock Assert-CommandAvailable {}
                Mock Get-LMFunctionList { @($MockFunction) }

                $result = Get-AWSFunctionData -Region 'us-east-1'
                $result.Size | Should -Be 'dotnet8'
            }
        }

        It 'parses LastModified to CreatedAt' {
            InModuleScope PSCumulus -Parameters @{ MockFunction = $script:mockFunction } {
                param($MockFunction)
                Mock Assert-CommandAvailable {}
                Mock Get-LMFunctionList { @($MockFunction) }

                $result = Get-AWSFunctionData -Region 'us-east-1'
                $result.CreatedAt | Should -BeOfType [datetime]
            }
        }

        It 'includes FunctionArn in Metadata' {
            InModuleScope PSCumulus -Parameters @{ MockFunction = $script:mockFunction } {
                param($MockFunction)
                Mock Assert-CommandAvailable {}
                Mock Get-LMFunctionList { @($MockFunction) }

                $result = Get-AWSFunctionData -Region 'us-east-1'
                $result.Metadata.FunctionArn | Should -Be 'arn:aws:lambda:us-east-1:123456789012:function:my-prod-function'
            }
        }

        It 'returns PSCumulus.CloudRecord type' {
            InModuleScope PSCumulus -Parameters @{ MockFunction = $script:mockFunction } {
                param($MockFunction)
                Mock Assert-CommandAvailable {}
                Mock Get-LMFunctionList { @($MockFunction) }

                $result = Get-AWSFunctionData -Region 'us-east-1'
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRecord'
            }
        }

        It 'returns nothing when no functions exist' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Get-LMFunctionList { @() }

                $results = @(Get-AWSFunctionData -Region 'us-east-1')
                $results.Count | Should -Be 0
            }
        }
    }
}
