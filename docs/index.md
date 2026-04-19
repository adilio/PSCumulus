# PSCumulus

`PSCumulus` is a thin cross-cloud PowerShell abstraction for Azure, AWS, and GCP.

It keeps a small set of high-value cloud tasks consistent in the shell without pretending every provider concept maps cleanly to the same thing.

## What The Module Does

- Connect to Azure, AWS, or GCP with a single verb-noun entry point
- Query common infrastructure categories with a shared command shape
- Search by name across connected clouds when the provider or resource kind is unknown
- Export point-in-time inventory for audit, demo, and comparison work
- Surface supported regions for completion and scripting
- Return a stable inventory object for cross-cloud inspection
- Normalize tags and labels from all three providers into a consistent `Tags` hashtable
- Keep provider-native details available in `Metadata`

## Public Commands

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

## Documentation Layout

- Use [Getting Started](getting-started.md) for installation and first commands
- Use [Strategy](concepts/strategy.md) for project rationale and normalization rules
- Use [Evolution](concepts/evolution.md) for the full staged roadmap, origin story, and architectural rationale
- Use [Reference](reference/index.md) for generated command documentation

## PowerShell Help

The module also exposes native help:

```powershell
Get-Help about_PSCumulus
Get-Help Connect-Cloud -Detailed
Get-Help Get-CloudInstance -Examples
```
