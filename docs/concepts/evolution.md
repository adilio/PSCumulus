# PSCumulus Evolution

PSCumulus is a cross-cloud PowerShell module for Azure, AWS, and GCP. That sentence is simple, but the work behind it is not. The goal is not to hide every provider difference, and it is not to build a universal cloud API. The goal is to give operators one fluent PowerShell shape for the questions that really can be asked across clouds.

This document explains the why behind the architecture, the staged roadmap, what landed in **v0.6.0**, what the **v0.6.1** documentation refresh clarified, and why several tempting features were deliberately held back.

## The Short Version

PSCumulus is evolving around five ideas:

- **PowerShell is the stable layer.** Azure, AWS, and GCP disagree on names, scopes, APIs, identity models, and output shapes. PowerShell gives the module a consistent verb-noun and pipeline model.
- **The cmdlets are the product.** A future Provider may be useful, but the current value lives in commands like `Get-CloudInstance`, `Find-CloudResource`, and `Export-CloudInventory`.
- **Normalize only where it stays honest.** Compute, storage, disks, networks, functions, tags, regions, and inventory can share a useful shape. IAM should not be flattened into pretend sameness.
- **Provider detail must remain reachable.** PSCumulus should make common workflows easier without hiding the fields users need for real cloud operations.
- **Correctness beats cleverness.** The project should fix broken assumptions, dead branches, stale docs, and leaky semantics before adding larger abstractions.

## Origin Story

The roadmap sharpened after the PowerShell + DevOps Global Summit 2026 talk on **Monday, April 13, 2026**.

The talk proved that PSCumulus already had a useful shape: normalized records, cross-cloud pipelines, and a deliberately narrow abstraction. It also made clear that the next architectural move could not be "build a Provider because Providers are cool." That would skip over the harder question: what exactly is the object model the Provider would navigate?

The most important guidance came from Jeffrey Snover:

> Base class that has all of the common properties, the subclass for each vendor, then base output parser on subclass.

That advice changed the roadmap. The immediate problem was not a missing filesystem-like drive. The immediate problem was making records trustworthy, typed, self-describing, and owned by the right layer.

The corrected direction became:

- keep the existing cmdlets stable
- fix correctness issues first
- make record construction explicit and typed
- make path parsing testable before attempting navigation
- add a Provider later only if it can sit on top of those foundations

## Current Status

PSCumulus is at **v0.6.1**. Stages 1, 2, 3, and the v0.6.0 hardening pass are complete. v0.6.1 does not change runtime command behavior; it updates the release notes and public documentation so the story behind the hardening pass is easier to understand.

The public surface is intentionally finite:

- 18 exported functions
- 8 aliases
- cmdlet-first usage
- PowerShell 5.1-compatible core module
- Azure, AWS, and GCP support across the same normalized record contract

The biggest change in v0.6.0 is philosophical as much as technical: the module stopped treating "more commands" as automatic progress. `Get-CloudSnapshot`, `Get-CloudImage`, and `Remove-CloudTag` were removed from the release scope because they were not complete enough to carry the same promise as the rest of the module. Half-wired features make a module feel larger and less trustworthy at the same time.

## What v0.6.1 Clarified

v0.6.1 is a documentation and release-notes refresh. It explains the current staged roadmap, names Stage 0 and Stage 3.5 explicitly, and makes the "why" behind the v0.6.0 hardening pass easier for future contributors and users to follow.

## What v0.6.0 Actually Did

v0.6.0 was not a flashy Provider release. It was a confidence release. It made the module more honest, more consistent, and easier to explain.

### New Cross-Cloud Helpers

`Find-CloudResource` answers a very common operational question:

```powershell
Find-CloudResource -Name 'payment-*'
```

The point is not to replace provider-native search. The point is to help when you know the name, or part of the name, but not the cloud or resource kind. It searches across connected providers and resource kinds using the same normalized output shape as the rest of PSCumulus.

`Export-CloudInventory` turns the current connected state into an audit-friendly artifact:

```powershell
Export-CloudInventory -Path ./inventory.json
Export-CloudInventory -Path ./inventory.csv -Format Csv
```

This is the same philosophy as `Get-CloudInstance -All`: one command can fan out across connected clouds, but the output should still be predictable PowerShell data.

`Get-CloudRegion` makes region knowledge visible and reusable:

```powershell
Get-CloudRegion
Get-CloudRegion -Provider AWS | Where-Object Name -like 'us-*'
```

The region lists also feed argument completion now, so there is one source of truth instead of duplicated static arrays.

### Usability Consistency

The read commands now line up more cleanly:

- `Get-CloudStorage`
- `Get-CloudNetwork`
- `Get-CloudDisk`
- `Get-CloudFunction`

all gained `-Name` and `-Detailed`, matching the pattern users already had on `Get-CloudInstance`.

Lifecycle commands also became more consistent:

- `Start-CloudInstance`
- `Stop-CloudInstance`
- `Restart-CloudInstance`

now share `-Wait`, `-TimeoutSeconds`, `-PollingIntervalSeconds`, and `-PassThru` behavior across direct, piped, and path-based usage. When `-Wait -PassThru` is used, the command emits the freshest polled record rather than stale input.

### Correctness Fixes

Several fixes were about removing false confidence:

- `Get-CloudContext` now reads AWS expiry from the correct variable.
- The broken GCP token-expiry branch was replaced with an active-account check because `gcloud` access tokens are opaque.
- `Get-CloudContext -Provider` now exists, because both users and internal helpers naturally want that filter.
- `Get-CloudTag -All` now uses Azure subscription-scoped resource IDs rather than subscription display names.
- `Test-CloudConnection` now defaults to all providers when called with no arguments.
- `Connect-Cloud -Region` and `Connect-Cloud -Project` are optional so native configured defaults can be used.
- `Disconnect-Cloud -AccountEmail` works for GCP, and the dead `-Account` parameter was removed.
- `Invoke-CloudProvider` now wraps backend failures with PSCumulus-specific guidance instead of surfacing raw provider SDK errors with no context.

These are not glamorous changes, but they matter. A module that claims to smooth over three clouds has to be especially careful about its own false assumptions.

### Azure Scope Was Treated More Honestly

One of the most important v0.6.0 corrections was Azure scope handling in `Find-CloudResource` and `Export-CloudInventory`.

The first implementation assumed the stored Azure context had a single `ResourceGroup` value. Real Azure session context does not work that way. A subscription can contain many resource groups, and the stored context does not name exactly one.

The fix was to enumerate visible resource groups with `Get-AzResourceGroup` and query each one. This is slower than pretending there is one resource group, but it is honest. If no resource groups are visible, the command skips Azure with verbose context instead of silently making up a scope.

This is a good example of the module's larger philosophy: normalize the shape of the answer, not the structure of the cloud.

### Deliberate Scope Cuts

Three planned commands were held back:

- `Get-CloudSnapshot`
- `Get-CloudImage`
- `Remove-CloudTag`

The snapshot and image classes that had been added early were also removed. Leaving unused record classes in the module would have implied a supported surface that did not exist.

`Set-CloudTag -Path` was also removed. Path-based tagging is a good future idea, but the old implementation depended on a nonexistent resource lookup path. It was better to remove the parameter set than ship a command shape that looked complete and failed at runtime.

## The Architecture In One Mental Model

PSCumulus has three layers today.

### 1. Public Cmdlets

These are the product surface:

```powershell
Get-CloudInstance
Get-CloudDisk
Find-CloudResource
Export-CloudInventory
Start-CloudInstance
Set-CloudTag
```

They should feel like PowerShell: discoverable parameters, pipeline-friendly records, `ShouldProcess` for writes, useful aliases, and predictable output.

### 2. Provider Backends

Private backend functions talk to Az modules, AWS.Tools modules, or `gcloud`.

Their job is not to decide what a PSCumulus record means. Their job is to retrieve provider-native data and hand it to the right typed factory method.

### 3. Typed Records And Path Model

The record layer owns normalization:

- base `CloudRecord`
- vendor and kind-specific subclasses
- status maps
- tag helpers
- `Metadata.NativeStatus`

The path layer owns path parsing:

- `CloudPath`
- `CloudPathDepth`
- `CloudPathResolver`
- `Resolve-CloudPath`

This split matters because it keeps responsibilities small. Backend functions fetch. Record classes normalize. Path classes parse and resolve identity. Public cmdlets compose those pieces into a PowerShell experience.

## Design Principles

### Cmdlet-First, Provider-Later

PSCumulus is not waiting for a Provider to become useful. The cmdlet surface is already the stable interface.

That is why a future Provider must be additive. If `Azure:\prod-rg\Instances\web-01` eventually works, it should build on the same backend engine as:

```powershell
Get-CloudInstance -Provider Azure -ResourceGroup prod-rg -Name web-01
```

The Provider should not create a second implementation of the module.

### Thin Abstraction, Not Universal Cloud

PSCumulus should normalize practical operational shapes:

- name
- provider
- kind
- region
- status
- size
- created time
- tags
- common provider identity fields

It should not pretend every cloud has the same mental model. Azure resource groups, AWS regions, and GCP projects are not interchangeable concepts. PSCumulus can route through those scopes consistently, but it should still name the native concept when the user needs it.

### Common Fields Become Properties

Earlier versions leaned heavily on `Metadata`. That preserved detail, but it made common fields feel hidden.

The newer record model promotes commonly-used fields to typed properties:

- Azure `ResourceGroup`, `VmId`, `DiskSizeGB`
- AWS `InstanceId`, `VpcId`, `VolumeId`, `BucketName`
- GCP `Project`, `Zone`, `NetworkName`

`Metadata` still matters, but it is no longer the junk drawer for fields users need constantly.

### Native Meaning Must Be Preserved

Semantic status normalization is useful only if the native state is not lost.

For example:

- AWS `shutting-down` normalizes to `Terminating`
- Azure deallocated VMs normalize to `Stopped`
- GCP `TERMINATED` normalizes to `Stopped`, because in GCP it usually means stopped but restartable

PSCumulus exposes a cross-cloud status, but preserves native status in `Metadata.NativeStatus` where that difference matters.

### Completion And Docs Are Part Of UX

The v0.6.0 pass treated argument completers, generated docs, aliases, and about-help as part of the product. That matters because a PowerShell module is discovered as much through tab completion and `Get-Help` as through README examples.

If docs list commands that do not exist, if generated reference pages contain unfinished placeholder markers, or if completers fail silently, the module feels less real. The release fixed those because confidence is a feature.

## Stage Map

The roadmap is staged so each step can ship independently and remain useful even if later stages change.

## Stage 0: Cmdlet Contract

**Status:** Complete.

This is the original useful module shape:

- connect to Azure, AWS, and GCP
- keep provider contexts side by side
- query instances, storage, disks, networks, functions, and tags
- start, stop, restart, and tag resources
- use `-All` to query every connected provider
- return normalized PowerShell objects

This stage proved the thesis: a small cmdlet vocabulary can make cross-cloud work feel less like context switching.

## Stage 1: Internal Typed Contract

**Status:** Complete.

Stage 1 gave the module a stronger internal language:

- `CloudProvider`
- semantic status enums
- status map helpers
- tag conversion helpers
- `Metadata.NativeStatus`

The reason was correctness. A prettified string is not the same as a normalized state model. This stage made state and tag handling testable without changing how users called the module.

## Stage 2: Vendor Subclass Records

**Status:** Complete.

Stage 2 implemented the Snover direction directly:

- `CloudRecord` base class
- vendor and kind-specific subclasses
- factory methods such as `AzureInstanceRecord::FromAzVM()` and `GCPDiskRecord::FromGcpDisk()`
- typed first-class provider properties
- kind-aware detailed formatting
- backend functions delegating normalization to record classes

This is the stage that made records self-describing. Users still see `PSCumulus.CloudRecord` compatibility, but the object underneath can carry provider-specific properties cleanly.

## Stage 3: Cloud Path Model

**Status:** Complete.

Stage 3 introduced:

- `CloudPath`
- `CloudPathDepth`
- `CloudPathResolver`
- `Resolve-CloudPath`
- path parameter sets for lifecycle commands

The point was to make path identity explicit before building any navigation layer. A Provider without a tested path model would be fragile.

Path-based lifecycle operations now work for:

```powershell
Start-CloudInstance   -Path 'Azure:\prod-rg\Instances\web-server-01'
Stop-CloudInstance    -Path 'AWS:\us-east-1\Instances\i-0abc123'
Restart-CloudInstance -Path 'GCP:\contoso-prod\Instances\prod-web-01'
```

For GCP, path-based lifecycle commands resolve zone information by looking up the instance, because the path uses project as its scope while the native operation needs a zone.

## Stage 3.5: v0.6.0 Hardening And Cross-Cloud Helpers

**Status:** Complete.

This was the release that made the module feel more complete without jumping to Stage 4.

It added:

