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

> **Note:** GCP doesn't have a maintained PowerShell module, so there's no `Install-Module` equivalent. Install the `gcloud` CLI for your platform using the link above.

## Install The Module

```powershell
Install-Module PSCumulus -Scope CurrentUser
Import-Module PSCumulus
```

## Connect To A Provider

```powershell
Connect-Cloud -Provider Azure
Connect-Cloud -Provider AWS -Region "us-east-1"
Connect-Cloud -Provider GCP -Project "my-project"
```

`Connect-Cloud` does more than set a provider. It checks whether you are already authenticated and triggers the provider-native login flow automatically if not. If you are already logged in, it skips login and stores the session context directly.

`Connect-Cloud` remembers the active provider for the current session. In interactive use, many later commands can omit `-Provider` when the remaining parameters already imply the target cloud or when the current provider makes the intent clear.

```powershell
Connect-Cloud -Provider AWS -Region "us-east-1"

Get-CloudInstance -Region "us-east-1"
Start-CloudInstance -InstanceId "i-0abc123" -Region "us-east-1"
Get-CloudTag -ResourceId "i-0abc123"
```

Pass `-Provider` explicitly whenever you want to override the remembered provider.

## Check Your Session

After connecting to one or more providers, use `Get-CloudContext` to see all established sessions:

```powershell
Get-CloudContext
```

```
Provider ConnectionState Account            Scope        Region
-------- -------------- -------            -----        ------
Azure    Connected      adil@contoso.com   my-sub
AWS      Current        default            default      us-east-1
GCP      Connected      adil@example.com   my-project
```

`ConnectionState` shows which provider is active right now without making the
others look disconnected. Providers not yet connected are omitted from the output.

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
| `conc` | `Connect-Cloud` |
| `gcont` | `Get-CloudContext` |
| `gcin` | `Get-CloudInstance` |
| `sci` | `Start-CloudInstance` |
| `tci` | `Stop-CloudInstance` |

Use the full command names in scripts and shared examples.
