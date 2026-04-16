# PSCumulus Evolution

This document explains where PSCumulus is going, why it is being evolved in stages, what each stage is meant to accomplish, and what has already landed.

It is intentionally more reflective and more explicit than the README. The README explains what the module is and how to use it. This document explains why the architecture is being reshaped the way it is.

## Origin Story

The staged roadmap did not appear in a vacuum. It crystallized after the PowerShell + DevOps Global Summit 2026 talk on **Monday, April 13, 2026**.

That talk was the public proof that PSCumulus already had a useful shape as a cmdlet-first module. The audience could see the point of the normalized records, the cross-cloud pipelines, and the narrowness of the abstraction. But the future direction of the module still felt open-ended.

The real unlock came in the room: **Jeffrey Snover sat in the front row and offered an insight that clarified the next move**. The important future direction was not to replace the cmdlet model that was already working. It was to recognize that PSCumulus could keep the cmdlets as the primary surface and, later, add a Provider-shaped navigation layer on top of the same backend engine.

That was the architectural unlock.

It reframed the roadmap from “what should this module become instead?” to “how can this module grow without betraying the thing that already makes it useful?”

Once that clicked, the stages became much easier to define:

- fix correctness first
- make records and paths more self-describing
- only then add navigation
- keep the Provider additive rather than foundational

## Current Status

PSCumulus is currently at **Stage 1 — Internal Typed Contract**.

That means the core module still behaves the same way from the outside:

- the public interface is still cmdlet-first
- `Get-CloudInstance`, `Get-CloudDisk`, `Get-CloudStorage`, and the rest still return `PSCumulus.CloudRecord`
- those records are still `[pscustomobject]` instances stamped with a custom type name
- the public command surface has not been broken or renamed

What changed in Stage 1 is the internal vocabulary and correctness model:

- instance states now normalize semantically instead of just being title-cased
- the original provider state is preserved in `Metadata.NativeStatus`
- tag conversion logic now has a dedicated internal home
- the module has a typed internal foundation that later stages can build on

That distinction matters. PSCumulus is not being rewritten in one dramatic jump. It is being evolved so that each stage can land safely, be tested independently, and remain useful even if the later stages take time or change shape.

## Why Evolve In Stages

The staged plan exists for three reasons.

### 1. The cmdlets are the product today

PSCumulus already works as a cmdlet-based module. People can use it now. That means future changes should not treat the current surface as disposable scaffolding. The public commands are not a temporary bootstrap for a Provider. They are the primary user experience, and any future Provider is an additional affordance layered on top.

This is why the plan insists on:

- keeping the existing cmdlets stable
- preserving `PSCumulus.CloudRecord`
- adding future navigation as an additive path, not a replacement

### 2. Correctness should land before cleverness

The biggest real problems in the codebase were not the absence of a Provider. They were simpler and more fundamental:

- status normalization was too close to string prettification
- provider-native status meaning was being lost
- tag conversion rules were repeated inline and had no shared internal home

Fixing those first is valuable on its own. It improves the module even if the later stages never happen.

### 3. PowerShell version constraints are real

The core module still targets PowerShell 5.1. That matters. Some future ideas, especially around Providers and class-based navigation infrastructure, fit PowerShell 7+ much better than 5.1.

The staged plan preserves a clean split:

- the **core module** stays broadly compatible
- the **future navigation layer** can make stronger assumptions when it is ready

That lets PSCumulus improve now without forcing the entire project to jump versions or change delivery model prematurely.

## The Philosophy Behind The Plan

PSCumulus started from a very specific thesis:

> Build on what does not move.

The clouds differ wildly. PowerShell does not. The module works because PowerShell's verb-noun model provides a stable lens through which Azure, AWS, and GCP can be queried without pretending they are identical.

That thesis imposes two obligations:

### Normalize only where the answer is still honest

If the providers are expressing the same practical thing in different dialects, normalization is useful.

That is true for:

- compute inventory
- disks
- storage
- networks
- functions
- tags and labels

