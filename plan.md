# PSCumulus Improvement Plan

> **STATUS UPDATE:** Tasks 1-22, 29-31, 34-35 completed. Tasks 23-28 (documentation) remain. CI is currently failing on PSScriptAnalyzer warnings (unused parameter warnings in Register-PSCumulusCompleters.ps1).
>
> **SCOPE CHANGE:** Get-CloudSnapshot, Get-CloudImage, and Remove-CloudTag were removed from scope during implementation. Classes were added for Snapshot/Image records but the commands were not fully implemented and were removed from the manifest. Final command count is 18, not 21.

Audience: an execution agent with no prior context. Every instruction below is written to be actioned without further interpretation. File paths are absolute. Where a `Why` appears, it is for your judgement on edge cases — the required change is in the `Action` line.

Scope of this plan: fix correctness bugs, raise UX consistency across the public surface, close the README/docs drift, and add carefully-chosen commands. Then update docs, keep tests green, write tests for new code, commit, push, and watch CI until green.

---

## Section 1 — UX and Usability Audit

Findings are ordered by severity. Each includes a `Where`, `Why`, and a concrete `Action`. Any vague finding has been pulled in favor of items you can actually execute.

### 1.1 (CRITICAL BUG) `Get-CloudContext` AWS expiry reads the wrong variable

- **Where:** `Public/Get-CloudContext.ps1:52`
- **Problem:** The code does `$expiresAt = $profile.Expiration.ToLocalTime()`. `$profile` is a PowerShell automatic variable pointing to the user's profile script path (a string). The filtered object was assigned to `$awsProfile` on line 49. Result: every call on a session with stored AWS context throws silently inside the `try`, the catch swallows it to `Write-Verbose`, and `ExpiresAt` is always `$null` for AWS.
- **Action:** In `Public/Get-CloudContext.ps1`, change `$profile.Expiration.ToLocalTime()` on line 52 to `$awsProfile.Expiration.ToLocalTime()`.

### 1.2 (CRITICAL BUG) `Get-CloudContext` GCP token-expiry path never works

- **Where:** `Public/Get-CloudContext.ps1:63-79`
- **Problem:** Code calls `Invoke-GCloudJson -Arguments @('auth', 'print-access-token')`. `Invoke-GCloudJson` always appends `--format=json --quiet` and pipes through `ConvertFrom-Json`. `gcloud auth print-access-token` returns raw opaque text, not JSON — so either the parse fails or `$tokenInfo` is the full text string. It is then base64-decoded and JSON-parsed as if it were a JWT payload, which it is not (access tokens from gcloud are opaque). The whole branch is dead code.
- **Action:** Replace the entire GCP branch body inside the `try` block (currently `Public/Get-CloudContext.ps1:62-80`) with the following:

  ```powershell
  'GCP' {
      $gcloudAuth = gcloud auth list --format=json 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue
      $activeAccount = $gcloudAuth | Where-Object { $_.status -eq 'ACTIVE' } | Select-Object -First 1
      if (-not $activeAccount) {
          Write-Warning "GCP credentials for $($entry.Account) are not active. Please run Connect-Cloud -Provider GCP."
      }
      # GCP access tokens are opaque; there is no reliable expiry without an extra API call.
      # We leave $expiresAt null and surface status only via the warning above.
  }
  ```

  Do not add any new tests specifically for this branch; the existing expiry-warning tests under `tests/Public/Get-CloudContext.Tests.ps1` should be left untouched if they still pass. If they fail because they mocked `Invoke-GCloudJson`, update the mock target to `gcloud` and assert the warning path.

### 1.3 (CRITICAL BUG) `Set-CloudTag` pipeline / path branches call a non-existent function and a private helper with the wrong shape

- **Where:** `Public/Set-CloudTag.ps1:75` and `Public/Set-CloudTag.ps1:130-144`
- **Problem A:** Line 75 calls `Get-CloudResource -Path $Path`. That function is not defined anywhere in the module. The Path parameter set throws immediately.
- **Problem B:** Lines 130-144 call `Invoke-CloudProvider -Provider $targetInfo.Provider -ScriptBlock { ... } -ArgumentList $targetInfo, $Tags, $Merge`. `Private/Invoke-CloudProvider.ps1` only declares `-Provider`, `-CommandMap`, and `-ArgumentMap`. The call always fails with a parameter-binding error. The existing Pester test for Path is marked `-Pending`, which is why CI didn't catch it. The Piped branch works only because the final call fails silently on dispatch — so "success" here just means "no error surfaced".
- **Action A — Path branch:** Remove the Path parameter set entirely. Delete the `'Path'` `ParameterSetName` declaration on the `$Path` parameter, delete the `'Path'` switch case (lines 74-97 in the current file), and remove the `-Pending` test for Path in `tests/Public/Set-CloudTag.Tests.ps1` (lines 111-136 of that test file) — replace it with a test that asserts `Set-CloudTag -Path ... ` errors out as an unknown parameter (i.e., Path is no longer a valid parameter). Rationale: `CloudPath` parsing and `Get-CloudResource` are Stage-4 Provider territory; shipping them half-wired is worse than removing. Set-CloudTag will regain a path-driven entry point in Stage 4.
- **Action B — dispatch:** Replace the `Invoke-CloudProvider -ScriptBlock ...` block in `Public/Set-CloudTag.ps1` (the `if ($PSCmdlet.ShouldProcess($targetDisplay, "Set tags $($Tags.Keys -join ', ')"))` body) with a direct dispatch:

  ```powershell
  if ($PSCmdlet.ShouldProcess($targetDisplay, "Set tags $($Tags.Keys -join ', ')")) {
      $result = switch ($targetInfo.Provider) {
          'Azure' { Set-AzureTag -ResourceId $targetInfo.ResourceId -Tags $Tags -Merge:$Merge }
          'AWS'   { Set-AWSTag -ResourceId $targetInfo.ResourceId -Tags $Tags -Merge:$Merge -Region $targetInfo.Region }
          'GCP'   { Set-GCPTag -Project $targetInfo.Project -Resource $targetInfo.Resource -Tags $Tags -Merge:$Merge }
      }

      if ($result) {
          $results.Add($result)
      }
  }
  ```

