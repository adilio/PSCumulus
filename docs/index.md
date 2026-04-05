# PSCumulus

`PSCumulus` is a thin cross-cloud PowerShell abstraction for Azure, AWS, and GCP.

It keeps a small set of high-value cloud tasks consistent in the shell without pretending every provider concept maps cleanly to the same thing.

## What The Module Does

- Connect to Azure, AWS, or GCP with a single verb-noun entry point
- Query common infrastructure categories with a shared command shape
- Return a stable inventory object for cross-cloud inspection
- Keep provider-native details available in `Metadata`

## Public Commands

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

## Documentation Layout

- Use [Getting Started](getting-started.md) for installation and first commands
- Use [Strategy](concepts/strategy.md) for project rationale and normalization rules
- Use [Reference](reference/index.md) for generated command documentation

## PowerShell Help

The module also exposes native help:

```powershell
Get-Help about_PSCumulus
Get-Help Connect-Cloud -Detailed
Get-Help Get-CloudInstance -Examples
```
