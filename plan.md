# PSCumulus v0.4.0 Implementation Plan

## Changes Completed

### Change 1: Progress reporting on -All queries ✅
- Added `Write-Progress` to all `Get-*` cmdlets with `-All` parameter
- Implemented in: Get-CloudInstance, Get-CloudStorage, Get-CloudDisk, Get-CloudNetwork, Get-CloudFunction, Get-CloudTag

### Change 2: Add -All to all remaining Get-* cmdlets ✅
- Added `-All` parameter to: Get-CloudStorage, Get-CloudDisk, Get-CloudNetwork, Get-CloudFunction, Get-CloudTag
- Iterates through all connected providers with progress reporting

### Change 3: Add -Status and -Tag filter parameters ✅
- Added `-Status` (enum type) and `-Tag` (hashtable) filters to all Get-* cmdlets
- Filter types:
  - Get-CloudInstance: CloudInstanceStatus enum
  - Get-CloudStorage: CloudStorageStatus enum
  - Get-CloudDisk: CloudDiskStatus enum
  - Get-CloudNetwork: CloudNetworkStatus enum
  - Get-CloudFunction: CloudFunctionStatus enum

### Change 4: Add Restart-CloudInstance cmdlet ✅
- Created Public/Restart-CloudInstance.ps1
- Private backends: Restart-AzureInstance, Restart-AWSInstance, Restart-GCPInstance
- Alias: `rci`
- Supports ShouldProcess, Path parameter, pipeline input

### Change 5: Add -Wait switch to lifecycle cmdlets ✅
- Added `-Wait`, `-TimeoutSeconds` (default 300), `-PollingIntervalSeconds` (default 5) to:
  - Start-CloudInstance
  - Stop-CloudInstance
- Polls Get-*Data backends until target status reached
- Shows progress during wait

### Change 6: Add Set-CloudTag cmdlet ✅
- Created Public/Set-CloudTag.ps1
- Private backends: Set-AzureTag, Set-AWSTag, Set-GCPTag
- Alias: `sct`
- Supports `-Merge` to combine with existing tags
- Parameter sets: Azure, AWS, GCP, Piped, Path

### Change 7: Add -PassThru to lifecycle cmdlets ✅
- Added `-PassThru` to: Start-CloudInstance, Stop-CloudInstance, Restart-CloudInstance
- Returns CloudRecord object after operation

### Change 8: Add Test-CloudConnection cmdlet ✅
- Created Public/Test-CloudConnection.ps1
- Private backends: Test-AzureConnection, Test-AWSConnection, Test-GCPConnection
- Alias: `tci`
- Returns PSCumulus.ConnectionTestResult objects
- Added Format.ps1xml view for results

### Change 9: Add argument completers ✅
- Created Private/Register-PSCumpleters.ps1
- Completers for:
  - `-Region`: Static lists for Azure, AWS, GCP regions
  - `-ResourceGroup`: From Azure context
  - `-Project`: From GCP context
- Dot-sourced in PSCumulus.psm1

### Change 10: Credential expiry warning ✅
- Added `ExpiresAt` property to Get-CloudContext
- Writes `Write-Warning` when credentials expire within 5 minutes
- Updated Format.ps1xml to show ExpiresAt in context table
- Checks Azure token expiry, AWS temp credential expiry, GCP token expiry

## Documentation Updates

### README.md ✅
- Updated command table (14 commands)
- Added new features to Quick Start section
- Updated "Where this abstraction stops" section

### Release Notes (PSCumulus.psd1) ✅
- Updated release notes for v0.4.0 with all features

## Testing Status

### Test Files Created ✅
- Public/Set-CloudTag.Tests.ps1
- Private/Set-AzureTag.Tests.ps1
- Private/Set-AWSTag.Tests.ps1
- Private/Set-GCPTag.Tests.ps1

### Test Fixes Completed ✅
- Fixed module path resolution in test files (moved to tests/ directory)
- Fixed parameter validation tests to use InModuleScope for private functions
- Fixed Set-GCPTag.ps1 syntax error (line 45 string concatenation)
- Fixed Azure tag tests with Skip flags when Az module not available
- Fixed AWS tag tests with Skip flags when AWS module not available
- Fixed Public/Set-CloudTag.Tests.ps1 module path and InModuleScope issues
- Fixed pipeline input test to use script-level mock record

### Current Test Results
- Tests Passed: 634
- Tests Failed: 0
- Tests Skipped: 7 (Azure/AWS tests when modules unavailable + Pending tests)

## Files Modified

### Public cmdlets
- Get-CloudInstance.ps1 (progress, filters)
- Get-CloudStorage.ps1 (-All, progress, filters)
- Get-CloudDisk.ps1 (-All, progress, filters)
- Get-CloudNetwork.ps1 (-All, progress, filters)
- Get-CloudFunction.ps1 (-All, progress, filters)
- Get-CloudTag.ps1 (-All, progress)
- Get-CloudContext.ps1 (ExpiresAt, warnings)
- Start-CloudInstance.ps1 (-Wait, -PassThru)
- Stop-CloudInstance.ps1 (-Wait, -PassThru)

### New Public cmdlets
- Restart-CloudInstance.ps1
- Set-CloudTag.ps1
- Test-CloudConnection.ps1

### New Private functions
- Restart-AzureInstance.ps1
- Restart-AWSInstance.ps1
- Restart-GCPInstance.ps1
- Set-AzureTag.ps1
- Set-AWSTag.ps1
- Set-GCPTag.ps1
- Test-AzureConnection.ps1
- Test-AWSConnection.ps1
- Test-GCPConnection.ps1
- Register-PSCumpleters.ps1

### Module files
- PSCumulus.psd1 (updated exports, version 0.4.0)
- PSCumulus.psm1 (added aliases, dot-sourced completers)
- PSCumulus.Format.ps1xml (new views, updated context view)

## Remaining Work

1. ✅ Fix remaining test failures (fixed all - 634 passing)
2. ✅ Update release notes in PSCumulus.psd1
3. ✅ Verify documentation is complete
4. Git commit with proper message (no co-author)
5. Push to remote

## Git Identity
- User: Adil Leghari <adilio@gmail.com>
- No co-author attribution on commits
