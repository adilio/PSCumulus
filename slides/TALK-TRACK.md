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

> The first wall everybody hits is auth. Three clouds, three login models, three places credentials can live. That's where the wrapper started.

Then connect to the naming insight:

> The verb-noun model turns out to be a superpower here, because it makes you ask, "what am I actually trying to do?" before you ask, "what does this provider call it?"

## 9:00-15:00 Same Intent, Different Providers

Goal:

- show the module doing something useful and legible

Key message:

- PSCumulus is not abstracting "all cloud"
- it is abstracting repeated operator intent

Suggested transition:

> The useful question stopped being, "what is the AWS equivalent of Get-AzVM?" and became, "what is the stable operator intent underneath all of this?"

For compute:

> Across all three clouds, I can ask for compute instances. The provider names differ, the APIs differ, the outputs differ, but the operator intent is stable.

For storage:

> Same idea with storage, although this is already where the edges start to show a little more.

For metadata:

> Tags and labels are another good example because they matter operationally, but they never line up quite as cleanly as you'd hope.

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
> The other reason is practical: PowerShell already has a `Get-VM` command in the Hyper-V world. I did not want this module pretending it owned that noun.

Then:

> The native provider detail still matters. I just keep it in metadata instead of forcing it into the public command name.

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

## 21:00-23:30 Where The Abstraction Breaks

Goal:

- prove discipline
- show that good abstraction has edges

Key message:

- the module is useful because it refuses to lie

Suggested language:

> The best part of building this was not where it worked. It was where it broke.
>
> IAM is where the module stopped me from pretending the clouds are the same.

Then:

> You cannot honestly write `Get-CloudPermission` and have it mean the same thing everywhere.
>
> Not really.

Then name the three explicit commands:

> So instead of forcing one fake abstraction, I kept three clear ones: Azure role assignments, AWS policy attachments, GCP IAM bindings.

Then land the lesson:

> Knowing when not to abstract is the actual skill.

And tie it back to Terraform carefully:

> Sometimes tools hide differences until those differences hurt you. I wanted this module to abstract the repeated intent but still respect the real seams.

## 23:30-25:00 Close

Goal:

- leave the room with a lens, not a recap

Suggested language:

> We spend a lot of time asking, "what's the right tool for the job?"
>
> I think there's another question that's just as important:
>
> What's the tool you'll still trust when the job gets weird?
>
> Those are not always the same answer.

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

