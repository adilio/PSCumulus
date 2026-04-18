# Talk Track — Cross-Cloud without Crossed Fingers

Continuous 25-minute spoken track for the PowerShell + DevOps Global Summit 2026 session.

Written for the voice: short sentences, contractions, breath marks implied by paragraph breaks. Stage directions in [brackets]. `[laugh beat]` means let the line land and don't step on it — if the room doesn't laugh, keep moving, don't flinch. The whole track is written to sound natural when spoken, not read.

**Running constraint.** Microsoft, AWS, and Google engineers are all in the room. The framing is always *"here's the complexity we're all navigating together,"* never *"here's why $CLOUD made your life hard."* Nobody's cloud is the villain. The villain is the inherent difficulty of three independently-evolved systems not lining up.

---

## Timing map

```
0:00 – 1:45    Hook + frozen terminal                      (Slides 1–2)
1:45 – 4:00    Why multi-cloud breaks your head            (Slide 3)
4:00 – 5:30    The anchor and the bet                      (Slides 4–5)
5:30 – 9:30    DEMO A — native vs. unified                 (Slide 6)
9:30 – 13:30   DEMO B — one pipe, three clouds             (Slides 7–8)
13:30 – 15:00  Why the name matters                        (Slide 9)
15:00 – 17:00  What earns a unified command                (Slide 10)
17:00 – 19:30  Why the dash is the point                   (Slide 11)
19:30 – 20:30  Not Terraform's job                         (Slide 12)
20:30 – 22:30  What PSCumulus does not do                  (Slide 13)
22:30 – 24:30  The lens                                    (Slide 14)
24:30 – 25:00  Close + repo                                (Slide 15)
```

---

## 0:00 – 1:45 · Hook

*[Lights. Walk on. Slide 1 — Title.]*

All right. Thanks for being here.

This is a talk about three cloud providers, one keyboard, and the specific feeling of typing a command and realizing halfway through that you have no idea which cloud you're actually in.

I'm Adil. I work at Wiz on the solutions engineering side. Before that I did a long stretch of PowerShell and sysadmin work — some of it in environments where you find out at 2am, not before, that you were supposed to know all three of these clouds. That was the talk I almost gave, five years ago. It would have been worse. Now it's a module, and it's this.

*[Advance to Slide 2 — The Frozen Terminal.]*

Look at that command. Nobody wrote that on purpose. That command is what happens when you were in Azure ten minutes ago, you're in AWS now, and your fingers haven't been told yet.

You know this moment. You're halfway through a command. You're staring at the flag you just typed. And you genuinely cannot remember whether this CLI wants one dash or two. You can't remember if it's `--region` or `-Region` in this one. You're *pretty sure* this flag exists. You're not sure it exists *here*. And for about four seconds you just — stop.

*[laugh beat]*

And for that beat, you don't know which cloud you're in anymore.

That was me. It's still me, sometimes. I once spent ten minutes debugging a `gcloud` command that wasn't working, and it wasn't working because it was an `az` command. [laugh beat] I was bouncing between these three clouds, and I didn't feel like I was learning one big system. I felt like I was renting three different brains, and one of them was always offline.

So I reached for the one tool my hands already trusted.

---

## 1:45 – 4:00 · Why multi-cloud breaks your head

