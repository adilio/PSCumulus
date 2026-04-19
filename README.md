# PSCumulus

A thin, honest PowerShell abstraction for Azure, AWS, and GCP.

> Companion repo for the PowerShell + DevOps Global Summit 2026 session
> **"Cross-Cloud without Crossed Fingers: Surviving Azure, AWS, and GCP with PowerShell."**

**Talk:** `talk/presentation.md` (slides) · `talk/talk-track.md` (spoken track)
**Docs:** https://adilio.github.io/PSCumulus/

---

## What this is

`PSCumulus` is a small cross-cloud module with two ideas behind it:

1. **Build on what does not move.** PowerShell's verb-noun model is a stable cognitive anchor when you're drowning in three different cloud providers. Fluency is infrastructure.
2. **Refuse to lie about the seams.** Every unified command in PSCumulus had to pass a test: *do the underlying provider philosophies overlap enough that a normalized answer is still honest?* For compute, storage, disks, networks, functions, and tags, yes. For IAM, no. That's why there is no `Get-CloudPermission`.

The module is evidence for an argument. The argument is that a deliberately narrow abstraction, with its seams left visible, is more useful than a comprehensive one that pretends the clouds are interchangeable.

## The public surface

Eighteen commands. Verb-noun, normalized output, no provider marketing in the noun.

| Command | Intent |
|---|---|
| `Connect-Cloud` | Detect or trigger a provider-native login and store a normalized session context |
| `Disconnect-Cloud` | Clear stored session context for a selected provider |
| `Export-CloudInventory` | Export all connected inventory to JSON or CSV for audit/compliance |
| `Find-CloudResource` | Cross-kind, cross-cloud search by name (supports wildcards) |
| `Get-CloudContext` | List established provider sessions for the current shell (includes credential expiry warnings) |
| `Get-CloudDisk` | Disks / volumes (supports `-All`, `-Status`, `-Tag`, `-Name`, `-Detailed` filters) |
| `Get-CloudFunction` | Serverless functions (supports `-All`, `-Status`, `-Tag`, `-Name`, `-Detailed` filters) |
| `Get-CloudInstance` | Compute instances (supports `-All`, `-Status`, `-Tag`, `-Name`, `-Detailed` filters) |
| `Get-CloudNetwork` | Virtual networks / VPCs (supports `-All`, `-Status`, `-Tag`, `-Name`, `-Detailed` filters) |
| `Get-CloudRegion` | List supported regions for Azure, AWS, or GCP |
| `Get-CloudStorage` | Storage accounts / buckets (supports `-All`, `-Status`, `-Tag`, `-Name`, `-Detailed` filters) |
| `Get-CloudTag` | Tags / labels (supports `-All`, subscription-scoped for Azure) |
| `Resolve-CloudPath` | Parse a cloud path string into a structured CloudPath object |
| `Restart-CloudInstance` | Restart a compute instance (supports `-Wait`, `-PassThru`, `-TimeoutSeconds`) |
| `Set-CloudTag` | Set tags/labels on cloud resources (supports `-Merge`, Azure by Name/ResourceGroup or ResourceId) |
| `Start-CloudInstance` | Start a compute instance (supports `-Wait`, `-PassThru`) |
| `Stop-CloudInstance` | Stop a compute instance (supports `-Wait`, `-PassThru`) |
| `Test-CloudConnection` | Test connectivity to all connected providers (defaults to `-All`) |

Read commands return `PSCumulus.CloudRecord`-compatible records with a stable shared shape. For instance inventory, that contract is now implemented with a real base class plus vendor subclasses.

## Quick start

```powershell
Install-Module PSCumulus -Scope CurrentUser
Import-Module PSCumulus

Connect-Cloud -Provider AWS, Azure, GCP
Get-CloudContext
Get-CloudInstance -All | Where-Object { $_.Tags['environment'] -eq 'prod' }

# New features
Test-CloudConnection                    # Verify all provider connections (defaults to all)
Get-CloudInstance -All -Status Running  # Filter by status
Get-CloudInstance -Name 'web01'        # Filter by name
Get-CloudTag -All                       # Query tags across all providers (subscription-scoped for Azure)
Set-CloudTag -ResourceId '/subscriptions/.../disks/disk01' -Tags @{Backup = 'weekly'}  # Tag any Azure resource by ResourceId
Find-CloudResource -Name 'web-*' -Provider Azure, AWS    # Cross-cloud search
Export-CloudInventory -Path 'inventory.json'              # Export all inventory to JSON
Start-CloudInstance -Name 'web01' -ResourceGroup 'prod-rg' -Wait -PassThru
```

`Connect-Cloud` does more than set a flag: it verifies the required provider tools are present, detects whether an authenticated session already exists, triggers the provider-native login flow only if one is needed, and stores a normalized context for each provider. Per-provider context persists side by side so a single shell can talk to all three clouds without re-authenticating every time.

## The shared shape

