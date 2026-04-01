# Module Roadmap

`PSCumulus` is intentionally a thin abstraction, not a full cloud framework.

## First implementation targets

1. `Connect-Cloud`
2. `Get-CloudInstance`
3. `Get-CloudStorage` or `Get-CloudTag`
4. One explicit non-abstraction example for IAM

## Output contract

Public inventory-style commands should normalize results into a single object shape:

- `Name`
- `Provider`
- `Region`
- `Status`
- `Size`
- `CreatedAt`
- `Metadata`

## Provider strategy

- Azure: wrap `Az.*`
- AWS: wrap `AWS.Tools.*`
- GCP: prefer `gcloud ... --format=json` for Summit scope

## Non-goals

- Full networking abstraction
- Full IAM abstraction
- Complete parity across providers
- Production-ready orchestration surface

