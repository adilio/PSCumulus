# Cross-Cloud without Crossed Fingers — Analysis & Rebuild

This document is a no-mercy critique of the talk as it exists at `main@HEAD`, followed by a full rebuild: revised structure, slide-by-slide deck content, a continuous 25-minute talk track, and demo/code recommendations.

The deliverables in the repo (`README.md`, `talk/presentation.md`, `talk/talk-track.md`) have been rewritten to match the recommendations in Phase 2. This file is the record of the decisions behind those rewrites.

---

## PHASE 1 — BRUTAL HONEST CRITIQUE

### 1. Concept validity

The concept is **real but underleveraged**.

"PowerShell's verb-noun model as a cognitive anchor across clouds" is a genuinely good thesis. It's specific, defensible, and unusual enough to be interesting at Summit. The module — especially the `-All` pipeline and the `PSCumulus.CloudRecord` contract — is the right size for a 25-minute session: small enough to demo end-to-end, opinionated enough to justify a talk.

But the current execution dilutes that thesis under a pile of emotional framing. Slides titled *The Wreck*, *Stable Lens*, *The Abstraction Bet*, *Different Layer*, *Output Matters*, *The Reframe*, *Failure Is The Lesson* — six separate slides, each landing a variant of the same "fluency is infrastructure" mantra. That is not a talk. That is a poem stapled to a module.

The Summit audience will sit through one philosophical frame. They will not sit through six. Every one of those decorator slides is asking the audience to re-absorb the thesis instead of forcing the module to carry it.

### 2. Audience fit

Summit attendees are **opinionated, senior, and allergic to hand-wavy content.** They will forgive a 100-level abstraction if the code is crisp and the speaker is honest about tradeoffs. They will not forgive a talk that spends five minutes on "here is what I felt" before showing any PowerShell.

The 100-level level choice is **defensible but risky**. 100-level at Summit doesn't mean "beginner" — it means "doesn't assume you already live in this corner of the ecosystem." The right read of 100-level here is: "you don't need to know Azure, AWS, and GCP to follow this." Not: "we're going to spend five minutes explaining that PowerShell uses verb-noun."

The talk-track currently drifts toward the second interpretation. Lines like:

> PowerShell did not make me faster because it was magically superior. It made me faster because I already had the keystrokes in my hands.

…are fine as a single beat. They are not fine as a four-minute section labeled "PowerShell As Anchor." The audience at Summit already agrees. Move on.

### 3. Talk structure and flow

The **timing map is arithmetically honest but dramatically wrong**:

```
0:00-2:00  opening feeling
2:00-5:00  why multi-cloud is hard
5:00-9:00  PowerShell as cognitive anchor
9:00-15:00 same intent across providers
15:00-18:00 output normalization and naming
18:00-21:00 why not Terraform
21:00-23:30 where the abstraction breaks
23:30-25:00 close
```

Nine minutes (36% of the talk) elapse before the module is introduced. **The first PowerShell command shown on a slide is at slide 7 (`Credential Chaos`)**, and it is three disconnected lines (`Connect-AzAccount / Set-AWSCredential / gcloud auth login`) with a speaker note that literally says *"Do not add more commands to this slide."* That slide is load-bearing pain and it's half-built.

There is **no explicit demo block anywhere in the deck.** The talk-track says "Let me show you what that looks like in practice" at the 9-minute mark, but the deck that follows is six code-snippet slides in a row. If the speaker reads those off the slides, the audience experiences this as a lecture about PowerShell, not a demo of PowerShell. The module never actually runs on screen.

The **Terraform section is over-budget**. Three whole slides (`Why Not Terraform`, `Different Layer`, `Output Matters`) for an objection the audience already concedes. One slide, ninety seconds, done. That recovered time belongs in the demo.

The close is **thematically correct but structurally weak**. *"What is the tool you will still trust when the job gets weird?"* is a good line. It is followed by a `Thanks` slide with three bullet points (`repo link / talk link / questions after`), which is exactly the kind of housekeeping the talk-track itself warns against. Kill the housekeeping slide. Put the repo link on the close slide.

### 4. Slide content and speaker notes

Specific calls:

**Title slide** — `<p class="name">Adil</p>`. At a Summit session with 200–300 attendees from multiple orgs, "Adil" alone is a mistake. It should read "Adil Leghari" with the Wiz affiliation. The handle `@adil` is also too generic for the audience to act on post-talk; use the GitHub handle `@adilio` since the repo link is the actual call to action.

**`The Wreck`** — the three-bullet list ("three CLIs / three auth models / three mental maps") is phrase-heavy but is doing the work of a headline, not a slide. Keep the slide, but replace the list with one line of terminal output — *actual frozen terminal text* — showing the moment: a half-typed `gcloud`/`az`/`aws` command with the cursor blinking. That image earns the title. The current bullets don't.

**`Why This Feels Hard`** — gradient callout saying *"Multi-cloud is not hard because you are bad at it."* Fine line. It does not deserve its own slide. Merge with the IAM proof on the next slide.

**`Same Problem, Different Philosophy`** — the IAM table is the best slide in the deck and it is used wrong. It appears early (slide 4) as a throwaway, then reappears at slide 15 (`What Earns a Unified Command`) as the main payoff, then reappears again at slide 20 (`Failure Is The Lesson`). **Three appearances for one idea.** Pick one.

**`Why PowerShell`** — three bullets ("familiar keystrokes / familiar verb-noun shape / less syntax panic"). The speaker notes admit these are tribal-language-adjacent. The Summit audience does not need to be sold on PowerShell. Cut this slide entirely, or compress into a single line on the slide that introduces PSCumulus.

**`Stable Lens`** — `"Fluency is infrastructure. Build on what does not move."` This is the thesis slide. Keep exactly one slide like this in the deck. Currently there are four that do variants of the same job (this one, `The Abstraction Bet`, `Ask The Intent First`, `The Reframe`). Ruthlessly.

**`Credential Chaos`** — three lines of pseudocode with no output and no commentary from the slide itself. Either make it a real terminal scrape or cut it and live-demo `Connect-Cloud` instead. The current form is a placeholder.

