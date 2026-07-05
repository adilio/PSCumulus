BeforeAll {
    Import-Module (Resolve-Path (Join-Path $PSScriptRoot '..\..\PSCumulus.psd1')).Path -Force
}

Describe 'Get-GCPImageData' {

    Context 'when images are returned' {
        It 'returns a normalized image record scoped to the project' {
            InModuleScope PSCumulus {
                Mock Assert-GCloudAuthenticated { $true }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson {
                    @([pscustomobject]@{
                        name              = 'app-base-image'
                        id                = '5555555555'
                        family            = 'app-base'
                        creationTimestamp = '2026-02-10T01:00:00-07:00'
                        status            = 'READY'
                        diskSizeGb        = '20'
                        sourceDisk        = 'projects/my-project/zones/us-central1-a/disks/build-01'
                    })
                }

                $result = Get-GCPImageData -Project 'my-project'
                $result.Name | Should -Be 'app-base-image'
                $result.Provider | Should -Be 'GCP'
                $result.Kind | Should -Be 'Image'
                $result.ImageId | Should -Be '5555555555'
                $result.Publisher | Should -Be 'app-base'
                $result.Project | Should -Be 'my-project'
            }
        }

        It 'excludes standard public images and pins the project' {
            InModuleScope PSCumulus {
                Mock Assert-GCloudAuthenticated { $true }
                Mock Get-GCloudProject { 'my-project' }
                Mock Invoke-GCloudJson { @() }

                $null = Get-GCPImageData -Project 'my-project'
                Should -Invoke Invoke-GCloudJson -Times 1 -ParameterFilter {
                    ($Arguments -contains '--no-standard-images') -and ($Arguments -contains '--project=my-project')
                }
            }
        }
    }
}
