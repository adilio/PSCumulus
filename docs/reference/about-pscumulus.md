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
- `Get-CloudContext`
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
| `conc` | `Connect-Cloud` |
| `gcont` | `Get-CloudContext` |
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

`Get-CloudContext` returns `PSCumulus.CloudContext` objects with these properties:

- `Provider`
- `IsActive`
- `Account`
- `Scope`
- `Region`
- `ConnectedAt`

## Provider Context

`Connect-Cloud` is the session readiness command. It does not assume you are already authenticated. Instead it:

1. Checks whether required provider tools are installed
2. Detects whether an active authentication session exists
3. Triggers the provider-native login flow automatically if not authenticated
4. Stores a normalized per-provider session context

The authentication check and login trigger differ per provider because the providers are genuinely different:

- **Azure**: checks `Get-AzContext`; calls `Connect-AzAccount` if no session exists
- **AWS**: checks environment variables and `~/.aws` credential files; proceeds through `Initialize-AWSDefaultConfiguration`
- **GCP**: checks `gcloud auth list` for an active account; calls `gcloud auth application-default login` if none is found

Session context is stored per provider. Connecting to Azure, then AWS, then GCP leaves all three contexts available for the duration of the session.

After connecting, the active provider is remembered so that many public commands can omit `-Provider` when the remaining parameters already imply the target cloud or when the active provider makes the intent unambiguous.

Use `Get-CloudContext` at any time to inspect all established provider sessions.

## Limits

PSCumulus does not attempt to unify domains such as IAM, RBAC, policy documents, or billing. Those models differ too much across providers to support an honest shared command surface.
