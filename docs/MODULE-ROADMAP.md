# Module Roadmap

`PSCumulus` is intentionally a thin abstraction, not a full cloud framework.

## First implementation targets

1. `Connect-Cloud`
2. `Get-CloudInstance`
3. `Get-CloudStorage` or `Get-CloudTag`
4. One explicit non-abstraction example for IAM

## Current implementation state

- Azure: `Connect-Cloud` and `Get-CloudInstance` backend path implemented via `Az.*`
- AWS: `Connect-Cloud` and `Get-CloudInstance` backend path implemented via `AWS.Tools.*`
- GCP: `Connect-Cloud` and `Get-CloudInstance` backend path implemented via `gcloud`
- Storage and tag backends: still scaffolded

## Output contract

Public inventory-style commands should normalize results into a single object shape:

- `Name`
- `Provider`
- `Region`
- `Status`
- `Size`
- `CreatedAt`
- `Metadata`

See also: `docs/NORMALIZATION-STRATEGY.md`

## Public naming

The normalized public surface should continue using `Cloud*` nouns for now:

- `Get-CloudInstance`
- `Get-CloudStorage`
- `Get-CloudTag`

That naming keeps the abstraction explicit and avoids boxing the module into provider-native nouns too early.

## Provider strategy

- Azure: wrap `Az.*`
- AWS: wrap `AWS.Tools.*`
- GCP: prefer `gcloud ... --format=json` for Summit scope

## GCP implementation decision

For PSCumulus v1, GCP support should use the `gcloud` CLI as an adapter boundary instead of Cloud Tools for PowerShell or direct REST calls.

Why:

- It matches Google's mainstream scripting story better than a PowerShell-specific SDK path.
- It keeps authentication practical through `gcloud auth login` and `gcloud auth application-default login`.
- It allows stable machine-readable output with `--format=json`.
- It avoids pulling REST auth, pagination, and endpoint plumbing into a Summit-scoped proof of concept.

Implementation approach:

1. Add a shared helper that verifies `gcloud` is installed and invokes commands with `--format=json`.
2. Prefer passing `--project` explicitly instead of mutating global `gcloud` configuration in the module.
3. Keep `Connect-GCPBackend` focused on dependency and auth/context validation, not on owning the whole Google auth lifecycle.
4. Implement `Get-GCPInstanceData` with `gcloud compute instances list --project <project> --format=json`.
5. Leave storage and labels/tags for the next pass after instance inventory is solid.

## Non-goals

- Full networking abstraction
- Full IAM abstraction
- Complete parity across providers
- Production-ready orchestration surface
- A custom OAuth or REST authentication stack for Google Cloud in v1
