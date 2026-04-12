---
marp: true
theme: summit-2026
paginate: true
header: PowerShell + DevOps Global Summit 2026
footer: '@adilio'
---

<!-- _class: title -->
# Cross-Cloud without Crossed Fingers

## Surviving Azure, AWS, and GCP with PowerShell

<p class="name">Adil Leghari</p>
<p class="handle">@adilio · Wiz</p>

<!--
All right. Thanks for being here. This is a talk about three cloud providers,
one keyboard, and what happens when you try to keep them all in your head at
the same time.

I'm Adil. I work at Wiz, on the solutions engineering side. Before that I did
a lot of PowerShell and sysadmin work, some of it in places where you don't
find out until 2am that you were supposed to know all three of these clouds.
That's the talk this was going to be, five years ago. Now it's a module, and
it's this.
-->

---

# The Frozen Terminal

```
PS /prod> aws ec2 describe-instances --resource-group prod-rg
                                     ^
                                     which cloud am I even in?
```

<!--
You know this moment. You're halfway through a command, you can't remember
whether this CLI uses one dash or two, you can't remember whether the flag you
want exists in this cloud, and for about four seconds, you just -- stop. You
look at the terminal. And for a beat, you don't know which cloud you're in
anymore.

That was me. It's still me sometimes. I was bouncing between Azure, AWS, and
GCP, and I didn't feel like I was learning one big system. I felt like I was
renting three different brains.

[Pause. Let the room laugh if it wants to.]

So I reached for the one tool I already trusted.
-->

---

# It's Not You

The clouds disagree on what a thing *is*.

| AWS | Azure | GCP |
|---|---|---|
| Policy documents | Role assignments | IAM bindings |

Same question. Three different grammars. IAM is just the loudest example.

<!--
Before we get into the module, one thing worth saying out loud: multi-cloud is
hard for a reason, and the reason is not that you are bad at it. The clouds
were not designed to coexist in your head. They have different philosophies of
identity, different resource hierarchies, different regional models, different
ideas of what a *resource* even is.

The loudest example is IAM. AWS expresses access as policy documents. Azure
expresses it as role assignments scoped to a hierarchy. GCP expresses it as
bindings. Those are not the same thing wearing different clothes. Those are
three different grammars.

Hold that example in your head. I'm going to come back to it at the end,
because it turns out to be the most important slide in this talk.
-->

---

<!-- _class: no_background -->
# Build on What Does Not Move

<div class="callout primary">
  <h3>Fluency is infrastructure.</h3>
</div>

<!--
So if the systems don't agree, I wanted an anchor that did. For me, the anchor
was PowerShell. Not because PowerShell is objectively best -- I don't believe
in "objectively best" for any tool. It was the tool I was most fluent in. My
hands already knew the shape. Verb-noun, pipeline, object out. The cognitive
cost was close to zero.

That's what I wanted for cross-cloud work. Not the best tool. The *fluent*
tool.

And that's the bet the rest of this talk is about. You build on what doesn't
move. Fluency is infrastructure.
-->

---

# PSCumulus

A thin, honest abstraction for Azure, AWS, and GCP.

```text
Connect-Cloud          Get-CloudInstance      Start-CloudInstance
Disconnect-Cloud       Get-CloudStorage       Stop-CloudInstance
Get-CloudContext       Get-CloudDisk
                       Get-CloudNetwork
                       Get-CloudFunction
                       Get-CloudTag
```

Same verb-noun. Same output shape. No pretending the providers are identical.

<!--
This is PSCumulus. Eleven public commands. Verb-noun, normalized output, no
pretending the providers are the same. Two things to call out before we look
at code.

First: the noun is always `Cloud<Thing>`. Never `Az`, never `EC2`, never `GCP`.
The public noun is a normalized concept. The native type still lives in
metadata.

Second: every read command returns the same output shape, regardless of which
cloud it hit.

That's the whole bet. Let's see what it looks like.
-->

---

# [DEMO] Native vs. Unified

```powershell
# Native
Get-AzVM
Get-EC2Instance
gcloud compute instances list --format=json

# Unified
Connect-Cloud     -Provider AWS, Azure, GCP
Get-CloudContext
Get-CloudInstance -Provider Azure -ResourceGroup prod-rg
Get-CloudInstance -Provider AWS   -Region us-east-1
Get-CloudInstance -Provider GCP   -Project contoso-prod
```

