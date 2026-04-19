@{
    RootModule        = 'PSCumulus.psm1'
    ModuleVersion     = '0.6.1'
    GUID              = '9e7bb15e-7fc3-47ec-a6f9-86a8b4478fd7'
    Author            = 'Adil Leghari'
    CompanyName       = 'Open Source'
    Copyright         = '(c) Adil. All rights reserved.'
    Description       = 'Cross-cloud PowerShell module for Azure, AWS, and GCP. Unified commands (Get-CloudInstance, Get-CloudStorage, etc.) return normalized objects with a consistent output shape across all three providers.'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')

    FormatsToProcess  = @('PSCumulus.Format.ps1xml')

    FunctionsToExport = @(
        'Connect-Cloud',
        'Disconnect-Cloud',
        'Export-CloudInventory',
        'Find-CloudResource',
        'Get-CloudContext',
        'Get-CloudDisk',
        'Get-CloudFunction',
        'Get-CloudInstance',
        'Get-CloudNetwork',
        'Get-CloudRegion',
        'Get-CloudStorage',
        'Get-CloudTag',
        'Restart-CloudInstance',
        'Set-CloudTag',
        'Start-CloudInstance',
        'Stop-CloudInstance',
        'Test-CloudConnection',
        'Resolve-CloudPath'
    )

    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @(
        'conc',
        'fcr',
        'gcont',
        'gcin',
        'rci',
        'sci',
        'sct',
        'tci'
    )

    PrivateData = @{
        PSData = @{
            Tags         = @('PowerShell', 'Cloud', 'Azure', 'AWS', 'GCP', 'MultiCloud', 'DevOps')
            ProjectUri   = 'https://github.com/adilio/PSCumulus'
            LicenseUri   = 'https://opensource.org/licenses/MIT'
            ReleaseNotes = @'
0.6.1
- Updated the evolution narrative to explain the v0.6.0 hardening pass, current staged roadmap, and the why behind the cmdlet-first architecture.
- Updated the strategy documentation with all 18 public commands, the Stage 0 foundation, and the Stage 3.5 hardening phase.
- Updated README roadmap details to show the current stage plan and clarify that any future Provider remains additive.
- Updated docs landing, getting-started, and about pages to include cross-cloud search, inventory export, region data, tagging, and connection testing.
- Updated reeval.md with a continuation note for the documentation narrative pass.
- No runtime command behavior changed in this release.

0.6.0
- New command: Find-CloudResource, with alias fcr, searches by name across connected providers and resource kinds.
- New command: Export-CloudInventory exports connected inventory to JSON or CSV for audits, demos, and before/after snapshots.
- New command: Get-CloudRegion lists supported Azure, AWS, and GCP regions using shared private region data.
- Added tests for Find-CloudResource, Export-CloudInventory, and Get-CloudRegion.
- Added generated command reference pages for Find-CloudResource, Export-CloudInventory, and Get-CloudRegion.
- Added Find-CloudResource, Export-CloudInventory, and Get-CloudRegion to module exports, README, docs index, module reference, MkDocs nav, and about-help.
- Fixed Get-CloudContext AWS expiry calculation by reading $awsProfile.Expiration instead of the PowerShell $profile automatic variable.
- Fixed the Get-CloudContext GCP credential-status branch by using gcloud auth list and removing broken opaque-token JWT parsing.
- Added Get-CloudContext -Provider for Azure, AWS, or GCP-specific context filtering.
- Fixed Get-CloudTag -All for Azure by querying the subscription-scoped resource ID instead of the subscription display name.
- Updated Get-CloudTag documentation to clarify -All scope across Azure, AWS, and GCP.
- Fixed Set-CloudTag dispatch by replacing the invalid Invoke-CloudProvider -ScriptBlock call with direct provider backend calls.
- Removed the broken Set-CloudTag -Path parameter set until CloudPath provider support can supply a real resource lookup.
- Added Set-CloudTag AzureById support so any Azure resource can be tagged by full -AzureResourceId.
- Kept Set-CloudTag AzureByName behavior limited to virtual machines and documented that scope.
- Loosened Set-CloudTag pipeline validation to accept PSCumulus CloudRecord objects or any object with non-null Provider and Name properties.
- Fixed Set-AzureTag merge behavior and tests so server-side Azure merge only sends new tags to Update-AzTag.
- Renamed Register-PSCumpleters.ps1 to Register-PSCumulusCompleters.ps1.
- Fixed argument completers by removing invalid Get-CloudContext -Provider calls and reading module context safely.
- Added cached Azure resource-group completion and guarded completion paths so missing provider tools do not throw.
- Moved static region data into Get-CloudRegionData so completers and Get-CloudRegion share one source.
- Test-CloudConnection now defaults to testing all providers when called with no parameters.
- Made Connect-Cloud -Region for AWS optional so backend defaults can be used.
- Made Connect-Cloud -Project for GCP optional so gcloud configured defaults can be used.
- Fixed Disconnect-Cloud -Provider GCP -AccountEmail matching.
- Added -Name and -Detailed to Get-CloudStorage, Get-CloudNetwork, Get-CloudDisk, and Get-CloudFunction for consistency with Get-CloudInstance.
- Fixed Start-CloudInstance -Wait -PassThru to emit the freshest polled record instead of stale input.
- Fixed Stop-CloudInstance -Wait -PassThru to emit the freshest polled record instead of stale input.
- Added Restart-CloudInstance -Wait, -TimeoutSeconds, -PollingIntervalSeconds, and -PassThru.
- Fixed Restart-CloudInstance -Wait -PassThru to emit the freshest running record.
- Added central Invoke-CloudProvider error wrapping with PSCumulus-specific guidance and an optional CallerPSCmdlet path.
- Kept Get-CloudSnapshot, Get-CloudImage, and Remove-CloudTag out of the 0.6.0 public surface.
- Removed stale gcsn alias for the out-of-scope Get-CloudSnapshot command.
- Confirmed the final 0.6.0 public surface is 18 exported functions and 8 aliases.
- Updated PSCumulus.Tests.ps1 to assert the 18-command public surface and current aliases.
- Fixed CI PSScriptAnalyzer warnings in Register-PSCumulusCompleters.ps1.
- Fixed CI Pester failures in Set-AzureTag, Set-CloudTag pipeline input, Restart-AWSInstance, Connect-Cloud optional scope tests, Get-CloudTag Azure -All tests, and Export-CloudInventory tests.
- Regenerated PlatyPS command reference documentation.
- Updated scripts/Update-Docs.ps1 so generated docs remove residual PlatyPS placeholders and remain stable in CI.
- Updated docs/getting-started.md with a Cross-Cloud Helpers section and the canonical alias table.
- Updated docs/reference/about-pscumulus.md and en-US/about_PSCumulus.help.txt with all 18 commands and all current aliases.
- Updated README with the 18-command public surface, Resolve-CloudPath, Find-CloudResource, Export-CloudInventory, and Get-CloudRegion.
- Updated docs/concepts/strategy.md and docs/concepts/evolution.md to v0.6.0 status.
- Added and maintained plan.md as the execution handoff and completion record for this improvement pass.
- All local tests pass: 658 passed, 6 skipped.
- Latest CI Docs and Test and Publish workflows are green before release tagging.

0.5.0
- Updated command reference documentation for Start-CloudInstance and Stop-CloudInstance to include -Wait, -PassThru, -TimeoutSeconds, and -PollingIntervalSeconds parameters
- Added command reference documentation for Restart-CloudInstance, Set-CloudTag, and Test-CloudConnection
- All 634 tests passing

0.4.0
- Added progress reporting to all Get-* cmdlets with -All parameter
- Added -All parameter to Get-CloudStorage, Get-CloudDisk, Get-CloudNetwork, Get-CloudFunction, Get-CloudTag
- Added -Status (enum) and -Tag (hashtable) filter parameters to all Get-* cmdlets
- Added Restart-CloudInstance cmdlet with alias rci
- Added -Wait, -TimeoutSeconds, -PollingIntervalSeconds to Start-CloudInstance and Stop-CloudInstance
- Added Set-CloudTag cmdlet with alias sct for cross-cloud tag management
- Added -PassThru switch to Start-CloudInstance, Stop-CloudInstance, Restart-CloudInstance
- Added Test-CloudConnection cmdlet with alias tci for connectivity testing
- Added argument completers for -Region (static lists), -ResourceGroup (from Azure), -Project (from GCP)
- Added ExpiresAt property to Get-CloudContext with credential expiry warnings
- All 634 tests passing

0.3.2
- Implemented semantic status normalization for all non-Instance resource types (Disk, Storage, Network, Function)
- Added CloudDiskStatus, CloudStorageStatus, CloudNetworkStatus, and CloudFunctionStatus enums
- Added CloudDiskStatusMap, CloudStorageStatusMap, CloudNetworkStatusMap, and CloudFunctionStatusMap helpers
- Status values are now semantic (Available, Attached, Active, etc.) while preserving native status in Metadata.NativeStatus
- All resource types now have consistent status normalization matching Stage 1 philosophy
- All 524 tests passing

0.3.1
- Enhanced detailed format views to display all vendor-specific properties for Function and Tag resource types
- Function.Detailed view now shows: ResourceGroup, FunctionName, Project, EntryPoint
- Tag.Detailed view now shows: ResourceId, Project, Resource
- Aligned Metadata dual-write consistency across all resource types - Instance records now include promoted fields in Metadata for backward compatibility
- All 524 tests passing

0.3.0
- Completed Stage 2: Vendor Subclass Records for all resource types (Instance, Disk, Storage, Network, Function, Tag)
- Implemented kind-split flat hierarchy with 15 vendor-specific record classes (AzureInstanceRecord, AWSDiskRecord, GCPStorageRecord, etc.)
- Each resource kind now has typed first-class provider properties accessible via tab-completion (e.g., $vm.ResourceGroup, $disk.VolumeType, $bucket.BucketName)
- All Get-*Data backends now delegate to subclass factory methods for normalization
- Start/Stop lifecycle commands now return typed subclass records
- Removed ConvertTo-CloudRecord and wrapper converter functions in favor of typed record classes
- Added kind-level detailed format views for better display experience
- Promoted provider identity fields from Metadata to typed properties with dual-write for backward compatibility
- UX improvements: Where-Object shorthand filtering, Get-Member discoverability, Select-Object support

0.2.0
- Marked a major architectural step in PSCumulus: the module now follows the corrected Snover direction of a shared base record with vendor subclasses, and normalization owned by subclass factory methods
- Implemented Stage 2 for instance inventory: Get-CloudInstance now returns class-based Azure, AWS, and GCP instance records while preserving the PSCumulus.CloudRecord contract for formatting and pipeline use
- Promoted commonly-needed provider identity fields to first-class properties on instance records, including Azure ResourceGroup and VmId, AWS InstanceId, VpcId, and SubnetId, and GCP Project and Zone
- Retired the old Azure Ready fallback for missing power state and now emit Unknown so public instance status stays aligned with the semantic status model introduced in Stage 1
- Updated the roadmap, strategy, and about/help documentation so the module page and repo docs clearly describe the new object-model direction and the current stage of the evolution plan

0.1.2
- Added scoped Disconnect-Cloud for Azure, AWS, and GCP
- Get-CloudInstance now supports name filtering, detailed output, and richer instance metadata
- Cloud context now reads Current vs Connected, with friendlier Azure VM state handling
- Azure tenant/subscription support, AWS instance parsing, and CI docs/test stability were improved

0.1.1
- Added demo setup and talk materials with simulated multi-cloud data and richer examples
- Added CloudRecord Tags, Connect-Cloud array-provider support, and Get-CloudInstance -All
- Prepared the manifest and docs for PSGallery install flow
- Refined the normalization philosophy and docs to match the cross-cloud design

0.1.0
- Initial release with Connect-Cloud, Get-CloudContext, inventory commands, lifecycle commands, and normalized cross-cloud output
'@
        }
    }
}