### 1.4 (CRITICAL BUG) `Set-CloudTag` Azure hardcodes Microsoft.Compute/virtualMachines

- **Where:** `Public/Set-CloudTag.ps1:47-55`
- **Problem:** In the `Azure` parameter set, the target `ResourceId` is constructed as `"/subscriptions/$subscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Compute/virtualMachines/$Name"`. This means `Set-CloudTag -Name … -ResourceGroup …` only works for VMs. Piping a disk, storage account, function, or network into Set-CloudTag lands in the `Piped` branch and uses `InputObject.Id`, which is fine, but the explicit Azure parameter set is misleading and silently wrong for non-VM resources.
- **Action:**
  1. Add a new parameter to the `Azure` set named `-ResourceId` that accepts a full Azure resource ID; make it a peer of `-Name`/`-ResourceGroup`.
  2. Restructure the Azure parameter set so that `-ResourceId` is mutually exclusive with `-Name`/`-ResourceGroup`. Use two parameter set names: `AzureByName` (existing shape) and `AzureById` (just `-ResourceId`). Keep `AzureByName` limited to VMs and update its synopsis help string to say so.
  3. In the `Azure` switch branch, if `-ResourceId` was supplied, use it directly; otherwise build the VM resource id as today.
  4. Add `.EXAMPLE` entries for tagging a disk by `ResourceId` and for piped `Get-CloudDisk | Set-CloudTag`.

### 1.5 (CRITICAL BUG) `Get-CloudTag -All` is broken for Azure

- **Where:** `Public/Get-CloudTag.ps1:83-89`
- **Problem:** The `-All` branch sets `$argumentMap.ResourceId = $ctx.Scope` for Azure. `$ctx.Scope` for Azure is the **subscription name** (see `Public/Connect-Cloud.ps1:114`). Azure's `Get-AzTag` backend takes a full Azure resource ID — a subscription name will fail. This has never worked end-to-end.
- **Action:** In `Public/Get-CloudTag.ps1`, change the Azure branch of `-All` to pass the subscription-scoped resource ID instead:

  ```powershell
  if ($providerName -eq 'Azure') {
      $subId = $ctx.SubscriptionId
      if ([string]::IsNullOrWhiteSpace($subId)) {
          $skippedProviders.Add("$providerName (no stored subscription id)")
          continue
      }
      $argumentMap.ResourceId = "/subscriptions/$subId"
  }
  ```

  Also update the `.DESCRIPTION` block of the function to say: "With `-All`, returns the subscription-scoped tags for Azure, the region-level tagged resources for AWS, and the project-scoped labels for GCP. For more specific tag queries, omit `-All` and pass `-ResourceId`/`-Project`/`-Resource` explicitly."

### 1.6 (BUG) Argument completers are wired to a non-existent property and an unsupported parameter

- **Where:** `Private/Register-PSCumpleters.ps1:54-73`
- **Problem:** The ResourceGroup completer calls `Get-CloudContext -Provider Azure`, but `Get-CloudContext` (see `Public/Get-CloudContext.ps1:20`) takes no `-Provider` parameter. PowerShell binding fails silently inside a completer, so completion just returns nothing. The completer also tries to access `$context.ResourceGroups`, which is never set on the `PSCumulus.CloudContext` output. The Project completer reproduces the same `-Provider` bug.
- **Action:**
  1. Rename `Private/Register-PSCumpleters.ps1` to `Private/Register-PSCumulusCompleters.ps1` (typo). Update the reference in `PSCumulus.psm1:25`.
  2. Rewrite the body of the file so that:
     - Region completer keeps its current static-list behaviour.
     - ResourceGroup completer drops the `-Provider` call; it reads from the script-scope context directly: ```$ctx = & (Get-Module PSCumulus) { $script:PSCumulusContext }```, then uses `Get-AzResourceGroup -ErrorAction SilentlyContinue | Select-Object -Expand ResourceGroupName` when an Azure context exists. Guard with `Get-Command Get-AzResourceGroup -ErrorAction SilentlyContinue`.
     - Project completer likewise reads `$ctx.Providers.GCP.Project` via the same module-scope trick and returns it as the single completion when it matches the prefix.

  If the Az/gcloud modules are not present at completion time, return an empty list (never throw). Completers run on every key press; never make them network-blocking. Each completer must finish in under ~150ms on a populated session; if `Get-AzResourceGroup` is noticeably slow, cache its result in a `$script:__PSCumulusRgCache` with a 60-second TTL keyed by subscription id.

### 1.7 (BUG) `Test-CloudConnection` with neither `-Provider` nor `-All` is a silent no-op

