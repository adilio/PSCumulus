BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Invoke-GCloudJson' {

    Context 'when gcloud is not available' {
        It 'throws when gcloud command is missing' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {
                    throw [System.Management.Automation.CommandNotFoundException]::new(
                        "Required command 'gcloud' was not found."
                    )
                }

                { Invoke-GCloudJson -Arguments @('compute', 'instances', 'list') } |
                    Should -Throw
            }
        }
    }

    Context 'when gcloud returns valid JSON' {
        It 'parses and returns the JSON output' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock gcloud { '[{"name":"vm-01","status":"RUNNING"}]' }
                $global:LASTEXITCODE = 0

                $result = Invoke-GCloudJson -Arguments @('compute', 'instances', 'list')

                $result | Should -Not -BeNullOrEmpty
                $result[0].name | Should -Be 'vm-01'
                $result[0].status | Should -Be 'RUNNING'
            }
        }

        It 'appends --format=json and --quiet to the argument list' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                $capturedArgs = @()
                Mock gcloud {
                    $script:capturedArgs = $args
                    '[]'
                }
                $global:LASTEXITCODE = 0

                Invoke-GCloudJson -Arguments @('auth', 'list')

                $script:capturedArgs | Should -Contain '--format=json'
                $script:capturedArgs | Should -Contain '--quiet'
            }
        }

        It 'returns null when gcloud output is empty' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock gcloud { '' }
                $global:LASTEXITCODE = 0

                $result = Invoke-GCloudJson -Arguments @('compute', 'instances', 'list')
                $result | Should -BeNullOrEmpty
            }
        }
    }

    Context 'when gcloud exits with non-zero' {
        It 'throws InvalidOperationException' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock gcloud { 'ERROR: (gcloud) some failure' }
                $global:LASTEXITCODE = 1

                { Invoke-GCloudJson -Arguments @('compute', 'instances', 'list') } |
                    Should -Throw

                $global:LASTEXITCODE = 0
            }
        }

        It 'includes gcloud error output in the exception message' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                Mock gcloud { 'ERROR: project not found' }
                $global:LASTEXITCODE = 1

                try {
                    Invoke-GCloudJson -Arguments @('projects', 'describe', 'missing-project')
                } catch {
                    $_.Exception.Message | Should -BeLike '*project not found*'
                } finally {
                    $global:LASTEXITCODE = 0
                }
            }
        }
    }
}
