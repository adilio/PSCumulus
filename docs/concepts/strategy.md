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
| `Get-CloudContext` | Inspect established provider sessions for the current shell |
| `Get-CloudInstance` | Enumerate compute instances, optionally filtered by exact name within scope |
| `Get-CloudStorage` | Enumerate storage resources |
| `Get-CloudTag` | Enumerate tags or labels |
| `Get-CloudNetwork` | Enumerate virtual networks |
| `Get-CloudDisk` | Enumerate disks or volumes |
| `Get-CloudFunction` | Enumerate serverless functions |
| `Start-CloudInstance` | Start a compute instance |
| `Stop-CloudInstance` | Stop a compute instance |

## Provider Strategy

- Azure: wrap `Az.*` modules
- AWS: wrap `AWS.Tools.*` modules
- GCP: wrap `gcloud ... --format=json`

GCP uses the CLI adapter path deliberately. It provides stable JSON output and aligns with the most common authentication flow users already have on hand.

## Normalization Strategy

The test behind every unified command: do the underlying CSP philosophies behind this concept overlap enough that a normalized answer is still honest?

- For compute, storage, disk, network, functions, and tags — yes. The question translates. The answer can be normalized.
- For IAM — the question is the same. The answer cannot be. AWS thinks in policy documents. Azure thinks in role assignments scoped to a resource hierarchy. GCP thinks in bindings. Forcing a single surface over those would erase distinctions that matter in practice.

Provider-native differences that survive normalization belong in `Metadata`, not in the public command noun.

### Shared Output Contract

Inventory commands return `PSCumulus.CloudRecord` objects with a stable cross-cloud shape:

| Field | Description |
|---|---|
| `Name` | Resource name |
| `Provider` | `Azure`, `AWS`, or `GCP` |
| `Region` | Region or zone |
| `Status` | Normalized title-case state |
| `Size` | SKU, instance type, or storage class |
| `CreatedAt` | Creation time when available |
| `PrivateIpAddress` | Private IP address when available |
| `PublicIpAddress` | Public IP address when available |
| `Tags` | Normalized hashtable — AWS tags, Azure tags, GCP labels all map here |
| `Metadata` | Provider-native details that do not normalize cleanly |

### What Belongs In `Metadata`

- Azure: `ResourceGroup`, `VmId`, `OsType`, `Sku`
- AWS: `InstanceId`, `VpcId`, `SubnetId`, `VolumeType`
- GCP: `Project`, `Zone`, `Labels`, `DiskType`

### What Not To Normalize

Do not force a shared command when the providers express materially different models. IAM is the clearest example — the human question is the same ("who can do what?"), but the CSP answers are structured so differently that a normalized surface would be dishonest:

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

Session context is stored per provider, not as a single active slot. This means connecting to Azure, then AWS, then GCP leaves all three contexts available. `Get-CloudContext` surfaces all of them.

## Ergonomics

After `Connect-Cloud`, the module remembers the active provider for the current session. Public commands can often omit `-Provider` when:

- the parameter set already implies the provider
- the active session provider makes the intent unambiguous

This keeps interactive usage fast without making scripts depend on hidden state.

## Roadmap

Near-term improvements that fit the current philosophy:

- Expand inline help and examples for the public commands
- Keep generated reference docs current through PlatyPS
- Keep improving test readability and coverage around interactive ergonomics
- Add more provider-safe lifecycle and read-only inventory scenarios where the intent is genuinely shared

Work intentionally left out:

- A fake universal IAM surface
- Terraform-style provisioning
- Abstractions that erase important provider semantics