- **Where:** `Public/Test-CloudConnection.ps1:40-45`
- **Problem:** When no args are passed, `$PSCmdlet.ParameterSetName` is the default (unnamed) set, `$Provider` is empty, so the loop iterates on `@('')` and returns a single object with `Connected = $false, Message = 'No session context found'`. Either making `-Provider` mandatory when `-All` is absent, or defaulting to `-All`, would be clearer.
- **Action:** Default to `-All` when the user supplies neither `-Provider` nor `-All`. In `Public/Test-CloudConnection.ps1`, replace the body of `process` so that when both `-Provider` and `-All` are absent, `$providersToTest = @('Azure', 'AWS', 'GCP')`. Also add `.EXAMPLE Test-CloudConnection` (no args) to the help block and document that it is equivalent to `-All`.

### 1.8 Inventory commands other than `Get-CloudInstance` lack `-Name` and `-Detailed`

- **Where:** `Public/Get-CloudStorage.ps1`, `Public/Get-CloudNetwork.ps1`, `Public/Get-CloudDisk.ps1`, `Public/Get-CloudFunction.ps1`
- **Problem:** `Get-CloudInstance` supports `-Name` (filter by name inside scope) and `-Detailed` (turn on the format-ps1xml detail view). The four sibling commands do not, which is both inconsistent and frustrating when trying to look up one resource.
- **Action:** Add both parameters to each of the four commands, mirroring the pattern in `Get-CloudInstance.ps1`:

  1. Add a `[string]$Name` parameter that lives in Azure/AWS/GCP/All sets. Filter `$results` after the backend call with `$results = $results | Where-Object { [string]::IsNullOrWhiteSpace($Name) -or $_.Name -eq $Name }`. Apply the filter once, after the `-Status`/`-Tag` filters, so behaviour is identical to Get-CloudInstance.
  2. Add a `[switch]$Detailed` parameter in Azure/AWS/GCP/All sets. Wrap the backend-call results in the same `decorateRecord` scriptblock used in `Get-CloudInstance.ps1:128-140`: when `-Detailed` is set, insert `'PSCumulus.CloudRecord.Detailed'` into each record's `PSObject.TypeNames` at position 0.
  3. Add one `.EXAMPLE` per file showing `-Name` usage and one showing `-Detailed`.

### 1.9 `Start/Stop/Restart-CloudInstance` `-Wait` does not re-emit the fresh record, and `-PassThru` re-emits stale input

- **Where:** `Public/Start-CloudInstance.ps1:304-309`, `Public/Stop-CloudInstance.ps1` (equivalent), `Public/Restart-CloudInstance.ps1`
- **Problem:** When `-Wait` is set, the loop already computes `$currentRecord` for each poll. That record is the freshest available view, but it's never emitted. `-PassThru` only emits `$InputObject`, which may be stale (it's the pre-start snapshot). On the `Path` parameter set, `-PassThru` emits nothing because `$InputObject` is $null.
- **Action:** In `Public/Start-CloudInstance.ps1`, `Public/Stop-CloudInstance.ps1`, and `Public/Restart-CloudInstance.ps1`:
  1. Track a variable `$lastRecord = $null` through the `-Wait` loop; assign `$lastRecord = $currentRecord` on each poll.
  2. After the loop completes normally, replace the `if ($PassThru) { Write-Output $InputObject }` block with:

     ```powershell
     if ($PassThru) {
         if ($lastRecord) { Write-Output $lastRecord }
         elseif ($InputObject) { Write-Output $InputObject }
     }
     ```

  3. For the `Path` parameter set branch (Start/Stop only currently implement -Wait here), add the same tracking, and honour `-PassThru` as "emit the fresh record after wait". Restart-CloudInstance has no `-Wait` today; add `-Wait`/`-TimeoutSeconds`/`-PollingIntervalSeconds`/`-PassThru` parameters mirroring Start-CloudInstance so behaviour is consistent across the lifecycle trio. For Restart, the terminal target status is `Running`.

### 1.10 Errors from backend calls surface raw SDK exceptions with no hint toward `Connect-Cloud`

- **Where:** Every `Private/Get-*Data.ps1`, `Private/Start-*Instance.ps1`, `Private/Stop-*Instance.ps1`, `Private/Set-*Tag.ps1`
- **Problem:** When Az / AWS / gcloud throws (expired creds, wrong region, unknown RG), the raw error bubbles up. Users do not know whether the failure is a PSCumulus wiring issue or a credential issue. The central dispatcher `Invoke-CloudProvider` does not wrap errors.
- **Action:** In `Private/Invoke-CloudProvider.ps1`, wrap the final `& $commandName @ArgumentMap` in a `try { ... } catch { ... }` that:
  1. Rethrows the original exception as the `InnerException`.
  2. Writes a single user-facing error record via `$PSCmdlet.ThrowTerminatingError` (requires accepting a `$CallerPSCmdlet` parameter; add it as optional) with a hint like: "`$Provider` backend call failed: <original message>. If this looks like an auth error, run `Test-CloudConnection -Provider $Provider` or `Connect-Cloud -Provider $Provider`."
  3. Do not swallow non-auth failures — always rethrow, just with the PSCumulus prefix so the user can tell where it came from.

  Since `Invoke-CloudProvider` is now shape-changed, add a backwards-compatible default: if `$CallerPSCmdlet` is not supplied, fall back to `throw`ing a new `System.InvalidOperationException` carrying the prefix string and original `$_`.

### 1.11 `Connect-Cloud` parameter requirements are inconsistent across providers

