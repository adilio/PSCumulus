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

Today, this repo contains:

- a detailed talk plan in `PLAN.md`
- a Marp slide skeleton in `slides/PSCumulus.md`
- an early PowerShell module scaffold for the proof of concept

If your focus is the module, start with `PSCumulus.psd1`, `PSCumulus.psm1`, `Public/`, `Private/`, and `docs/MODULE-ROADMAP.md`.

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
Connect-Cloud -Provider AWS    -Region "us-east-1"
Connect-Cloud -Provider GCP    -Project "my-project"
```

---

## Core API

Same verb. Same output shape. Swappable provider.

```powershell
# List compute instances
Get-CloudInstance -Provider Azure -ResourceGroup "prod-rg"
Get-CloudInstance -Provider AWS   -Region "us-east-1"
Get-CloudInstance -Provider GCP   -Project "my-project"

# List storage
Get-CloudStorage  -Provider Azure -ResourceGroup "prod-rg"
Get-CloudStorage  -Provider AWS
Get-CloudStorage  -Provider GCP   -Project "my-project"

# Get resource tags
Get-CloudTag      -Provider Azure -ResourceId "/subscriptions/.../myVM"
Get-CloudTag      -Provider AWS   -ResourceId "i-0abc123def456"
Get-CloudTag      -Provider GCP   -Project "my-project" -Resource "instances/my-vm"
```

All commands return a `PSCustomObject` with consistent properties:

| Property    | Description                        |
|-------------|-----------------------------------|
| `Name`      | Resource name                      |
| `Provider`  | `Azure` / `AWS` / `GCP`            |
| `Region`    | Cloud region or zone               |
| `Status`    | Running, Stopped, etc.             |
| `Size`      | Instance type / SKU                |
| `CreatedAt` | Timestamp (where available)        |

---

## Where It Breaks

Identity and access management **cannot be cleanly unified.** These are genuinely different models, not just different names.

```powershell
# Three philosophies. Three functions. That's okay.
Get-AzureRoleAssignment  -Scope "/subscriptions/..."
Get-AWSPolicyAttachment  -UserName "adil"
Get-GCPIAMBinding        -Project "my-project"
```

The lesson: **knowing when not to abstract is the actual skill.**

This is intentional — and it's a section of the talk.

---

## Module Structure

```
PSCumulus/
├── PSCumulus.psd1
├── PSCumulus.psm1
├── Private/
│   ├── ConvertTo-CloudRecord.ps1
│   ├── Connect-AzureBackend.ps1
│   ├── Connect-AWSBackend.ps1
│   └── Connect-GCPBackend.ps1
└── Public/
    ├── Connect-Cloud.ps1
    ├── Get-CloudInstance.ps1
    ├── Get-CloudStorage.ps1
    └── Get-CloudTag.ps1
```

**Design principles:**
- Consistent output objects across all providers
- Provider param on every public function — not baked into the noun
- No hard dependencies beyond official SDKs; GCP wraps `gcloud` CLI output
- Explicit over clever — when abstraction gets messy, write three clear functions

The current scaffold is intentionally incomplete. Public commands exist, module loading works, and provider-specific implementations are still placeholders.

Today, the first real backend path is Azure connection plus Azure instance inventory. The AWS and GCP backends are still placeholders.

---

## The Talk

**"Cross-Cloud without Crossed Fingers: Surviving Azure, AWS, and GCP with PowerShell"**

The surface story: here's how to use PowerShell across three clouds.

The deep story: here's what happens to your brain when the map doesn't match the territory, and why reaching for a familiar tool is a legitimate engineering decision.

**Key takeaways:**
- How to connect to Azure, AWS, and GCP with PowerShell
- The similarities and differences between common services
- How Terraform and PowerShell can complement each other
- When to abstract — and when to stop

---

## Build the Slides

This repo uses [Marp](https://marp.app/) for slides. Theme via [HeyItsGilbert/PSSummit2026](https://github.com/HeyItsGilbert/PSSummit2026).

```powershell
# Install Marp CLI
npm i -g @marp-team/marp-cli

# Export to HTML
marp .\slides\PSCumulus.md --theme-set .\summit-2026.css --html --output .\dist\PSCumulus.html

# Export to PDF
marp .\slides\PSCumulus.md --theme-set .\summit-2026.css --pdf --allow-local-files --output .\dist\PSCumulus.pdf

# Export to PPTX
marp .\slides\PSCumulus.md --theme-set .\summit-2026.css --pptx --allow-local-files --output .\dist\PSCumulus.pptx
```

The deck skeleton follows the slide constraints captured in `PLAN.md` and the Death by PowerPoint review guidance referenced in the attribution section.

---

## Contributing

This is a Summit demo — scope is intentionally narrow. PRs welcome for:

- Bug fixes in the three core commands
- GCP backend improvements (the `gcloud` wrapper is rough)
- Corrections to the slides

Please don't open PRs that expand scope. Version B is a trap.

---

## License

MIT — see [LICENSE](./LICENSE).

---

## Attribution

- **Slide theme:** [HeyItsGilbert/PSSummit2026](https://github.com/HeyItsGilbert/PSSummit2026) — Marp theme for PowerShell + DevOps Global Summit 2026
- **Slide review:** [Death by PowerPoint skill](https://github.com/HeyItsGilbert/marketplace/blob/main/plugins/presentation-review/skills/death-by-ppt/SKILL.md) by [@HeyItsGilbert](https://github.com/HeyItsGilbert), based on David JP Phillips' ["How to Avoid Death by PowerPoint"](https://www.youtube.com/watch?v=Iwpi1Lm6dFo)
- **PowerShell module guidance:** [PoshCode/PowerShellPracticeAndStyle](https://github.com/PoshCode/PowerShellPracticeAndStyle) — used as a reference for function structure, help, output behavior, and packaging hygiene
