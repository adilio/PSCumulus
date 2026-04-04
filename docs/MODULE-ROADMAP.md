# Module Roadmap

`PSCumulus` is a thin cross-cloud abstraction, not a full cloud framework.

## Current state

461/461 tests passing. All planned commands implemented across all three providers.

| Command              | Azure                    | AWS                        | GCP                                    |
|----------------------|--------------------------|----------------------------|----------------------------------------|
| `Connect-Cloud`      | `Connect-AzAccount`      | `Set-AWSCredential`        | `gcloud auth`                          |
| `Get-CloudInstance`  | `Get-AzVM`               | `Get-EC2Instance`          | `gcloud compute instances list`        |
| `Get-CloudStorage`   | `Get-AzStorageAccount`   | `Get-S3Bucket`             | `gcloud storage buckets list`          |
| `Get-CloudTag`       | `Get-AzTag`              | `Get-EC2Tag`               | `gcloud compute TYPE list --filter`    |
| `Get-CloudNetwork`   | `Get-AzVirtualNetwork`   | `Get-EC2Vpc`               | `gcloud compute networks list`         |
| `Get-CloudDisk`      | `Get-AzDisk`             | `Get-EC2Volume`            | `gcloud compute disks list`            |
| `Get-CloudFunction`  | `Get-AzFunctionApp`      | `Get-LMFunctionList`       | `gcloud functions list`                |
| `Start-CloudInstance`| `Start-AzVM`             | `Start-EC2Instance`        | `gcloud compute instances start`       |
| `Stop-CloudInstance` | `Stop-AzVM`              | `Stop-EC2Instance`         | `gcloud compute instances stop`        |

## Output contract

All inventory commands normalize results into `PSCumulus.CloudRecord`:

| Field       | Description                          |
|-------------|--------------------------------------|
| `Name`      | Resource name                        |
| `Provider`  | `Azure` / `AWS` / `GCP`             |
| `Region`    | Cloud region or zone                 |
| `Status`    | Normalized state string              |
| `Size`      | Instance type, SKU, or storage class |
| `CreatedAt` | Creation timestamp (where available) |
| `Metadata`  | Provider-native details              |

See [`NORMALIZATION-STRATEGY.md`](./NORMALIZATION-STRATEGY.md) for the decision guide.

## Provider strategy

- **Azure:** wrap `Az.*` SDK modules
- **AWS:** wrap `AWS.Tools.*` SDK modules
- **GCP:** `gcloud ... --format=json` via `Invoke-GCloudJson` helper

GCP uses the CLI adapter because Google's PowerShell SDK story is less central than Az or AWS.Tools. The `gcloud` path gives stable JSON output and keeps auth aligned with `gcloud auth login`.

## Non-goals

- Full IAM / role / binding abstraction — models are too different; write three explicit functions instead
- Provisioning (`New-Cloud*`, `Remove-Cloud*`) — that's Terraform's domain
- Advanced networking (load balancers, firewalls, security groups) — models diverge too much
- `Get-CloudCost` — billing schemas are too provider-specific; output would be mostly `Metadata`
- Complete parity across every provider resource
