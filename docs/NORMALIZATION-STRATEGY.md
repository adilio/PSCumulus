# Normalization Strategy

`PSCumulus` borrows a simple version of the normalization philosophy used by products like Wiz:

- keep one cross-cloud concept when the user intent is genuinely the same
- preserve the provider's native shape in metadata instead of pretending the clouds are identical
- stop normalizing when the underlying models are meaningfully different

This is a talk demo module, so the goal is not to build a giant ontology. The goal is to make common cross-cloud tasks easier to reason about without lying about the underlying platforms.

## Core philosophy

Normalize by **intent**, not by provider naming.

Examples:

- `Get-CloudInstance` should represent the idea of "show me compute instances"
- `Get-CloudStorage` should represent the idea of "show me storage resources"
- `Get-CloudTag` should represent the idea of "show me resource metadata"

The provider-native names still matter:

- AWS EC2 Instance
- Azure Virtual Machine
- GCP Compute Instance

But they matter as **native types**, not as the primary public abstraction.

## Naming philosophy

Public PSCumulus nouns should be:

- clear to a human operator
- broad enough to cover the same intent across clouds
- narrow enough to avoid becoming vague
- unlikely to collide with common provider-specific or virtualization module commands

That is why PSCumulus currently prefers names like:

- `Get-CloudInstance`
- `Get-CloudStorage`
- `Get-CloudTag`

instead of shorter nouns like:

- `Get-VM`
- `Get-Bucket`

The shorter nouns are not always wrong, but they create two problems for this module:

1. they can collide conceptually with existing ecosystem commands in Hyper-V or other infrastructure tooling
2. they can imply a stricter one-to-one resource match than PSCumulus can honestly guarantee across providers

Concrete example:

- `Get-VM` is already a Hyper-V command in the PowerShell ecosystem

That makes `Get-CloudInstance` a better public noun for PSCumulus even if "VM" feels shorter or more familiar.

So the naming pattern is:

- use `Cloud*` nouns for the normalized public surface
- preserve native provider terminology in `Metadata`
- only split into narrower nouns later if the abstraction becomes clearer rather than noisier

## What PSCumulus should normalize

Normalize only the fields that support real cross-cloud workflows:

- `Name`
- `Provider`
- `Region`
- `Status`
- `Size`
- `CreatedAt`
- `Metadata`

These fields are the stable cross-cloud contract. They should exist wherever the provider exposes enough data to fill them honestly.

For example:

- `CloudInstance` is the shared compute noun
- `CloudStorage` is the current shared storage noun

That does **not** mean every provider uses the same native resource:

- AWS may surface an EC2 instance or S3 bucket
- Azure may surface a virtual machine or storage account/container-adjacent object
- GCP may surface a compute instance or bucket

The public noun is the operator-facing abstraction. The native type still belongs in `Metadata`.

## What PSCumulus should preserve as native detail

Anything that does not map cleanly should stay in `Metadata`.

Examples:

- Azure resource group, VM ID, OS type
- AWS instance ID, subnet ID, VPC ID, private/public IPs
- GCP project, zone, labels, network interface details

This gives us a common object shape without throwing away provider-specific signal.

## What PSCumulus should not normalize

Do not force a shared noun when the providers are expressing genuinely different systems.

Current explicit non-normalization areas:

- IAM and role/binding models
- advanced networking constructs
- provider-specific policy systems
- any service where the common denominator is too vague to be useful

Rule of thumb:

If the normalized object would be mostly `Metadata`, the abstraction is probably too weak to deserve a first-class public command.

## Native type pattern

Each normalized PSCumulus object should still carry its source identity.

Recommended approach:

- keep the public noun normalized
- add provider-native identifiers and labels in `Metadata`
- optionally add `NativeType` later if it becomes useful for display or debugging

Example:

```powershell
[pscustomobject]@{
    Name      = 'web-01'
    Provider  = 'AWS'
    Region    = 'us-east-1a'
    Status    = 'Running'
    Size      = 't3.small'
    CreatedAt = [datetime]'2026-03-01T12:34:56Z'
    Metadata  = @{
        NativeType = 'EC2 Instance'
        InstanceId = 'i-0123456789abcdef0'
        VpcId      = 'vpc-01234567'
    }
}
```

## Implementation guidance

When adding a new public command:

1. Identify the cross-cloud intent first.
2. Define the smallest honest shared field set.
3. Map provider-native fields into that shared shape.
4. Put everything else in `Metadata`.
5. Do not add a public abstraction if the providers are too semantically different.

When adding a new provider backend:

1. Fetch native data as directly as possible.
2. Normalize only at the adapter boundary.
3. Avoid leaking raw provider object graphs out of public commands.
4. Keep the public output consistent even if the provider fetch mechanism differs.

## Current normalized surfaces

- `Connect-Cloud`
- `Get-CloudInstance`

## Planned normalized surfaces

- `Get-CloudStorage`
- `Get-CloudTag`

## Deliberate non-goals

- A complete cross-cloud object taxonomy
- One-to-one coverage of every provider resource
- Hiding every provider difference from the caller
- Matching Wiz's scope or graph depth

## Practical takeaway

PSCumulus should feel like:

- a thin cross-cloud lens for common operations

Not like:

- a universal cloud control plane
