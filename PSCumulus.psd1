@{
    RootModule        = 'PSCumulus.psm1'
    ModuleVersion     = '0.6.0'
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
        'Get-CloudContext',
        'Get-CloudInstance',
        'Get-CloudStorage',
        'Get-CloudTag',
        'Get-CloudNetwork',
        'Get-CloudDisk',
        'Get-CloudFunction',
        'Start-CloudInstance',
        'Stop-CloudInstance',
        'Resolve-CloudPath',
        'New-CloudDrive',
        'Remove-CloudDrive',
        'New-CloudAggregationDrive',
        'Remove-CloudAggregationDrive'
    )

    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @(
        'conc',
        'gcont',
        'gcin',
        'sci',
        'tci',
        'ncd',
        'rcd',
        'ncad',
        'rcad'
    )

    PrivateData = @{
        PSData = @{
            Tags         = @('PowerShell', 'Cloud', 'Azure', 'AWS', 'GCP', 'MultiCloud', 'DevOps')
            ProjectUri   = 'https://github.com/adilio/PSCumulus'
            LicenseUri   = 'https://opensource.org/licenses/MIT'
            ReleaseNotes = @'
0.6.0
- Completed Stage 6: Cross-Cloud Aggregation Drive
- Added CloudAggregationRoot SHiPS class for cross-cloud browsing
- Added New-CloudAggregationDrive and Remove-CloudAggregationDrive cmdlets
- Added ncad and rcad aliases for aggregation drive management
- Cloud:\ drive shows all connected providers as top-level containers
- Auto-creates provider drives on Connect-Cloud when SHiPS available (PS 7+)
- Auto-removes provider drives on Disconnect-Cloud
- Enables navigation: dir Cloud:\Azure\prod-rg\Instances, dir Cloud:\AWS\us-east-1\Disks
- Bump version to 0.6.0

0.5.1
- Completed Stage 5: Path-Aware Lifecycle Operations
- Added Path parameter set to Start-CloudInstance and Stop-CloudInstance
- Supports starting/stopping instances using cloud paths: Start-CloudInstance -Path 'Azure:\prod-rg\Instances\web-server-01'
- Path parameter validates kind (must be Instances) and depth (must be Resource)
- GCP paths automatically resolve Zone via instance lookup
- Maintains backward compatibility with existing parameter sets

0.5.0
- Completed Stage 4: Read-only SHiPS Provider with per-provider drives
- Added CloudProviderRoot, CloudScopeNode, CloudKindNode, and CloudResourceLeaf SHiPS classes
- Added Get-AzureScopes, Get-AWSScopes, Get-GCPScopes private functions for scope enumeration
- Added New-CloudDrive and Remove-CloudDrive cmdlets for drive management
- Added ncd and rcd aliases for drive management
- SHiPS provider conditionally loads in PS 7+ when SHiPS module is available
- Supports navigation: dir Azure:\prod-rg\Instances, Get-Item AWS:\us-east-1\Disks\vol-123
- Module loader updated to exclude PSCumulusProvider.ps1 from standard loop and load conditionally

0.4.0
- Completed Stage 3: Cloud Path Model
- Added CloudPathDepth enum (Root, Scope, Kind, Resource)
- Added CloudPath class for structured path parsing and validation
- Added CloudPathResolver class for mapping paths to backend commands
- Path format: {Provider}:\{Scope}\{Kind}\{ResourceName} (e.g., Azure:\prod-rg\Instances\web-server-01)
- Added Resolve-CloudPath cmdlet for parsing path strings
- Supports case-insensitive provider names and singular/plural kind normalization
- All path model components fully tested with Pester

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
