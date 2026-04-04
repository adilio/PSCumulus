# Getting Started

## Requirements

```powershell
# Azure
Install-Module Az -Scope CurrentUser

# AWS
Install-Module AWS.Tools.EC2, AWS.Tools.S3 -Scope CurrentUser

# GCP
# Requires the gcloud CLI:
# https://cloud.google.com/sdk/docs/install
```

## Import The Module

```powershell
Import-Module PSCumulus
```

## Connect To A Provider

```powershell
Connect-Cloud -Provider Azure
Connect-Cloud -Provider AWS -Region "us-east-1"
Connect-Cloud -Provider GCP -Project "my-project"
```

`Connect-Cloud` remembers the active provider for the current session. In interactive use, many later commands can omit `-Provider` when the remaining parameters already imply the target cloud or when the current provider makes the intent clear.

```powershell
Connect-Cloud -Provider AWS -Region "us-east-1"

Get-CloudInstance -Region "us-east-1"
Start-CloudInstance -InstanceId "i-0abc123" -Region "us-east-1"
Get-CloudTag -ResourceId "i-0abc123"
```

Pass `-Provider` explicitly whenever you want to override the remembered provider.

## Common Examples

```powershell
Get-CloudInstance -Provider Azure -ResourceGroup "prod-rg"
Get-CloudStorage -Provider AWS -Region "us-east-1"
Get-CloudTag -Provider GCP -Project "my-project" -Resource "instances/web-01"
Start-CloudInstance -Provider AWS -InstanceId "i-0abc123" -Region "us-east-1"
Stop-CloudInstance -Provider Azure -Name "web-01" -ResourceGroup "prod-rg"
```

## Interactive Aliases

These aliases are exported for terminal convenience:

| Alias | Command |
|---|---|
| `cc` | `Connect-Cloud` |
| `gcin` | `Get-CloudInstance` |
| `sci` | `Start-CloudInstance` |
| `tci` | `Stop-CloudInstance` |

Use the full command names in scripts and shared examples.
