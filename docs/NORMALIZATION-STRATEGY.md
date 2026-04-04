# Normalization Strategy

PSCumulus borrows a simple normalization philosophy: keep one cross-cloud concept when the user intent is the same, preserve native details in `Metadata`, and stop normalizing when the underlying models are meaningfully different.

## Core philosophy

Normalize by **intent**, not by provider naming.

- `Get-CloudInstance` = "show me compute instances" — not "show me VMs"
- `Get-CloudStorage` = "show me storage resources" — not "show me buckets"
- `Get-CloudNetwork` = "show me virtual networks" — not "show me VPCs"

The provider-native resource (EC2 Instance, Azure Virtual Machine, GCP Compute Instance) still matters — it belongs in `Metadata`, not in the public noun.

## What to normalize

The stable cross-cloud contract — fields that support real cross-cloud workflows:

| Field       | Maps from                                                       |
|-------------|-----------------------------------------------------------------|
| `Name`      | VM name, bucket name, volume name, etc.                         |
| `Provider`  | Always `Azure`, `AWS`, or `GCP`                                 |
| `Region`    | Azure location, AWS AZ, GCP zone                                |
| `Status`    | Normalized to title-case (Running, Stopped, Available, etc.)    |
| `Size`      | VM SKU, instance type, storage class, disk size string          |
| `CreatedAt` | Creation timestamp where available; omitted when not            |
| `Metadata`  | Everything else — provider-native IDs, IPs, labels, etc.        |

## What to put in Metadata

Anything that does not map cleanly goes in `Metadata`. Examples:

- Azure: ResourceGroup, VmId, OsType, Sku, AccessTier
- AWS: InstanceId, VpcId, SubnetId, VolumeType, Encrypted
- GCP: Project, Zone, Labels, DiskType, AutoCreateSubnetworks

## What not to normalize

Do not force a shared noun when the providers have genuinely different models.

**Explicit non-normalization areas:**

- **IAM / roles / policies** — AWS policy documents, Azure RBAC assignments, and GCP IAM bindings are three incompatible philosophies. Write three explicit functions; do not pretend they are the same thing.
- **Advanced networking** — load balancers, firewalls, and security groups diverge too much.
- **Billing / cost** — schemas are wildly provider-specific; the normalized object would be mostly `Metadata`, which is the signal to stop.

**Rule of thumb:** if the normalized object would be mostly `Metadata`, the abstraction is too weak to deserve a first-class public command.

## Naming convention

Public nouns use `Cloud*`:

- `Get-CloudInstance` (not `Get-VM`)
- `Get-CloudStorage` (not `Get-Bucket`)
- `Get-CloudNetwork` (not `Get-VPC`)

This keeps the abstraction explicit, avoids collision with ecosystem commands like `Get-VM` (Hyper-V), and signals that the output is a normalized shape rather than a native object.

## When adding a new command

1. Identify the cross-cloud intent first.
2. Define the smallest honest shared field set.
3. Map provider-native fields into that shape.
4. Put everything else in `Metadata`.
5. If the providers are too semantically different, don't add the public abstraction.

## Example record

```powershell
[pscustomobject]@{
    Name      = 'web-01'
    Provider  = 'AWS'
    Region    = 'us-east-1a'
    Status    = 'Running'
    Size      = 't3.small'
    CreatedAt = [datetime]'2026-03-01T12:34:56Z'
    Metadata  = @{
        InstanceId       = 'i-0123456789abcdef0'
        VpcId            = 'vpc-01234567'
        PrivateIpAddress = '10.0.1.5'
    }
}
```

The type name is always `PSCumulus.CloudRecord`.
