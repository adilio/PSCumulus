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
- Describe the terminal paralysis moment from the plan.
- End with: "So I reached for the one tool I already knew."
-->

---

# Why This Feels Hard

<div class="callout gradient">
  <h3>Multi-cloud is not hard because you are bad at it.</h3>
  <p>The systems disagree at a conceptual level.</p>
</div>

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
-->

---

# Why PowerShell

<div class="secondary-list">

- familiar keystrokes
- familiar verb-noun shape
- less syntax panic

</div>

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
- Do not add more commands to this slide.
-->

---

# The Abstraction Bet

> Build on what does not move.

<div class="callout primary">
  PowerShell was the stable lens.
</div>

---

# Compute

```powershell
Get-AzVM
Get-EC2Instance
gcloud compute instances list --format=json
```

---

# Compute, Unified

```powershell
Get-CloudInstance -Provider Azure -ResourceGroup "prod-rg"
Get-CloudInstance -Provider AWS -Region "us-east-1"
Get-CloudInstance -Provider GCP -Project "my-project"
```

---

# Shared Output Shape

| Name | Provider | Region | Status | Size | CreatedAt |
|---|---|---|---|---|---|
| web-01 | Azure | eastus | Running | Standard_B2s | 2026-03-01 |
| api-01 | AWS | us-east-1 | running | t3.small | 2026-02-18 |
| worker-01 | GCP | us-central1-a | RUNNING | e2-medium | 2026-03-10 |

<!--
Speaker notes:
- This is the payoff slide.
- Keep the table simple and legible.
-->

---

# Storage

```powershell
Get-AzStorageAccount
Get-S3Bucket
gcloud storage ls
```

---

# Metadata

```powershell
Get-AzTag
Get-EC2Tag
# GCP labels via API or CLI output
```

---

# Terraform, Briefly

<div class="callout secondary">
  <h3>Terraform provisions.</h3>
  <p>PowerShell operates.</p>
</div>

---

# Where It Breaks

You cannot honestly unify IAM into one neat noun.

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

---

# The Reframe

What is the tool you will still trust when the job gets weird?

---

# Thanks

<div class="checklist">

- repo link
- talk link
- questions after

</div>

