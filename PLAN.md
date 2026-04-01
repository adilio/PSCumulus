# Cross-Cloud without Crossed Fingers: Talk Planning Document

> PowerShell Summit 2026 | April 13-16, Bellevue, WA
> Fast Focus | 25 Minutes | Level 100 (Beginner) | Session confirmed

---

## Session Details

- **Full Title:** Cross-Cloud without Crossed Fingers: Surviving Azure, AWS, and GCP with PowerShell
- **Format:** Fast Focus (25 minutes), also accepted as General Session (45 min)
- **Level:** 100 (Beginner)
- **Primary Category:** Cloud
- **Additional Categories:** PowerShell, DevOps, Automation, Real-World Solutions
- **Submitted:** 31 Aug 2025 | Accepted: 27 Oct 2025

### Key Takeaways (as submitted)
- How to connect to Azure, AWS, and GCP with PowerShell
- The similarities and differences between common services in each cloud
- Ways Terraform and PowerShell can complement each other
- Lessons from building a PowerShell module for cross-cloud resource management

---

## What This Talk Is Actually About

On the surface: PowerShell across three clouds.

Underneath: **cognitive overload and the survival instinct to reach for familiar tools.**

The clouds are the setting. PowerShell is the coping mechanism. The real subject is: *what do you do when the map doesn't match the territory?*

This talk resonates beyond the PowerShell crowd because it speaks to a universal engineering experience: being handed responsibility you didn't ask for, in a system that wasn't designed to make sense.

---

## Core Thesis

> **"Build on what doesn't move."**

Extended version: *"Fluency is infrastructure. The tool you already trust is the one you should build on top of."*

One-liner for the hallway: *"You don't need to master three clouds. You need one stable lens to see through all three."*

---

## The Philosophical Claim

The industry has a bias toward "right tool for the job." Your talk is a **counter-argument to that orthodoxy** — not a rejection, but a complication.

When operating in a high-uncertainty environment, the cognitive cost of context-switching tools is real and underestimated. Every time you pick up a tool you're less fluent in, you're spending working memory on syntax instead of the problem.

PowerShell didn't make you faster because it's technically superior. It made you faster because **you already had the keystrokes in your hands.** Your fingers knew where things were. That freed your brain to think about cloud architecture instead of flag syntax.

**Familiarity is an underrated engineering virtue.** Say that out loud in the talk.

---

## The Surface Story and The Deep Story

Every great conference talk has two stories running in parallel.

**Surface story:** Here's how I use PowerShell to manage Azure, AWS, and GCP.

**Deep story:** Here's what I learned about myself and how I work when I was out of my depth.

The deep story is what people remember a year later. The surface story is what makes it feel useful in the moment. Weave both threads through the entire talk. Don't abandon the human thread when the first slide appears.

---

## Who Is In That Room

- Sysadmins and cloud engineers who've been handed multi-cloud responsibility they didn't ask for
- People who know PowerShell well but feel lost once they leave Azure
- People who feel like they're the only one who doesn't have it figured out

The last group is the most important. **Imposter syndrome is rampant in multi-cloud work** because the surface area is enormous and everyone pretends to know more than they do. This talk has a chance to say: *"yeah, it's actually just as messy for everyone."* That's a gift. Lead with it.

---

## Emotional Architecture

The technical content rides on top of an emotional arc. Map them together:

| Time | Technical Beat | Emotional Beat |
|---|---|---|
| 0:00 - 3:00 | The chaos origin story | **Recognition** — audience sees themselves |
| 3:00 - 6:00 | Why multi-cloud is genuinely hard | **Relief** — it's not their fault |
| 6:00 - 14:00 | Comparative services section | **Curiosity** — discovery, not instruction |
| 14:00 - 18:00 | The module and the abstraction | **Delight** — simplicity emerging from chaos |
| 18:00 - 22:00 | Where the abstraction breaks | **Respect** — they see you as a peer |
| 22:00 - 25:00 | Close and reframe | **Resonance** — they leave with a new lens |

---

## Slide Design Guardrails

Use the HeyItsGilbert `death-by-ppt` skill and the Summit 2026 Marp theme as active constraints while building the deck, not as polish at the end.

