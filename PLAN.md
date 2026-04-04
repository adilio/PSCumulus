# Cross-Cloud without Crossed Fingers: Talk Planning Document

> PowerShell Summit 2026 | April 13-16, Bellevue, WA
> Fast Focus | 25 Minutes | Level 100 | Session confirmed

---

## Session Details

- **Full Title:** Cross-Cloud without Crossed Fingers: Surviving Azure, AWS, and GCP with PowerShell
- **Format:** Fast Focus (25 minutes), also accepted as General Session (45 min)
- **Level:** 100 (Beginner)
- **Submitted:** 31 Aug 2025 | **Accepted:** 27 Oct 2025

---

## Core Thesis

> **"Build on what doesn't move."**

One-liner for the hallway: *"You don't need to master three clouds. You need one stable lens to see through all three."*

The philosophical claim: fluency is infrastructure. The tool you already trust is the one you should build on top of. PowerShell didn't make you faster because it's technically superior — it made you faster because you already had the keystrokes in your hands.

**Familiarity is an underrated engineering virtue.**

---

## The Two Stories

Every great talk has two stories running in parallel.

**Surface story:** Here's how to use PowerShell to manage Azure, AWS, and GCP.

**Deep story:** Here's what happens to your brain when the map doesn't match the territory, and why reaching for a familiar tool is a legitimate engineering decision.

The deep story is what people remember. The surface story is what makes it feel useful. Weave both through the entire talk.

---

## Who Is In That Room

- Sysadmins and cloud engineers handed multi-cloud responsibility they didn't ask for
- PowerShell practitioners who feel lost once they leave Azure
- People who feel like they're the only one who doesn't have it figured out

That last group matters most. Imposter syndrome is rampant in multi-cloud work because the surface area is enormous and everyone pretends to know more than they do. Say: *"yeah, it's actually just as messy for everyone."*

---

## Emotional Architecture

| Time | Technical Beat | Emotional Beat |
|---|---|---|
| 0:00–3:00 | The chaos origin story | **Recognition** — audience sees themselves |
| 3:00–6:00 | Why multi-cloud is genuinely hard | **Relief** — it's not their fault |
| 6:00–14:00 | Comparative services section | **Curiosity** — discovery, not instruction |
| 14:00–18:00 | The module and the abstraction | **Delight** — simplicity emerging from chaos |
| 18:00–22:00 | Where the abstraction breaks | **Respect** — they see you as a peer |
| 22:00–25:00 | Close and reframe | **Resonance** — they leave with a new lens |

---

## Structural Flow

### 0:00–2:00 | The Wreck

Don't open with a slide. Open with a sensation.

> *"You know that feeling when you're typing a command and you get halfway through and you can't remember if it's a dash or two dashes or if the flag even exists in this CLI? And you stop. And you look at the terminal. And you realize you've been staring at it for four seconds and you don't know what cloud you're even in right now. That's where I was."*

Every person in that room has had this feeling. You've named something they've never heard named before. End with: *"So I reached for the one tool I already knew."*

### 2:00–5:00 | Why This Is Hard (And Not Your Fault)

Multi-cloud is hard because the clouds were not designed to coexist. Name it as a system problem, not a competence problem.

- AWS IAM is a policy document model
- Azure RBAC is a role assignment model
- GCP IAM is a binding model

These aren't the same thing wearing different clothes. Release the audience from self-blame. Then pivot: given that the system is incoherent, here's what I did.

### 5:00–10:00 | PowerShell as Cognitive Anchor

How you started connecting to each cloud. Lead with credential chaos — that's the first wall everyone hits.

Three CLIs, three auth models, three config file locations. Then show the moment you wrote your first wrapper and how much smaller the problem felt.

Key insight: **the verb-noun mental model is secretly a superpower.** It forces you to name the thing before you figure out how. That naming act is where clarity comes from.

### 10:00–18:00 | Same Same, But Different

Three service categories. Deep enough to be useful, shallow enough to keep moving.

| Concept | Azure | AWS | GCP |
|---|---|---|---|
| Compute | `Get-AzVM` | `Get-EC2Instance` | `gcloud compute instances list` |
| Storage | `Get-AzStorageAccount` | `Get-S3Bucket` | `gcloud storage ls` |
| Tags | `Get-AzTag` | `Get-EC2Tag` | Labels on resource |

For each: show the raw provider command, then show the wrapper. Let the audience see the translation layer working.

Frame this as **discovery, not instruction.** You're showing them the map you drew when you were lost.

### 18:00–21:00 | Terraform: Name the Relationship, Move On

Address it in under 3 minutes.

> *"Terraform standardizes infrastructure. PSCumulus standardizes how humans interact with infrastructure across clouds."*

One concrete example: post-deploy tagging compliance check, or drift detection piped into a report. Then move.

> **Consider cutting Terraform entirely** and going deeper on one service comparison. Depth over breadth in a Fast Focus. Always.

### 21:00–23:30 | Where the Abstraction Breaks

**Do not cut this section under time pressure.**

Every 100-level talk presents the solution. Yours shows the failure — and explains why the failure is okay.

The specific failure: IAM/identity. You cannot write `Get-CloudPermission` and have it mean the same thing across all three providers. So you wrote three clearly named functions and stopped apologizing:

```powershell
Get-AzureRoleAssignment
Get-AWSPolicyAttachment
Get-GCPIAMBinding
```

The lesson: **knowing when not to abstract is the actual skill.** Premature abstraction is as dangerous as no abstraction. This is the moment a 100-level talk transcends its label.

### 23:30–25:00 | Close: The Reframe

Don't summarize. They heard the talk.

