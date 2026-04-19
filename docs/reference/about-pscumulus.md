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
- `Disconnect-Cloud`
- `Export-CloudInventory`
- `Find-CloudResource`
- `Get-CloudContext`
- `Get-CloudDisk`
- `Get-CloudFunction`
- `Get-CloudInstance`
- `Get-CloudNetwork`
- `Get-CloudRegion`
- `Get-CloudStorage`
- `Get-CloudTag`
- `Resolve-CloudPath`
- `Restart-CloudInstance`
- `Set-CloudTag`
- `Start-CloudInstance`
- `Stop-CloudInstance`
- `Test-CloudConnection`

## Aliases

| Alias | Command |
|---|---|
| `conc` | `Connect-Cloud` |
| `fcr` | `Find-CloudResource` |
| `gcont` | `Get-CloudContext` |
| `gcin` | `Get-CloudInstance` |
| `rci` | `Restart-CloudInstance` |
| `sci` | `Start-CloudInstance` |
| `sct` | `Set-CloudTag` |
| `tci` | `Test-CloudConnection` |

## Output Types

Inventory commands return `PSCumulus.CloudRecord` objects with these common properties:

- `Name`
- `Provider`
- `Region`
- `Status`
- `Size`
- `PrivateIpAddress`
- `PublicIpAddress`
- `Tags`
- `CreatedAt`
- `Metadata`

For instance inventory, the shared contract is now backed by a real base class with vendor subclasses. Common provider identity fields such as Azure `ResourceGroup`, AWS `InstanceId`, and GCP `Project` are first-class properties on those vendor-specific instance records rather than living only in `Metadata`.

`Connect-Cloud` returns `PSCumulus.ConnectionResult`.

`Get-CloudContext` returns `PSCumulus.CloudContext` objects with these properties:

- `Provider`
- `ConnectionState`
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