It is not true for every cloud problem. IAM remains the clearest non-example. A fake cross-cloud IAM surface would flatten differences that actually matter.

### Preserve the seam when the seam is meaningful

A good abstraction is not one that erases every difference. It is one that gives the user a stable top-level shape while still preserving the provider-native detail that they will sometimes need.

That is why `Metadata` exists.

The evolution plan keeps that philosophy intact. Even the new typed internals are not an attempt to pretend all providers are the same. They are a way to make the module more precise about which differences are normalized and which differences remain native.

## Design Principles Across All Stages

These principles apply to the full roadmap.

- Each stage should ship independently and provide value on its own.
- The cmdlet surface remains the primary interface.
- The Provider, if and when it lands, is additive.
- The core module keeps its PowerShell 5.1-compatible posture.
- Later navigation work may require PowerShell 7+.
- New providers and new resource kinds should get easier to add over time, not harder.

That last point is especially important. The roadmap is not only about new user features. It is also about making PSCumulus cheaper to extend without turning it into an over-abstracted framework.

## Stage 1 — Internal Typed Contract

### Purpose

Establish an internal typed vocabulary for provider state and tag conversion without breaking the existing public contract.

### What It Introduces

- `Classes/PSCumulus.Types.ps1`
- `CloudProvider`
- `CloudInstanceStatus`
- `CloudInstanceStatusMap`
- `CloudTagHelper`
- wrapper converter functions that now delegate to the typed mapping layer
- semantic instance-state normalization
- `Metadata.NativeStatus` on instance records

### Why This Stage Exists

Stage 1 fixes correctness first.

Before this stage, the module had a stable public shape, but some of its semantics were weaker than they appeared. A state string that looks normalized is not the same thing as a state model that is normalized semantically.

Examples:

- AWS `shutting-down` should not remain effectively “just a prettified string”; it should normalize to `Terminating`
- Azure `VM deallocated` should normalize to `Stopped`
- GCP `TERMINATED` should normalize to `Stopped`, because in GCP it means stopped-but-restartable, not permanently gone

This stage gives PSCumulus a more honest and more testable internal language for those cases.

### Why It Stops Where It Does

Stage 1 deliberately does **not**:

- replace `PSCumulus.CloudRecord` with a public class
- add methods like `.Start()` to records
- introduce a Provider
- change public command signatures

That restraint is the point. This stage is about making the existing module more trustworthy, not about changing how users interact with it.

## Stage 2 — Resource Kind Awareness

### Purpose

Make each `CloudRecord` self-describing about which broad resource family it belongs to.

### What It Introduces

- a resource-kind field on records
- backend population of that field for instances, disks, storage, networks, functions, and tags

### Why This Stage Exists

Right now, a record knows who it came from and what region it lives in, but it does not inherently know what kind of cloud thing it is. That information is implicit in which command produced it.

That is fine for cmdlet use. It is not enough for future path-based navigation. A navigation layer needs records to be self-describing so it can place them under containers like `Instances`, `Disks`, or `Functions` without guessing.

### Why It Is Separate

This is an additive metadata stage. It does not need a Provider to be valuable, and it is much easier to test on its own than as part of a full navigation feature.

## Stage 3 — Cloud Path Model

### Purpose

Define a structured cloud path and a resolver that can translate paths into backend calls.

### What It Introduces

- a `CloudPath` model
- a resolver layer that maps paths to backend operations
- a public helper for path resolution if useful

### Why This Stage Exists

The path model is the heart of any future Provider. It is also useful independently of a Provider because it turns path parsing and identity resolution into something explicit and testable.

This matters because cloud hierarchies do not line up neatly:

- Azure groups many workflows around resource groups
- AWS often scopes lookups around regions
- GCP often scopes them around projects

The path model is where PSCumulus decides how to turn those different scope systems into one navigable hierarchy without lying about the underlying structure.

### Why It Is Separate