### Non-negotiables per slide

- **One message per slide.** If a slide has two takeaways, it is two slides.
- **Six objects max.** Count headings, bullets, images, icons, code blocks, diagrams, and table chunks.
- **Prefer phrases over sentences.** The deck should support spoken delivery, not duplicate it.
- **Make the key idea visually dominant.** The most important thing should be the largest or highest-contrast element.
- **Density matters more than slide count.** More slides is fine if each one is easy to absorb.

### What this means for this talk

- Open with a nearly blank slide or no slide at all. Do not start with an agenda.
- Comparative slides should show one concept at a time: compute, then storage, then tagging.
- Code should be cropped to the few lines the audience actually needs to see.
- Tables must stay simple. If a comparison table starts to feel like reference material, split it.
- Any slide that feels like something you would read aloud should be rewritten into keywords and speaker notes.

### Pacing heuristics

- Alternate between story slides, comparison slides, and proof slides so the deck never gets visually monotonous.
- Use "breathing room" slides after any dense comparison or code example.
- Keep the IAM failure section visually cleaner than the success section so the contrast helps the lesson land.

---

## Structural Flow

### 0:00 - 2:00 | The Wreck

**Don't open with a slide. Open with a sensation.**

Describe the specific physical and cognitive experience of being lost in unfamiliar tooling. Not a situation — a feeling.

> *"You know that feeling when you're typing a command and you get halfway through and you can't remember if it's a dash or two dashes or if the flag even exists in this CLI? And you stop. And you look at the terminal. And you realize you've been staring at it for four seconds and you don't know what cloud you're even in right now. That's where I was."*

This is not a situation. It's a feeling every person in that room has had. You've named something they've never heard named before. From this moment, they're with you.

The toddler road trip metaphor lands here. End the opening with: *"So I reached for the one tool I already knew."*

---

### 2:00 - 5:00 | Why This Is Hard (And Not Your Fault)

Multi-cloud is hard because **the clouds were not designed to coexist.** They have different opinions about identity, networking, regions, and even what counts as a "resource."

Acknowledge this directly. Name it as a system problem, not a competence problem.

- AWS IAM is a policy document model
- Azure RBAC is a role assignment model
- GCP IAM is a binding model

These are not the same thing wearing different clothes. They're genuinely different philosophies.

Release the audience from self-blame. Then pivot to: given that the system is incoherent, here's what I did.

---

### 5:00 - 10:00 | PowerShell as Cognitive Anchor

How you started connecting to each cloud. Lead with credential chaos — that's the first wall everyone hits.

Show the three auth models side by side:
- `Connect-AzAccount`
- `Set-AWSCredential`
- `gcloud auth login` or `gcloud auth application-default login`

Three CLIs, three auth models, three config file locations. Then show the moment you wrote your first wrapper function and how much smaller the problem felt.

Key insight to surface here: **the verb-noun mental model is secretly a superpower.** It forces you to name the thing you're trying to do before you figure out how. That naming act is where clarity comes from.

---

### 10:00 - 18:00 | Same Same, But Different

The comparative meat of the talk. Pick three service categories. Go deep enough to be useful, shallow enough to keep moving.

**Recommended picks:**
1. Compute
2. Storage
3. Tagging / Resource metadata (high practical value, often overlooked)

| Concept | Azure | AWS | GCP |
|---|---|---|---|
| Compute | `Get-AzVM` | `Get-EC2Instance` | `gcloud compute instances list` |
| Storage | `Get-AzStorageAccount` | `Get-S3Bucket` | `gcloud storage ls` |
| Tags | `Get-AzTag` | `Get-EC2Tag` | Labels via REST |

For each: show the raw provider command, then show your wrapper. Let the audience see the translation layer working.

Frame this as **discovery, not instruction.** You're showing them the map you drew when you were lost.

---

### 18:00 - 21:00 | Terraform: Name the Relationship, Move On

Terraform is an elephant in the room. Address it in under 3 minutes.

One clear framing: *"PowerShell is the shell around the shell. Terraform provisions. PowerShell operates."*

One concrete example: a post-deploy tagging compliance check, or drift detection piped into a report.

