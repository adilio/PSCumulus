# Talk Track — Cross-Cloud without Crossed Fingers

Continuous 25-minute spoken track for the PowerShell + DevOps Global Summit 2026 session.

Written for speaking, not reading. Stage directions appear in [brackets]. Voice: direct, technically confident, dry where it helps. Not a script to read verbatim — a track that sounds natural when spoken.

---

## Timing map

```
0:00 – 1:30    Hook (Slides 1–2)
1:30 – 3:30    Why multi-cloud breaks your head (Slide 3)
3:30 – 5:00    PowerShell as anchor, PSCumulus as bet (Slides 4–5)
5:00 – 9:00    DEMO A — connect once, inventory once per provider (Slide 6)
9:00 – 13:30   DEMO B — -All, the shared pipeline, the shared shape (Slides 7–8)
13:30 – 15:00  Why the name matters (Slide 9)
15:00 – 17:00  What earns a unified command (Slide 10)
17:00 – 19:30  Why the dash is the point (Slide 11)
19:30 – 20:30  Not Terraform's job (Slide 12)
20:30 – 22:30  What PSCumulus does not do (Slide 13)
22:30 – 24:30  The lens (Slide 14)
24:30 – 25:00  Close + repo (Slide 15)
```

---

## 0:00 – 1:30 · Hook

[Lights. Walk on. Slide 1 — Title.]

> All right. Thanks for being here. This is a talk about three cloud providers, one keyboard, and what happens when you try to keep them all in your head at the same time.
>
> I'm Adil. I work at Wiz, on the solutions engineering side. Before that I did a lot of PowerShell and sysadmin work, some of it in places where you don't find out until 2am that you were supposed to know all three of these clouds. That's the talk this was going to be, five years ago. Now it's a module, and it's this.

[Advance to Slide 2 — The Frozen Terminal.]

> You know this moment. You're halfway through a command, you can't remember whether this CLI uses one dash or two, you can't remember whether the flag you want exists in this cloud, and for about four seconds, you just — stop. You look at the terminal. And for a beat, you don't know which cloud you're in anymore.
>
> That was me. It's still me sometimes. I was bouncing between Azure, AWS, and GCP, and I didn't feel like I was learning one big system. I felt like I was renting three different brains.

[Pause. Let the room laugh if it wants to.]

> So I reached for the one tool I already trusted.

---

## 1:30 – 3:30 · Why this is hard