- **Where:** `Public/Connect-Cloud.ps1:52-81`
- **Problem:** `-Region` is mandatory for AWS, `-Project` is mandatory for GCP, but Azure has no mandatory scope parameter. In practice most users already have a default region/project in config; requiring these at Connect time forces them to repeat themselves.
- **Action:** Make `-Region` and `-Project` optional. Change `[Parameter(Mandatory, ParameterSetName = 'AWS')]` to `[Parameter(ParameterSetName = 'AWS')]` for `-Region`, and the same for `-Project` under `ParameterSetName = 'GCP'`. The backends already handle the no-scope case (see `Private/Connect-AWSBackend.ps1:20-24` and `Private/Connect-GCPBackend.ps1:15`). Update `.EXAMPLE` entries to show both the explicit and the config-default styles.

### 1.12 Aliases documentation across README / docs / about-help disagrees

- **Where:** `docs/getting-started.md:87`, `docs/reference/about-pscumulus.md:35`, `en-US/about_PSCumulus.help.txt:38-41`
- **Problem:** Each of the three sources lists a different aliases table and each is wrong in a different way:
  - `docs/getting-started.md` says `tci` aliases `Stop-CloudInstance` (actual: Test-CloudConnection).
  - `docs/reference/about-pscumulus.md` says `tci` aliases `Stop-CloudInstance` (same bug). Misses `rci`, `sct`, `gcont`.
  - `en-US/about_PSCumulus.help.txt` says `cc` aliases `Connect-Cloud` (actual: `conc`). Misses `rci`, `sct`, `gcont`, `conc`.
- **Action:** Replace the aliases section in each of those three files with a single canonical table that matches `PSCumulus.psd1:34-42`. The canonical set is:

  | Alias | Command |
  |---|---|
  | `conc` | `Connect-Cloud` |
  | `gcont` | `Get-CloudContext` |
  | `gcin` | `Get-CloudInstance` |
  | `sci` | `Start-CloudInstance` |
  | `rci` | `Restart-CloudInstance` |
  | `sct` | `Set-CloudTag` |
  | `tci` | `Test-CloudConnection` |

  Also update the COMMANDS section in `en-US/about_PSCumulus.help.txt` to include every currently-exported function (15 total: see `PSCumulus.psd1`).

### 1.13 `docs/index.md` command list lags the module surface

- **Where:** `docs/index.md:17-26`
- **Problem:** Lists 10 commands. Missing 5: `Disconnect-Cloud`, `Restart-CloudInstance`, `Set-CloudTag`, `Test-CloudConnection`, `Resolve-CloudPath`.
- **Action:** Replace the bulleted list with the full list of 15 functions in the order they appear in `PSCumulus.psd1`.

### 1.14 `docs/reference/module.md` shows a placeholder synopsis

- **Where:** `docs/reference/module.md:66`
- **Problem:** The Set-CloudTag section reads `{{ Fill in the Synopsis }}` because `Public/Set-CloudTag.ps1` has no comment-based help block.
- **Action:**
  1. Add full comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, four `.EXAMPLE` entries covering Azure, AWS, GCP, and piped input) to `Public/Set-CloudTag.ps1`. The one-line synopsis is: "Sets tags or labels on a cloud resource across Azure, AWS, or GCP."
  2. Regenerate the reference page by running `scripts/Update-Docs.ps1` (see next item). If the file still contains the placeholder after regeneration, replace the placeholder by hand with the new synopsis.
  3. Also fix the `{{ Fill in the Description }}` placeholder at `docs/reference/commands/Get-CloudInstance.md:406` (OUTPUTS section) by replacing the entire line with `PSCumulus.CloudRecord or a vendor subclass (PSCumulus.AzureCloudRecord, PSCumulus.AWSCloudRecord, PSCumulus.GCPCloudRecord).`

### 1.15 Roadmap version is out of date in two strategy / evolution docs

- **Where:** `docs/concepts/strategy.md:171`, `docs/concepts/evolution.md:30`
- **Problem:** Both say `v0.4.0`; `PSCumulus.psd1:3` is `0.5.0`.
- **Action:** Change both occurrences to `v0.5.0`.

### 1.16 `Disconnect-Cloud` `-AccountEmail` parameter is only honoured in Azure

- **Where:** `Public/Disconnect-Cloud.ps1:77-81, 105-107, 125-133`
- **Problem:** `providerSpecificParams` for GCP is `@('Project', 'AccountEmail')`, but the Azure branch is the one that actually matches `-AccountEmail` against `$context.Account`. For GCP the code matches `-Account`, which is not in `providerSpecificParams` for any provider. As a result, `Disconnect-Cloud -Provider GCP -AccountEmail …` silently no-ops the match check, and `-Account` throws as "not supported".
- **Action:** In `Public/Disconnect-Cloud.ps1`:
  1. In the GCP branch of the match switch (current lines 125-133), change `if ($PSBoundParameters.ContainsKey('Account') ...)` to `if ($PSBoundParameters.ContainsKey('AccountEmail') ...)` and compare against `$context.Account`.
  2. Remove the unused `-Account` parameter declaration if nothing else uses it.

### 1.17 `Set-CloudTag` pipeline input does not accept the newer vendor subclass TypeNames