*[Advance to Slide 3 — It's Not You.]*

Before we get into the module, one thing I want to say out loud, because it gets left out of a lot of multi-cloud talks.

Multi-cloud is hard for a reason, and the reason is not that you are bad at it.

These three clouds were not designed to coexist in one person's head. They were designed independently, by different companies, at different times, with different first customers and different very-reasonable answers to very-fundamental questions. *What is a resource? How is it scoped? Who owns it? How do you grant someone access to it?* Each of these clouds answered those questions carefully — and separately.

That is not a criticism of any of them. It's what happens when three excellent teams solve the same problem in parallel. All three of those teams are, statistically, in this room. [laugh beat] I'm not throwing anybody under a bus today. The bus is the problem space itself.

The loudest example is identity. AWS expresses access as policy documents. Azure expresses access as role assignments scoped to a hierarchy. GCP expresses access as bindings. Those three approaches are not the same idea wearing different clothes. They are three different grammars for the same English sentence — *"who can do what to this thing?"*

Hold that example in your head. I'm coming back to it in about fifteen minutes, because it turns out to be the single most important slide in this talk. And not for the reason you probably think right now.

---

## 4:00 – 5:30 · The anchor and the bet

*[Advance to Slide 4 — Fluency is Infrastructure.]*

So if the systems don't agree, I want an anchor that does.

For me, that anchor was PowerShell. Not because PowerShell is objectively best — I don't believe in "objectively best" for any tool. [laugh beat] If you use bash, we're still friends. If you use Python, still friends. If you've quietly written your own CLI in Rust because you don't trust anybody's tooling, we are *especially* still friends.

PowerShell is just the tool I'm most fluent in. My hands already know the shape: verb-noun, pipeline, object out. The cognitive cost of a PowerShell command is, for me, close to zero. That's what I wanted for cross-cloud work. Not the best tool on paper. The *fluent* tool in my hands.

That's the bet the rest of this talk is about. When the systems underneath you don't hold still, you build on the thing that does. For me, that's PowerShell. For you, it could be something else. The idea travels. Fluency is infrastructure.

*[Advance to Slide 5 — PSCumulus.]*

So here's the module. It's called PSCumulus — because I needed a name, "cumulus" was the only cloud word nobody had taken, and "PS" is how every PowerShell module legally has to start. [laugh beat] I know.

Eleven public commands. Deliberately small. The first version had about twenty, and I cut half of them, and the half I cut turned out to be more of this talk than the half that's left.

Two things to flag before we look at code.

First: the noun is always `Cloud<Thing>`. Never `Az`. Never `EC2`. Never `GCP`. The public noun is a normalized concept. The native type still lives in metadata, because it still exists, and pretending it doesn't would be worse.

Second: every read command returns the same output shape, regardless of which cloud it hit. That's the whole bet. Let me show you.

---

## 5:30 – 9:30 · Demo A — native vs. unified

*[Advance to Slide 6 — Demo A. Switch to terminal.]*

The three commands on the left — `Get-AzVM`, `Get-EC2Instance`, `gcloud compute instances list --format=json`. All three answer the same human question: *what compute do I have here?* All three answer it in completely different output shapes, with completely different authentication states behind them, stored in completely different config locations on my disk. [laugh beat]

I'm not going to run them. You know what they do. You know what you *don't* know? What the same question looks like when it doesn't care which cloud it's in.

*[Run: `Connect-Cloud -Provider AWS, Azure, GCP`]*

One call, three providers. Under the hood, this checks each provider for an existing session and triggers the native login if there isn't one. That's still three login flows — I can't fix that with a module, those aren't mine to fix. What I *can* do is stop making you remember which one is which.

And critically, the contexts live side by side. Connecting to AWS does not log you out of Azure. This is a small thing, and I once lost an afternoon to it, so here we are.

*[Run: `Get-CloudContext`]*

Three providers. Each with an account, a scope, a region. All active. Every column means the same thing in every row. That matters more than it sounds like it should.

*[Run: `Get-CloudInstance -Provider Azure -ResourceGroup prod-rg`]*

Azure instances. Name, Provider, Region, Status, Size, CreatedAt. Look at the shape.

*[Run: `Get-CloudInstance -Provider AWS -Region us-east-1`]*

Same command, AWS. Same shape.

*[Run: `Get-CloudInstance -Provider GCP -Project contoso-prod`]*

GCP. Same shape. The output doesn't know which cloud it came from until you look at the Provider column.

That's the whole move.

---

## 9:30 – 13:30 · Demo B — one pipe, three clouds

*[Advance to Slide 7 — Demo B.]*

Now the thing that actually justified building the whole module. If nothing else lands in this talk, this is the one.

*[Run: `Get-CloudInstance -All`]*

That flag — `-All` — iterates every provider that has a stored context, calls each backend, and streams one pipeline of `CloudRecord` objects. I'm not writing three loops. I'm not merging three output shapes with `Select-Object` gymnastics. I'm just getting one stream of objects.

And once you have one stream, you can do this.

*[Run:*
```powershell
Get-CloudInstance -All |
  Where-Object { -not $_.Tags['owner'] } |
  Format-Table Name, Provider, Region -AutoSize
```
*]*

That is *"find me the untagged production assets across every cloud I'm currently connected to,"* in three lines, across three cloud providers. The tag key `owner` works the same whether the source was an AWS tag, an Azure tag, or a GCP label. That normalization is the whole game.

The first time this worked end to end, I stared at it for about a minute. Then I ran it again, because I was pretty sure I was hallucinating. [laugh beat]

*[Run: `Show-FleetHealth` or `Get-CloudInstance -All | Group-Object Provider`]*

And here's what makes this actually trustworthy in production: every one of these operations supports `-WhatIf`. You can run the entire pipeline — across all three clouds — with `-WhatIf` first, see exactly what would happen, and then commit when you're ready. I didn't have to build that safety net. PowerShell gave it to me.

And this is the part I care about most. This isn't one trick. The `CloudRecord` shape composes into any pipeline you already know how to write. `Group-Object`. `Sort-Object`. `Where-Object`. `Select-Object`. The mental model is PowerShell, which you already have. The data is multi-cloud, which you didn't used to.

*[Back to slides. Advance to Slide 8 — The Shared Shape.]*

That shape has a name. `PSCumulus.CloudRecord`. Eight fields: Name, Provider, Region, Status, Size, CreatedAt, Tags, Metadata.

Seven of those are the fields you can safely filter and group against across clouds, because all three providers have a coherent answer for them. The eighth — Metadata — is where the honest provider-native stuff lives. Your Azure resource group. Your AWS VPC ID. Your GCP zone. Those are real, they're not lies, they just don't belong in the first seven columns because they don't exist in all three clouds. Promoting them there would be a lie.

The trick with this kind of abstraction isn't deciding what to include. It's deciding what to leave in Metadata without apologizing for it.

---

## 13:30 – 15:00 · Why the name matters

*[Advance to Slide 9 — Why the Name Matters.]*

Quick aside on the naming, because someone always asks.

I picked `Get-CloudInstance`, not `Get-VM`. Two reasons.

First: `Get-VM` is already owned by the Hyper-V world in PowerShell, and it has been for a long time. I was not going to have this module walk in and pretend it owned that noun. Too many people have muscle memory there, and some of them, again, are in this room.

Second: the public noun is a normalized *cloud* concept, not a vendor name. `CloudInstance` tells the truth about what the abstraction is. If I named it `Get-AzureInstance`, I'd be implying Azure was the main character. It isn't. Same for AWS, same for GCP. Nobody's the main character — that's the shape of the bet.

I had that argument with myself for about ten minutes in a text editor with no other humans present. [laugh beat] Then I called it `Get-CloudInstance` and got on with my life.

---

## 15:00 – 17:00 · What earns a unified command

*[Advance to Slide 10 — What Earns a Unified Command.]*

OK. This is the real content of the talk. If you only take one slide home, this is it.

Every command in PSCumulus had to pass a single test: *do the underlying cloud philosophies behind this concept overlap enough that a normalized answer is still honest?*

For compute — yes. All three clouds agree that a compute instance is a thing that runs, has a name, lives in a region, has a size, has a status. The philosophies align. `Get-CloudInstance` exists.

For storage — yes, with seams. Billing models differ, lifecycle policies differ, consistency guarantees differ. But the operator-level question, *what storage exists here*, translates. `Get-CloudStorage` exists.

For disks, networks, functions, tags — same story. Increasing amounts of seam showing at the edges, but the core concept is close enough that normalizing isn't lying. Those commands exist.

Now look at the last row. IAM. There's a dash where a PSCumulus command would be.

The human question — *who has access, and what can they do?* — is the same across all three clouds. But the answer can't be normalized. The underlying philosophies don't overlap.

That dash is not an omission. That dash is load-bearing.

---

## 17:00 – 19:30 · Why the dash is the point

*[Advance to Slide 11 — Why the Dash Is the Point.]*

Let me make the IAM thing concrete, because this is the part that sells me on the discipline.

All three of these are coherent on their own. Each is the right answer to the problem the team in front of it was solving. I'm not here to tell you any of them is wrong. I'm genuinely impressed by all three of them. They just don't compose.

AWS expresses access as policy documents. JSON objects declaring what actions are allowed or denied on what resources, attached to users, groups, or roles. Policy-first.

Azure expresses access as role assignments. A principal bound to a named role at a specific scope in a resource hierarchy, inherited downward through management groups, subscriptions, resource groups. Hierarchy-first.

GCP expresses access as bindings on a resource. Member and role pairs, sometimes conditional, attached at the resource level. Resource-first.

Different scoping. Different inheritance. Different mental models. Three good answers to the same question, each correct in its own grammar, none of them translatable into the others without losing information that actually matters.

If I wrote `Get-CloudPermission` anyway, one of two bad things would happen. Either I'd flatten everything to the least common denominator, and lose the scoping and inheritance that make the answer useful in the first place. Or I'd stuff the real answer into Metadata, and the top-level object would be this sincere, friendly wrapper with almost nothing in it. [laugh beat] Either way I'd be lying — just with different body language.

So there's a rule I use for decisions like this. *If the normalized object would be mostly Metadata, the abstraction is too weak to deserve a first-class command.* That's why there is no `Get-CloudPermission`. Instead, three explicit provider-native commands — `Get-AzureRoleAssignment`, `Get-AWSPolicyAttachment`, `Get-GCPIAMBinding`. Three seams, left visible, on purpose.

I think this is the actual skill of this kind of work. Knowing when *not* to abstract is harder than knowing when to. Because when you don't abstract, the slide looks empty, and you have to defend the empty space. [laugh beat] That empty space is a feature. The module is useful because it refuses to lie about the places where the clouds are genuinely, philosophically different.

---

## 19:30 – 20:30 · Not Terraform's job

*[Advance to Slide 12 — Not Terraform's Job.]*

Somebody is thinking it, so let's get it out of the way. *Why not Terraform?*

Terraform's great. I use Terraform. Terraform solves a different problem.

Terraform standardizes *infrastructure* — what exists, in what shape, managed as code. Desired state, provisioning, drift correction. PSCumulus standardizes *how a human interacts with* infrastructure once it already exists. An operational shell with consistent ergonomics across three clouds.

Terraform is not an operational shell. PSCumulus is deliberately behaving like one. Different layer. Not opposition. If your question is *"what should exist,"* reach for Terraform. If your question is *"what does exist, what shape is it in right now, and can I filter it before I have to page somebody"* — that's the shell, and that's where this lives.

---

## 20:30 – 22:30 · What this does not do

*[Advance to Slide 13 — What This Does Not Do.]*

Before I land this, let me name what PSCumulus doesn't do. The people most likely to ask these questions deserve a straight answer, and I would rather say it on stage than leave it for a GitHub issue that gets filed at 11pm tonight.

There's no cost surface. Cost across these three clouds is its own multi-hour talk, and it is not this one. [laugh beat]

There's no unified health or status surface. The provider status signals are shaped too differently to compose honestly.

`Start-CloudInstance` and `Stop-CloudInstance` both ship with full `-WhatIf` and `-Confirm` support. Build a pipeline that touches instances across all three clouds, run it with `-WhatIf`, and you see exactly what would happen before anything executes. That's the safety net that makes bulk cross-cloud operations trustworthy — and it's available today.

There's no cross-cloud search by name. And there's no IAM, for the reasons we just spent five minutes on.

Some of those are roadmap. Some are deliberate. None of them are hidden. Gaps named are gaps owned.

---

## 22:30 – 24:30 · The lens

*[Advance to Slide 14 — The Lens.]*

I want to leave you with something that isn't a summary.

We spend a lot of time in this field asking what the *right* tool is for a given job. It's a good question, and I don't want to talk anybody out of it. But there's another question I think about more now.

*What's the tool you will still trust when the job gets weird?*

When you're on call and the environment is half-configured and you cannot remember which cloud you're supposed to be in. When you need to move fast and you genuinely cannot afford a mistake, and you need your hands to already know what to do without you looking anything up.

Those are the moments where fluency matters more than optimality. And fluency is built over time, on tools you already know.

For me, that tool was PowerShell. The module you just saw is just the map I drew on top of it, with the places marked where the terrain stops cooperating. I hope some of it is useful to you. And if the only thing that travels back home is the *question* — what's the tool you'll still trust when the job gets weird — that's fine with me too.

---

## 24:30 – 25:00 · Close

*[Advance to Slide 15 — Repo.]*

Repo's at `github.com/adilio/PSCumulus`. Slides and the talk track are in there too, so you don't have to photograph anything. Thanks for listening.

*[End.]*

---

## Rehearsal & stage notes

**Cadence checks.**

- The first two minutes should be delivered nearly word-for-word, confidently, without looking at notes. That's the trust-builder.
- The demo blocks (minutes 5:30–13:30) must run without hesitation. Every command has been keyed in from muscle memory at least three times with `demo-setup.ps1` loaded.
- The IAM section (Slides 10–11) is the credibility beat of the whole talk. It should feel confident, not apologetic. That section is where the senior audience members decide whether this module — and this speaker — is serious.
- The close lands as a *thought*, not a *summary*. Resist every instinct to recap. Trust the audience to carry the question out of the room.

**Humor calibration.**

- If a `[laugh beat]` doesn't land, move on without flinching. Every line around a beat works whether the laugh happens or not.
- The humor is all rooted in recognition: four-second pauses, wrong CLIs, ten-minute debug sessions, three config file locations. None of it punches down at Azure, AWS, or GCP. If a line ever starts to feel like it's mocking a cloud, cut it live.
- The line "statistically, in this room" (Slide 3 / minute ~2:45) is a warm acknowledgment of the Summit audience. Make it warm. If it sounds even slightly pointed, it's not worth it.

**Pre-talk checklist.**

- Terminal pre-staged: 18pt+ font, dark theme, history cleared, `demo-setup.ps1` loaded, context seeded via `Connect-Cloud -Provider Azure, AWS, GCP`.
- Backup recording of the demo queued in a browser tab, ready to cut to if anything breaks.
- Decide and lock: suppress `Connect-Cloud` output with `$null = ...`, or show it. Pick one and rehearse it.
- Confirm provider iteration order (`Azure, AWS, GCP` is the module's fixed order) — mention it in one sentence on stage if the audience looks curious.
- Check the Summit projector's contrast before the session; adjust theme if needed.
- Slides run 1 through 15 in a dry run; all `[DEMO]` hand-offs feel natural.

**What to avoid.**

- Reading the slides aloud. The slides are a safety net for a live demo, not a canvas.
- Over-explaining PowerShell. This audience lives in it.
- Over-defending against Terraform. One slide, one beat, move on.
- Closing on housekeeping. The reframe line on Slide 14 is the last real thing in the room; Slide 15 is just a URL.

**Anticipated questions.**

- *Why not `Google.Cloud.PowerShell`?* — It's effectively unmaintained. The `gcloud` CLI is the honest adapter.
- *Why are aliases exported?* — They're interactive conveniences. Full names are canonical in scripts and docs.
- *Does `-All` respect some ordering?* — Yes, alphabetical by provider name, deliberately fixed so output is predictable regardless of connect order.
- *Why no `ShouldProcess` on `Start/Stop-CloudInstance`?* — `ShouldProcess` is already implemented. Both commands support `-WhatIf` and `-Confirm` for safe bulk operations.
- *Isn't this just another wrapper?* — It is *a* wrapper, honestly stated as such. The discipline is in what it refuses to wrap. See the dash.