**Do not demo the integration.** Name the relationship, show one real use, and move. Every minute spent on Terraform is a minute not spent on the human story.

> **Consider cutting Terraform entirely** and using those minutes to go deeper on one service comparison. Depth over breadth in a Fast Focus. Always.

---

### 21:00 - 23:30 | Where the Abstraction Breaks

**This is the best section and the most likely to get cut under time pressure. Do not cut it.**

Every 100-level talk presents the solution. Yours will show the failure — and explain why the failure is okay.

**The specific failure to show: IAM/identity.**

You cannot write `Get-CloudPermission` and have it mean the same thing across all three providers. You tried. It became a mess. So you wrote three clearly named functions and stopped apologizing for it:

```powershell
Get-AzureRoleAssignment
Get-AWSPolicyAttachment
Get-GCPIAMBinding
```

The lesson: **knowing when not to abstract is the actual skill.** Premature abstraction is as dangerous as no abstraction. The module taught you where the real differences live. That's more valuable than a clean API.

This is the moment where a 100-level talk transcends its label. A 400-level engineer would want to watch this section.

---

### 23:30 - 25:00 | Close: The Reframe

**Do not summarize. They heard the talk.**

End with a provocation. Something that opens a question rather than closing one.

> *"We spend a lot of time asking 'what's the right tool for the job.' I think there's an underrated second question: 'what's the tool I'll still trust when the job gets weird?' Those aren't always the same answer. Knowing the difference is worth thinking about."*

Then: repo link. Done.

No "any questions?" No summary slide. Just that thought, hanging in the air, and your laptop closed.

---

## The Vulnerability Move

If you want to go from "really good Fast Focus" to "the talk people remember from Summit 2026":

**Be more vulnerable than feels comfortable.**

> *"I didn't reach for PowerShell because it was the best choice. I reached for it because I was scared and it was familiar. And I think that's okay. I think we should talk more about the role of fear in technical decision-making, because it drives more of our choices than we admit."*

You have the credibility to say this. Your career arc — neuroscience to sysadmin to package management to IAM to cloud security — is the source material. You've been perpetually at the edge of your competence. That's not a liability. Use it.

---

## The Module: Design and Role

### Role in the Talk

The module is **evidence, not conclusion.** Specifically: evidence that the cognitive anchor strategy works.

Building `Get-CloudInstance` and making it work across three providers forces you to answer: *what is a compute instance, really?* Name, region, status, size. That's it. Everything else is provider-specific noise.

**The abstraction is a learning tool.** The act of building it forced conceptual clarity. That's the real insight — not "use this module," but "building this taught me more about cloud infrastructure than any certification."

### Module as Character

Don't present it as a polished artifact. Tell its story:

- Started as a desperate hack, written at 11pm
- A single function because you were tired of looking up the AWS equivalent of `Get-AzVM`
- It grew. It broke when you added GCP. You refactored it
- You realized you'd accidentally documented your own mental model of cloud infrastructure

That's a better story than "here's a module I built."

### Repo Name Candidates

Shortlisted from brainstorm (PSX-style, cloud noun pattern):

- **PSCirrus** — cirrus clouds are high-altitude, span everything, sounds fast and light. Matches the thin abstraction layer design philosophy. Recommended.
- **PSNimbus** — more substantial sounding, strong runner-up
- **PSStratus** — layered clouds, layered abstraction
- **PSXCloud** — explicit, the X implies cross/multi
- **CloudShim** — honest about what it does, no PS prefix

Treat availability as a point-in-time check, not a permanent fact. Re-verify package and repo availability before publishing anything externally.

---

### Proposed Structure

**Name candidates:** `PSCirrus` | `PSNimbus` | `CloudShim`

```
CrossCloud/
  CrossCloud.psd1
  CrossCloud.psm1
  Private/
    Connect-AzureBackend.ps1
    Connect-AWSBackend.ps1
    Connect-GCPBackend.ps1
  Public/
    Connect-Cloud.ps1
    Get-CloudInstance.ps1
    Get-CloudStorage.ps1
    Get-CloudTag.ps1
```

### Design Principles

- Consistent output objects: `PSCustomObject` with standard properties across all providers
  - `Name`, `Provider`, `Region`, `Status`, `Size`, `CreatedAt`
