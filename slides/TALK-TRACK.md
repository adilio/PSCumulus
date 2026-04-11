# Talk Track

This file is the working spoken draft for the Summit talk. It is intentionally more detailed than the slides. The slides should support this story, not duplicate it.

## Throughline

The talk has two stories happening at once.

Surface story:

- here is a PowerShell module that lets me move between Azure, AWS, and GCP with less friction

Deep story:

- here is what I learned about fear, fluency, and cognitive overload when I was responsible for systems that did not share a mental model

The technical material makes the talk useful. The human story makes it memorable.

## Tone

The tone should be:

- honest
- calm
- lightly funny
- specific rather than dramatic
- peer-level, not guru-level

This talk should feel like:

- "I got lost too, and here is the map I drew"

Not like:

- "I solved multi-cloud"

## Timing map

- 0:00-2:00 opening feeling and recognition
- 2:00-5:00 why multi-cloud is hard and not a personal failure
- 5:00-9:00 PowerShell as cognitive anchor
- 9:00-15:00 same intent across providers
- 15:00-18:00 output normalization and naming
- 18:00-21:00 why not Terraform
- 21:00-23:30 where the abstraction breaks
- 23:30-25:00 close

## 0:00-2:00 Opening

Goal:

- make the audience feel seen before teaching anything

Suggested opening:

> You know that feeling when you're halfway through a command and you can't remember whether this CLI uses one dash or two, or whether the flag even exists in this cloud? And you just stop. You look at the terminal. You realize you've been staring at it for four seconds, and for a second you don't even know which cloud you're in anymore.
>
> That was me.

Then:

> I was bouncing between Azure, AWS, and GCP, and I didn't feel like I was learning one big system. I felt like I was renting three different brains.

Then land the pivot:

> So I reached for the one tool I already trusted: PowerShell.

Important note:

- say this slowly
- let the room laugh a little if they want to
- do not rush to the technical slide

## 2:00-5:00 Why This Is Hard

Goal:

- release the audience from the feeling that they are individually bad at multi-cloud

Key message:

- the clouds are not three brands of the same operating system
- they are different systems with different philosophies

Suggested language:

> Multi-cloud is hard for a reason. These clouds were not designed to coexist in your head.
>
> AWS has one philosophy of identity. Azure has another. GCP has another. Networking is different. Regions are different. Resource hierarchies are different. Even what counts as a resource is different.
>
> So if you've ever felt slow or disoriented doing multi-cloud work, that is not a character flaw. That is a systems problem.

Then use IAM as the first proof:

> AWS gives you policy documents. Azure gives you role assignments. GCP gives you bindings. Those are not the same thing wearing different clothes.

Transition into PowerShell:

> That's what makes multi-cloud disorienting in a way that's easy to mistake for personal failure. The systems aren't just named differently. They're built on different conceptual foundations. So giving yourself permission to find it hard is actually step one. And step two is finding a stable anchor.

And before you leave this section, name the on-call version of the opening feeling:

> What I'm describing in the abstract has a very specific concrete form: it's 2am, a thing is broken, and you cannot remember whether the flag is --resource-group or -ResourceGroupName, and you do not know where you are. That is not hypothetical. That is the thing I was trying to solve.

## 5:00-9:00 PowerShell As Anchor

Goal:

- explain why PowerShell was the tool, without making this a tribal language pitch

Key message:

- PowerShell was not "best" in the abstract
- it was the most fluent tool available to you

Suggested language:

> PowerShell did not make me faster because it was magically superior.
>
> It made me faster because I already had the keystrokes in my hands.
>
> My brain could spend less time on syntax and more time on the actual cloud problem.

Then connect to auth:

> The first wall everybody hits is auth. Three clouds, three login models, three places credentials can hide. That's where the wrapper started.

Then connect to the naming insight:

> The verb-noun model turns out to be a superpower here, because it makes you ask, "what am I actually trying to do?" before you ask, "what does this provider call it?"

And there's a third thing PowerShell gave me that I didn't expect to matter as much as it did: a starting point for someone new to cross-cloud work. If you're coming in fresh and you don't yet know which native CLI to trust, having a consistent verb-noun surface gives you something to reach for before you go native. It's a learning scaffold. You can graduate out of it when you know the platforms well enough, but it lowers the cost of the early days considerably.

Transition into demo:

> Let me show you what that looks like in practice.