**`Compute, Native`** — good content, right idea (show the pain). Should sit immediately before `Compute, Unified` with no filler between them.

**`Compute, Unified`** — this should be live, not a code slide. Currently both `Compute, Native` and `Compute, Unified` are static code blocks; the audience will not feel the difference unless one of them actually runs.

**`Cross-Cloud in One Pipeline`** — the `-All` slide is the single best technical beat in the talk and it's buried eleven slides in. This is what the session is actually about. It should be the climax of the demo, not a code snippet.

**`Shared Output Shape`** — great slide. Keep. Consider showing it as the actual output from the live `-All` command rather than a pre-baked table.

**`Why The Name Matters`** — the `Get-VM` / `Get-CloudInstance` argument is good and genuine. Keep as one tight beat. Currently the bullets are `"Get-CloudInstance / not Get-VM / not provider marketing names"` which is fine, but the speaker note ("I had that argument with myself for about ten minutes and then called it Get-CloudInstance") is the best line on that slide and isn't on the slide.

**`What Earns a Unified Command`** — the six-row table with IAM as the dash. **This is the heart of the talk.** It's currently sandwiched between filler slides. Move it earlier, right after the demo payoff, and spend real time here.

**`Storage, Next` / `Metadata, Next`** — the speaker notes literally say *"Keep it light here"* and *"Keep it light."* These are admitted filler. Cut both. The table on `What Earns a Unified Command` already makes the same point with more rigor.

**`Why Not Terraform` / `Different Layer` / `Output Matters`** — three slides for one objection. Collapse into one slide titled `Not Terraform's Job`. Ninety seconds, two sentences, move on.

**`Where It Breaks` / `Failure Is The Lesson`** — this should be the payoff, not a coda. The IAM case is the hardest, most credible, most interesting part of the talk. Currently it arrives at minute 21 and gets less than two minutes. It deserves three minutes and should come earlier, built out of the `What Earns a Unified Command` table.

**`The Reframe`** — *"What is the tool you will still trust when the job gets weird?"* Good line. Should be the last slide, not the second-to-last. Remove the `Thanks` slide.

**`Thanks`** — cut. Repo link moves onto the close slide.

**Speaker notes quality** — the talk-track.md file is excellent prose. The slide speaker notes in `presentation.md` are thin echoes. This is backwards: the speaker notes in the deck should be the spoken version, because that's what Marp exports put in the speaker view. As-is, the speaker will either read from talk-track.md on a separate device or wing it from the echo bullets. Fix this by promoting talk-track content into the slide speaker notes.

### 5. Demo and code quality

The module itself is in **much better shape than the talk around it**. Reading through `Public/` and `Private/`:

- `Connect-Cloud` genuinely implements the detect-then-auth flow described in the talk. Not hand-wavy.
- `Get-CloudInstance -All` works, has proper parameter sets, skips providers with no stored context, and writes a `Verbose` message listing skipped providers. That's correct behavior and it's quietly good.
- The `PSCumulus.CloudRecord` shape is real and enforced via `ConvertTo-CloudRecord`.
- The `scripts/demo-setup.ps1` file is **the strongest asset in the whole demo pipeline**. It monkeypatches the provider backends inside the module scope so every command returns seeded realistic data, with no real cloud credentials needed. This is exactly the right answer for Summit demo reliability — the conference network will hate you, real auth will fail on a schedule, and this sidesteps all of it.
- Pester tests exist in `tests/`. Not exhaustive, but they exist and cover the public surface.

**Things a senior PowerShell engineer in the audience will notice:**

1. `Start-CloudInstance` and `Stop-CloudInstance` do not support `-WhatIf` / `ShouldProcess`. For state-changing commands at a PowerShell conference, this is table stakes. It will be the first question. Either add `SupportsShouldProcess` before Monday or own the omission explicitly on stage.
2. The module exports aliases (`conc`, `gcont`, `gcin`, `sci`, `tci`). Exported aliases on a module published to the gallery is a debatable choice. Not wrong, but someone will ask. Have an answer: "they're interactive conveniences; the full names are canonical."
3. `Get-CloudInstance -All` iterates providers in a fixed order (`Azure, AWS, GCP`). In the demo output, that ordering is visible and clean. If you reorder the `Connect-Cloud -Provider AWS, Azure, GCP` call, the output still sorts by the fixed list, not by connect order. Worth a sentence so the audience doesn't think connect-order matters.
4. GCP uses the `gcloud` CLI under the hood. The talk should not hide this. Someone will ask "why didn't you use `Google.Cloud.PowerShell`?" — the answer is "it's unmaintained; the CLI is the honest adapter." That answer is already in `README.md`. Make sure it's in your head before the Q&A.

**Live demo risks:**

- If you run `Connect-Cloud -Provider AWS, Azure, GCP` against real clouds during the demo, you will be interactively prompted three times. On the conference wifi. In front of 300 people. Do not do that. Use `demo-setup.ps1` so `Connect-Cloud` hits the mocked backends.
- The mocked `Connect-Cloud` path writes three `PSCumulus.ConnectionResult` objects to the pipeline. Decide on stage whether to suppress (`$null = ...`) or show them. Both are defensible; pick one and rehearse it.
- The `-All` demo depends on all three `Providers[*]` entries in `$script:PSCumulusContext` being populated. `demo-setup.ps1` does call `Connect-Cloud -Provider Azure, AWS, GCP` at the end to seed this. If you re-import the module during the talk (accidentally or on purpose), you lose the context and have to re-run the setup. Lock the terminal state before you start.

### 6. Transitions and connective tissue

Where the audience gets lost:

- **Between `Stable Lens` and `Credential Chaos`** (slides 6→7): the deck jumps from a mantra slide to three lines of shell commands with no bridge. The audience has to do the work of figuring out that these are the three login flows that motivated the wrapper.
- **Between `Compute, Unified` and `Cross-Cloud in One Pipeline`** (slides 11→12): this is the most important transition in the talk and it is completely unmarked on the slides. One shows `Get-CloudInstance -Provider Azure/AWS/GCP` three times; the next shows `Get-CloudInstance -All | Where-Object ...`. That `-All` should be the drumroll moment. Currently it reads as just another code slide.
- **Between `Different Layer` and `Output Matters`** (slides 17→18): both slides make the same point. The audience waits for the next idea and doesn't get one.
- **Between `Failure Is The Lesson` and `The Reframe`** (slides 20→21): the talk shifts from technical (IAM doesn't normalize) to philosophical (what tool do you trust) with no bridge. The speaker notes on `The Reframe` say "Do not summarize the whole talk," which is good, but the deck also does not bridge into it.

### 7. README

The README is accurate but mis-positioned. Today it reads like a product README for a published PSGallery module. That's not what this repo is. This repo is:

1. A talk companion, with demo assets under `talk/`
2. A working module that exists to make the talk's thesis concrete
3. An artifact that readers find *after* the Summit session and want to understand

The current README leads with installation and command reference. A post-conference reader clicking through from the slides wants to know *what the talk argued* and *how the module is evidence for the argument*. Reorder accordingly: thesis → commands → installation → limits → testing.

Specific issues:

- The title tagline says `"Surviving Azure, AWS, and GCP with PowerShell"` but the talk title in the deck is `"Cross-Cloud without Crossed Fingers"`. Pick one and keep them aligned.
- The `Commands` section is a wall of code blocks. The narrative value is on the `-All` pipeline example, which is currently buried in the middle of the Inventory block.
- The `Interactive aliases` table is a distraction in a README that's landing page for a talk. Keep the aliases exported, but move them out of the top-level README (or into a small footnote).
- The `Limits` section is the best-written part of the README. Currently titled `Limits`, which is neutral — retitle to something that does work (`Where This Abstraction Stops`).
- No link back to the Summit session listing. Someone finding this repo via GitHub search should be able to click through to the talk.

### 8. Biggest risks

Ranked:

1. **The demo never actually runs.** The deck currently uses static code slides for what should be a live demo. If the speaker reads from the slides, this becomes a lecture-about-PowerShell, not a PowerShell demo. At Summit, that's a visible failure mode.
2. **The philosophical framing outpaces the technical content.** Six "thesis" slides and four-plus minutes of emotional framing before the module appears. A senior Summit audience will check out during the emotional preamble and come back only when code lands. By then you've spent a third of your budget.
3. **No `ShouldProcess` on `Start-CloudInstance`/`Stop-CloudInstance`.** At a PowerShell conference, building lifecycle commands without `-WhatIf` will generate a visible cringe in the first three rows. Either add it before Monday or pre-empt it on stage.

Honorable mentions:

- IAM is the strongest content in the talk and it's used in three places, which dilutes its impact.
- The `Thanks` slide as the final slide undercuts the reframe line that should be the last word.
- The handle `@adil` on the title slide is ambiguous; the repo link is the only thing the audience can act on and it's not on the title or the close.

---

## PHASE 2 — REBUILD

### 1. Revised talk structure (25 minutes)

The rebuild is organized around a simple rule: **code runs by minute 5, and runs again every three minutes after that.** The talk becomes a demo with a frame, not a frame with a demo.

```
0:00 – 1:30   Hook
1:30 – 3:30   Why multi-cloud breaks your head (IAM as first proof)
3:30 – 5:00   PowerShell as the anchor, PSCumulus as the bet
5:00 – 9:00   DEMO A — Connect once, inventory once, per provider
9:00 – 13:30  DEMO B — -All, the shared pipeline, the shared shape
13:30 – 16:30 What earns a unified command (the table with the dash)
16:30 – 19:00 Why the dash is the point (IAM, closely)
19:00 – 20:30 Not Terraform's job
20:30 – 22:30 What PSCumulus does not do (named gaps)
22:30 – 24:30 The lens — fluency, trust, and what you reach for
24:30 – 25:00 Close + repo
```

**Scene by scene, in the room:**

**0:00 – 1:30, Hook.** Lights up. Adil walks on. No "hi I'm Adil, I work at Wiz" right away — that's slide 2. Instead, he opens with the frozen-terminal moment: you are halfway through a command, you can't remember whether it's `--resource-group` or `-ResourceGroupName`, and for a beat you don't know which cloud you're in. The room laughs, a little nervously, because most of them have been there in the last week. He lets the laugh breathe. Then the title slide, then the intro slide. Thirty seconds of credentials. Done.

**1:30 – 3:30, Why this is hard.** He names the systems problem quickly: these are not three brands of the same OS, they're three different conceptual foundations. He uses IAM as the first proof — *AWS has policy documents, Azure has role assignments, GCP has bindings* — and the table stays on screen for about twenty seconds. This is the first appearance of IAM. It plants a seed. It will return at minute 16 as the payoff. He doesn't belabor it here.

**3:30 – 5:00, The anchor and the bet.** One slide: `Build on what does not move.` Not four slides. One. He names PowerShell as the fluent tool in his hands (not the objectively-best tool, the *fluent* tool), introduces PSCumulus by name, and shows the public surface in one glance (`Connect-Cloud`, `Get-Cloud*`, `Start/Stop-CloudInstance`). The bet is named: *same verbs, same nouns, same output shape across three different systems, with limits that I'll defend.*

**5:00 – 9:00, Demo A — the native pain and the unified relief.** He switches to the terminal (VS Code integrated terminal, dark theme, large font, pre-staged with `demo-setup.ps1` loaded and a clean history). Three beats, live:

- Show the native commands side by side (`Get-AzVM`, `Get-EC2Instance`, `gcloud compute instances list --format=json`). He doesn't run these — he shows the slide. Then he pivots: "I'm not going to run these, because you already know what they do. You know what you don't know? What the same question looks like when it doesn't care which cloud it's in."
- Run `Connect-Cloud -Provider AWS, Azure, GCP` live. The demo-setup mocks make this instant. Show `Get-CloudContext` — the normalized three-row table.
- Run `Get-CloudInstance -Provider Azure -ResourceGroup 'prod-rg'`, then AWS, then GCP. Same shape, three times. The point isn't that it works; the point is that *the output shape doesn't change*.

**9:00 – 13:30, Demo B — one pipe, three clouds.** This is the beat the whole talk is building toward. He runs:

```powershell
Get-CloudInstance -All
```

Lets it breathe. Then:

```powershell
Get-CloudInstance -All | Where-Object { $_.Tags['environment'] -eq 'prod' }
```

And the kicker:

```powershell
Get-CloudInstance -All |
  Where-Object { -not $_.Tags['owner'] } |
  Format-Table Name, Provider, Region -AutoSize
```

That's the "find me untagged production assets across every cloud I'm connected to" query, in four lines, across three cloud providers, with one output shape. It lands or it doesn't — if it lands, the room exhales. He then shows `Show-FleetHealth` to demonstrate that this isn't one trick; the `CloudRecord` shape composes into any pipeline the audience already knows how to write. Back to slides.

**13:30 – 16:30, The table.** The single most important static slide of the talk: the seven-row table of `Azure / AWS / GCP / PSCumulus` mappings, with the last row — IAM — rendered as a dash. He explains the dash not as a gap but as discipline. He states the rule that generated the table: *do the underlying CSP philosophies behind this concept overlap enough that a normalized answer is still honest?* For six rows, yes. For one row, no.

**16:30 – 19:00, Why the dash is the point.** The deepest technical beat in the talk. He explains — in concrete terms — why IAM doesn't normalize: policy documents vs. hierarchical role assignments vs. resource-scoped bindings. He names the failure mode of abstracting anyway: either you lose the scoping (dishonest) or you stuff everything into `Metadata` and the top-level object is nearly empty (useless). He names the rule: *if the normalized object would be mostly Metadata, the abstraction is too weak to deserve a first-class public command.* That's why there's no `Get-CloudPermission`. Three explicit provider-native commands exist instead — `Get-AzureRoleAssignment`, `Get-AWSPolicyAttachment`, `Get-GCPIAMBinding` — because the seams are part of the truth.

**19:00 – 20:30, Not Terraform.** Ninety seconds, one slide. Terraform standardizes infrastructure. PSCumulus standardizes *interaction with* infrastructure. Terraform is the provisioning tool. PSCumulus is the operational shell. Different layer, not opposition. Move on.

**20:30 – 22:30, What this does not do.** This is the credibility beat. He names the gaps out loud: no cost surface, no health/status unified surface, no write commands for most inventory queries, no cross-cloud search-by-name, no IAM. Gaps named are gaps owned. The audience now trusts the limits that were implied earlier.

**22:30 – 24:30, The lens.** He does not summarize. He reframes. *We spend a lot of time asking what the right tool is. I've started asking: what is the tool I'll still trust when the job gets weird?* For me, that was PowerShell. The map I drew is a thin abstraction on top of three genuinely different systems, with the seams left visible where they matter. The module is useful because it refused to lie.

**24:30 – 25:00, Close.** One slide: the reframe line, the repo URL, the handle. Thanks. Stop. No "questions after" bullet; the MC will handle that.

### 2. Improved slide deck content (16 slides)

Each slide is listed with: **title**, **what's on screen**, **speaker note (spoken language)**, and **visual/code recommendation**.

---

**Slide 1 — Title**

- **On screen:** *Cross-Cloud without Crossed Fingers — Surviving Azure, AWS, and GCP with PowerShell.* Full name: *Adil Leghari.* Handles: `@adilio` on GitHub, Wiz affiliation. Summit 2026 branding.
- **Speaker note:** "All right. Thanks for being here. This is a talk about three cloud providers, one keyboard, and what happens when you try to keep them all in your head at the same time."
- **Visual:** existing Summit title-slide layout, with full name + `@adilio` (GitHub) instead of `@adil`.

---

**Slide 2 — The Frozen Terminal**

- **On screen:** a stylized terminal screenshot showing a half-typed command where the prompt shows one cloud context, the command uses another cloud's flag syntax, and the cursor sits blinking at a wrong hyphen count. One subtitle line: *"Which cloud am I even in?"*
- **Speaker note:** "You know this moment. You're halfway through a command. You can't remember whether this CLI uses one dash or two. You can't remember whether this flag exists in this cloud. And for about four seconds, you just — stop. I've had this moment. I had it last week. I had it this week. It's the moment this talk is about."
- **Visual:** real terminal block, monospaced, with the blinking cursor indicated by a solid `|` glyph. No bullet list.

---

**Slide 3 — It's Not You**

- **On screen:** a two-row table. Row 1 header: *The clouds disagree on what a thing is.* Row 2: three cells — `AWS: policy documents`, `Azure: role assignments`, `GCP: bindings`. Subtitle: *Same question. Three different answers. IAM is just the loudest example.*
- **Speaker note:** "Multi-cloud is hard for a reason, and it isn't you. These clouds weren't built to coexist in your head. AWS has one philosophy of identity. Azure has another. GCP has a third. That's not three dialects — that's three different grammars. IAM is the most visible case, but networking does it, resource hierarchies do it, even what counts as a resource does it. If you've felt slow doing multi-cloud work, that's a systems problem, not a you problem."
- **Visual:** the existing IAM table, promoted to the main slide artwork. First appearance of IAM. It will return.

---

**Slide 4 — Build on What Does Not Move**

- **On screen:** one large line: *Build on what does not move.* One smaller line: *Fluency is infrastructure.*
- **Speaker note:** "So if the systems don't agree, I want an anchor that does. For me, the anchor was PowerShell — not because it's magically best, but because it was the tool I was most fluent in. My hands already knew the shape. Verb-noun, pipeline, object out. The cognitive cost of a PowerShell command is almost zero for me. That's what I wanted for cross-cloud work: not the best tool, the *fluent* tool."
- **Visual:** typography-driven, no list. This is the thesis. Only one slide does this job now.

---

**Slide 5 — PSCumulus**

- **On screen:** *PSCumulus — a thin, honest abstraction for Azure, AWS, and GCP.* A two-column list of the public commands:
  - `Connect-Cloud`
  - `Disconnect-Cloud`
  - `Get-CloudContext`
  - `Get-CloudInstance`
  - `Get-CloudStorage`
  - `Get-CloudDisk`
  - `Get-CloudNetwork`
  - `Get-CloudFunction`
  - `Get-CloudTag`
  - `Start-CloudInstance`
  - `Stop-CloudInstance`
- **Speaker note:** "This is PSCumulus. It's deliberately small. Eleven public commands. Verb-noun, normalized output, no pretending the providers are identical. Before we look at the demo, two things to call out: first, the noun is always `Cloud<Thing>`, never provider-native. Second, every read command returns the same output shape regardless of which cloud it hit. That's the whole bet. Let's see what that looks like."
- **Visual:** command list in monospace, two-column. No prose bullets.

---

**Slide 6 — [DEMO] Native vs. Unified**

- **On screen:** `DEMO` slug top-left. Below: side-by-side code blocks showing `Get-AzVM` / `Get-EC2Instance` / `gcloud compute instances list --format=json` vs. `Get-CloudInstance -Provider Azure/AWS/GCP`. The slide is a safety net — the speaker is in the terminal, not on this slide.
- **Speaker note:** (switch to terminal) "These three commands on the left do the same job across three clouds. I'm not going to run them. You know what they do. I'm going to run the thing on the right. *Connect-Cloud -Provider AWS, Azure, GCP.* One call, three providers. *Get-CloudContext.* Three normalized contexts, active, accounts visible. *Get-CloudInstance -Provider Azure -ResourceGroup prod-rg.* Same command against AWS. Same command against GCP. Notice the output: same columns, same types, every time."
- **Visual:** the slide is backup; the primary canvas is the terminal. Demo-setup.ps1 already loaded, module imported, context seeded.

---

**Slide 7 — [DEMO] One Pipe, Three Clouds**

- **On screen:** `DEMO` slug top-left. Code block:
  ```powershell
  Get-CloudInstance -All |
    Where-Object { -not $_.Tags['owner'] } |
    Format-Table Name, Provider, Region
  ```
  Below that: *Untagged production assets across every connected cloud. One pipeline. Three providers. One output shape to filter against.*
- **Speaker note:** (back to terminal) "This is the moment the module earns its keep. *Get-CloudInstance -All* — that iterates every provider with stored context, calls each backend, and streams one pipeline of `CloudRecord` objects. Now I'm going to do something I couldn't do cleanly before: filter across every cloud I'm connected to for untagged resources. *Where-Object not dollar underscore dot Tags owner.* The tag key works the same whether the source was an AWS tag, an Azure tag, or a GCP label. Three different cloud APIs. One filter. One answer."
- **Visual:** code block is the reference; the terminal does the work.

---

**Slide 8 — The Shared Shape**

- **On screen:** the `PSCumulus.CloudRecord` field table:

  | Name | Provider | Region | Status | Size | CreatedAt | Tags | Metadata |

  And one sample row showing one Azure, one AWS, one GCP record. Subtitle: *Same fields. Same types. Same pipeline expectations.*
- **Speaker note:** "This is the shape. Name, Provider, Region, Status, Size, CreatedAt, Tags as a normalized hashtable, and Metadata — which is where the honest provider-native stuff lives. Your Azure resource group isn't in the first seven columns, because it doesn't exist in AWS or GCP. It's in Metadata. The first seven columns are what you can actually filter and group against without the query being a lie."
- **Visual:** table layout, monospace, with one row per provider demonstrating the shape holds across them.

---

**Slide 9 — Why the Name Matters**

- **On screen:** three stacked lines:
  - `Get-CloudInstance` ← chosen
  - `Get-VM` ← already taken by Hyper-V
  - `Get-AzureInstance` / `Get-EC2Instance` / `Get-GCPInstance` ← provider marketing
- **Speaker note:** "One aside on the naming, because someone always asks. I picked `Get-CloudInstance`, not `Get-VM`. Two reasons. First, `Get-VM` is already owned by the Hyper-V world in PowerShell — I didn't want this module pretending it owned that noun. Second, the public noun is a normalized cloud concept, not a vendor name. `CloudInstance` tells the truth about what the abstraction is. The native type still lives in Metadata. I had that argument with myself for about ten minutes, and then I called it `Get-CloudInstance`."
- **Visual:** three lines, increasing opacity for the first, struck through for the second and third.

---

**Slide 10 — What Earns a Unified Command**

- **On screen:** the seven-row table:

  | Resource | Azure | AWS | GCP | PSCumulus |
  |---|---|---|---|---|
  | Compute | `Get-AzVM` | `Get-EC2Instance` | `gcloud compute instances list` | `Get-CloudInstance` |
  | Storage | `Get-AzStorageAccount` | `Get-S3Bucket` | `gcloud storage ls` | `Get-CloudStorage` |
  | Disk | `Get-AzDisk` | `Get-EC2Volume` | `gcloud compute disks list` | `Get-CloudDisk` |
  | Network | `Get-AzVirtualNetwork` | `Get-EC2Vpc` | `gcloud compute networks list` | `Get-CloudNetwork` |
  | Functions | `Get-AzFunctionApp` | `Get-LMFunctionList` | `gcloud functions list` | `Get-CloudFunction` |
  | Tags | `Get-AzTag` | `Get-EC2Tag` | `gcloud resource-manager tags` | `Get-CloudTag` |
  | IAM | `Get-AzRoleAssignment` | `Get-IAMPolicy` | `gcloud projects get-iam-policy` | **—** |

  Subtitle: *The test: do the underlying philosophies overlap enough that a normalized answer is honest?*
- **Speaker note:** "This is the decision framework for the whole module. For every candidate command, I asked: do the underlying cloud philosophies overlap enough that a normalized answer is still honest? For six of these rows, yes. The question *and* the answer translate. For the seventh — IAM — the question translates. The answer doesn't. That's what the dash means. It's not an omission. It's the test failing honestly."
- **Visual:** keep the table layout; the dash in the last row is the whole visual story.

---

**Slide 11 — Why the Dash Is the Point**

- **On screen:** three short lines:
  - `AWS → policy documents (JSON, attached)`
  - `Azure → role assignments (hierarchical, inherited)`
  - `GCP → IAM bindings (resource-scoped, member+role)`

  One rule below: *If the normalized object would be mostly Metadata, the abstraction is too weak to deserve a first-class command.*
- **Speaker note:** "Let me make the IAM thing concrete. AWS expresses access as policy documents — JSON, attached to principals. Azure expresses access as role assignments bound to a scope in a hierarchy that inherits downward. GCP expresses access as bindings on a resource — member and role pairs, sometimes conditional. Three different models. Different scoping, different inheritance, different mental models. The question 'who has access' is the same. The answer cannot be. If I wrote `Get-CloudPermission` anyway, either I'd flatten it to the least common denominator and lose the scoping that makes it useful, or I'd stuff the real answer into Metadata and the top-level object would be an empty wrapper. There's a rule I use for this: if the normalized object would be mostly Metadata, the abstraction is too weak to deserve a first-class command. That's why there's no `Get-CloudPermission`. Instead, three explicit provider commands — `Get-AzureRoleAssignment`, `Get-AWSPolicyAttachment`, `Get-GCPIAMBinding`. Three seams, left visible."
- **Visual:** three stacked one-liners, the rule in a small callout below. No callout-box decoration overload.

---

**Slide 12 — Not Terraform's Job**

- **On screen:** a two-cell contrast:
  - *Terraform — desired state, provisioning, lifecycle*
  - *PSCumulus — operator intent, interactive querying, shared shape*

  One line below: *Different layer. Not opposition.*
- **Speaker note:** "Someone is usually thinking: why not Terraform? Terraform solves a different problem. Terraform standardizes *infrastructure* — what exists, in what shape, managed as code. PSCumulus standardizes *how a human interacts with* infrastructure once it exists. Terraform is not an operational shell. PSCumulus is intentionally behaving like one. Not opposition. Different layer."
- **Visual:** two blocks side by side, equal weight, no winner.

---

**Slide 13 — What This Does Not Do**

- **On screen:** a short, honest list:
  - No cost surface
  - No unified health / status surface
  - No write commands for most inventory queries
  - No cross-cloud search-by-name
  - No IAM
- **Speaker note:** "Before I land this, let me name what PSCumulus doesn't do — because the people most likely to ask deserve a straight answer. There's no cost surface. There's no unified health or status surface. The module is read-oriented; most inventory queries don't have corresponding write commands. There's no cross-cloud search by name. And there's no IAM, for the reason we just talked about. Those are real gaps. Some of them are roadmap. Some are deliberate. None of them are hidden."
- **Visual:** plain list, no icons, no strikethroughs. This slide is credibility, not marketing.

---

**Slide 14 — The Lens**

- **On screen:** one line: *What is the tool you will still trust when the job gets weird?*
- **Speaker note:** "I want to leave you with something that isn't a summary. We spend a lot of time asking what the right tool is for a given job, and it's a good question. But there's another one I think about more now: what's the tool I'll still trust when the job gets *weird*? When I'm on call, and the environment is half-configured, and I can't remember which cloud I'm supposed to be in. Those are the moments where fluency matters more than optimality. And fluency is built over time, on tools you already know. For me, that tool was PowerShell. The module is just the map I drew. I hope some of it is useful to you."
- **Visual:** large typography, single line, centered. This is the last idea in the room.

---

**Slide 15 — Repo**

- **On screen:** `github.com/adilio/PSCumulus`. `@adilio`. *Slides + talk track linked in the repo.* Summit logo.
- **Speaker note:** "Repo link. Thanks for listening."
- **Visual:** one URL, one handle, no bullet list. End.

---

*Slide count: 15 (was 21). Slides cut: `Stable Lens` duplicate thesis, `Credential Chaos` (replaced by live demo), `Ask The Intent First`, `The Abstraction Bet`, `Storage, Next`, `Metadata, Next`, `Different Layer`, `Output Matters`, `Failure Is The Lesson` (merged into Slide 11), `Thanks` (merged into Slide 15). New slides: `The Frozen Terminal` (Slide 2), explicit `[DEMO]` slides (6, 7), `What This Does Not Do` (Slide 13).*

### 3. Polished 25-minute talk track

*A continuous, speakable track. Stage directions in [brackets]. Written in Adil's voice: direct, technically confident, dry where it helps.*

---

[Lights. Walk on. Title slide.]

All right. Thanks for being here. This is a talk about three cloud providers, one keyboard, and what happens when you try to keep them all in your head at the same time.

I'm Adil. I work at Wiz, on the solutions engineering side. Before that I did a lot of PowerShell and sysadmin work, some of it in places where you don't find out until 2am that you were supposed to know all three of these clouds. That's the talk this was going to be, five years ago. Now it's a module, and it's this.

[Advance to Slide 2 — The Frozen Terminal.]

You know this moment. You're halfway through a command, you can't remember whether this CLI uses one dash or two, you can't remember whether the flag you want exists in this cloud, and for about four seconds, you just — stop. You look at the terminal. And for a beat, you don't know which cloud you're in anymore.

That was me. It's still me sometimes. I was bouncing between Azure, AWS, and GCP, and I didn't feel like I was learning one big system. I felt like I was renting three different brains.

[Brief pause. Let the room laugh if it wants to.]

So I reached for the one tool I already trusted.

[Advance to Slide 3 — It's Not You.]

Before we get there, one thing worth saying out loud: multi-cloud is hard for a reason, and the reason is not that you are bad at it. The clouds were not designed to coexist in your head. They have different philosophies of identity, different resource hierarchies, different regional models, different ideas of what a *resource* even is.

The loudest example is IAM. AWS expresses access as policy documents. Azure expresses it as role assignments scoped to a hierarchy. GCP expresses it as bindings. Those are not the same thing wearing different clothes. Those are three different grammars.

Hold that example in your head. I'm going to come back to it at the end, because it turns out to be the most important slide in this talk.

[Advance to Slide 4 — Build on What Does Not Move.]

So if the systems don't agree, I wanted an anchor that did. For me, the anchor was PowerShell. Not because PowerShell is objectively best — I don't believe in "objectively best" for any tool. It was the tool I was most fluent in. My hands already knew the shape. Verb-noun, pipeline, object out. The cognitive cost was close to zero.

That's what I wanted for cross-cloud work. Not the best tool. The *fluent* tool.

And that's the bet the rest of this talk is about. You build on what doesn't move. Fluency is infrastructure.

[Advance to Slide 5 — PSCumulus.]

So here's the module. It's called PSCumulus. Eleven public commands. Verb-noun, normalized output, no pretending the providers are the same. I want to flag two things before we look at code.

First: the noun is always `Cloud<Thing>`. Never `Az`, never `EC2`, never `GCP`. The public noun is a normalized concept. The native type still lives in metadata.

Second: every read command returns the same output shape, regardless of which cloud it hit.

That's the whole bet. Let's see what it looks like.

[Advance to Slide 6 — Demo A. Switch to terminal.]

These three commands on the left, you already know. `Get-AzVM`. `Get-EC2Instance`. `gcloud compute instances list --format=json`. Three clouds, three surfaces, three output shapes. I'm not going to run them. You know what they do. You know what you *don't* know? What the same question looks like when it doesn't care which cloud it's in.

[Run: `Connect-Cloud -Provider AWS, Azure, GCP`.]

One call, three providers. This checks each provider for an existing session, triggers the native login if there isn't one, and stores a normalized context for each. The contexts live side by side — connecting to one doesn't disconnect the others.

[Run: `Get-CloudContext`.]

Three providers. Each with an account, a scope, a region. All active.

[Run: `Get-CloudInstance -Provider Azure -ResourceGroup 'prod-rg'`.]

Azure instances. Name, Provider, Region, Status, Size, CreatedAt. Notice the shape.

[Run: `Get-CloudInstance -Provider AWS -Region 'us-east-1'`.]

Same command, AWS. Same shape.

[Run: `Get-CloudInstance -Provider GCP -Project 'contoso-prod'`.]

GCP. Same shape. The output doesn't know which cloud it came from until you look at the Provider column.

[Advance to Slide 7 — Demo B.]

Now the thing that actually justified building the module.

[Run: `Get-CloudInstance -All`.]

That flag — `-All` — iterates every provider with stored context, calls each backend, and streams a single pipeline of CloudRecord objects. I'm not writing three loops. I'm not managing three output shapes. I'm just getting one stream of objects.

And once you have one stream, you can do this.

[Run:
```powershell
Get-CloudInstance -All |
  Where-Object { -not $_.Tags['owner'] } |
  Format-Table Name, Provider, Region -AutoSize
```
]

Untagged production assets across every cloud I'm connected to. The tag key `owner` works the same whether the source was an AWS tag, an Azure tag, or a GCP label — that normalization is the point. Three different cloud APIs. One filter. One answer.

[Run: `Show-FleetHealth` or an equivalent grouping query.]

And this is the part I care about most. This isn't one trick. The CloudRecord shape composes into any pipeline you already know how to write. `Group-Object`, `Sort-Object`, `Where-Object`, `Select-Object`. The mental model is PowerShell. The data is multi-cloud.

[Back to slides. Advance to Slide 8 — The Shared Shape.]

That shape has a name. `PSCumulus.CloudRecord`. Eight fields. Name, Provider, Region, Status, Size, CreatedAt, Tags, Metadata.

Seven of those are what you can safely filter and group against across clouds, because they exist cleanly in all three. The eighth — Metadata — is where the honest provider-native stuff lives. Your Azure resource group. Your AWS VPC ID. Your GCP zone. Those are real. They matter. They just don't belong in the first seven columns, because they don't exist across all three clouds. Putting them there would be a lie.

[Advance to Slide 9 — Why the Name Matters.]

Quick aside on the naming, because someone always asks.

I picked `Get-CloudInstance`, not `Get-VM`. Two reasons. First, `Get-VM` is already owned by the Hyper-V world in PowerShell. I didn't want this module pretending it owned that noun. Second, the public noun is a normalized cloud concept, not a vendor name. `CloudInstance` tells the truth about what the abstraction is.

I had that argument with myself for about ten minutes. Then I called it `Get-CloudInstance`.

[Advance to Slide 10 — What Earns a Unified Command.]

OK. Here's the real content of the talk.

Every command in PSCumulus had to pass a test. The test was this: do the underlying CSP philosophies behind this concept overlap enough that a normalized answer is still honest?

For compute, yes. All three clouds define an instance as something that runs, has a name, a region, a status, a size. The philosophies align. `Get-CloudInstance` exists.

For storage — yes, with seams. The billing models and the lifecycle rules differ, but the operator intent — *what storage exists here* — maps. `Get-CloudStorage` exists.

For disks, networks, functions, tags — same story. Increasing amounts of seam showing at the edges, but the core concept is close enough that normalization isn't lying. Those commands exist.

Now look at the last row. IAM. There's a dash where a PSCumulus command would be.

The human question is the same — who has access, and what can they do? That doesn't change across clouds. But the answer can't be normalized, because the underlying philosophies don't overlap.

[Advance to Slide 11 — Why the Dash Is the Point.]

Let me make that concrete.

AWS expresses access as policy documents — JSON objects that describe what actions are allowed or denied on what resources, attached to users, groups, or roles.

Azure expresses access as role assignments — a principal bound to a named role at a specific scope in the resource hierarchy, inherited downward through subscriptions and resource groups.

GCP expresses access as IAM bindings on a resource — member and role pairs, sometimes conditional.

The scoping is different. The inheritance behavior is different. The mental model you need to reason about them is different. If I wrote `Get-CloudPermission` anyway, one of two things would happen. Either I'd flatten everything to the least common denominator and lose the scoping and inheritance that make the answer useful. Or I'd stuff the real answer into Metadata, and the normalized object on top would be an empty wrapper.

There's a rule I use. If the normalized object would be mostly Metadata, the abstraction is too weak to deserve a first-class command. That's why there's no `Get-CloudPermission`. Instead, three explicit provider-native commands — `Get-AzureRoleAssignment`, `Get-AWSPolicyAttachment`, `Get-GCPIAMBinding`. Three seams, left visible.

The module is useful because it refuses to lie about the places where the providers are genuinely different. Adding `Get-CloudPermission` would have been easy to do, and plausible-looking. It also would have been the thing that eventually burned the person who trusted the abstraction a little too far.

Knowing when *not* to abstract is the actual skill. It's also, honestly, the harder one.

[Advance to Slide 12 — Not Terraform's Job.]

At this point somebody is usually thinking: why not Terraform? Terraform solves a different problem.

Terraform standardizes *infrastructure*. PSCumulus standardizes *how a human interacts with* infrastructure once it exists. Terraform gives you desired state, provisioning, drift correction. PSCumulus gives you an operational shell with consistent ergonomics across three clouds.

Terraform is not an operational shell. PSCumulus is intentionally behaving like one. Different layer. Not opposition.

[Advance to Slide 13 — What This Does Not Do.]

Before I land this, let me name what PSCumulus doesn't do — because the people most likely to ask deserve a straight answer.

There's no cost surface. There's no unified health or status surface. The module is read-oriented; most inventory queries don't have corresponding write commands. There's no cross-cloud search-by-name. And there's no IAM, for the reason we just talked about.

Some of those are roadmap. Some are deliberate. None of them are hidden.

[Advance to Slide 14 — The Lens.]

I want to leave you with something that isn't a summary.

We spend a lot of time in this field asking what the right tool is for a given job. And it's a good question. But there's another one I think about more now.

What is the tool you will still trust when the job gets weird? When you're on call and the environment is half-configured and you cannot remember which cloud you're supposed to be in. When you need to move fast and you genuinely cannot afford a mistake, and you need your hands to know what to do without looking it up.

Those are the moments where fluency matters more than optimality. And fluency is built over time, on tools you already know.

For me, that tool was PowerShell. The module you just saw is just the map I drew. I hope some of it is useful to you.

[Advance to Slide 15 — Repo.]

Repo's at `github.com/adilio/PSCumulus`. Slides and the talk track are in there too. Thanks for listening.

[End.]

---

### 4. Demo and code recommendations

**What needs to exist before Monday (priority order):**

1. **Nothing blocks the demo.** `scripts/demo-setup.ps1` is in good shape. It mocks `Connect-*Backend`, all `Get-*Data`, and `Start/Stop-*Instance` inside the module scope, and seeds context via a real `Connect-Cloud` call. The demo will be deterministic on conference wifi.

2. **Add `SupportsShouldProcess` to `Start-CloudInstance` and `Stop-CloudInstance`.** At a PowerShell conference, lifecycle commands without `-WhatIf` are a visible gap. The Public/Start-CloudInstance.ps1 function signature currently has `[CmdletBinding()]`; change to `[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]` and wrap the provider invocation in `if ($PSCmdlet.ShouldProcess(...))`. Mirror for `Stop-CloudInstance`. *If you do not have time to add it, pre-empt the question explicitly: "`ShouldProcess` is on the roadmap; I wanted to land the read path first."*

3. **Pre-stage the terminal.** Large font (suggested: 18pt or larger), dark theme with sufficient contrast from the Summit projector's light bleed, one tab, history cleared. Demo-setup loaded before you walk on. Run `Clear-Host` once so the first visible line is the prompt.

4. **Rehearse the `-All` command twice in sequence.** On the first run, the output of `Get-CloudInstance -All` will include the mocked `ConnectionResult` objects if you call `Connect-Cloud` during the demo rather than having demo-setup do it. Suppress with `$null = Connect-Cloud ...` or pre-seed context via `demo-setup.ps1` before the talk and skip connecting on stage.

5. **Decide what to do with `Get-CloudContext` output ordering.** The module iterates `Azure, AWS, GCP` in a fixed order. If you connect in `AWS, Azure, GCP` order on stage, the context table will still sort `Azure, AWS, GCP`. Either explain the fixed order in one sentence ("the module sorts providers alphabetically for predictable output"), or connect in alphabetical order to sidestep.

6. **Have a backup recording.** If the live demo breaks in any way, cut to a 90-second pre-recorded terminal capture of the same commands. This is belt-and-suspenders at Summit; almost every veteran Summit speaker does this.

**Code hygiene notes that a sharp audience member will flag:**

- `Get-CloudInstance -All` uses a fixed provider iteration order. If you add a fourth provider later, the iteration list is hardcoded in `Public/Get-CloudInstance.ps1`. Not a bug; just a thing to know.
- The `Detailed` switch on `Get-CloudInstance` injects a second type name (`PSCumulus.CloudRecord.Detailed`) into the object's `PSTypeNames`. The formatter in `PSCumulus.Format.ps1xml` keys off this. Worth knowing if someone asks how the detailed view is implemented.
- Exported aliases (`conc`, `gcont`, `gcin`, `sci`, `tci`) live in `PSCumulus.psm1`. At least one person will ask whether exported aliases are a good idea. Have the answer ready: "they're interactive conveniences; the full names are canonical in scripts and docs."

**What does not need to change for Monday:**

- The `PSCumulus.CloudRecord` contract is solid.
- `Connect-Cloud` genuinely implements detect-then-auth. The claim on stage is true.
- The Pester tests exist and cover the public surface. They don't have to be exhaustive to be enough.

---

### 5. Files rewritten in this pass

- **`README.md`** — rewritten to lead with the talk thesis, not installation. The `Limits` section is now `Where This Abstraction Stops`, which is where the real argument lives.
- **`talk/presentation.md`** — rewritten to the 15-slide structure described in Phase 2, with full speaker notes promoted from the old `talk-track.md`.
- **`talk/talk-track.md`** — replaced with the continuous 25-minute spoken track from Phase 2 section 3.