- Provider param on every public function, not baked into the noun
- No hard dependencies beyond official SDKs: `Az`, `AWS.Tools.*` — GCP handled via `gcloud` CLI wrapping (see GCP tooling note below)
- Explicit over clever: when abstraction gets messy, write three clear functions

### Deck Implementation Notes

Build the slides in Marp with the Summit theme from the start:

- Front-matter should include `marp: true`, `theme: summit-2026`, and `paginate: true`
- Use `<!-- _class: title -->` for the opening slide rather than inventing a custom title layout
- Prefer the theme's callouts, branded list styles, and text emphasis utilities over ad hoc HTML/CSS
- Use `header:` and `footer:` intentionally, but avoid cluttering minimal slides with repeated metadata
- Default background treatment should follow the theme; use `<!-- _class: no_background -->` only when it improves contrast or focus
- Treat long paragraphs as speaker-note material, not slide content

### The Core API Pattern

```powershell
# Same verb, same output shape, swappable provider
Get-CloudInstance -Provider Azure -ResourceGroup "prod-rg"
Get-CloudInstance -Provider AWS -Region "us-east-1"
Get-CloudInstance -Provider GCP -Project "my-project"

# Where it breaks — and that's okay
Get-AzureRoleAssignment -Scope "/subscriptions/..."
Get-AWSPolicyAttachment -UserName "adil"
Get-GCPIAMBinding -Project "my-project"
```

---

## PS Gallery Research: The Space Is Wide Open

The positioning still looks strong, but the claim should stay modest: there does not appear to be a widely adopted PowerShell module that offers a clean Azure/AWS/GCP abstraction for the narrow IaaS-style use case this talk is targeting. That is enough to justify the talk. It does **not** require proving that no similar code exists anywhere.

### What was searched and found

**Name check guidance:** treat names like CloudShim, PSNimbus, PSCirrus, PSStratus, and PolyCloud as candidates that must be re-checked close to publication. Avoid locking the talk strategy to any one name until that check is repeated.

**Names that exist but serve different purposes:**
- `PSCloudPC` — Windows 365 only (23,709 downloads)
- `PSCloudFlare` — Cloudflare API wrapper
- `PSCloudConnect` — Office 365/Azure credentials only
- `CloudBridge` — Oracle OCI migration tool, not cross-cloud abstraction

**GitHub near-miss worth noting:** `viciousviper/PowerShellCloudProvider` implements a unified PS filesystem provider across multiple clouds — but targets consumer storage (OneDrive, Google Drive, Box), not IaaS. Last updated 2015. The design pattern validates the technical approach even if the scope is different.

**Cross-cloud abstraction exists in other ecosystems** — for example Python's CloudBridge. That helps validate the pattern. Avoid overstating demand or uniqueness unless you have fresh evidence in hand.

### The competitive landscape summary

| Provider | PS Gallery module | Status |
|---|---|---|
| Azure | Az.\* | Actively maintained by Microsoft |
| AWS | AWS.Tools.\* | Actively maintained by Amazon |
| GCP | GoogleCloud / Cloud Tools for PowerShell docs still present | Less central in the PowerShell ecosystem; verify current support posture before citing it live |
| Cross-cloud abstraction | No obvious dominant module found | Good gap signal, but phrase carefully |

---

## GCP Tooling: Risk and Opportunity

GCP remains the awkward provider in a PowerShell-first workflow. Even if Cloud Tools for PowerShell still exists, it is much less central than `Az` and `AWS.Tools.*`, and many practitioners will already be reaching for the `gcloud` CLI or REST APIs.

**Decision:** for PSCumulus v1, the GCP layer should be treated as a `gcloud` adapter boundary. That is now the planned implementation path.

**What this means for the module:** wrap `gcloud` JSON output instead of building directly on REST or trying to invest in a PowerShell-specific Google SDK path. Direct REST calls are still possible later, but they introduce auth, pagination, and schema work you do not need for a 25-minute talk.

**What this means for the talk:** it strengthens the story that PowerShell is your stable lens even when the provider-specific experience is uneven.