## 9:00-15:00 Same Intent, Different Providers

Goal:

- show the module doing something useful and legible

Key message:

- PSCumulus is not abstracting "all cloud"
- it is abstracting repeated operator intent

Suggested transition:

> The useful question stopped being, "what is the AWS equivalent of Get-AzVM?" and became, "what is the stable operator intent underneath all of this?"

Before getting into the demo, name the three things this is actually going to prove:

> There are three use cases I care most about here. First: on-call orientation -- you're in an unfamiliar environment, you need a list of what's running, and you don't want to context-switch between three CLIs to get it. Second: cross-cloud audit -- you want to filter across all your connected clouds in one pipeline, by tag, by status, by provider. Third: onboarding -- you need to bring someone new up to speed who hasn't memorized the native surface yet. The demo is going to show all three of these.

For the Compute Native slide:

> This is what I was working with before PSCumulus. Three providers, three commands, three completely different output shapes, and one increasingly confused operator.
>
> The AWS command gives you a deeply nested object. The Azure one gives you something else. And GCP doesn't have a maintained PowerShell module, so you're calling gcloud directly with --format=json and piping the output. Which works. It's just not what anyone would design on purpose.
>
> None of this is wrong. These are different systems that were built by different teams with different design philosophies, and they're doing what makes sense given where they came from. The problem is just that they all live in your head at the same time.

For the Compute Unified slide -- explain Connect-Cloud first, then the commands:

> Before we look at the output, let me walk through what Connect-Cloud is actually doing.
>
> When you call Connect-Cloud -Provider Azure, the first thing it does is check whether you already have an authenticated session. It calls Get-AzContext under the hood. If there's an active context, it skips the login step entirely and stores the session. If not, it calls Connect-AzAccount and waits for the browser flow.
>
> For AWS, it checks your environment variables and your ~/.aws credential files. For GCP, it runs gcloud auth list to see whether there's an active account. If nothing shows up, it calls gcloud auth application-default login.
>
> So Connect-Cloud is not just dispatching a command. It's making a decision: are you already ready to work, or do we need to get you there first? Once it's done, it stores a normalized context for that provider -- account identity, scope, region -- and sets that provider as the active one for the session.
>
> That's why the subsequent commands can drop -Provider. If you've already called Connect-Cloud -Provider AWS, then Get-CloudInstance without a -Provider flag knows exactly what you mean. And if you've connected to all three clouds in the same session, you can call Get-CloudContext and see all of them -- each provider has its own stored context, and IsActive marks which one you last connected.

Now show the multi-provider connect and the cross-cloud audit:

> Here's where it gets interesting. Instead of three separate Connect-Cloud calls, you can pass an array:
>
> `Connect-Cloud -Provider AWS, Azure, GCP`
>
> That goes through each provider in sequence, runs the auth check, stores the context. Now you have all three connected in one session.
>
> And then you can do this:
>
> `Get-CloudInstance -All | Where-Object { $_.Tags['environment'] -eq 'prod' }`
>
> What -All does is iterate every provider that has stored context, call the backend for each one, and return all the results into one pipeline. You're not writing three loops. You're not managing three output shapes. You get one stream of CloudRecord objects, and you filter against it. Tags are normalized -- 'environment' works the same whether the source was an AWS tag, an Azure tag, or a GCP label.
>
> That's the cross-cloud audit use case. One pipeline, three clouds.

For the Shared Output Shape slide:

> This is what comes back. Name, Provider, Region, Status, Size, CreatedAt. Same fields whether you asked Azure, AWS, or GCP.
>
> That sounds simple, and it is. But the payoff is that you can write one script that works with CloudRecord objects and it doesn't need to branch for each provider. The pipeline behavior is consistent. The field names are consistent. You stop translating and start just working.
>
> The native provider detail is still there. You haven't lost the Azure resource group or the AWS VPC ID or the GCP zone. Those live in the Metadata property. They're accessible. They just aren't in the first six columns because they don't normalize cleanly across providers, and pretending they do would be lying.

For the Storage Next slide:

> Storage is useful, but this is where you start to feel the seams a little more.
>
> An Azure storage account, an S3 bucket, and a GCP bucket are similar enough in operator intent that one command makes sense. You're asking the same question: what storage resources exist here, what are they called, where are they? That maps.
>
> But the billing models, the access control patterns, the lifecycle rules -- those don't map to each other, and I'm not going to force them to. The command is unified. The underlying systems are not, and the abstraction doesn't pretend otherwise.

