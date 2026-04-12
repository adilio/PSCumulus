# PSCumulus

A thin cross-cloud PowerShell abstraction for Azure, AWS, and GCP.

> Companion repo for the PowerShell + DevOps Global Summit 2026 session:
> **"Cross-Cloud without Crossed Fingers: Surviving Azure, AWS, and GCP with PowerShell"**

**Docs:** https://adilio.github.io/PSCumulus/

## Synopsis

`PSCumulus` provides a small, consistent PowerShell surface for common cross-cloud tasks such as connecting, inventorying compute and storage, inspecting tags, and starting or stopping instances.

It is intentionally not a full cloud framework. The goal is to make a few high-value tasks feel consistent in the shell without hiding where the providers are genuinely different.

## Description

The module uses a stable verb-noun pattern across Azure, AWS, and GCP:

- `Connect-Cloud`
- `Disconnect-Cloud`
- `Get-CloudContext`
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
Install-Module PSCumulus -Scope CurrentUser
Import-Module PSCumulus
```

## Quick Start

### Connect to a provider

```powershell
Connect-Cloud -Provider Azure
Connect-Cloud -Provider AWS -Region "us-east-1"
Connect-Cloud -Provider GCP -Project "my-project"
```

`Connect-Cloud` does more than set a provider. It checks whether you are already authenticated and triggers the provider-native login flow automatically if not. If a session already exists, it skips login and stores the context directly. The active provider is remembered for the current session, so later commands can often omit `-Provider` when the intent is clear.

```powershell
Connect-Cloud -Provider AWS -Region "us-east-1"

Get-CloudInstance -Region "us-east-1"
Start-CloudInstance -InstanceId "i-0abc123" -Region "us-east-1"
Get-CloudTag -ResourceId "i-0abc123"
```

Pass `-Provider` explicitly whenever you want to override the remembered session provider.

Use `Disconnect-Cloud` to clear PSCumulus's remembered session state for a specific provider without signing out of the cloud provider itself:

```powershell
Disconnect-Cloud -Provider AWS -AccountId "123456789012"
Disconnect-Cloud -Provider Azure -Subscription "my-subscription"
Disconnect-Cloud -Provider GCP -Project "my-project"
```

## Commands

### Session

```powershell
# Show all established provider sessions
Get-CloudContext

# Example output
# Provider IsActive Account            Scope        Region
# -------- -------- -------            -----        ------
# Azure    False    adil@contoso.com   my-sub
# AWS      True     default            default      us-east-1
# GCP      False    adil@example.com   my-project
```

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
| `conc` | `Connect-Cloud` |
| `gcont` | `Get-CloudContext` |
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
| `Tags` | Normalized hashtable of tags or labels across providers |
| `Metadata` | Provider-native details |

`Connect-Cloud` returns a `PSCumulus.ConnectionResult` object describing the validated provider context for the session.

`Disconnect-Cloud` clears the stored PSCumulus context for the selected provider and returns a `PSCumulus.ConnectionResult` object with `Connected = False`.

## Limits

The test behind every unified command: do the underlying CSP philosophies behind this concept overlap enough that a normalized answer is still honest?

For compute, storage, disk, network, functions, and tags — yes. The question and the answer both translate.

For IAM, the question is the same. The answer cannot be. AWS thinks in policy documents. Azure thinks in role assignments scoped to a resource hierarchy. GCP thinks in bindings. Those are not the same concept wearing different clothes, so PSCumulus does not try to unify them:

```powershell
Get-AzRoleAssignment -Scope "/subscriptions/..."
Get-IAMPolicy -UserName "adil"
gcloud projects get-iam-policy my-project
```

Knowing when not to abstract is the actual skill.

## Testing

Tests use [Pester](https://pester.dev) 5.x. Cloud SDKs and credentials are not required because provider calls are mocked.

```powershell
Install-Module Pester -MinimumVersion 5.6.0 -Scope CurrentUser
Invoke-Pester
```

## Documentation

Full documentation is at **https://adilio.github.io/PSCumulus/**

- [Getting Started](https://adilio.github.io/PSCumulus/getting-started/) — installation and first commands
- [Strategy](https://adilio.github.io/PSCumulus/concepts/strategy/) — project rationale and normalization philosophy
- [Reference](https://adilio.github.io/PSCumulus/reference/) — generated command documentation

Native PowerShell help is also available:

```powershell
Get-Help about_PSCumulus
Get-Help Get-CloudInstance -Examples
```

To build docs locally:

```powershell
python -m pip install -r requirements-docs.txt
./scripts/Update-Docs.ps1
mkdocs serve
```

## Notes

- Public command help is available through `Get-Help`.
- The module overview is also available as `Get-Help about_PSCumulus`.
- The consolidated project rationale, normalization rules, and roadmap live in [`docs/concepts/strategy.md`](./docs/concepts/strategy.md).
- The generated command reference lives under [`docs/reference/`](./docs/reference/).
- The talk draft and speaker material remain under [`slides/`](./slides).
