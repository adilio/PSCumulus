BeforeAll {
    if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
        $script:stubCreatedGcloud = $true
        function global:gcloud {
            $global:lastGcloudArgs = @($args)

            if ($null -ne $global:gcloudStdout) {
                $global:gcloudStdout
            }

            if ($null -ne $global:gcloudExitCode) {
                $global:LASTEXITCODE = $global:gcloudExitCode
            } else {
                $global:LASTEXITCODE = 0
            }
        }
    }

    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

AfterAll {
    if ($script:stubCreatedGcloud) {
        Remove-Item -Path Function:global:gcloud -ErrorAction SilentlyContinue
    }
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
                $global:gcloudStdout = '[{"name":"vm-01","status":"RUNNING"}]'
                $global:gcloudExitCode = 0

                $result = Invoke-GCloudJson -Arguments @('compute', 'instances', 'list')

                $result | Should -Not -BeNullOrEmpty
                $result[0].name | Should -Be 'vm-01'
                $result[0].status | Should -Be 'RUNNING'
            }
        }

        It 'appends --format=json and --quiet to the argument list' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                $global:gcloudStdout = '[]'
                $global:gcloudExitCode = 0
                $global:lastGcloudArgs = @()

                Invoke-GCloudJson -Arguments @('auth', 'list')

                $global:lastGcloudArgs | Should -Contain '--format=json'
                $global:lastGcloudArgs | Should -Contain '--quiet'
            }
        }

        It 'returns null when gcloud output is empty' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                $global:gcloudStdout = ''
                $global:gcloudExitCode = 0

                $result = Invoke-GCloudJson -Arguments @('compute', 'instances', 'list')
                $result | Should -BeNullOrEmpty
            }
        }
    }

    Context 'when gcloud exits with non-zero' {
        It 'throws InvalidOperationException' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                $global:gcloudStdout = 'ERROR: (gcloud) some failure'
                $global:gcloudExitCode = 1

                { Invoke-GCloudJson -Arguments @('compute', 'instances', 'list') } |
                    Should -Throw

                $global:gcloudExitCode = 0
            }
        }

        It 'includes gcloud error output in the exception message' {
            InModuleScope PSCumulus {
                Mock Assert-CommandAvailable {}
                $global:gcloudStdout = 'ERROR: project not found'
                $global:gcloudExitCode = 1

                try {
                    Invoke-GCloudJson -Arguments @('projects', 'describe', 'missing-project')
                } catch {
                    $_.Exception.Message | Should -BeLike '*project not found*'
                } finally {
                    $global:gcloudExitCode = 0
                }
            }
        }
    }
}