<!--
[Switch to terminal.]

These three commands on the left, you already know. Get-AzVM. Get-EC2Instance.
gcloud compute instances list --format=json. Three clouds, three surfaces,
three output shapes. I'm not going to run them. You know what they do. You
know what you *don't* know? What the same question looks like when it doesn't
care which cloud it's in.

[Run: Connect-Cloud -Provider AWS, Azure, GCP]

One call, three providers. This checks each provider for an existing session,
triggers the native login if there isn't one, and stores a normalized context
for each. The contexts live side by side -- connecting to one doesn't
disconnect the others.

[Run: Get-CloudContext]

Three providers. Each with an account, a scope, a region. All active.

[Run: Get-CloudInstance -Provider Azure -ResourceGroup 'prod-rg']
[Run: Get-CloudInstance -Provider AWS -Region 'us-east-1']
[Run: Get-CloudInstance -Provider GCP -Project 'contoso-prod']

Same command, three clouds. Same output shape every time.
-->

---

# [DEMO] One Pipe, Three Clouds

```powershell
Get-CloudInstance -All |
  Where-Object { -not $_.Tags['owner'] } |
  Format-Table Name, Provider, Region -AutoSize
```

Untagged production assets across every connected cloud.
One pipeline. Three providers. One output shape to filter against.

<!--
[Terminal.]

This is the moment the module earns its keep.

[Run: Get-CloudInstance -All]

That flag -- -All -- iterates every provider with stored context, calls each
backend, and streams a single pipeline of CloudRecord objects. One stream of
objects. Three clouds.

Once you have one stream, you can do this.

[Run: Get-CloudInstance -All | Where-Object { -not $_.Tags['owner'] } | Format-Table Name, Provider, Region -AutoSize]

Untagged production assets across every cloud I'm connected to. The tag key
'owner' works the same whether the source was an AWS tag, an Azure tag, or a
GCP label -- that normalization is the point. Three different cloud APIs. One
filter. One answer.

[Run: Show-FleetHealth]

This isn't one trick. The CloudRecord shape composes into any pipeline you
already know how to write. Group-Object, Sort-Object, Where-Object,
Select-Object. The mental model is PowerShell. The data is multi-cloud.
-->

---

# The Shared Shape

`PSCumulus.CloudRecord`

| Name | Provider | Region | Status | Size | CreatedAt | Tags | Metadata |
|---|---|---|---|---|---|---|---|
| web-01 | Azure | eastus | Running | Standard_B2s | 2026-03-01 | {env:prod} | … |
| api-01 | AWS | us-east-1 | Running | t3.small | 2026-02-18 | {env:prod} | … |
| worker-01 | GCP | us-central1-a | Running | e2-medium | 2026-03-10 | {env:prod} | … |

Seven safe columns. One honest `Metadata` property for everything else.

<!--
That shape has a name. PSCumulus.CloudRecord. Eight fields. Name, Provider,
Region, Status, Size, CreatedAt, Tags, Metadata.

Seven of those are what you can safely filter and group against across clouds,
because they exist cleanly in all three. The eighth -- Metadata -- is where
the honest provider-native stuff lives. Your Azure resource group. Your AWS
VPC ID. Your GCP zone. Those are real. They matter. They just don't belong in
the first seven columns, because they don't exist across all three clouds.
Putting them there would be a lie.
-->

---

# Why the Name Matters

- `Get-CloudInstance` ← public abstraction
- ~~`Get-VM`~~ ← already owned by Hyper-V
- ~~`Get-AzureInstance` / `Get-EC2Instance`~~ ← provider marketing

<!--
Quick aside on the naming, because someone always asks.

I picked Get-CloudInstance, not Get-VM. Two reasons. First, Get-VM is already
owned by the Hyper-V world in PowerShell. I didn't want this module pretending
it owned that noun. Second, the public noun is a normalized cloud concept, not
a vendor name. CloudInstance tells the truth about what the abstraction is.

I had that argument with myself for about ten minutes. Then I called it
Get-CloudInstance.
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
| IAM | `Get-AzRoleAssignment` | `Get-IAMPolicy` | `gcloud projects get-iam-policy` | **—** |

The test: do the underlying philosophies overlap enough that a normalized answer is still honest?

<!--
Every command in PSCumulus had to pass a test: do the underlying CSP
philosophies behind this concept overlap enough that a normalized answer is
still honest?