For the Metadata Next slide:

> Tags are a good example because they matter operationally -- cost allocation, environment labeling, ownership -- and all three clouds support them. GCP calls them labels instead of tags, which is the least surprising divergence in this whole talk, but still. The query mechanics differ per provider.
>
> Get-CloudTag works across all three and returns a consistent shape. What I'm not claiming is that the providers work the same way. The abstraction covers the intent. It doesn't erase the implementation.
>
> This is actually the cleaner end of the trade-off. Tags are similar enough that normalizing them is genuinely useful. Not everything is, and the next section is about what happens when you try anyway.

Important point to say out loud:

> I'm not claiming these things are identical. I'm claiming there is enough overlap in the operator intent to justify a thin normalized command.

## 15:00-18:00 Output And Naming

Goal:

- explain why the output shape and command names matter

Key message:

- the value is not just fewer commands
- the value is consistent output and a stable mental model

Suggested language:

> The real payoff isn't just that the commands rhyme. It's that the output shape is consistent.
>
> Same top-level fields. Same pipeline behavior. Same script expectations.

Then:

> That also explains the naming. I used `Get-CloudInstance`, not `Get-VM`, on purpose.
>
> One reason is conceptual: the public noun is a normalized cloud concept, not a provider-native name.
>
> The other reason is practical: PowerShell already has a `Get-VM` command in the Hyper-V world. I did not want this module pretending it owned that noun. I had that argument with myself for about ten minutes and then called it Get-CloudInstance.

Then:

> The native provider detail still matters. I just keep it in metadata instead of forcing it into the public command name.

Then show the table and state the philosophy explicitly:

> Every command in this module started with the same question: is the operator intent genuinely the same across all three clouds? Not the implementation. Not the API shape. The intent. What is the person actually trying to find out?
>
> For compute, the answer is yes. You want to know what's running, where, and what state it's in. Azure, AWS, and GCP all have a concept that maps to that. So Get-CloudInstance exists.
>
> For storage -- buckets, accounts, whatever they call it -- the intent maps. For disks, for networks, for serverless functions. The intent is similar enough that a normalized command earns its place.
>
> And then there's IAM. Look at the last row. There's a dash where the PSCumulus command would be.
>
> That's not an omission. That's the test failing. AWS policy documents, Azure role assignments, GCP IAM bindings -- those are not the same operator intent wearing different clothes. The scoping is different, the inheritance model is different, the mental model you need to reason about them is different. Flattening them into one command would produce something that looks unified and lies about it.
>
> So the dash stays. The table is the philosophy made visible: normalization is only worth the cost when the thing you're normalizing is real.

Transition into Terraform:

> That's the case for the module as it currently stands. But there's an obvious question that usually surfaces around here.

## 18:00-21:00 Why Not Terraform

Goal:

- answer the obvious objection directly and credibly

Key message:

- Terraform is the right tool for provisioning
- PSCumulus is solving a different layer of the problem

Suggested language:

> At this point somebody is usually thinking, "why not just use Terraform?"
>
> And the answer is: Terraform solves a different problem.

Then make the distinction explicit:

> Terraform standardizes infrastructure.
>
> PSCumulus standardizes how humans interact with infrastructure across clouds.

Then expand:

> Terraform gives you desired state, provisioning, lifecycle management, drift correction.
>
> PSCumulus gives you command ergonomics, output normalization, interactive querying, and less cognitive switching cost during day-to-day operations.

Then the strongest line:

> Terraform standardizes what exists. PSCumulus standardizes how I think about and interact with what exists.

Then the shell line:

> Terraform is not an operational shell. PSCumulus is intentionally behaving like one.

Then avoid sounding oppositional:

> This is not Terraform versus PowerShell. It's Terraform for provisioning, and PSCumulus for cross-cloud interaction once the infrastructure already exists.

Transition into where it breaks:

> That distinction matters, and it's also what makes the next part honest. Because even at the operational-shell level, there are places where the abstraction doesn't hold, and where PSCumulus has to step back and say: no, this one is too different. We're not going to pretend.

## 21:00-23:30 Where The Abstraction Breaks

Goal:

- prove discipline
- show that good abstraction has edges

Key message:

- the module is useful because it refuses to lie

Suggested language:

> You saw the table. You saw the dash on IAM. This is where we talk about what that actually cost.
>
> IAM is where the module stopped me from pretending the clouds are the same. And it's worth going one level deeper on why, because the temptation to paper over it was real.
>
> Think about what a fake Get-CloudPermission command would actually have to do to work.
>
> In AWS, permissions are policy documents. JSON objects describing what actions are allowed or denied on what resources, attached to users, groups, or roles. In Azure, you have role assignments, which bind a named role to a principal at a particular scope in the resource hierarchy. In GCP, you have IAM bindings, which tie a member to a role on a project or resource.
>
> Those are not the same model. Different shapes, different scoping rules, different inheritance behaviors.
>
> So if I wrote Get-CloudPermission anyway, one of two things would happen. Either I'd flatten everything to the least common denominator and you'd lose the detail that actually matters. Or I'd put almost everything in Metadata, and the normalized object on top is nearly empty -- just a PSCumulus costume with nothing useful showing through.
>
> There's a rule I use for this: if the normalized object would be mostly Metadata, the abstraction is too weak to deserve a first-class public command.
>
> That's why there's no Get-CloudPermission in PSCumulus.

Then name the three explicit commands:

> Instead there are three explicit commands that don't claim to be the same thing: Get-AzureRoleAssignment, Get-AWSPolicyAttachment, Get-GCPIAMBinding. Three seams, left visible.

Before landing the lesson, name the gaps directly:

> Let me also name what this module does not do, because naming it is better than leaving you to find out later. There is no cost surface. There is no health or status surface. The output is read-oriented -- you can pipeline and filter but there are no corresponding write commands for most inventory queries. And there is no cross-cloud resource search by name. These are real gaps. I am naming them because the people most likely to ask about them deserve a straight answer.

Then land the lesson:

> The module is useful because it refuses to lie about the places where the providers are genuinely different. Adding Get-CloudPermission would have been easy to do and plausible-looking. It also would have been the thing that eventually burned the person who trusted the abstraction a little too far.
>
> Knowing when not to abstract is the actual skill. It's also, honestly, the harder one.

## 23:30-25:00 Close

Goal:

- leave the room with a lens, not a recap

Suggested language:

> I want to leave you with something that isn't a summary.
>
> We spend a lot of time in this field asking what the right tool is for a given job. And it's a good question. But there's another one I think about more now, and it's this: what is the tool you will still trust when the job gets weird?
>
> When you're on call and the environment is half-configured and you can't remember which cloud you're supposed to be in. When you need to move fast and you genuinely cannot afford a mistake and you need your hands to know what to do without looking it up.
>
> Those are the moments where fluency matters more than optimality. And fluency is built over time, on tools you already know.
>
> For me, it was PowerShell. That's the map I drew. I hope some of it is useful to you.

But building the module taught me something I didn't expect:

> But building the module taught me something I didn't expect. Every command required me to ask: what IS this thing, actually, across all three clouds? What do they share? Where do they diverge? That question turned out to be more useful than the command. The module is evidence for an argument about where the clouds are genuinely the same and where they're not. The IAM section isn't where the module failed. It's where the thinking worked.

Then finish simply:

- repo link
- thank the audience
- stop

## Slides by job

Each slide should have a clear purpose.

- title: establish topic and tone
- wreck: recognition
- why hard: relief
- IAM philosophy: proof that the systems differ
- why PowerShell: emotional anchor
- stable lens: thesis
- credential chaos: the practical pain
- ask the intent first: bridge into abstraction
- abstraction bet: transition into the module
- compute native: show translation problem
- compute unified: show translation solution
- shared output shape: show why the solution matters
- why the name matters: explain noun choice and normalization
- storage next: show second example and edge pressure
- metadata next: show third example and increasing seams
- why not Terraform: define different layer
- different layer: make the distinction concrete
- output matters: reinforce the operator experience argument
- where it breaks: prime the limitation
- failure is the lesson: show disciplined abstraction
- reframe: closing idea

## What to avoid

- do not over-explain three cloud platforms in 25 minutes
- do not become defensive about Terraform
- do not promise production-grade completeness
- do not let the module overshadow the human story
- do not read bullets verbatim

## Rehearsal goals

By the next pass, the goal should be:

- the opening two minutes can be delivered nearly word-for-word
- the Terraform section can be delivered confidently in under two minutes
- the IAM section feels crisp, not apologetic
- the close lands as a thought, not a summary
