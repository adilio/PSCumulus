# PSCumulus

A cross-cloud PowerShell abstraction module and companion repo for the PowerShell + DevOps Global Summit 2026 talk:
**"Cross-Cloud without Crossed Fingers: Surviving Azure, AWS, and GCP with PowerShell"**

> Fast Focus · 25 minutes · Level 100 · April 13–16, Bellevue, WA

---

## What This Is

PSCumulus is a **thin abstraction layer** over the three major clouds — Azure, AWS, and GCP — using PowerShell you already know.

It is **not** a general-purpose cloud management framework. It is a proof of concept built to answer one question:

> *"Can you use a single verb-noun pattern to operate across clouds without losing your mind?"*

Mostly yes. [Except for IAM.](#where-it-breaks)

---

## Quick Start

### Prerequisites

```powershell
# Azure
Install-Module Az -Scope CurrentUser

# AWS
Install-Module AWS.Tools.EC2, AWS.Tools.S3 -Scope CurrentUser

# GCP — requires gcloud CLI
# https://cloud.google.com/sdk/docs/install
```

### Connect to a Cloud

```powershell
Import-Module PSCumulus

Connect-Cloud -Provider Azure
Connect-Cloud -Provider AWS  -Region "us-east-1"
Connect-Cloud -Provider GCP  -Project "my-project"
```

---

## Core API

Same verb. Same output shape. Swappable provider.

```powershell
# Compute instances
Get-CloudInstance -Provider Azure -ResourceGroup "prod-rg"
Get-CloudInstance -Provider AWS   -Region "us-east-1"
Get-CloudInstance -Provider GCP   -Project "my-project"

# Storage resources
Get-CloudStorage  -Provider Azure -ResourceGroup "prod-rg"
Get-CloudStorage  -Provider AWS   -Region "us-east-1"
Get-CloudStorage  -Provider GCP   -Project "my-project"

# Tags and labels
Get-CloudTag      -Provider Azure -ResourceId "/subscriptions/.../myVM"
Get-CloudTag      -Provider AWS   -ResourceId "i-0abc123def456"
Get-CloudTag      -Provider GCP   -Project "my-project" -Resource "instances/my-vm"

# Virtual networks / VPCs
Get-CloudNetwork  -Provider Azure -ResourceGroup "prod-rg"
Get-CloudNetwork  -Provider AWS   -Region "us-east-1"
Get-CloudNetwork  -Provider GCP   -Project "my-project"

# Disks and volumes
Get-CloudDisk     -Provider Azure -ResourceGroup "prod-rg"
Get-CloudDisk     -Provider AWS   -Region "us-east-1"
Get-CloudDisk     -Provider GCP   -Project "my-project"

# Serverless functions
Get-CloudFunction -Provider Azure -ResourceGroup "prod-rg"
Get-CloudFunction -Provider AWS   -Region "us-east-1"
Get-CloudFunction -Provider GCP   -Project "my-project"

# Instance lifecycle
Start-CloudInstance -Provider Azure -Name "web-01" -ResourceGroup "prod-rg"
Start-CloudInstance -Provider AWS   -InstanceId "i-0abc123" -Region "us-east-1"
Start-CloudInstance -Provider GCP   -Name "web-01" -Zone "us-central1-a" -Project "my-project"

Stop-CloudInstance  -Provider Azure -Name "web-01" -ResourceGroup "prod-rg"
Stop-CloudInstance  -Provider AWS   -InstanceId "i-0abc123" -Region "us-east-1"
Stop-CloudInstance  -Provider GCP   -Name "web-01" -Zone "us-central1-a" -Project "my-project"
```

All commands return a `PSCumulus.CloudRecord` object with consistent properties:

| Property    | Description                               |
|-------------|-------------------------------------------|
| `Name`      | Resource name                             |
| `Provider`  | `Azure` / `AWS` / `GCP`                   |
| `Region`    | Cloud region or zone                      |
| `Status`    | Normalized state (Running, Stopped, etc.) |
| `Size`      | Instance type, SKU, or storage class      |
| `CreatedAt` | Creation timestamp (where available)      |
| `Metadata`  | Provider-native details                   |

The design approach is documented in [`docs/NORMALIZATION-STRATEGY.md`](./docs/NORMALIZATION-STRATEGY.md): normalize by intent, preserve native details in `Metadata`, and stop abstracting when the underlying models are genuinely different.

---

## Where It Breaks

Identity and access management **cannot be cleanly unified.** These are genuinely different models, not just different names.

```powershell
# Three philosophies. Three functions. That's okay.
Get-AzureRoleAssignment  -Scope "/subscriptions/..."
Get-AWSPolicyAttachment  -UserName "adil"
Get-GCPIAMBinding        -Project "my-project"
```

The lesson: **knowing when not to abstract is the actual skill.** This is intentional — and it's a section of the talk.

---

## Module Structure

```
PSCumulus/
├── PSCumulus.psd1
├── PSCumulus.psm1
├── Public/
│   ├── Connect-Cloud.ps1
│   ├── Get-CloudInstance.ps1
│   ├── Get-CloudStorage.ps1
│   ├── Get-CloudTag.ps1
│   ├── Get-CloudNetwork.ps1
│   ├── Get-CloudDisk.ps1
│   ├── Get-CloudFunction.ps1
│   ├── Start-CloudInstance.ps1
│   └── Stop-CloudInstance.ps1
├── Private/
│   ├── ConvertTo-CloudRecord.ps1
│   ├── Invoke-CloudProvider.ps1
│   ├── Invoke-GCloudJson.ps1
│   ├── Assert-CommandAvailable.ps1
│   ├── Assert-ProviderParameterSet.ps1
│   ├── Assert-CloudTagArguments.ps1
│   ├── Assert-GCloudAuthenticated.ps1
│   ├── Connect-{Azure,AWS,GCP}Backend.ps1
│   ├── Get-{Azure,AWS,GCP}InstanceData.ps1
│   ├── Get-{Azure,AWS,GCP}StorageData.ps1
│   ├── Get-{Azure,AWS,GCP}TagData.ps1
│   ├── Get-{Azure,AWS,GCP}NetworkData.ps1
│   ├── Get-{Azure,AWS,GCP}DiskData.ps1
│   ├── Get-{Azure,AWS,GCP}FunctionData.ps1
│   ├── Start-{Azure,AWS,GCP}Instance.ps1
│   └── Stop-{Azure,AWS,GCP}Instance.ps1
└── docs/
    ├── NORMALIZATION-STRATEGY.md
    └── MODULE-ROADMAP.md
```

**Design principles:**
- Consistent `PSCumulus.CloudRecord` output across all providers
- `-Provider` parameter on every public function — not baked into the noun
- No hard dependencies beyond official SDKs; GCP wraps `gcloud` CLI output
- Explicit over clever — when abstraction gets messy, write three clear functions

---

## Why Not Terraform?

Terraform standardizes how infrastructure is declared and provisioned. PSCumulus standardizes how infrastructure is queried and interacted with.

> Terraform standardizes infrastructure. PSCumulus standardizes how humans interact with infrastructure across clouds.

---

## The Talk

**"Cross-Cloud without Crossed Fingers: Surviving Azure, AWS, and GCP with PowerShell"**

The surface story: here's how to use PowerShell across three clouds.

The deep story: here's what happens to your brain when the map doesn't match the territory, and why reaching for a familiar tool is a legitimate engineering decision.

The working spoken argument is in `slides/TALK-TRACK.md`.

---

## Testing

Tests use [Pester](https://pester.dev) 5.x. No cloud credentials or SDKs required — all provider calls are mocked.

```powershell
Install-Module Pester -MinimumVersion 5.6.0 -Scope CurrentUser
Invoke-Pester
```

The GitHub Actions workflow runs the full suite on every push and PR to `main`.

---

## Build the Slides

```powershell
npm i -g @marp-team/marp-cli

marp .\slides\PSCumulus.md --theme-set .\summit-2026.css --html  --output .\dist\PSCumulus.html
marp .\slides\PSCumulus.md --theme-set .\summit-2026.css --pdf   --allow-local-files --output .\dist\PSCumulus.pdf
marp .\slides\PSCumulus.md --theme-set .\summit-2026.css --pptx  --allow-local-files --output .\dist\PSCumulus.pptx
```

---

## Contributing

This is a Summit demo — scope is intentionally narrow. PRs welcome for bug fixes, GCP backend improvements, and slide corrections. Please don't open PRs that expand scope. Version B is a trap.

---

## License

MIT — see [LICENSE](./LICENSE).

---

## Attribution

- **Slide theme:** [HeyItsGilbert/PSSummit2026](https://github.com/HeyItsGilbert/PSSummit2026)
- **Slide review:** [Death by PowerPoint skill](https://github.com/HeyItsGilbert/marketplace/blob/main/plugins/presentation-review/skills/death-by-ppt/SKILL.md) by [@HeyItsGilbert](https://github.com/HeyItsGilbert)
- **PowerShell guidance:** [PoshCode/PowerShellPracticeAndStyle](https://github.com/PoshCode/PowerShellPracticeAndStyle)