> *"We spend a lot of time asking 'what's the right tool for the job.' I think there's an underrated second question: 'what's the tool I'll still trust when the job gets weird?' Those aren't always the same answer. Knowing the difference is worth thinking about."*

Repo link. Done. No summary slide.

---

## The Vulnerability Move

If you want to go from "really good Fast Focus" to "the talk people remember":

> *"I didn't reach for PowerShell because it was the best choice. I reached for it because I was scared and it was familiar. And I think that's okay. I think we should talk more about the role of fear in technical decision-making, because it drives more of our choices than we admit."*

Your career arc — neuroscience to sysadmin to package management to IAM to cloud security — is the source material. You've been perpetually at the edge of your competence. Use it.

---

## Module Status

**461/461 tests passing.** All commands implemented.

| Command | Providers | Notes |
|---|---|---|
| `Connect-Cloud` | Azure, AWS, GCP | Auth + context validation |
| `Get-CloudInstance` | Azure, AWS, GCP | Normalized compute inventory |
| `Get-CloudStorage` | Azure, AWS, GCP | Storage accounts / S3 / GCS buckets |
| `Get-CloudTag` | Azure, AWS, GCP | Tags and labels on any resource |
| `Get-CloudNetwork` | Azure, AWS, GCP | VNets / VPCs / GCP Networks |
| `Get-CloudDisk` | Azure, AWS, GCP | Managed Disks / EBS / Persistent Disks |
| `Get-CloudFunction` | Azure, AWS, GCP | Function Apps / Lambda / Cloud Functions |
| `Start-CloudInstance` | Azure, AWS, GCP | Instance lifecycle |
| `Stop-CloudInstance` | Azure, AWS, GCP | Instance lifecycle |

The module is further along than "good enough to demo." Show two or three commands live. Let the output objects sell the pattern.

### The Core API for the Deck

```powershell
# Same verb, same output shape, swappable provider
Get-CloudInstance -Provider Azure -ResourceGroup "prod-rg"
Get-CloudInstance -Provider AWS   -Region "us-east-1"
Get-CloudInstance -Provider GCP   -Project "my-project"

# Where it breaks — and that's okay
Get-AzureRoleAssignment -Scope "/subscriptions/..."
Get-AWSPolicyAttachment -UserName "adil"
Get-GCPIAMBinding       -Project "my-project"
```

---

## Slide Design Guardrails

- **One message per slide.** Two takeaways = two slides.
- **Six objects max** (headings, bullets, images, code blocks, table chunks).
- **Phrases over sentences.** The deck supports delivery; it doesn't duplicate it.
- **Make the key idea visually dominant.**

Open with a nearly blank slide or no slide at all. Do not start with an agenda.

Code should be cropped to the few lines the audience actually needs. Tables must stay simple. If a comparison table feels like reference material, split it. Long paragraphs are speaker notes, not slide content.

---

## Open Items

- [ ] Write the opening 90 seconds word for word — highest leverage writing in the talk
- [ ] Draft the "where it breaks" demo with the IAM example
- [ ] Write the closing provocation and test it out loud
- [ ] Fact-check pass the week before Summit

---

## Format Note

Planned as a **Fast Focus (25 min)**. If moved to General Session (45 min):

- Expand the comparative section from 3 services to 4-5
- Add a live demo loop instead of just showing code snippets
- Deepen the module demo — show actual output objects being piped
- Add Q&A buffer
- The emotional arc and thesis do not change

---

## Code Quality Findings (External Audit)

External LLM review conducted 2026-04-03. All findings verified against source.

### Finding 1 — Missing ShouldProcess on Start/Stop-CloudInstance ✅ Fixed

`Start-CloudInstance` and `Stop-CloudInstance` mutate real infrastructure but neither
exposed `-WhatIf` or `-Confirm`. Fixed by adding `SupportsShouldProcess` to
`[CmdletBinding()]` on both functions and wrapping `Invoke-CloudProvider` with
`$PSCmdlet.ShouldProcess(...)`.

### Finding 2 — Workflow publishes on every push to main ✅ Fixed

`test-and-publish.yml` triggered `Publish-Module` on every `main` push. Fixed by gating
the publish job on version tags (`v*.*.*`) and adding `workflow_dispatch` for manual
releases. Tests still run on every push and PR.

### Finding 3 — Build docs omit the CSS theme dependency ✅ Fixed

The "Build the Slides" section referenced `.\summit-2026.css` without explaining where to
get it. The file lives in [HeyItsGilbert/PSSummit2026](https://github.com/HeyItsGilbert/PSSummit2026)
and must be cloned locally before running the Marp commands. README updated to include
that prerequisite step.

### Finding 4 — No format/type data for PSCumulus.CloudRecord (deferred)

`ConvertTo-CloudRecord` inserts the type name but no `.ps1xml` format file exists.
Output works, but `Format-Table` uses default property selection. Worth addressing if the
module graduates beyond a demo — add `PSCumulus.Format.ps1xml` with a `TableControl` for
Name, Provider, Region, Status, Size and reference it in `FormatsToProcess`.

### Finding 5 — DefaultParameterSetName drift on Get-CloudStorage (deferred)

`Get-CloudStorage` uses `DefaultParameterSetName = 'AWS'` while all other commands use
`'Azure'`. No functional impact (Provider is always mandatory), but inconsistent. Fix
when touching that file for another reason.

### Finding 6 — Repetitive test patterns (deferred)

461/461 tests pass. Reviewer noted boilerplate validation/routing tests could be
converted to data-driven Pester `TestCases`. Not urgent; address post-talk if the module
sees wider use. Also consider adding a PSScriptAnalyzer lint step to CI at that point.
