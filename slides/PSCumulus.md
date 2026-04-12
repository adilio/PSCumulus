---
marp: true
theme: summit-2026
paginate: true
header: PowerShell + DevOps Global Summit 2026
footer: '@adil'
---

<!-- _class: title -->
# Cross-Cloud without Crossed Fingers

## Surviving Azure, AWS, and GCP with PowerShell

<p class="name">Adil</p>
<p class="handle">@adil</p>

<!--
Speaker notes:
- Open with the feeling, not the slide.
- Pause before advancing.
-->

---

<!-- _class: no_background -->
# The Wreck

I was lost in:

<div class="primary-list">

- three CLIs
- three auth models
- three mental maps

</div>

<!--
Speaker notes:
- Describe the terminal paralysis moment in concrete physical terms.
- "I felt like I was renting three different brains."
- End with: "So I reached for the one tool I already knew."
-->

---

# Why This Feels Hard

<div class="callout gradient">
  <h3>Multi-cloud is not hard because you are bad at it.</h3>
  <p>The systems disagree at a conceptual level.</p>
</div>

<!--
Speaker notes:
- Say: "This is a systems problem, not a competence problem."
- The goal here is relief.
-->

---

# Same Problem, Different Philosophy

| Cloud | IAM shape |
|---|---|
| AWS | Policy documents |
| Azure | Role assignments |
| GCP | Bindings |

<!--
Speaker notes:
- Keep this verbal and short.
- The point is relief, not a deep IAM lecture.
- "These are not the same thing wearing different clothes."
-->

---

# Why PowerShell

<div class="secondary-list">

- familiar keystrokes
- familiar verb-noun shape
- less syntax panic

</div>

<!--
Speaker notes:
- PowerShell was not "the best" in some abstract sense.
- It was the tool I was most fluent in.
- Familiarity reduced syntax overhead.
-->

---

# Stable Lens

<div class="callout primary">
  <h3>Fluency is infrastructure.</h3>
  <p>Build on what does not move.</p>
</div>

<!--
Speaker notes:
- This is the philosophical center of the talk.
- Slow down here.
-->

---

# Credential Chaos

```powershell
Connect-AzAccount
Set-AWSCredential -ProfileName prod
gcloud auth login
```

<!--
Speaker notes:
- Explain that the wrapper started here.
- The problem is not just three commands; it is three auth models.
- Do not add more commands to this slide.
-->

---

# Ask The Intent First

<div class="secondary-list">

- what am I trying to do?
- what stays stable?
- what is just provider naming?

</div>

<!--
Speaker notes:
- The verb-noun model forces the right question first.
- This is the bridge into the module.
-->

---

# The Abstraction Bet

> Build on what does not move.

<div class="callout primary">
  PowerShell was the stable lens.
</div>

<!--
Speaker notes:
- The module is evidence, not the point.
- The abstraction is there to reduce mental switching cost.
-->

---

# Compute, Native

```powershell
Get-AzVM
Get-EC2Instance
gcloud compute instances list --format=json
```

<!--
Speaker notes:
- Same operator intent, three different provider surfaces.
-->

---

# Compute, Unified

```powershell
Get-CloudInstance -Provider Azure -ResourceGroup "prod-rg"
Get-CloudInstance -Provider AWS -Region "us-east-1"
Get-CloudInstance -Provider GCP -Project "my-project"
```

<!--
Speaker notes:
- This is the first payoff moment.
- "I am not abstracting all cloud, I am abstracting repeated intent."
-->

---

# Cross-Cloud in One Pipeline

```powershell
Connect-Cloud -Provider AWS, Azure, GCP

Get-CloudInstance -All |
  Where-Object { $_.Tags['environment'] -eq 'prod' } |
  Group-Object Provider |
  Select-Object Name, Count
```

<!--
Speaker notes:
- This is the use case that justified building the module.
- One pipeline. Three clouds. One output shape to filter against.
- The Tags property is normalized across providers. 'environment' works the same
  whether the source was an AWS tag, an Azure tag, or a GCP label.
-->

---

# Shared Output Shape

| Name | Provider | Region | Status | Size | CreatedAt |
|---|---|---|---|---|---|
| web-01 | Azure | eastus | Running | Standard_B2s | 2026-03-01 |
| api-01 | AWS | us-east-1 | Running | t3.small | 2026-02-18 |
| worker-01 | GCP | us-central1-a | Running | e2-medium | 2026-03-10 |