[Advance to Slide 3 — It's Not You.]

> Before we get into the module, one thing worth saying out loud: multi-cloud is hard for a reason, and the reason is not that you are bad at it. The clouds were not designed to coexist in your head. They have different philosophies of identity, different resource hierarchies, different regional models, different ideas of what a resource even is.
>
> The loudest example is IAM. AWS expresses access as policy documents. Azure expresses it as role assignments scoped to a hierarchy. GCP expresses it as bindings. Those are not the same thing wearing different clothes. Those are three different grammars.
>
> Hold that example in your head. I'm going to come back to it at the end, because it turns out to be the most important slide in this talk.

---

## 3:30 – 5:00 · The anchor and the bet

[Advance to Slide 4 — Build on What Does Not Move.]

> So if the systems don't agree, I wanted an anchor that did. For me, the anchor was PowerShell. Not because PowerShell is objectively best — I don't believe in "objectively best" for any tool. It was the tool I was most fluent in. My hands already knew the shape. Verb-noun, pipeline, object out. The cognitive cost was close to zero.
>
> That's what I wanted for cross-cloud work. Not the best tool. The fluent tool.
>
> And that's the bet the rest of this talk is about. You build on what doesn't move. Fluency is infrastructure.

[Advance to Slide 5 — PSCumulus.]

> This is PSCumulus. Eleven public commands. Verb-noun, normalized output, no pretending the providers are the same. Two things to call out before we look at code.
>
> First: the noun is always `Cloud<Thing>`. Never `Az`, never `EC2`, never `GCP`. The public noun is a normalized concept. The native type still lives in metadata.
>
> Second: every read command returns the same output shape, regardless of which cloud it hit.
>
> That's the whole bet. Let's see what it looks like.

---

## 5:00 – 9:00 · DEMO A — native pain, unified relief

[Advance to Slide 6 — Demo A. Switch to terminal.]

> These three commands on the left, you already know. `Get-AzVM`. `Get-EC2Instance`. `gcloud compute instances list --format=json`. Three clouds, three surfaces, three output shapes. I'm not going to run them. You know what they do. You know what you *don't* know? What the same question looks like when it doesn't care which cloud it's in.

[Run: `Connect-Cloud -Provider AWS, Azure, GCP`]

> One call, three providers. This checks each provider for an existing session, triggers the native login if there isn't one, and stores a normalized context for each. The contexts live side by side — connecting to one doesn't disconnect the others.

[Run: `Get-CloudContext`]

> Three providers. Each with an account, a scope, a region. All active.

[Run: `Get-CloudInstance -Provider Azure -ResourceGroup 'prod-rg'`]

> Azure instances. Name, Provider, Region, Status, Size, CreatedAt. Notice the shape.

[Run: `Get-CloudInstance -Provider AWS -Region 'us-east-1'`]

> Same command, AWS. Same shape.

[Run: `Get-CloudInstance -Provider GCP -Project 'contoso-prod'`]

> GCP. Same shape. The output doesn't know which cloud it came from until you look at the Provider column.

---

## 9:00 – 13:30 · DEMO B — one pipe, three clouds

[Advance to Slide 7 — Demo B.]

> Now the thing that actually justified building the module.

[Run: `Get-CloudInstance -All`]

> That flag — `-All` — iterates every provider with stored context, calls each backend, and streams a single pipeline of CloudRecord objects. I'm not writing three loops. I'm not managing three output shapes. I'm just getting one stream of objects.
>
> And once you have one stream, you can do this.

[Run:
```powershell
Get-CloudInstance -All |
  Where-Object { -not $_.Tags['owner'] } |
  Format-Table Name, Provider, Region -AutoSize
```
]

> Untagged production assets across every cloud I'm connected to. The tag key `owner` works the same whether the source was an AWS tag, an Azure tag, or a GCP label — that normalization is the point. Three different cloud APIs. One filter. One answer.

[Run: `Show-FleetHealth`]

> And this is the part I care about most. This isn't one trick. The CloudRecord shape composes into any pipeline you already know how to write. `Group-Object`, `Sort-Object`, `Where-Object`, `Select-Object`. The mental model is PowerShell. The data is multi-cloud.

[Back to slides.]

---

## 13:30 – 15:00 · The shared shape & the name

[Advance to Slide 8 — The Shared Shape.]

> That shape has a name. `PSCumulus.CloudRecord`. Eight fields. Name, Provider, Region, Status, Size, CreatedAt, Tags, Metadata.
>
> Seven of those are what you can safely filter and group against across clouds, because they exist cleanly in all three. The eighth — Metadata — is where the honest provider-native stuff lives. Your Azure resource group. Your AWS VPC ID. Your GCP zone. Those are real. They matter. They just don't belong in the first seven columns, because they don't exist across all three clouds. Putting them there would be a lie.

[Advance to Slide 9 — Why the Name Matters.]

> Quick aside on the naming, because someone always asks.
>
> I picked `Get-CloudInstance`, not `Get-VM`. Two reasons. First, `Get-VM` is already owned by the Hyper-V world in PowerShell. I didn't want this module pretending it owned that noun. Second, the public noun is a normalized cloud concept, not a vendor name. `CloudInstance` tells the truth about what the abstraction is.
>
> I had that argument with myself for about ten minutes. Then I called it `Get-CloudInstance`.

---

## 15:00 – 17:00 · What earns a unified command

[Advance to Slide 10 — What Earns a Unified Command.]

> OK. Here's the real content of the talk.
>
> Every command in PSCumulus had to pass a test. The test was this: do the underlying CSP philosophies behind this concept overlap enough that a normalized answer is still honest?
>
> For compute, yes. All three clouds define an instance as something that runs, has a name, a region, a status, a size. The philosophies align. `Get-CloudInstance` exists.
>
> For storage — yes, with seams. The billing models and the lifecycle rules differ, but the operator intent — *what storage exists here* — maps. `Get-CloudStorage` exists.
>
> For disks, networks, functions, tags — same story. Increasing amounts of seam showing at the edges, but the core concept is close enough that normalization isn't lying. Those commands exist.
>
> Now look at the last row. IAM. There's a dash where a PSCumulus command would be.
>
> The human question is the same — who has access, and what can they do? That doesn't change across clouds. But the answer can't be normalized, because the underlying philosophies don't overlap.

---

## 17:00 – 19:30 · Why the dash is the point

[Advance to Slide 11 — Why the Dash Is the Point.]

> Let me make that concrete.
>
> AWS expresses access as policy documents — JSON objects that describe what actions are allowed or denied on what resources, attached to users, groups, or roles.
>
> Azure expresses access as role assignments — a principal bound to a named role at a specific scope in the resource hierarchy, inherited downward through subscriptions and resource groups.
>
> GCP expresses access as IAM bindings on a resource — member and role pairs, sometimes conditional.
>
> The scoping is different. The inheritance behavior is different. The mental model you need to reason about them is different. If I wrote `Get-CloudPermission` anyway, one of two things would happen. Either I'd flatten everything to the least common denominator and lose the scoping and inheritance that make the answer useful. Or I'd stuff the real answer into Metadata, and the normalized object on top would be an empty wrapper.
>
> There's a rule I use. If the normalized object would be mostly Metadata, the abstraction is too weak to deserve a first-class command. That's why there's no `Get-CloudPermission`. Instead, three explicit provider-native commands — `Get-AzureRoleAssignment`, `Get-AWSPolicyAttachment`, `Get-GCPIAMBinding`. Three seams, left visible.
>
> The module is useful because it refuses to lie about the places where the providers are genuinely different. Adding `Get-CloudPermission` would have been easy to do, and plausible-looking. It also would have been the thing that eventually burned the person who trusted the abstraction a little too far.
>
> Knowing when *not* to abstract is the actual skill. It's also, honestly, the harder one.

---

## 19:30 – 20:30 · Not Terraform

[Advance to Slide 12 — Not Terraform's Job.]

> At this point somebody is usually thinking: why not Terraform? Terraform solves a different problem.
>
> Terraform standardizes *infrastructure*. PSCumulus standardizes *how a human interacts with* infrastructure once it exists. Terraform gives you desired state, provisioning, drift correction. PSCumulus gives you an operational shell with consistent ergonomics across three clouds.
>
> Terraform is not an operational shell. PSCumulus is intentionally behaving like one. Different layer. Not opposition.

---

## 20:30 – 22:30 · What this does not do

[Advance to Slide 13 — What This Does Not Do.]

> Before I land this, let me name what PSCumulus doesn't do — because the people most likely to ask deserve a straight answer.
>
> There's no cost surface. There's no unified health or status surface. The module is read-oriented; most inventory queries don't have corresponding write commands. There's no cross-cloud search-by-name. And there's no IAM, for the reason we just talked about.
>
> Some of those are roadmap. Some are deliberate. None of them are hidden.

---

## 22:30 – 24:30 · The lens

[Advance to Slide 14 — The Lens.]

> I want to leave you with something that isn't a summary.
>
> We spend a lot of time in this field asking what the right tool is for a given job. And it's a good question. But there's another one I think about more now.
>
> What is the tool you will still trust when the job gets weird? When you're on call and the environment is half-configured and you cannot remember which cloud you're supposed to be in. When you need to move fast and you genuinely cannot afford a mistake, and you need your hands to know what to do without looking it up.
>
> Those are the moments where fluency matters more than optimality. And fluency is built over time, on tools you already know.
>
> For me, that tool was PowerShell. The module you just saw is just the map I drew. I hope some of it is useful to you.

---

## 24:30 – 25:00 · Close

[Advance to Slide 15 — Repo.]

> Repo's at `github.com/adilio/PSCumulus`. Slides and the talk track are in there too. Thanks for listening.

[End.]

---

## Rehearsal goals

- The first two minutes can be delivered nearly word-for-word without looking at notes.
- The demo blocks run without hesitation — every command has been keyed in from muscle memory at least three times.
- The IAM section (slides 10–11) feels confident, not apologetic. This is the credibility beat.
- The close lands as a thought, not a summary. Resist the urge to recap.

## Pre-talk checklist

- Terminal pre-staged: large font, dark theme, history clear, demo-setup loaded, context seeded.
- Backup recording of the live demo queued up in a browser tab, ready to cut to if anything breaks.
- Zoom/font size confirmed readable from the back row.
- `$null = Connect-Cloud …` suppression decided (suppress or show — pick one and stick to it).
- Slides advanced from 1 to 15 in a dry run; all `DEMO` hand-offs feel natural.

## What to avoid

- Reading the slides. The slides are a safety net for a live demo, not the canvas.
- Explaining PowerShell to the Summit audience. They already use it.
- Over-defending against Terraform. One slide, one beat, move on.
- Closing on "thanks" housekeeping. The reframe line is the last thing in the room.