A Provider built without a clean path model would be fragile. Pulling the model out into its own stage means the hard part can be reasoned about and tested without mixing it with PowerShell Provider mechanics.

## Stage 4 — The Provider (Read-Only)

### Purpose

Expose the existing backend engine through a read-only PowerShell navigation layer.

### What It Introduces

- navigable drives
- `Get-ChildItem` over cloud scopes and resource containers
- `Get-Item` / `Test-Path` style access over cloud paths
- drive-backed discovery on top of the same backend logic the cmdlets already use

### Why This Stage Exists

This is the “Snover stage.” It turns cloud inventory into something you can browse.

The attraction is obvious:

- `dir Azure:\`
- `dir Azure:\prod-rg\Instances`
- `Get-Item AWS:\us-east-1\Instances\...`

This does not replace the cmdlets. It adds a second, more exploratory way of working with the same data.

### Why It Comes After Stage 3

Because the Provider should be thin.

It should not invent a new engine. It should delegate to the same internal logic that already powers the cmdlets. That only works cleanly once the path model and resolver already exist.

### Version Philosophy

This is also the stage where PowerShell version reality matters most. Provider-oriented class infrastructure is a much more natural fit for PowerShell 7+ than for 5.1. That is why the roadmap treats the Provider as future-facing and additive, not as something the core module must force into 5.1 prematurely.

## Stage 5 — Write Operations Through The Provider

### Purpose

Let path context drive lifecycle operations after read-only navigation is already stable.

### What It Introduces

- path-based start/stop style actions
- Provider-aware lifecycle operations
- `ShouldProcess` and confirmation semantics carried into the navigation model

### Why This Stage Exists

Once users can navigate to a resource, the next natural question is whether they can act on it from that context.

That is appealing, but also the moment when convenience can become dangerous. Write operations need:

- reliable identity resolution
- clear `-WhatIf` behavior
- strong confirmation semantics

### Why It Is Not Earlier

Because a write-capable Provider built on an unstable read model would be reckless. Read-only navigation needs to be correct and predictable before any destructive or state-changing operations are layered on top.

## Stage 6 — Cross-Cloud Aggregation

### Purpose

Expose the existing multi-provider aggregation story through navigation as well as through cmdlets.

### What It Introduces

- a synthetic cross-cloud view
- navigable multi-provider containers
- a path-based form of the same “query all connected providers” story that `-All` already provides today

### Why This Stage Exists

PSCumulus already shines when it can say:

```powershell
Get-CloudInstance -All | Group-Object Provider, Status
```

Stage 6 asks what the navigation equivalent of that should look like.

### Why It Is Last

Because it depends on every prior stage being correct:

- typed vocabulary
- self-describing records
- stable path model
- reliable read-only Provider behavior

It also has the highest potential for surprising performance behavior, because a single navigation command can fan out across multiple connected providers.

## What The Plan Deliberately Does Not Prioritize

Some ideas are intentionally deferred even though they are interesting.

### Record methods

Methods like `.Start()` or `.Stop()` on records may sound attractive, but the cmdlet and Provider surfaces already map more naturally onto PowerShell’s `ShouldProcess` and pipeline behavior.

### Abstract backend class hierarchies

The current function-based routing is repetitive, but it is also very readable and proportional to the module’s size. More abstraction is only worth it when it clearly reduces complexity.

### Full context-object refactors

The session context can remain simple until later stages genuinely require stronger structure.

### A compiled provider-first architecture

That is a valid future option if the Provider direction becomes central. It is not the right first move while the module is still proving its staged architecture.

## What Success Looks Like

The roadmap is working if PSCumulus becomes:

- more correct internally
- easier to extend
- more expressive for users
- still recognizably the same module from the outside

That last point matters. A good evolution plan should make the module feel more capable, not unfamiliar.

## The Through-Line

Every stage in this plan is trying to protect the same original insight:

PowerShell is the stable layer. The clouds are not.

The job of PSCumulus is not to erase that reality. It is to make it livable.