Inventory commands return `PSCumulus.CloudRecord` records with a stable shape:

| Property | Description |
|---|---|
| `Name` | Resource name |
| `Provider` | `Azure`, `AWS`, or `GCP` |
| `Region` | Region or zone |
| `Status` | Normalized state (e.g. `Pending`, `Running`, `Stopped`, `Suspended`, `Terminated`) |
| `Size` | SKU, instance type, or storage class |
| `CreatedAt` | Creation time when available |
| `PrivateIpAddress` | Private IP address when available |
| `PublicIpAddress` | Public IP address when available |
| `Tags` | Normalized hashtable. AWS tags, Azure tags, and GCP labels all map here |
| `Metadata` | Provider-native details that don't normalize cleanly |

The first nine columns are what you can safely filter and group against across clouds. `Tags` stays a normal PowerShell hashtable lookup surface. `Metadata` remains available for honest provider-native long-tail detail, while commonly-needed instance fields like Azure `ResourceGroup`, AWS `InstanceId`, and GCP `Project` now live as first-class properties on vendor-specific instance subclasses.

Instance `Status` is semantic, not just title-cased provider text. For example:

- AWS `shutting-down` normalizes to `Terminating`
- Azure `VM deallocated` normalizes to `Stopped`
- GCP `TERMINATED` normalizes to `Stopped`

That last one is intentional: GCP native `TERMINATED` means the instance is stopped but still restartable, not permanently gone. The original provider value remains available in `Metadata.NativeStatus`. `Suspending` and `Suspended` are also valid normalized states, but currently come from GCP only.

When Azure does not expose a readable power state, PSCumulus now emits `Unknown` rather than the older `Ready` fallback so instance status stays aligned with the semantic status vocabulary.

## Cross-cloud pipelines

The demo beat of the Summit session is a single pipeline that queries every connected provider:

```powershell
# Untagged production assets across every cloud
Get-CloudInstance -All |
  Where-Object { -not $_.Tags['owner'] } |
  Format-Table Name, Provider, Region -AutoSize

# Fleet health by provider
Get-CloudInstance -All |
  Group-Object Provider, Status |
  Select-Object Name, Count |
  Sort-Object Count -Descending

# Stale/forgotten instances across clouds
$cutoff = (Get-Date).AddDays(-30)
Get-CloudInstance -All |
  Where-Object { $_.Status -ne 'Running' -and $_.CreatedAt -lt $cutoff }
```

`-All` iterates every provider with stored context, calls each backend in turn, and streams one pipeline of `CloudRecord` objects. Filters, grouping, and projection work exactly like they do on any other PowerShell pipeline.

## Evolution Roadmap

PSCumulus is being evolved in stages so each step ships independently, delivers value on its own, and makes the next one easier. The cmdlets remain the primary interface throughout. Any future Provider is additive, not a replacement. The core module stays PowerShell 5.1-compatible, while future navigation work is expected to target PowerShell 7+ where provider classes are a better fit.