> *"Azure and AWS both have mature PowerShell stories. GCP is where the seams show fastest. That friction is exactly why I wanted one familiar lens in front of all three."*

That framing is safer than citing a specific deprecation claim you may need to defend live.

### GCP implementation shape

Keep the implementation boring and explicit:

1. Verify `gcloud` is installed.
2. Verify the user is authenticated and a project has been supplied or resolved.
3. Invoke `gcloud ... --format=json --quiet`.
4. Parse JSON into PowerShell objects.
5. Normalize those objects into the PSCumulus record shape.

Do not mutate global `gcloud` config unless you have to. Prefer passing `--project` explicitly in module commands.

---

## Scope Risk Analysis: Is This a Mistake?

**Short answer: No — if you treat the talk and the module as different bets.**

### The talk is not a mistake

The research strengthens it. The point is not "nobody has ever tried this," it's "this remains a messy enough problem that the audience will recognize it immediately." Nobody expects a production-grade multi-cloud framework in a 25-minute 100-level Fast Focus. The module exists to prove a point and tell a story, not to ship to prod.

### The module has two versions — only one is a mistake

**Version A (right size):** A thin, opinionated abstraction over 5-6 operations you actually do repeatedly. Compute inventory. Storage listing. Tagging. Connection management. Intentionally narrow. Ships in a weekend. Honest about what it doesn't do. Good talk demo. This is not a mistake.

**Version B (trap):** A general-purpose cloud management framework that tries to normalize everything across all three providers. Infinitely scoped. Never ships. Quietly abandoned six months after Summit. This is a mistake.

The research confirms Version B is a mistake. Build Version A.

### The real risks, named honestly

1. **GCP is the least straightforward backend.** The sustainable v1 answer is a `gcloud`-backed adapter, which is practical but still adds CLI dependency and parsing concerns.
2. **IAM/identity cannot be cleanly abstracted.** This is already the planned "where it breaks" section — lean into it rather than fighting it.
3. **Maintenance compounds fast.** AWS has 300+ sub-modules. Az has 7,000+ cmdlets. Never try to wrap all of it.
4. **The abstraction ceiling is real.** Networking has the same seams as IAM. Know your ceiling before you start.
5. **Live credibility depends on accuracy.** Avoid claims like "this does not exist anywhere" or "Google killed the module" unless you have re-verified them that week.

### The right framing for Summit

The module is a proof of concept, not a launch. Three working commands. Honest scope. The talk is the product; the module is the evidence.

---

## What to Build Before Summit (13 days)

The module only needs to exist enough to demo 2-3 commands convincingly. Prioritize:

1. `Connect-Cloud` — the credential abstraction. For GCP, validate `gcloud`, validate auth/context, and avoid owning the full auth flow.
2. `Get-CloudInstance` — the poster child for the abstraction working. GCP backend should wrap `gcloud compute instances list --project <project> --format=json`
3. `Get-CloudStorage` or `Get-CloudTag` — pick one based on which produces the cleanest cross-cloud output with the least provider-specific weirdness
4. One deliberate failure case — IAM — to support the "where it breaks" section

Don't polish. Ship enough to be honest about.

---

## Open Questions / Next Steps

- [ ] **Choose module name** — PSCirrus still feels strong, but re-check availability before you commit publicly
- [x] **Decide on GCP backend approach** — use `gcloud` CLI wrapping for v1 unless a later REST requirement appears
- [ ] Decide on Terraform: keep brief or cut entirely
- [ ] Pick the third service category (tagging recommended over networking)
- [ ] Write the opening 90 seconds word for word — this is the highest leverage writing in the talk
- [ ] Build `Connect-Cloud` and `Get-CloudInstance` as working prototypes
- [ ] Draft the "where it breaks" demo with the IAM example
- [ ] Write the closing provocation and test it out loud
- [ ] Add one current-source fact check pass the week before Summit so your live claims stay fresh

---

## Notes on Format

This was planned as a **Fast Focus (25 min)**. If it gets moved to General Session (45 min):

- Expand the comparative section from 3 services to 4-5
- Add a live demo loop instead of just showing code snippets
- Deepen the module demo — show actual output objects being piped
- Add a Q&A buffer at the end
- The emotional arc and thesis do not change
