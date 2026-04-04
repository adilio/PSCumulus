# Reference

This section combines authored module guidance with generated command reference.

## What Lives Here

- [About PSCumulus](about-pscumulus.md): module overview in the style of an `about_` help topic
- [Module](module.md): generated module reference
- `commands/`: generated command reference created from comment-based help with PlatyPS

## Regenerating The Reference Docs

Run the docs generator from the repo root:

```powershell
./scripts/Update-Docs.ps1
```

That script imports the module, generates command markdown with `Microsoft.PowerShell.PlatyPS`, and updates the files under `docs/reference/commands/`.
