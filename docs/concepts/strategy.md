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
| `Connect-Cloud` | Establish and validate provider context |
| `Get-CloudInstance` | Enumerate compute instances |
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

Normalize by intent, not by provider naming.

- `Get-CloudInstance` means "show me compute instances"
- `Get-CloudStorage` means "show me storage resources"
- `Get-CloudNetwork` means "show me virtual networks"

Provider-native differences still matter, but they belong in `Metadata`, not in the public command noun.

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
| `Metadata` | Provider-native details that do not normalize cleanly |

### What Belongs In `Metadata`

- Azure: `ResourceGroup`, `VmId`, `OsType`, `Sku`
- AWS: `InstanceId`, `VpcId`, `SubnetId`, `VolumeType`
- GCP: `Project`, `Zone`, `Labels`, `DiskType`

### What Not To Normalize

Do not force a shared command when the providers express materially different models.

Explicit non-goals:

- IAM, RBAC, policies, and bindings
- Advanced networking concepts with incompatible semantics
- Billing and cost models
- Full provisioning coverage
- Perfect feature parity across all providers

Rule of thumb: if the normalized object would be mostly `Metadata`, the abstraction is too weak to deserve a first-class public command.

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
