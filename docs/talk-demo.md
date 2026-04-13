# PSCumulus Talk Demo — Cheat Sheet

Copy-paste blocks aligned to *Cross-Cloud without Crossed Fingers* (Summit 2026). `demo-setup.ps1` injects simulated data, so every command below runs offline and returns the same output every time.

Ordering mirrors the slide deck: setup → **Demo A** (Slide 7) → **Demo B** (Slide 8) → bonus queries → per-resource spot checks (Slide 11) → start/stop → cleanup.

---

## 0. Setup

### From PSGallery (stage machine)

```powershell
Install-Module PSCumulus -Scope CurrentUser
Import-Module PSCumulus
Invoke-WebRequest https://raw.githubusercontent.com/adilio/PSCumulus/main/scripts/demo-setup.ps1 -OutFile demo-setup.ps1
. ./demo-setup.ps1
```

### From source (rehearsal)

```powershell
Import-Module ./PSCumulus.psd1 -Force
. ./scripts/demo-setup.ps1
```

Dot-sourcing `demo-setup.ps1` pre-seeds context via `Connect-Cloud -Provider Azure, AWS, GCP` (output suppressed). On stage, run `Connect-Cloud` again interactively so the audience sees it.

---

## 1. DEMO A — Native vs. Unified *(Slide 7)*

### Native (shown on slide, not run on stage)

```powershell
Get-AzVM
Get-EC2Instance
gcloud compute instances list --format=json
```

### Connect once, three providers

```powershell
Connect-Cloud -Provider AWS, Azure, GCP
```

### Show the contexts

```powershell
Get-CloudContext
```

### Same question, three clouds — same shape every time

```powershell
Get-CloudInstance -Provider Azure -ResourceGroup prod-rg
```

```powershell
Get-CloudInstance -Provider AWS -Region us-east-1
```

```powershell
Get-CloudInstance -Provider GCP -Project contoso-prod
```

---

## 2. DEMO B — One Pipe, Three Clouds *(Slide 8)*

### The `-All` stream

```powershell
Get-CloudInstance -All
```

### Tagging compliance — untagged production assets across every cloud *(slide verbatim)*

```powershell
Get-CloudInstance -All |
  Where-Object { -not $_.Tags['owner'] } |
  Format-Table Name, Provider, Region -AutoSize
```

### Fleet health — running vs. not-running by provider

```powershell
Show-FleetHealth
```

### Group by provider (fallback for Show-FleetHealth)

```powershell
Get-CloudInstance -All | Group-Object Provider | Select-Object Name, Count
```

---

## 3. Bonus queries (if time allows)

### Untagged owner tag (same logic as the Demo B pipeline, wrapped)

```powershell
Find-UntaggedInstances
```

### Stale instances — stopped/terminated > 30 days

```powershell
Find-StaleInstances
```

### Cost-center rollup

```powershell
Show-CostCenterRollup
```

### Oldest five instances across all clouds

```powershell
Find-OldestInstances
```

### Run every bonus query in sequence

```powershell
Invoke-AllDemoQueries
```

---

## 4. Per-resource spot checks *(Slide 11 reference commands)*

### Storage

```powershell
Get-CloudStorage -Provider Azure -ResourceGroup prod-rg
Get-CloudStorage -Provider AWS   -Region us-east-1
Get-CloudStorage -Provider GCP   -Project contoso-prod
```

### Disks

```powershell
Get-CloudDisk -Provider Azure -ResourceGroup prod-rg
Get-CloudDisk -Provider AWS   -Region us-east-1
Get-CloudDisk -Provider GCP   -Project contoso-prod
```

### Networks

```powershell
Get-CloudNetwork -Provider Azure -ResourceGroup prod-rg
Get-CloudNetwork -Provider AWS   -Region us-east-1
Get-CloudNetwork -Provider GCP   -Project contoso-prod
```

### Functions

```powershell
Get-CloudFunction -Provider Azure -ResourceGroup prod-rg
Get-CloudFunction -Provider AWS   -Region us-east-1
Get-CloudFunction -Provider GCP   -Project contoso-prod
```

### Tags / labels

```powershell
Get-CloudTag -Provider Azure -ResourceId '/subscriptions/00000000/resourceGroups/prod-rg/providers/Microsoft.Compute/virtualMachines/web-server-01'
Get-CloudTag -Provider AWS   -ResourceId 'i-0a1b2c3d4e5f00001'
Get-CloudTag -Provider GCP   -Project contoso-prod -Resource 'instances/prod-web-01'
```

---

## 5. Start / Stop (write path)

### Start

```powershell
Start-CloudInstance -Provider Azure -Name web-server-01  -ResourceGroup prod-rg
Start-CloudInstance -Provider AWS   -InstanceId i-0a1b2c3d4e5f00003 -Region us-east-1
Start-CloudInstance -Provider GCP   -Name prod-worker-01 -Zone us-central1-c -Project contoso-prod
```

### Stop

```powershell
Stop-CloudInstance -Provider Azure -Name api-server-01  -ResourceGroup prod-rg
Stop-CloudInstance -Provider AWS   -InstanceId i-0a1b2c3d4e5f00002 -Region us-east-1
Stop-CloudInstance -Provider GCP   -Name prod-api-01    -Zone us-central1-b -Project contoso-prod
```

---

## 6. Cleanup

```powershell
Remove-DemoSetup             # unload module + demo functions
Remove-DemoSetup -Uninstall  # also uninstall PSCumulus
```

---

## Reference — demo helpers exposed by `demo-setup.ps1`

| Command | What it runs |
|---|---|
| `Find-UntaggedInstances` | `Get-CloudInstance -All` → missing `owner` tag |
| `Find-StaleInstances`    | Stopped/terminated instances older than 30 days |
| `Show-FleetHealth`       | `Group-Object Provider, Status` rollup |
| `Show-CostCenterRollup`  | `Group-Object` on the `cost-center` tag |
| `Find-OldestInstances`   | Five oldest instances across every cloud |
| `Invoke-AllDemoQueries`  | Runs all five above, with labelled headers |
| `Remove-DemoSetup`       | Removes demo functions, unloads (or uninstalls) the module |
