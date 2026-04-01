# Talk Track

This file is the working narrative for the Summit talk. It is not slide copy. It is the spoken argument underneath the deck.

## Core framing

This talk is not just about PowerShell or multi-cloud syntax.

It is about:

- cognitive load
- operator ergonomics
- stable interfaces
- knowing where abstraction helps and where it lies

## One-line thesis

> Terraform standardizes infrastructure. PSCumulus standardizes how humans interact with infrastructure across clouds.

## The Terraform answer

When someone asks "why not Terraform?", the answer is:

- Terraform standardizes desired state and provisioning
- PSCumulus standardizes interactive operations and command-level ergonomics

Terraform solves:

- desired state
- provisioning
- lifecycle management
- drift correction

PSCumulus solves:

- cross-cloud operational ergonomics
- command-level abstraction
- output normalization
- interactive exploration
- reduced cognitive switching cost

Short version:

> Terraform is not an operational shell. PSCumulus is intentionally behaving like one.

## The strongest comparison

Terraform standardizes **what exists**.

PSCumulus standardizes **how you think about and interact with what exists**.

That is the difference.

## Output argument

One of the clearest technical distinctions is output.

PSCumulus is trying to guarantee:

- same command shape
- same output shape
- same operator mental model

Terraform does not try to solve that problem.

Useful line:

> Terraform maps clouds into a shared resource model. PSCumulus maps them into a shared intent model.

## Cognitive load argument

The pain in multi-cloud is not only provisioning. It is:

- different nouns
- different auth flows
- different command structures
- different output shapes
- different hidden assumptions

PSCumulus exists to reduce that switching cost.

Useful line:

> Multi-cloud pain isn't "how do I create a VM." It's "why does the same idea behave differently in three places?"

## IAM proof point

IAM is the best proof that this is not just a naming exercise.

- AWS uses policy documents
- Azure uses role assignments
- GCP uses bindings

That is why PSCumulus should abstract where intent is genuinely shared and stop where the systems are fundamentally different.

Useful line:

> Terraform sometimes hides differences. PSCumulus makes a deliberate decision about where abstraction is useful and where it becomes misleading.

## Naming philosophy for the talk

Use the `Cloud*` nouns as deliberate evidence of design, not as generic filler.

Why `Get-CloudInstance` instead of `Get-VM`:

- it avoids collisions with existing module ecosystems
- it signals a normalized public surface
- it leaves room for different native compute resources underneath

Why `Get-CloudStorage` instead of `Get-Bucket` right now:

- it keeps the abstraction honest while Azure storage semantics are still being worked through
- it leaves room to split into narrower nouns later if the model becomes clearer

## Sound bite version

> Terraform is for provisioning. PSCumulus is for operating.
>
> Terraform gives you a state engine. PSCumulus gives you an interface.
>
> Terraform abstracts resources. PSCumulus abstracts intent.

## Closing thought

The repo should defend this clearly:

- Terraform is not the wrong tool
- it is the wrong layer for the problem this module is addressing

That makes PSCumulus complementary rather than competitive.