For compute, yes. All three clouds define an instance as something that runs,
has a name, a region, a status, a size. The philosophies align. Get-CloudInstance
exists.

For storage, disks, networks, functions, tags -- same story, with increasing
amounts of seam showing at the edges. But the core concept is close enough
that normalization isn't lying.

Now look at the last row. IAM. There's a dash where a PSCumulus command would
be. The human question is the same -- who has access? That doesn't change
across clouds. But the answer can't be normalized.
-->

---

# Why the Dash Is the Point

- **AWS** → policy documents (JSON, attached)
- **Azure** → role assignments (hierarchical, inherited)
- **GCP** → IAM bindings (resource-scoped, member + role)

<div class="callout tertiary">
  If the normalized object would be mostly <code>Metadata</code>,
  the abstraction is too weak to deserve a first-class command.
</div>

<!--
Let me make the IAM thing concrete.

AWS expresses access as policy documents -- JSON objects that describe what
actions are allowed or denied on what resources, attached to users, groups, or
roles.

Azure expresses access as role assignments -- a principal bound to a named
role at a specific scope in the resource hierarchy, inherited downward through
subscriptions and resource groups.

GCP expresses access as IAM bindings on a resource -- member and role pairs,
sometimes conditional.

Different scoping. Different inheritance. Different mental models. If I wrote
Get-CloudPermission anyway, either I'd flatten it to the least common
denominator and lose the scoping that makes it useful, or I'd stuff the real
answer into Metadata and the top-level object would be an empty wrapper.

There's a rule I use. If the normalized object would be mostly Metadata, the
abstraction is too weak to deserve a first-class command. That's why there's
no Get-CloudPermission. Instead, three explicit provider-native commands --
Get-AzureRoleAssignment, Get-AWSPolicyAttachment, Get-GCPIAMBinding. Three
seams, left visible.

The module is useful because it refuses to lie. Knowing when *not* to abstract
is the actual skill. It's also, honestly, the harder one.
-->

---

# Not Terraform's Job

<div class="callout secondary">
  <h3>Terraform — desired state, provisioning, lifecycle</h3>
  <h3>PSCumulus — operator intent, interactive querying, shared shape</h3>
</div>

Different layer. Not opposition.

<!--
Someone is usually thinking: why not Terraform? Terraform solves a different
problem.

Terraform standardizes *infrastructure*. PSCumulus standardizes *how a human
interacts with* infrastructure once it exists. Terraform gives you desired
state, provisioning, drift correction. PSCumulus gives you an operational
shell with consistent ergonomics across three clouds.

Terraform is not an operational shell. PSCumulus is intentionally behaving
like one. Different layer. Not opposition.
-->

---

# What This Does Not Do

<div class="primary-list">

- No cost surface
- No unified health / status surface
- No write commands for most inventory queries
- No cross-cloud search-by-name
- No IAM

</div>

<!--
Before I land this, let me name what PSCumulus doesn't do -- because the
people most likely to ask deserve a straight answer.

There's no cost surface. There's no unified health or status surface. The
module is read-oriented; most inventory queries don't have corresponding
write commands. There's no cross-cloud search by name. And there's no IAM,
for the reason we just talked about.

Some of those are roadmap. Some are deliberate. None of them are hidden.
-->

---

<!-- _class: no_background -->
# The Lens

<div class="callout gradient">
  What is the tool you will still trust when the job gets weird?
</div>

<!--
I want to leave you with something that isn't a summary.

We spend a lot of time in this field asking what the right tool is for a given
job. And it's a good question. But there's another one I think about more now.

What is the tool you will still trust when the job gets weird? When you're on
call and the environment is half-configured and you cannot remember which
cloud you're supposed to be in. When you need to move fast and you genuinely
cannot afford a mistake, and you need your hands to know what to do without
looking it up.

Those are the moments where fluency matters more than optimality. And fluency
is built over time, on tools you already know.

For me, that tool was PowerShell. The module you just saw is just the map I
drew. I hope some of it is useful to you.
-->

---

<!-- _class: title -->
# github.com/adilio/PSCumulus

<p class="handle">@adilio · Wiz</p>

*Slides and talk track linked in the repo. Thanks.*

<!--
Repo's at github.com/adilio/PSCumulus. Slides and the talk track are in there
too. Thanks for listening.
-->