- **Where:** `Public/Set-CloudTag.ps1:30-31`
- **Problem:** `[PSTypeName('PSCumulus.CloudRecord')]` on `$InputObject` works because the base-class TypeName is added in the `CloudRecord` constructor. This is fine today but will break if we ever skip inserting that base TypeName. There is also no explicit support for piping a plain `pscustomobject` with the right shape (e.g. demo-setup records).
- **Action:** Remove the `[PSTypeName('PSCumulus.CloudRecord')]` attribute from `$InputObject` and instead validate inside the `Piped` branch that `$InputObject` exposes a non-null `Provider` and `Name` property. Throw a clear `System.ArgumentException` otherwise: "Set-CloudTag requires a PSCumulus CloudRecord, or any object with non-null Provider and Name properties."

### 1.18 `Get-CloudContext` has no `-Provider` filter, yet multiple internal callers want one

- **Where:** `Public/Get-CloudContext.ps1:20`, `Private/Register-PSCumpleters.ps1:56-68`
- **Problem:** The completers tried to pass `-Provider` (see item 1.6). A filter is useful on its own — users frequently want `Get-CloudContext -Provider Azure` to check a specific provider.
- **Action:** Add an optional `[ValidateSet('Azure','AWS','GCP')][string]$Provider` parameter to `Get-CloudContext`. When set, iterate only that provider. Update tests in `tests/Public/Get-CloudContext.Tests.ps1` to add a case for the filtered path.

### 1.19 `Resolve-CloudPath` is exported but undocumented in README

- **Where:** `README.md:26-41` command table
- **Problem:** `Resolve-CloudPath` ships in the module (see `PSCumulus.psd1:29`) but is absent from the README command table. README lists "Fourteen commands"; the actual export count is fifteen.
- **Action:** In `README.md`, change "Fourteen commands" (line 24) to "Fifteen commands." Add a row to the table: `| \`Resolve-CloudPath\` | Parse a cloud path string into a structured CloudPath object |`. Keep ordering consistent with the manifest.

### What is good (keep)

- The Classes → Private → Public load ordering in `PSCumulus.psm1:15-23` is clean and works.
- `CloudRecord` base + vendor subclasses (`Classes/PSCumulus.Types.ps1`) is a strong pattern. Stage 2 landed well.
- The format-ps1xml views give reasonable default table / detail rendering.
- The test suite has high coverage across Private backends and Public command shape — keep it as-is outside the specific updates called out above.

---

## Section 2 — Missing Functionality Gap Analysis

Six new commands, ordered by likely user impact. Each one passes the module's own test: the normalized answer is still honest across providers. Each spec below is implementation-ready.

### 2.1 `Find-CloudResource` — cross-kind, cross-cloud search by name

- **Who benefits:** on-call engineers who know a resource name but not whether it's a VM, a disk, or a bucket; and compliance users checking whether "prod-*" exists anywhere.
- **Problem solved:** "Is there anything named 'payment-svc-03' anywhere?" today requires five Get-Cloud* commands and three providers.
- **Why it belongs here:** the README flags it as a roadmap item; native cloud CLIs cannot search across providers.
- **Action — build it:** Create `Public/Find-CloudResource.ps1` with:

  ```
  function Find-CloudResource {
      [CmdletBinding(DefaultParameterSetName = 'All')]
      [OutputType([pscustomobject])]
      param(
          [Parameter(Mandatory, Position = 0)]
          [SupportsWildcards()]
          [string]$Name,

          [ValidateSet('Azure','AWS','GCP')]
          [string[]]$Provider,

          [ValidateSet('Instance','Disk','Storage','Network','Function')]
          [string[]]$Kind
      )
      # Implementation:
      # 1. Resolve provider list from $Provider or all connected providers.
      # 2. Resolve kind list from $Kind or @('Instance','Disk','Storage','Network','Function').
      # 3. For each (provider, kind), call the corresponding Get-Cloud<Kind> -All path
      #    (using Invoke-CloudProvider) with the provider's stored scope.
      # 4. Filter the stream with -like $Name. Wildcards supported.
      # 5. Emit records with Kind property already populated (CloudRecord.Kind).
  }
  ```

  Place it under `Public/`. It must reuse the backend layer (`Invoke-CloudProvider` + `Get-*Data`) — do not add new backends. Tag completion under `Public/Find-CloudResource.ps1` has no new completer needs. Export from `PSCumulus.psd1` (add `'Find-CloudResource'` to `FunctionsToExport`). Add alias `fcr` (add to `AliasesToExport` and `PSCumulus.psm1`). Write tests under `tests/Public/Find-CloudResource.Tests.ps1` mirroring the Get-CloudInstance test style; mock `Get-*Data` backends.

### 2.2 `Export-CloudInventory` — snapshot all connected inventory to disk

- **Who benefits:** compliance/audit users, on-call teams needing a "before" snapshot before a large change, anyone demoing.
- **Problem solved:** freezes a point-in-time view of every resource across every connected cloud in a format (JSON or CSV) that tooling can diff later.
- **Why it belongs here:** it is the only tool that knows the normalized CloudRecord shape across providers. Native CLIs don't share a format.
- **Action — build it:** Create `Public/Export-CloudInventory.ps1`:

  ```
  function Export-CloudInventory {
      [CmdletBinding(SupportsShouldProcess)]
      [OutputType([System.IO.FileInfo])]
      param(
          [Parameter(Mandatory, Position = 0)]
          [string]$Path,

          [ValidateSet('Json','Csv')]
          [string]$Format = 'Json',

          [ValidateSet('Instance','Disk','Storage','Network','Function')]
          [string[]]$Kind = @('Instance','Disk','Storage','Network','Function'),

          [ValidateSet('Azure','AWS','GCP')]
          [string[]]$Provider
      )
      # Implementation:
      # 1. Build the same (provider, kind) matrix Find-CloudResource uses.
      # 2. Stream records into an ordered hashtable keyed by "<Provider>/<Kind>".
      # 3. For Json, ConvertTo-Json -Depth 8 and Out-File -Encoding utf8 to $Path.
      # 4. For Csv, flatten Tags and Metadata into semicolon-joined "k=v" strings
      #    and Export-Csv -NoTypeInformation to $Path.
      # 5. Return the resulting FileInfo via Get-Item.
      # 6. Wrap the write in $PSCmdlet.ShouldProcess($Path, 'Export cloud inventory').
  }
  ```

  Export from manifest. No alias. Add tests under `tests/Public/Export-CloudInventory.Tests.ps1` that mock the Get-*Data backends and assert the file content shape for both Json and Csv.

