BeforeAll {
    # Stub AWS EC2 tag command so Pester can create mocks when AWS.Tools is not installed
    if (-not (Get-Command Get-EC2Tag -ErrorAction SilentlyContinue)) {
        $script:stubCreatedGetEC2Tag = $true
        function global:Get-EC2Tag { param([hashtable]$Filter) }
    }

    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

AfterAll {
    if ($script:stubCreatedGetEC2Tag) {
        Remove-Item -Path Function:global:Get-EC2Tag -ErrorAction SilentlyContinue
    }
}

Describe 'Get-AWSTagData' {

    Context 'when AWS.Tools.EC2 is not installed' {
        It 'throws when Get-EC2Tag is unavailable' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {
                    throw [System.Management.Automation.CommandNotFoundException]::new(
                        "Required command 'Get-EC2Tag' was not found."
                    )
                }

                { Get-AWSTagData -ResourceId 'i-0abc123' } | Should -Throw
            }
        }
    }

    Context 'when tags are returned' {
        BeforeAll {
            $script:mockTags = @(
                [pscustomobject]@{ Key = 'Environment'; Value = 'production' }
                [pscustomobject]@{ Key = 'Team'; Value = 'platform' }
            )
        }

        It 'returns a CloudRecord' {
            InModuleScope PSCumulus -Parameters @{ MockTags = $script:mockTags } {
                param($MockTags)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Tag { $MockTags }

                $result = Get-AWSTagData -ResourceId 'i-0abc123'
                $result | Should -Not -BeNullOrEmpty
            }
        }

        It 'uses ResourceId as Name' {
            InModuleScope PSCumulus -Parameters @{ MockTags = $script:mockTags } {
                param($MockTags)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Tag { $MockTags }

                $result = Get-AWSTagData -ResourceId 'i-0abc123'
                $result.Name | Should -Be 'i-0abc123'
            }
        }

        It 'sets Provider to AWS' {
            InModuleScope PSCumulus -Parameters @{ MockTags = $script:mockTags } {
                param($MockTags)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Tag { $MockTags }

                $result = Get-AWSTagData -ResourceId 'i-0abc123'
                $result.Provider | Should -Be 'AWS'
            }
        }

        It 'includes ResourceId in Metadata' {
            InModuleScope PSCumulus -Parameters @{ MockTags = $script:mockTags } {
                param($MockTags)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Tag { $MockTags }

                $result = Get-AWSTagData -ResourceId 'i-0abc123'
                $result.Metadata.ResourceId | Should -Be 'i-0abc123'
            }
        }

        It 'builds Tags hashtable from EC2 tag objects' {
            InModuleScope PSCumulus -Parameters @{ MockTags = $script:mockTags } {
                param($MockTags)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Tag { $MockTags }

                $result = Get-AWSTagData -ResourceId 'i-0abc123'
                $result.Metadata.Tags['Environment'] | Should -Be 'production'
                $result.Metadata.Tags['Team'] | Should -Be 'platform'
            }
        }

        It 'returns PSCumulus.CloudRecord type' {
            InModuleScope PSCumulus -Parameters @{ MockTags = $script:mockTags } {
                param($MockTags)
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Tag { $MockTags }

                $result = Get-AWSTagData -ResourceId 'i-0abc123'
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRecord'
            }
        }

        It 'returns empty Tags hashtable when resource has no tags' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock Get-EC2Tag { @() }

                $result = Get-AWSTagData -ResourceId 'i-0abc123'
                $result.Metadata.Tags.Count | Should -Be 0
            }
        }
    }
}
