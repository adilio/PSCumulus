# PSCumulus Strategy

## Synopsis

`PSCumulus` is a thin cross-cloud PowerShell abstraction built for the PowerShell + DevOps Global Summit 2026 session:
**"Cross-Cloud without Crossed Fingers: Surviving Azure, AWS, and GCP with PowerShell"**

This document collects the project rationale, module boundaries, normalization rules, and roadmap in one place.

## Description

The project is built around a simple idea:

> Build on what does not move.

The clouds differ wildly. PowerShell does not. PSCumulus uses the PowerShell verb-noun model as a stable lens for querying and operating across Azure, AWS, and GCP without pretending the providers are identical.

This is intentionally not a full cloud framework. It is a narrow, honest abstraction aimed at interactive operations, demos, and cross-cloud discovery.

## Module Scope

The public surface focuses on a small set of cross-cloud tasks where the user intent is stable:

| Command | Intent |
|---|---|
| `Connect-Cloud` | Prepare a ready-to-use cloud session, including auth if needed |
| `Disconnect-Cloud` | Clear stored session context for a selected provider |
| `Get-CloudContext` | Inspect established provider sessions for the current shell |
| `Get-CloudInstance` | Enumerate compute instances, optionally filtered by exact name within scope |
| `Get-CloudStorage` | Enumerate storage resources |
| `Get-CloudTag` | Enumerate tags or labels |
| `Get-CloudNetwork` | Enumerate virtual networks |
| `Get-CloudDisk` | Enumerate disks or volumes |
| `Get-CloudFunction` | Enumerate serverless functions |
| `Start-CloudInstance` | Start a compute instance |
| `Stop-CloudInstance` | Stop a compute instance |

## What This Repo Already Was

Before the recent typed-contract and record-model work, PSCumulus was already a working cmdlet-first module with a clear shape:

- a small public surface built around verb-noun commands like `Get-CloudInstance`
- provider-specific backend functions under `Private/`
- normalized `PSCumulus.CloudRecord` output built from a stable shared property contract
- a stored multi-provider session context for interactive use
- honest provider-native detail preserved in `Metadata`

That matters because the current evolution work is not trying to replace the original idea. It is trying to strengthen it.

The repo was already proving a useful thesis:

- PowerShell's cmdlet model is a stable cross-cloud interface
- normalized records make pipelines practical across Azure, AWS, and GCP
- a narrow abstraction is more honest than pretending every cloud concept is universal

The recent changes do not invalidate that model. They tighten its internal correctness and prepare it for future additive capabilities.

## Provider Strategy

- Azure: wrap `Az.*` modules
- AWS: wrap `AWS.Tools.*` modules
- GCP: wrap `gcloud ... --format=json`

GCP uses the CLI adapter path deliberately. It provides stable JSON output and aligns with the most common authentication flow users already have on hand.

## Normalization Strategy

The test behind every unified command: do the underlying CSP philosophies behind this concept overlap enough that a normalized answer is still honest?

- For compute, storage, disk, network, functions, and tags, yes. The question translates. The answer can be normalized.
- For IAM, the question is the same. The answer cannot be. AWS thinks in policy documents. Azure thinks in role assignments scoped to a resource hierarchy. GCP thinks in bindings. Forcing a single surface over those would erase distinctions that matter in practice.

Provider-native differences that survive normalization belong in `Metadata`, not in the public command noun.

For Stage 2, that principle gets sharpened: genuinely opaque detail stays in `Metadata`, but commonly-needed vendor identity fields graduate into first-class properties on vendor subclasses.

### Shared Output Contract

Inventory commands return `PSCumulus.CloudRecord`-compatible records with a stable cross-cloud shape:

| Field | Description |
|---|---|
| `Name` | Resource name |
| `Provider` | `Azure`, `AWS`, or `GCP` |
| `Region` | Region or zone |
| `Status` | Normalized semantic state |
| `Size` | SKU, instance type, or storage class |
| `CreatedAt` | Creation time when available |
| `PrivateIpAddress` | Private IP address when available |
| `PublicIpAddress` | Public IP address when available |
| `Tags` | Normalized hashtable. AWS tags, Azure tags, and GCP labels all map here |
| `Metadata` | Provider-native details that do not normalize cleanly |

`Status` is semantic, not just title-cased provider output. Examples:

- AWS `shutting-down` becomes `Terminating`
- Azure `VM deallocated` becomes `Stopped`
- GCP `TERMINATED` becomes `Stopped`