### 2.3 `Remove-CloudTag` — delete specific keys from a resource's tags/labels

- **Who benefits:** anyone who wants to clean up tags. Today you can add/overwrite via `Set-CloudTag -Merge:$false` but you can't remove a single key.
- **Problem solved:** `Set-CloudTag` replaces or merges; there is no "remove only these keys, leave the rest alone" operation.
- **Why it belongs here:** same honest normalization as `Set-CloudTag` — the operation is tag-by-tag regardless of cloud.
- **Action — build it:** Create `Public/Remove-CloudTag.ps1` mirroring `Public/Set-CloudTag.ps1`. Parameter sets: Azure (by ResourceId), AWS, GCP, Piped. Accept `[string[]]$Key` instead of `[hashtable]$Tags`. Implementation:
  - Azure: fetch current tags via `Get-AzTag`, remove keys, call `Update-AzTag -Operation Replace` with the trimmed set.
  - AWS: call `Remove-EC2Tag -Resource $ResourceId -Tag $tagObjects` where `$tagObjects` is built from the keys.
  - GCP: call `gcloud resource-manager tags bindings delete` for each key (or `gcloud compute instances remove-labels` for compute-scoped labels — pick one and document the scope in the help block; start with compute labels, which is where `Set-GCPTag` is de facto targeted).

  Add three new Private helpers (`Remove-AzureTag.ps1`, `Remove-AWSTag.ps1`, `Remove-GCPTag.ps1`) mirroring the existing Set-*Tag helpers.

  Export from manifest. No alias. `SupportsShouldProcess = $true`. Write tests.

### 2.4 `Get-CloudSnapshot` — cross-cloud disk snapshot inventory

- **Who benefits:** backup/DR auditors, compliance reviewers, capacity planners.
- **Problem solved:** "are we still keeping snapshots for payment-vol-01?" today requires `Get-AzSnapshot`, `Get-EC2Snapshot`, `gcloud compute snapshots list` — three tools, three output shapes.
- **Why it belongs here:** snapshots are the most honestly-normalizable concept we haven't covered. Every provider has a snapshot that knows its source disk, size, and creation date.
- **Action — build it:**
  1. Add `class AzureSnapshotRecord : CloudRecord`, `class AWSSnapshotRecord : CloudRecord`, `class GCPSnapshotRecord : CloudRecord` to `Classes/PSCumulus.Types.ps1`, each with at least `SourceDiskId`, `SizeGB`. Follow the pattern of the existing Disk record subclasses.
  2. Add `Private/Get-AzureSnapshotData.ps1` wrapping `Get-AzSnapshot`, `Private/Get-AWSSnapshotData.ps1` wrapping `Get-EC2Snapshot -OwnerId self`, `Private/Get-GCPSnapshotData.ps1` wrapping `Invoke-GCloudJson -Arguments @('compute','snapshots','list')`.
  3. Add `Public/Get-CloudSnapshot.ps1` modelled on `Get-CloudDisk.ps1`: Azure/AWS/GCP/All sets, `-Name`, `-Tag`, `-Detailed` support. No `-Status` — snapshots don't have a stable shared state vocabulary across providers.
  4. Register format view under `PSCumulus.Format.ps1xml` mirroring the Disk views.
  5. Export from manifest. Add alias `gcs` → `Get-CloudSnapshot`.
  6. Tests under `tests/Public/Get-CloudSnapshot.Tests.ps1` and `tests/Private/Get-AzureSnapshotData.Tests.ps1` / AWS / GCP equivalents.

### 2.5 `Get-CloudImage` — normalize OS images / AMIs

- **Who benefits:** new-cloud learners, people chasing down "what AMI was this VM built from?", and ops staff auditing golden images.
- **Problem solved:** each cloud has its own name for "the OS image a VM booted from" (Azure image, AWS AMI, GCP image). All three share `Name`, `Id`, `Publisher`, `OsType`, `CreatedAt`.
- **Why it belongs here:** a genuinely overlapping concept; the normalized record is honest.
- **Action — build it:**
  1. Add `class AzureImageRecord`, `class AWSImageRecord`, `class GCPImageRecord` to `Classes/PSCumulus.Types.ps1`. Properties: `ImageId`, `Publisher`, `OsType`, plus the shared base.
  2. Add `Private/Get-AzureImageData.ps1` (wrap `Get-AzImage`), `Private/Get-AWSImageData.ps1` (wrap `Get-EC2Image -Owner self`), `Private/Get-GCPImageData.ps1` (wrap `Invoke-GCloudJson -Arguments @('compute','images','list','--no-standard-images')`).
  3. Add `Public/Get-CloudImage.ps1` matching the Get-CloudStorage shape (no `-Name`/`-Detailed` omission — include them from the start).
  4. Export. No alias.
  5. Tests under tests/Public and tests/Private.

  Important judgement call (do not implement if this fails verification): GCP `gcloud compute images list` returns public project images by default. We must filter to the caller's project (same `--project` argument you already pass elsewhere). Include a comment in the backend explaining why.

