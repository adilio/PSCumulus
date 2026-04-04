# About PSCumulus

`PSCumulus` is a thin PowerShell abstraction for common cross-cloud tasks across Azure, AWS, and GCP.

The module standardizes a small set of high-value commands for interactive work and demos without pretending that every provider concept maps cleanly to a universal object model.

## Focus Areas

- connect to a provider
- query common infrastructure categories
- start and stop compute instances
- return a stable output shape for inventory-style commands

## Commands

- `Connect-Cloud`
- `Get-CloudInstance`
- `Get-CloudStorage`
- `Get-CloudTag`
- `Get-CloudNetwork`
- `Get-CloudDisk`
- `Get-CloudFunction`
- `Start-CloudInstance`
- `Stop-CloudInstance`

## Aliases

| Alias | Command |
|---|---|
| `cc` | `Connect-Cloud` |
| `gcin` | `Get-CloudInstance` |
| `sci` | `Start-CloudInstance` |
| `tci` | `Stop-CloudInstance` |

## Output Types

Inventory commands return `PSCumulus.CloudRecord` objects with these common properties:

- `Name`
- `Provider`
- `Region`
- `Status`
- `Size`
- `CreatedAt`
- `Metadata`

`Connect-Cloud` returns `PSCumulus.ConnectionResult`.

## Provider Context

`Connect-Cloud` remembers the active provider for the current session. After connecting, many public commands can omit `-Provider` when the remaining parameters already imply the target cloud or when the active provider makes the intent unambiguous.

## Limits

PSCumulus does not attempt to unify domains such as IAM, RBAC, policy documents, or billing. Those models differ too much across providers to support an honest shared command surface.
