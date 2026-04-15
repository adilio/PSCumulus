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
2. **Refuse to lie about the seams.** Every unified command in PSCumulus had to pass a test: *do the underlying provider philosophies overlap enough that a normalized answer is still honest?* For compute, storage, disks, networks, functions, and tags — yes. For IAM — no. That's why there is no `Get-CloudPermission`.

The module is evidence for an argument. The argument is that a deliberately narrow abstraction, with its seams left visible, is more useful than a comprehensive one that pretends the clouds are interchangeable.

## The public surface

Eleven commands. Verb-noun, normalized output, no provider marketing in the noun.

| Command | Intent |
|---|---|
| `Connect-Cloud` | Detect or trigger a provider-native login and store a normalized session context |
| `Disconnect-Cloud` | Clear stored session context for a selected provider |
| `Get-CloudContext` | List established provider sessions for the current shell |
| `Get-CloudInstance` | Compute instances (supports `-All` across every connected provider) |
| `Get-CloudStorage` | Storage accounts / buckets |
| `Get-CloudDisk` | Disks / volumes |
| `Get-CloudNetwork` | Virtual networks / VPCs |
| `Get-CloudFunction` | Serverless functions |
| `Get-CloudTag` | Tags / labels |
| `Start-CloudInstance` | Start a compute instance |
| `Stop-CloudInstance` | Stop a compute instance |

Read commands return a single normalized record type, `PSCumulus.CloudRecord`.

## Quick start

```powershell
Install-Module PSCumulus -Scope CurrentUser
Import-Module PSCumulus

Connect-Cloud -Provider AWS, Azure, GCP
Get-CloudContext
Get-CloudInstance -All | Where-Object { $_.Tags['environment'] -eq 'prod' }
```

`Connect-Cloud` does more than set a flag: it verifies the required provider tools are present, detects whether an authenticated session already exists, triggers the provider-native login flow only if one is needed, and stores a normalized context for each provider. Per-provider context persists side by side so a single shell can talk to all three clouds without re-authenticating every time.

## The shared shape

Inventory commands return `PSCumulus.CloudRecord` objects with a stable shape:

| Property | Description |
|---|---|
| `Name` | Resource name |
| `Provider` | `Azure`, `AWS`, or `GCP` |
| `Region` | Region or zone |
| `Status` | Normalized state (e.g. `Running`, `Stopped`) |
| `Size` | SKU, instance type, or storage class |
| `CreatedAt` | Creation time when available |
| `Tags` | Normalized hashtable — AWS tags, Azure tags, GCP labels all map here |
| `Metadata` | Provider-native details that don't normalize cleanly |

The first seven columns are what you can safely filter and group against across clouds. `Metadata` is where honest provider-native detail (Azure resource groups, AWS VPC IDs, GCP zones) lives without pretending to normalize.

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

# GCP — no maintained PowerShell module; install the gcloud CLI
# https://cloud.google.com/sdk/docs/install
```

GCP is adapted via `gcloud … --format=json`. That's intentional: `Google.Cloud.PowerShell` is unmaintained, and the CLI is the honest adapter that matches the authentication flow most users already have.

## Where this abstraction stops

This module is intentionally not a full cloud framework. It does not cover:

- **IAM.** The underlying philosophies don't overlap. AWS thinks in policy documents, Azure in hierarchical role assignments, GCP in bindings. A unified `Get-CloudPermission` would either flatten the scoping that makes the answer useful or stuff the real answer into `Metadata` and hand you an empty wrapper. Use the provider-native commands.
- **Cost.** Each cloud's billing model is structured differently enough that a shared surface would be more misleading than helpful.
- **Provisioning.** Terraform exists and is the right tool. PSCumulus standardizes *interaction* with infrastructure; Terraform standardizes the infrastructure itself.
- **Write commands for most inventory.** The read path landed first. `Start/Stop-CloudInstance` are the two lifecycle commands currently in the public surface.
- **Cross-cloud search by name.** On the roadmap.

The rule behind every decision above: *if the normalized object would be mostly `Metadata`, the abstraction is too weak to deserve a first-class public command.*

## Testing

```powershell
Install-Module Pester -MinimumVersion 5.6.0 -Scope CurrentUser
Invoke-Pester
```

Provider SDK calls are mocked in the test suite, so cloud credentials are not required to run tests.

## Demo mode

For the Summit talk — and for anyone who wants to try PSCumulus without real cloud accounts — `scripts/demo-setup.ps1` monkeypatches the provider backends inside the module scope and seeds realistic multi-cloud data:

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
- [Strategy](https://adilio.github.io/PSCumulus/concepts/strategy/) — project rationale, normalization rules, roadmap
- [Command reference](https://adilio.github.io/PSCumulus/reference/) — generated from PlatyPS

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