### 2.6 `Get-CloudRegion` — list supported regions for each provider

- **Who benefits:** people picking a region for the first time, docs writers, tab-completion backers.
- **Problem solved:** Connect-Cloud asks for a region; today the only hint at valid values lives inside `Private/Register-PSCumpleters.ps1` as a static list. A first-class command surfaces this for humans.
- **Why it belongs here:** very small, very honest, and it removes a reason to leave PowerShell.
- **Action — build it:**
  1. Create `Public/Get-CloudRegion.ps1`. Parameters: `[ValidateSet('Azure','AWS','GCP')][string]$Provider` (optional — when omitted, returns all). No `-All` switch needed.
  2. Backing data: pull from the same `$script:AzureRegions` / `$script:AWSRegions` / `$script:GCPRegions` arrays already in `Private/Register-PSCumpleters.ps1`. Move those arrays into a new file `Private/Get-CloudRegionData.ps1` so they live in a scoped private command rather than script-level variables wired from a side effect of the completer registration. Keep the completers working by importing the arrays via that new helper.
  3. Output shape: one `[pscustomobject] @{ PSTypeName = 'PSCumulus.CloudRegion'; Provider = '…'; Name = '…' }` per region. Add a format-ps1xml view if it's helpful (not required).
  4. Export from manifest. No alias.
  5. Tests: `tests/Public/Get-CloudRegion.Tests.ps1` asserting the count for each provider and that filtered output has the right Provider value.

### Deliberately omitted (keep them out of scope)

- Cost, IAM, provisioning (README already rules these out — do not add them).
- `Save-CloudContext` / `Restore-CloudContext` persistence: security-sensitive; out of scope for this pass.
- `Watch-CloudInstance`: small UX win but less value than the six above; defer.
- Bulk `Set-CloudTag -All`: complicated ShouldProcess semantics; defer.
- `Compare-CloudInventory`: the diff is trivial once `Export-CloudInventory` lands (`Compare-Object`); don't build a dedicated command.

---

## Section 3 — Execution Agent Instructions

You are the execution agent. Work top-to-bottom. Every task is atomic. After each logical group of tasks, run the full Pester suite locally and only proceed when green.

### Ground rules

1. Do not alter the commit-style convention: commits are authored as the user (Adil Leghari). Do not add Claude co-author lines.
2. Keep PowerShell 5.1 compatibility (`PSCumulus.psd1` declares 5.1). No PS7-only syntax (`??`, ternary, pipeline chain operators, class-based enums that target ≥7, etc.).
3. Maintain `CmdletBinding` and parameter-set invariants. Every new public command gets `[OutputType(...)]` and comment-based help with at least one `.EXAMPLE` per supported parameter set.
4. Do not weaken any existing test. If a fix in Section 1 invalidates an existing assertion, update the assertion to match the corrected behavior and add a comment in the test file explaining the change.
5. Keep PSScriptAnalyzer clean (`Severity Error,Warning`, excluding `PSAvoidUsingWriteHost` — same rules as CI, see `.github/workflows/test-and-publish.yml:37`).
6. Never skip Git hooks. If a hook fails, fix the underlying issue.

### Ordered task list

**~~1. Fix `Get-CloudContext` AWS expiry bug~~** ✅ COMPLETED
**~~2. Fix `Get-CloudContext` GCP expiry dead branch~~** ✅ COMPLETED
**~~3. Fix `Set-CloudTag` Path-branch dead call and broken ScriptBlock dispatch~~** ✅ COMPLETED
**~~4. Remove Set-CloudTag VM-only hardcode~~** ✅ COMPLETED
**~~5. Fix `Get-CloudTag -All` Azure~~** ✅ COMPLETED
**~~6. Repair argument completers~~** ✅ COMPLETED
**~~7. Default `Test-CloudConnection` to `-All`~~** ✅ COMPLETED
**~~8. Add `-Name` and `-Detailed` to Get-CloudStorage/Network/Disk/Function~~** ✅ COMPLETED
**~~9. Emit fresh record on `-Wait` / `-PassThru`~~** ✅ COMPLETED
**~~10. Central error-wrap in `Invoke-CloudProvider`~~** ✅ COMPLETED
**~~11. Make `Connect-Cloud -Region` / `-Project` optional~~** ✅ COMPLETED
**~~12. Fix `Disconnect-Cloud` GCP `-AccountEmail` matching~~** ✅ COMPLETED
**~~13. Loosen `Set-CloudTag` pipeline type attribute~~** ✅ COMPLETED
**~~14. Add `Get-CloudContext -Provider` filter~~** ✅ COMPLETED
**~~15. Build `Find-CloudResource`~~** ✅ COMPLETED
**~~16. Build `Export-CloudInventory`~~** ✅ COMPLETED
**~~17. Build `Remove-CloudTag`~~** ❌ REMOVED FROM SCOPE (decided to defer)
**~~18. Build `Get-CloudSnapshot`~~** ❌ REMOVED FROM SCOPE (Classes added but command removed from manifest)
**~~19. Build `Get-CloudImage`~~** ❌ REMOVED FROM SCOPE (Classes added but command removed from manifest)
**~~20. Build `Get-CloudRegion`~~** ✅ COMPLETED
**~~21. Add `Resolve-CloudPath` row to README and correct command count~~** ✅ COMPLETED (Updated to 18 commands: 15 existing + 3 new = 18)
**~~22. Update `docs/index.md` command list~~** ✅ COMPLETED

