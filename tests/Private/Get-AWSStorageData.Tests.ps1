BeforeAll {
    # Stub AWS S3 commands so Pester can create mocks when AWS.Tools is not installed
    if (-not (Get-Command Get-S3Bucket -ErrorAction SilentlyContinue)) {
        $script:stubCreatedGetS3Bucket = $true
        function global:Get-S3Bucket { }
    }

    if (-not (Get-Command Get-S3BucketLocation -ErrorAction SilentlyContinue)) {
        $script:stubCreatedGetS3BucketLocation = $true
        function global:Get-S3BucketLocation { param([string]$BucketName) }
    }

    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

AfterAll {
    if ($script:stubCreatedGetS3Bucket) {
        Remove-Item -Path Function:global:Get-S3Bucket -ErrorAction SilentlyContinue
    }

    if ($script:stubCreatedGetS3BucketLocation) {
        Remove-Item -Path Function:global:Get-S3BucketLocation -ErrorAction SilentlyContinue
    }
}

Describe 'Get-AWSStorageData' {

    Context 'when AWS.Tools.S3 is not installed' {
        It 'throws when Get-S3Bucket is unavailable' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {
                    throw [System.Management.Automation.CommandNotFoundException]::new(
                        "Required command 'Get-S3Bucket' was not found."
                    )
                }

                { Get-AWSStorageData -Region 'us-east-1' } | Should -Throw
            }
        }
    }

    Context 'when buckets are returned' {
        BeforeAll {
            $script:mockBucket = [pscustomobject]@{
                BucketName   = 'my-prod-bucket'
                CreationDate = [datetime]'2026-02-01T12:00:00Z'
            }
            $script:mockLocation = [pscustomobject]@{
                Value = 'us-east-1'
            }
        }

        It 'returns a CloudRecord for each bucket' {
            InModuleScope PSCumulus -Parameters @{ MockBucket = $script:mockBucket; MockLocation = $script:mockLocation } {
                param($MockBucket, $MockLocation)
                Mock Assert-CommandAvailable {}
                Mock Get-S3Bucket { @($MockBucket) }
                Mock Get-S3BucketLocation { $MockLocation }

                $results = @(Get-AWSStorageData -Region 'us-east-1')
                $results.Count | Should -Be 1
            }
        }

        It 'maps BucketName to Name' {
            InModuleScope PSCumulus -Parameters @{ MockBucket = $script:mockBucket; MockLocation = $script:mockLocation } {
                param($MockBucket, $MockLocation)
                Mock Assert-CommandAvailable {}
                Mock Get-S3Bucket { @($MockBucket) }
                Mock Get-S3BucketLocation { $MockLocation }

                $result = Get-AWSStorageData -Region 'us-east-1'
                $result.Name | Should -Be 'my-prod-bucket'
            }
        }

        It 'sets Provider to AWS' {
            InModuleScope PSCumulus -Parameters @{ MockBucket = $script:mockBucket; MockLocation = $script:mockLocation } {
                param($MockBucket, $MockLocation)
                Mock Assert-CommandAvailable {}
                Mock Get-S3Bucket { @($MockBucket) }
                Mock Get-S3BucketLocation { $MockLocation }

                $result = Get-AWSStorageData -Region 'us-east-1'
                $result.Provider | Should -Be 'AWS'
            }
        }

        It 'sets Status to Available' {
            InModuleScope PSCumulus -Parameters @{ MockBucket = $script:mockBucket; MockLocation = $script:mockLocation } {
                param($MockBucket, $MockLocation)
                Mock Assert-CommandAvailable {}
                Mock Get-S3Bucket { @($MockBucket) }
                Mock Get-S3BucketLocation { $MockLocation }

                $result = Get-AWSStorageData -Region 'us-east-1'
                $result.Status | Should -Be 'Available'
            }
        }

        It 'maps CreationDate to CreatedAt' {
            InModuleScope PSCumulus -Parameters @{ MockBucket = $script:mockBucket; MockLocation = $script:mockLocation } {
                param($MockBucket, $MockLocation)
                Mock Assert-CommandAvailable {}
                Mock Get-S3Bucket { @($MockBucket) }
                Mock Get-S3BucketLocation { $MockLocation }

                $result = Get-AWSStorageData -Region 'us-east-1'
                $result.CreatedAt | Should -Be ([datetime]'2026-02-01T12:00:00Z')
            }
        }

        It 'uses us-east-1 when location value is empty' {
            InModuleScope PSCumulus -Parameters @{ MockBucket = $script:mockBucket } {
                param($MockBucket)
                Mock Assert-CommandAvailable {}
                Mock Get-S3Bucket { @($MockBucket) }
                Mock Get-S3BucketLocation { [pscustomobject]@{ Value = '' } }

                $result = Get-AWSStorageData
                $result.Region | Should -Be 'us-east-1'
            }
        }

        It 'filters buckets by region when Region is specified' {
            InModuleScope PSCumulus -Parameters @{ MockBucket = $script:mockBucket } {
                param($MockBucket)
                Mock Assert-CommandAvailable {}
                Mock Get-S3Bucket { @($MockBucket) }
                Mock Get-S3BucketLocation { [pscustomobject]@{ Value = 'eu-west-1' } }

                $results = @(Get-AWSStorageData -Region 'us-east-1')
                $results.Count | Should -Be 0
            }
        }

        It 'returns PSCumulus.CloudRecord type' {
            InModuleScope PSCumulus -Parameters @{ MockBucket = $script:mockBucket; MockLocation = $script:mockLocation } {
                param($MockBucket, $MockLocation)
                Mock Assert-CommandAvailable {}
                Mock Get-S3Bucket { @($MockBucket) }
                Mock Get-S3BucketLocation { $MockLocation }

                $result = Get-AWSStorageData -Region 'us-east-1'
                $result.PSObject.TypeNames | Should -Contain 'PSCumulus.CloudRecord'
            }
        }
    }
}