The staged direction sharpened after the PowerShell + DevOps Global Summit 2026 talk on **Monday, April 13, 2026**, when Jeffrey Snover offered the key insight that unlocked the next move: use a base class for shared properties, subclass per vendor, and let the subclass own parsing. The future Provider remains in the plan, but it now follows that corrected object-model foundation rather than defining it. The longer-form rationale lives in the [Evolution](https://adilio.github.io/PSCumulus/concepts/evolution/) doc.

**Current status:** Stages 1, 2, and 3 are complete (v0.5.0).

1. **Stage 1: Internal Typed Contract**  
   Purpose: establish a typed internal vocabulary without changing the public cmdlet surface.  
   Additive capability: internal types, wrapper converters, semantic instance status normalization, `Metadata.NativeStatus`, and no public cmdlet or output-type break.  
   Why separate: it fixes correctness first and gives every later stage the same status/tag vocabulary.
2. **Stage 2: Vendor Subclass Records**  
   Purpose: introduce a real `CloudRecord` base class, vendor subclasses, subclass-owned factory methods, and a `Kind` field.  
   Additive capability: instance normalization now lives in one place per provider, and future path or Provider work can build on typed records instead of generic property bags.  
   Why separate: it fixes the record model directly and absorbs resource-kind awareness into the same stage.
3. **Stage 3: Cloud Path Model**  
   Purpose: define and resolve hierarchical cloud paths independently of any Provider implementation.  
   Additive capability: a structured path model and resolver that can turn paths into backend calls and stable cloud identity.  
   Why separate: path parsing and resolution are useful and testable on their own, and they are the hardest part of Provider work to get right.
4. **Stage 4: The Provider (Read-Only)**  
   Purpose: make cloud resources navigable through PowerShell drives, building on the Stage 3 path model.  
   Additive capability: read-only navigation layered over the same backend engine the cmdlets already use.  
   Why separate: the Provider is additive, belongs in a PS 7+ companion module, and the implementation path has not been chosen.
5. **Stage 5: Write Operations Through the Provider**  
   Purpose: let lifecycle actions flow through path context once navigation is stable.  
   Additive capability: path-driven start/stop style operations with `ShouldProcess` behavior preserved.  
   Why separate: write operations need careful `-WhatIf` and confirmation behavior, so the read-only Provider needs to prove itself first.
6. **Stage 6: Cross-Cloud Aggregation**  
   Purpose: expose the existing cross-cloud aggregation story through navigation as well as cmdlets.  
   Additive capability: a synthetic cross-cloud view such as `Cloud:\Instances` spanning all connected providers.  
   Why separate: it depends on the earlier path and Provider work being stable, and it carries the highest performance and UX risk.

## Per-provider usage

Connect explicitly when you want a specific region, project, or subscription:

```powershell
Connect-Cloud -Provider Azure -Tenant '00000000-…' -Subscription 'contoso-prod'
Connect-Cloud -Provider AWS   -Region 'us-east-1'
Connect-Cloud -Provider GCP   -Project 'contoso-prod'

Get-CloudInstance -Provider Azure -ResourceGroup 'prod-rg'
Get-CloudInstance -Provider AWS   -Region 'us-east-1'
Get-CloudInstance -Provider GCP   -Project 'contoso-prod'

Start-CloudInstance -Provider Azure -Name 'web-01' -ResourceGroup 'prod-rg'
Stop-CloudInstance  -Provider AWS   -InstanceId 'i-0abc123' -Region 'us-east-1'
```

The active provider is remembered after `Connect-Cloud`, so subsequent commands can often omit `-Provider` when the intent is unambiguous.

## Requirements

```powershell
# Azure
Install-Module Az -Scope CurrentUser

# AWS
Install-Module AWS.Tools.EC2, AWS.Tools.S3 -Scope CurrentUser

# GCP: no maintained PowerShell module; install the gcloud CLI
# https://cloud.google.com/sdk/docs/install
```

GCP is adapted via `gcloud … --format=json`. That's intentional: `Google.Cloud.PowerShell` is unmaintained, and the CLI is the honest adapter that matches the authentication flow most users already have.

## Where this abstraction stops

This module is intentionally not a full cloud framework. It does not cover:

- **IAM.** The underlying philosophies don't overlap. AWS thinks in policy documents, Azure in hierarchical role assignments, GCP in bindings. A unified `Get-CloudPermission` would either flatten the scoping that makes the answer useful or stuff the real answer into `Metadata` and hand you an empty wrapper. Use the provider-native commands.
- **Cost.** Each cloud's billing model is structured differently enough that a shared surface would be more misleading than helpful.
- **Provisioning.** Terraform exists and is the right tool. PSCumulus standardizes *interaction* with infrastructure; Terraform standardizes the infrastructure itself.
- **Write commands for most inventory.** The read path landed first. `Start/Stop/Restart-CloudInstance` and `Set-CloudTag` are the lifecycle commands currently in the public surface.

The rule behind every decision above: *if the normalized object would be mostly `Metadata`, the abstraction is too weak to deserve a first-class public command.*

## Testing

```powershell
Install-Module Pester -MinimumVersion 5.6.0 -Scope CurrentUser
Invoke-Pester
```

Provider SDK calls are mocked in the test suite, so cloud credentials are not required to run tests.

## Demo mode

For the Summit talk, and for anyone who wants to try PSCumulus without real cloud accounts, `scripts/demo-setup.ps1` monkeypatches the provider backends inside the module scope and seeds realistic multi-cloud data:

```powershell
Import-Module ./PSCumulus.psd1 -Force
. ./scripts/demo-setup.ps1

Get-CloudContext
Get-CloudInstance -All
Find-UntaggedInstances
Show-FleetHealth
Show-CostCenterRollup
Invoke-AllDemoQueries
Remove-DemoSetup      # unload demo functions
```

See [`docs/talk-demo.md`](docs/talk-demo.md) for the curated query list used in the talk.

## Documentation

- [Getting Started](https://adilio.github.io/PSCumulus/getting-started/)
- [Strategy](https://adilio.github.io/PSCumulus/concepts/strategy/): project rationale, normalization rules, roadmap
- [Evolution](https://adilio.github.io/PSCumulus/concepts/evolution/): detailed staged plan, design rationale, origin story, and current project status
- [Command reference](https://adilio.github.io/PSCumulus/reference/): generated from PlatyPS

```powershell
Get-Help about_PSCumulus
Get-Help Get-CloudInstance -Examples
```

## Talk materials

| File | Contents |
|---|---|
| [`talk/presentation.md`](talk/presentation.md) | 15-slide Marp deck with speaker notes |
| [`talk/talk-track.md`](talk/talk-track.md) | Continuous 25-minute spoken track |
| [`talk/summit-2026.css`](talk/summit-2026.css) | Summit 2026 Marp theme |

## License

MIT. See [`LICENSE`](LICENSE).