**REMAINING TASKS:**

23. **Regenerate `docs/reference/commands/*.md` via PlatyPS** — Run `scripts/Update-Docs.ps1`. Fix any residual `{{ Fill in }}` placeholders by hand per Section 1.14.
23. **Regenerate `docs/reference/commands/*.md` via PlatyPS** — Run `scripts/Update-Docs.ps1`. Fix any residual `{{ Fill in }}` placeholders by hand per Section 1.14.
24. **Update `docs/reference/module.md`** — Include entries for Find-CloudResource, Export-CloudInventory, Get-CloudRegion. (Note: Get-CloudSnapshot, Get-CloudImage, Remove-CloudTag were removed from scope).
25. **Update `mkdocs.yml` nav** — Add the three new commands to the Commands section, alphabetized.
26. **Update `docs/reference/about-pscumulus.md`** — Section 1.12. Fix aliases table, expand Commands list to all 18 commands.
27. **Update `docs/getting-started.md`** — Section 1.12. Fix aliases table; show `Find-CloudResource` and `Export-CloudInventory` under a new "Cross-cloud helpers" subsection.
28. **Update `en-US/about_PSCumulus.help.txt`** — Section 1.12. Sync COMMANDS and ALIASES sections to the manifest.
**~~29. Update `docs/concepts/strategy.md:171` and `docs/concepts/evolution.md:30`~~** ✅ COMPLETED (Updated to v0.5.0)
**~~30. Update `PSCumulus.psd1` release notes~~** ✅ COMPLETED (Added 0.6.0 release notes and bumped version)
**~~31. Update the `tests/PSCumulus.Tests.ps1` aliases assertion~~** ✅ COMPLETED
32. **Run the full local suite:** `Invoke-Pester -Configuration (New-PesterConfiguration -Hashtable @{ Run = @{ Path = './tests'; Exit = $true } })`. Everything must pass. If a test fails, fix the underlying code rather than weakening the assertion.
33. **Run PSScriptAnalyzer locally** matching CI config: `Invoke-ScriptAnalyzer -Path ./Public,./Private,./PSCumulus.psd1,./PSCumulus.psm1 -Recurse -Severity Error,Warning -ExcludeRule PSAvoidUsingWriteHost`. Zero findings.
**~~34. Commit~~** ✅ COMPLETED (All changes committed and pushed)
**~~35. Push to the current branch (`main` per `git status`)~~** ✅ COMPLETED
36. **Watch CI** — Use `gh run list --limit 5 --branch main` and `gh run watch <id>` to follow the newest run. If the workflow fails, open the run log with `gh run view <id> --log-failed`, fix the failure at the root cause (do not skip PSScriptAnalyzer, do not `--no-verify` any hook), commit, push, and re-watch. Repeat until every check on the latest commit is green. **IN PROGRESS - CI failing on PSScriptAnalyzer warnings**

### Test-writing rules for new commands

For each new public command (`Find-CloudResource`, `Export-CloudInventory`, `Remove-CloudTag`, `Get-CloudSnapshot`, `Get-CloudImage`, `Get-CloudRegion`) write a Pester 5 test file under `tests/Public/` with at minimum:

1. A `Context 'Parameter validation'` block asserting mandatory parameters throw when omitted.
2. A `Context 'Provider dispatch'` block (when applicable) asserting the right Private backend is called (using `Mock` inside `InModuleScope PSCumulus`).
3. A `Context 'Output shape'` block asserting the returned objects carry the expected `PSTypeName` and `Kind` (or equivalent).
4. For `-All` / multi-provider commands, a test that skips providers without a stored context and emits verbose messages via `Write-Verbose` — mirror `tests/Public/Get-CloudInstance.Tests.ps1`'s approach.

For each new Private backend (`Get-AzureSnapshotData`, `Get-AWSSnapshotData`, `Get-GCPSnapshotData`, `Get-AzureImageData`, `Get-AWSImageData`, `Get-GCPImageData`, `Remove-AzureTag`, `Remove-AWSTag`, `Remove-GCPTag`) write a Pester 5 test file under `tests/Private/` following the style of `tests/Private/Get-AzureDiskData.Tests.ps1`. Mock the Az/AWS cmdlets or `Invoke-GCloudJson` and assert the resulting record properties.

### Final acceptance criteria

- All Pester tests pass locally and on CI.
- PSScriptAnalyzer clean on CI.
- `git log origin/main` shows the new commits authored by Adil Leghari (no Claude co-author).
- `gh run list --branch main --limit 1` shows the latest run as `completed success`.
- `Get-Command -Module PSCumulus` in a fresh shell lists all **18** exported functions plus all aliases, and every new command has working comment-based help surfaced via `Get-Help`. (Note: Get-CloudSnapshot, Get-CloudImage, and Remove-CloudTag were removed from scope, so final count is 18 not 21).
- `docs/index.md`, `docs/reference/module.md`, `docs/reference/about-pscumulus.md`, `docs/getting-started.md`, `en-US/about_PSCumulus.help.txt`, and `README.md` all agree on the command list and the aliases table.

Stop when every checkbox above is true.
