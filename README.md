# PSCumulus

A thin cross-cloud PowerShell abstraction for Azure, AWS, and GCP.

> Companion repo for the PowerShell + DevOps Global Summit 2026 session:
> **"Cross-Cloud without Crossed Fingers: Surviving Azure, AWS, and GCP with PowerShell"**

## Synopsis

`PSCumulus` provides a small, consistent PowerShell surface for common cross-cloud tasks such as connecting, inventorying compute and storage, inspecting tags, and starting or stopping instances.

It is intentionally not a full cloud framework. The goal is to make a few high-value tasks feel consistent in the shell without hiding where the providers are genuinely different.

## Description

The module uses a stable verb-noun pattern across Azure, AWS, and GCP:

- `Connect-Cloud`
- `Get-CloudInstance`
- `Get-CloudStorage`
- `Get-CloudTag`
- `Get-CloudNetwork`
- `Get-CloudDisk`
- `Get-CloudFunction`
- `Start-CloudInstance`
- `Stop-CloudInstance`

Most inventory commands return a normalized `PSCumulus.CloudRecord` object. Provider-native detail is preserved in the `Metadata` property instead of being flattened away.

## Requirements

```powershell
# Azure
Install-Module Az -Scope CurrentUser

# AWS
Install-Module AWS.Tools.EC2, AWS.Tools.S3 -Scope CurrentUser

# GCP
# Requires the gcloud CLI:
# https://cloud.google.com/sdk/docs/install
```

> **Note:** GCP doesn't have a maintained PowerShell module, so there's no `Install-Module` equivalent. Install the `gcloud` CLI for your platform using the link above.

## Installation

```powershell
Import-Module PSCumulus
```

## Quick Start

### Connect to a provider

```powershell
Connect-Cloud -Provider Azure
Connect-Cloud -Provider AWS -Region "us-east-1"
Connect-Cloud -Provider GCP -Project "my-project"
```

`Connect-Cloud` remembers the active provider for the current session. In interactive use, that means you can often omit `-Provider` on later commands when the remaining parameters already imply the target cloud or when the session context makes the intent clear.

```powershell
Connect-Cloud -Provider AWS -Region "us-east-1"

Get-CloudInstance -Region "us-east-1"
Start-CloudInstance -InstanceId "i-0abc123" -Region "us-east-1"
Get-CloudTag -ResourceId "i-0abc123"
```

Pass `-Provider` explicitly whenever you want to override the remembered session provider.

## Commands

### Inventory

```powershell
Get-CloudInstance -Provider Azure -ResourceGroup "prod-rg"
Get-CloudInstance -Provider AWS -Region "us-east-1"
Get-CloudInstance -Provider GCP -Project "my-project"

Get-CloudStorage -Provider Azure -ResourceGroup "prod-rg"
Get-CloudStorage -Provider AWS -Region "us-east-1"
Get-CloudStorage -Provider GCP -Project "my-project"

Get-CloudTag -Provider Azure -ResourceId "/subscriptions/.../myVM"
Get-CloudTag -Provider AWS -ResourceId "i-0abc123def456"
Get-CloudTag -Provider GCP -Project "my-project" -Resource "instances/my-vm"

Get-CloudNetwork -Provider Azure -ResourceGroup "prod-rg"
Get-CloudNetwork -Provider AWS -Region "us-east-1"
Get-CloudNetwork -Provider GCP -Project "my-project"

Get-CloudDisk -Provider Azure -ResourceGroup "prod-rg"
Get-CloudDisk -Provider AWS -Region "us-east-1"
Get-CloudDisk -Provider GCP -Project "my-project"

Get-CloudFunction -Provider Azure -ResourceGroup "prod-rg"
Get-CloudFunction -Provider AWS -Region "us-east-1"
Get-CloudFunction -Provider GCP -Project "my-project"
```

### Instance lifecycle

```powershell
Start-CloudInstance -Provider Azure -Name "web-01" -ResourceGroup "prod-rg"
Start-CloudInstance -Provider AWS -InstanceId "i-0abc123" -Region "us-east-1"
Start-CloudInstance -Provider GCP -Name "web-01" -Zone "us-central1-a" -Project "my-project"

Stop-CloudInstance -Provider Azure -Name "web-01" -ResourceGroup "prod-rg"
Stop-CloudInstance -Provider AWS -InstanceId "i-0abc123" -Region "us-east-1"
Stop-CloudInstance -Provider GCP -Name "web-01" -Zone "us-central1-a" -Project "my-project"
```

### Interactive aliases

These aliases are exported for terminal convenience:

| Alias | Command |
|---|---|
| `cc` | `Connect-Cloud` |
| `gcin` | `Get-CloudInstance` |
| `sci` | `Start-CloudInstance` |
| `tci` | `Stop-CloudInstance` |

Use the full command names in scripts, examples, and shared documentation.

## Output

Inventory commands return `PSCumulus.CloudRecord` objects with a stable cross-cloud shape:

| Property | Description |
|---|---|
| `Name` | Resource name |
| `Provider` | `Azure`, `AWS`, or `GCP` |
| `Region` | Region or zone |
| `Status` | Normalized state such as `Running` or `Stopped` |
| `Size` | SKU, instance type, or storage class |
| `CreatedAt` | Creation time when available |
| `Metadata` | Provider-native details |

`Connect-Cloud` returns a `PSCumulus.ConnectionResult` object describing the validated provider context for the session.

## Limits

Not every cloud concept should be abstracted. Identity and access management is the clearest example.

These are intentionally separate:

```powershell
Get-AzureRoleAssignment -Scope "/subscriptions/..."
Get-AWSPolicyAttachment -UserName "adil"
Get-GCPIAMBinding -Project "my-project"
```

If the providers do not share an honest common model, PSCumulus does not try to invent one.

## Testing

Tests use [Pester](https://pester.dev) 5.x. Cloud SDKs and credentials are not required because provider calls are mocked.

```powershell
Install-Module Pester -MinimumVersion 5.6.0 -Scope CurrentUser
Invoke-Pester
```

## Documentation

The docs are split by role:

- repo-level overview and quick usage in this README
- native PowerShell help through `Get-Help`
- a browsable docs site built with MkDocs
- generated command reference built from comment-based help with PlatyPS

To regenerate the command reference:

```powershell
./scripts/Update-Docs.ps1
```

To build the docs site locally:

```powershell
python -m pip install -r requirements-docs.txt
./scripts/Update-Docs.ps1
mkdocs build --strict
```

## Notes

- Public command help is available through `Get-Help`.
- The module overview is also available as `Get-Help about_PSCumulus`.
- The consolidated project rationale, normalization rules, and roadmap live in [`docs/concepts/strategy.md`](./docs/concepts/strategy.md).
- The generated command reference lives under [`docs/reference/`](./docs/reference/).
- The talk draft and speaker material remain under [`slides/`](./slides).