That GCP mapping is deliberate: native GCP `TERMINATED` means stopped-but-restartable, while normalized `Terminated` is reserved for permanently gone resources. The original provider value remains available in `Metadata.NativeStatus`.

`Suspending` and `Suspended` are valid normalized states today, but they currently come from GCP only.

For Azure instances, when no power state can be read, PSCumulus now emits `Unknown` rather than the older `Ready` fallback so the public status contract stays aligned with the semantic enum vocabulary.

### What Belongs On Vendor Subclasses

- Azure instance records: `ResourceGroup`, `VmId`, `OsType`
- AWS instance records: `InstanceId`, `VpcId`, `SubnetId`
- GCP instance records: `Project`, `Zone`, `Id`

### What Belongs In `Metadata`

- native status strings
- provider-native long-tail details that do not deserve a stable first-class property
- transitional compatibility data while older resource kinds still use the legacy construction path

### What Not To Normalize

Do not force a shared command when the providers express materially different models. IAM is the clearest example. The human question is the same ("who can do what?"), but the CSP answers are structured so differently that a normalized surface would be dishonest:

```powershell
Get-AzRoleAssignment -Scope "/subscriptions/..."
Get-IAMPolicy -UserName "adil"
gcloud projects get-iam-policy my-project
```

Explicit non-goals:

- IAM, RBAC, policies, and bindings
- Advanced networking concepts with incompatible semantics
- Billing and cost models
- Full provisioning coverage
- Perfect feature parity across all providers

Rule of thumb: if the normalized object would be mostly `Metadata`, the abstraction is too weak to deserve a first-class public command.

## Connection Lifecycle

`Connect-Cloud` is not just a dispatcher. It owns the full session readiness workflow:

1. Verify the required provider tools are installed
2. Detect whether an active authentication session exists
3. If not authenticated, trigger the provider-native login flow automatically
4. Store a normalized per-provider context (account identity, scope, region)
5. Set the active provider for the current session

The per-provider detection works differently for each provider because the providers are genuinely different:

- **Azure**: checks `Get-AzContext`; calls `Connect-AzAccount` if no session exists, and can pass tenant and subscription selectors when provided
- **AWS**: checks environment variables and `~/.aws` credential files; proceeds through `Initialize-AWSDefaultConfiguration`
- **GCP**: checks `gcloud auth list` for an active account; calls `gcloud auth application-default login` if none is found

Session context is stored per provider, not as a single active slot. This means connecting to Azure, then AWS, then GCP leaves all three contexts available. `Get-CloudContext` surfaces all of them, and `Disconnect-Cloud` can clear one provider without disturbing the others.

## Ergonomics

After `Connect-Cloud`, the module remembers the active provider for the current session. `Disconnect-Cloud` recalculates the active provider when the active one is removed. Public commands can often omit `-Provider` when:

- the parameter set already implies the provider
- the active session provider makes the intent unambiguous

This keeps interactive usage fast without making scripts depend on hidden state.

## Implementation Stages

PSCumulus is being built in additive stages so each one is shippable on its own. The cmdlets remain the primary interface throughout. Any future Provider is layered on top of the same backend engine, not treated as a replacement. The core module stays PowerShell 5.1-compatible, while later navigation work is expected to target PowerShell 7+ where provider classes are more reliable.

This direction became much clearer after the Summit talk on **Monday, April 13, 2026**, when Jeffrey Snover offered the insight that unlocked the roadmap: use a base class for shared properties, subclass per vendor, and let the subclass own parsing. The future Provider remains in the roadmap, but it now follows the corrected record model instead of leading it. The full rationale and stage-by-stage narrative live in [Evolution](evolution.md).

**Current status:** Stages 1, 2, and 3 are complete (v0.5.0).

Broad outline:

1. **Stage 1: Internal Typed Contract**: strengthen internal correctness without changing the public cmdlet surface.
2. **Stage 2: Vendor Subclass Records**: introduce a real base record class, vendor subclasses, subclass-owned normalization factories, and `Kind`.
3. **Stage 3: Cloud Path Model**: define a structured path/resolver layer independent of any Provider mechanics.
4. **Stage 4: The Provider (Read-Only)**: add additive navigation over the same backend engine.
5. **Stage 5: Write Operations Through the Provider**: let lifecycle actions flow through path context once navigation is stable.
6. **Stage 6: Cross-Cloud Aggregation**: expose multi-provider views through navigation as well as cmdlets.

For the full stage-by-stage plan, rationale, origin story, and decision details, see [Evolution](evolution.md).

Work intentionally left out:

- A fake universal IAM surface
- Terraform-style provisioning
- Abstractions that erase important provider semantics