- `Find-CloudResource`
- `Export-CloudInventory`
- `Get-CloudRegion`
- `Get-CloudContext -Provider`
- `-Name` and `-Detailed` consistency across inventory commands
- completed lifecycle `-Wait` / `-PassThru` behavior
- better backend error guidance
- better completers
- cleaner generated docs
- canonical alias/about-help docs

It also removed or deferred incomplete work:

- no public `Get-CloudSnapshot`
- no public `Get-CloudImage`
- no public `Remove-CloudTag`
- no broken `Set-CloudTag -Path`
- no unused snapshot/image record classes

This stage exists in the roadmap because it explains the real work between "path model exists" and "Provider exists." The module needed a trust pass before a navigation layer.

## Stage 4: Read-Only Provider

**Status:** Planned.

Stage 4 would expose the same backend engine through read-only navigation:

```powershell
Get-ChildItem Azure:\prod-rg\Instances
Get-Item AWS:\us-east-1\Instances\i-0abc123
Test-Path GCP:\contoso-prod\Storage\contoso-prod-assets
```

The important word is "same." The Provider should call into the same resolver and backend logic the cmdlets use. It should not fork the implementation.

The likely shape is a separate PowerShell 7+ companion layer. The core module still targets PowerShell 5.1, and that compatibility should not be broken just to ship navigation.

## Stage 5: Provider-Aware Writes

**Status:** Partially prepared, not implemented as Provider behavior.

Path-based lifecycle writes already exist through cmdlet parameters:

```powershell
Start-CloudInstance -Path 'Azure:\prod-rg\Instances\web-server-01' -Wait -PassThru
```

But Provider-driven writes are a separate problem. Acting on resources discovered through `Get-Item` or directory navigation needs:

- reliable identity resolution
- clear confirmation messages
- correct `-WhatIf` behavior
- predictable refresh behavior after writes

That belongs after read-only navigation is stable.

## Stage 6: Cross-Cloud Navigation And Aggregation

**Status:** Future.

PSCumulus already has cmdlet aggregation:

```powershell
Get-CloudInstance -All | Group-Object Provider, Status
Find-CloudResource -Name 'prod-*'
Export-CloudInventory -Path ./inventory.json
```

Stage 6 asks what the navigation equivalent should be. That might mean synthetic cross-cloud containers or multi-provider discovery views. It is last because fan-out behavior is powerful but easy to make surprising.

Performance, caching, progress, and skipped-provider reporting all matter more when one navigation command can touch three clouds.

## What PSCumulus Deliberately Does Not Do Yet

### It Does Not Abstract IAM

IAM is the clearest example of where honest normalization stops.

AWS policies, Azure role assignments, and GCP IAM bindings do not merely use different names for the same object. They encode different grammars. Flattening them too early would hide the differences users most need to understand.

### It Does Not Put Methods On Records

Records could eventually grow helper methods, but lifecycle operations belong naturally to cmdlets today:

```powershell
Get-CloudInstance -All | Where-Object Status -eq Stopped | Start-CloudInstance -WhatIf
```

Cmdlets give PowerShell the right places for `ShouldProcess`, pipeline binding, help, examples, and confirmation behavior.

### It Does Not Add Commands Just Because A Type Exists

The removed snapshot and image work is the best example. A record class is not a feature. A feature needs backend support, tests, docs, provider-specific edge cases, and a story for how it fits the public surface.

### It Does Not Depend On SHiPS

SHiPS can simplify Provider construction, but it is not the right dependency for PSCumulus right now. It is not active enough, it pushes the project away from its current compatibility posture, and it would make the Provider layer feel foundational instead of additive.

If a Provider lands, it should likely be raw Provider implementation in a separate PS7+ layer.

## What Success Looks Like

The roadmap is working if PSCumulus becomes:

- more correct internally
- easier to extend
- easier to explain
- richer for interactive PowerShell users
- still recognizably the same cmdlet-first module

The measure is not how many abstractions exist. The measure is whether someone operating across Azure, AWS, and GCP can ask a practical question once, receive predictable objects, and still reach provider-native detail when it matters.

## The Through-Line

The original insight still holds:

> Build on what does not move.

The clouds do not move together. PowerShell gives PSCumulus a stable language for the parts of cloud operations that can be made common.

The job of PSCumulus is not to erase provider reality. It is to make that reality easier to work with, one honest abstraction at a time.
