# PSCumulus Talk Demo

## Setup

```powershell
Install-Module PSCumulus -Scope CurrentUser
Import-Module PSCumulus
Invoke-WebRequest https://raw.githubusercontent.com/adilio/PSCumulus/main/scripts/demo-setup.ps1 -OutFile demo-setup.ps1
. ./demo-setup.ps1
```

---

## Connect

```powershell
Connect-Cloud -Provider Azure, AWS, GCP
```

---

## Inventory

```powershell
Get-CloudInstance -All
```

```powershell
Get-CloudInstance -All | Where-Object { $_.Tags['environment'] -eq 'prod' }
```

```powershell
Get-CloudInstance -All | Group-Object Provider | Select-Object Name, Count
```

---

## Tagging compliance

```powershell
Get-CloudInstance -All | Where-Object { -not $_.Tags['owner'] }
```

---

## Cost waste candidates

```powershell
$cutoff = (Get-Date).AddDays(-30)
Get-CloudInstance -All |
    Where-Object { $_.Status -ne 'Running' -and $_.CreatedAt -lt $cutoff } |
    Select-Object Name, Provider, Status, CreatedAt |
    Format-Table -AutoSize
```

---

## Fleet health

```powershell
Get-CloudInstance -All |
    Group-Object Provider, Status |
    Select-Object Name, Count |
    Sort-Object Count -Descending |
    Format-Table -AutoSize
```

---

## Cost-center rollup

```powershell
Get-CloudInstance -All |
    Group-Object { $_.Tags['cost-center'] } |
    Select-Object Name, Count |
    Sort-Object Count -Descending |
    Format-Table -AutoSize
```

---

## Oldest instances

```powershell
Get-CloudInstance -All |
    Where-Object { $_.CreatedAt } |
    Sort-Object CreatedAt |
    Select-Object Name, Provider, Region, CreatedAt -First 5 |
    Format-Table -AutoSize
```

---

## Run everything at once

```powershell
Invoke-AllDemoQueries
```

---

## Cleanup

```powershell
Remove-DemoSetup             # unload module, remove demo functions from session
Remove-DemoSetup -Uninstall  # also uninstall PSCumulus from the system
```