<!--
Speaker notes:
- This is the real value, not just prettier command names.
- Same output shape means same human expectations and same scripting surface.
-->

---

# Why The Name Matters

<div class="primary-list">

- `Get-CloudInstance`
- not `Get-VM`
- not provider marketing names

</div>

<!--
Speaker notes:
- Hyper-V already owns Get-VM in the PowerShell ecosystem.
- CloudInstance tells the truth about the public abstraction.
- Native type still lives in metadata.
-->

---

# What Earns a Unified Command

| Resource | Azure | AWS | GCP | PSCumulus |
|---|---|---|---|---|
| Compute | `Get-AzVM` | `Get-EC2Instance` | `gcloud compute instances list` | `Get-CloudInstance` |
| Storage | `Get-AzStorageAccount` | `Get-S3Bucket` | `gcloud storage ls` | `Get-CloudStorage` |
| Disk | `Get-AzDisk` | `Get-EC2Volume` | `gcloud compute disks list` | `Get-CloudDisk` |
| Network | `Get-AzVirtualNetwork` | `Get-EC2Vpc` | `gcloud compute networks list` | `Get-CloudNetwork` |
| Functions | `Get-AzFunctionApp` | `Get-LMFunctionList` | `gcloud functions list` | `Get-CloudFunction` |
| Tags | `Get-AzTag` | `Get-EC2Tag` | `gcloud resource-manager tags` | `Get-CloudTag` |
| IAM | `Get-AzRoleAssignment` | `Get-IAMPolicy` | `gcloud projects get-iam-policy` | — |

<!--
Speaker notes:
- The test behind every command: do the underlying CSP philosophies behind this concept
  overlap enough that a normalized answer is still honest?
- For compute, storage, disk, network, functions, tags: yes. The concepts align.
- For IAM: the human question is the same. The answer can't be.
  AWS thinks in policy documents. Azure in role assignments scoped to a hierarchy.
  GCP in bindings. Those aren't the same concept wearing different clothes.
- The dash is not an omission. It's the test failing honestly.
-->

---

# Storage, Next

```powershell
Get-AzStorageAccount
Get-S3Bucket
gcloud storage ls
```

<!--
Speaker notes:
- Storage is useful, but this is where the seams start to show more.
- Keep it light here.
-->

---

# Metadata, Next

```powershell
Get-AzTag
Get-EC2Tag
# GCP labels via API or CLI output
```

<!--
Speaker notes:
- Metadata is operationally valuable and also slightly messy.
- Good example of "shared enough" without claiming sameness.
-->

---

# Why Not Terraform?

<div class="callout secondary">
  <h3>Terraform standardizes infrastructure.</h3>
  <p>PSCumulus standardizes interaction.</p>
</div>

<!--
Speaker notes:
- Terraform is not the wrong tool.
- It solves a different layer of the problem.
-->

---

# Different Layer

<div class="primary-list">

- Terraform: desired state
- PSCumulus: operator intent
- Terraform: provisioning
- PSCumulus: interactive querying

</div>

<!--
Speaker notes:
- "Terraform standardizes what exists."
- "PSCumulus standardizes how I think about and interact with what exists."
- "Terraform is not an operational shell. PSCumulus is intentionally behaving like one."
-->

---

# Output Matters

<div class="secondary-list">

- same command shape
- same output shape
- same operator mental model

</div>

<!--
Speaker notes:
- Terraform does not try to solve this problem.
- PSCumulus is about reducing cognitive switching cost during operations.
-->

---

# Where It Breaks

You cannot honestly unify IAM into one neat noun.

<!--
Speaker notes:
- This is the credibility section.
- Good abstraction has edges.
-->

---

# Failure Is The Lesson

```powershell
Get-AzureRoleAssignment
Get-AWSPolicyAttachment
Get-GCPIAMBinding
```

<div class="callout tertiary">
  Knowing when not to abstract is the actual skill.
</div>

<!--
Speaker notes:
- The module is useful because it refuses to lie.
- The clouds are genuinely different systems.
-->

---

# The Reframe

What is the tool you will still trust when the job gets weird?

<!--
Speaker notes:
- Do not summarize the whole talk.
- Leave them with the lens, not the table of contents.
-->

---

# Thanks

<div class="checklist">

- repo link
- talk link
- questions after

</div>

<!--
Speaker notes:
- Keep the finish simple.
- End on the previous slide's thought, not on housekeeping.
-->
