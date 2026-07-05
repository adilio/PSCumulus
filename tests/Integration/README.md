# Integration tests (skipped by default)

Everything under `tests/` outside this folder is fully mocked. The tests in
this folder are the opposite: they run against **real** cloud accounts, so
they are skipped unless explicitly enabled. `Invoke-Pester -Path tests` will
always show them as skipped in a normal run.

## Enabling

Two gates must both open:

1. Set the master switch:

   ```powershell
   $env:PSCUMULUS_INTEGRATION = '1'
   ```

2. Provide credentials for each provider you want to exercise. A provider
   without its variables stays skipped, so you can light up one cloud at a
   time.

| Provider | Required env vars | Notes |
|---|---|---|
| Azure | `PSCUMULUS_AZURE_SUBSCRIPTION` (subscription id or name), `PSCUMULUS_AZURE_RESOURCE_GROUP` | Needs `Az.Accounts`/`Az.Compute` installed and an identity that can `Reader` the subscription. Interactive `Connect-AzAccount` or a service principal via `AZURE_*` env vars both work. |
| AWS | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `PSCUMULUS_AWS_REGION` | Needs `AWS.Tools.EC2`. The key needs `ec2:Describe*` at minimum. |
| GCP | `PSCUMULUS_GCP_PROJECT` | Needs the `gcloud` CLI authenticated (`gcloud auth login`) with `compute.instances.list` on the project. |

## Account guidance

Use **throwaway accounts/projects only** — never a production tenant:

- Azure: a dedicated subscription (or a free-tier sub) with one empty
  resource group named in `PSCUMULUS_AZURE_RESOURCE_GROUP`.
- AWS: a sandbox account under an Organizations OU with an IAM user scoped to
  read-only EC2.
- GCP: a disposable project with billing capped at $0 where possible.

The round-trip templates assert the call path (connect → context → list),
not resource contents, so empty accounts are fine.

## Running

```powershell
$env:PSCUMULUS_INTEGRATION = '1'
# ...set provider vars...
Invoke-Pester -Path tests/Integration -Output Detailed
```

Or filter by tag from the repo root:

```powershell
Invoke-Pester -Path tests -TagFilter Integration -Output Detailed
```

## Extending

`Connect-CloudRoundTrip.Tests.ps1` is a template, not a suite. When real
throwaway accounts exist, grow coverage command-by-command (inventory kinds,
tagging round trips with cleanup, lifecycle start/stop on a nano instance),
keeping every test idempotent and safe to re-run.
