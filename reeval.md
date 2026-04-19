# PSCumulus Re-evaluation — Execution Pass Verification

Branch: `main`. Module version at `PSCumulus.psd1:3` is `0.6.0`.
Final public surface reports 18 functions and 8 aliases, matching the revised plan scope.

---

## Continuation Update — 2026-04-18

Picked up the follow-up queue and completed Groups 1 through 8 from Section 4.

### Completed in this continuation
- **Group 1:** Fixed Azure handling in `Find-CloudResource` and `Export-CloudInventory`.
  - Azure now enumerates visible resource groups with `Get-AzResourceGroup` instead of reading nonexistent `$ctx.ResourceGroup`.
  - AWS/GCP skip paths now use an explicit `$skipProvider` flag instead of `continue` inside `switch`.
  - Tests now model the real Azure context shape and mock `Get-AzResourceGroup`.
- **Group 2 + Group 8:** Closed lifecycle `Path` parameter-set gaps and fixed `-WhatIf` wait side effects.
  - `Start-CloudInstance`, `Stop-CloudInstance`, and `Restart-CloudInstance` now expose `-Wait`, `-TimeoutSeconds`, `-PollingIntervalSeconds`, and `-PassThru` on `Path`.
  - Path wait loops track `$lastRecord` and `-Wait -PassThru` emits the freshest polled record.
  - Wait guards now use `$WhatIfPreference`, so `-Wait -WhatIf` does not poll.
- **Group 3:** Cleaned generated PlatyPS docs.
  - `scripts/Update-Docs.ps1` now scrubs per-parameter `{{ Fill ... Description }}` placeholders.
  - Added parameter help comments to `Disconnect-Cloud`, `Set-CloudTag`, and `Resolve-CloudPath`.
  - Regenerated command reference docs; `rg "{{ Fill" docs/reference/` returns no matches.
- **Group 4:** Removed dead `Disconnect-Cloud -Account`.
  - Deleted the parameter and removed it from Azure provider-specific filters.
  - Added a Pester assertion that `-Account` now fails parameter binding.
- **Group 5:** Consolidated region arrays.
  - Removed duplicate region arrays from `Private/Register-PSCumulusCompleters.ps1`.
  - Region completion now reads `Get-CloudRegionData` from module scope.
- **Group 6:** Removed orphan snapshot/image classes and `CloudSnapshotStatus`.
  - Deleted the unused Snapshot/Image record classes from `Classes/PSCumulus.Types.ps1`.
  - Updated `PSCumulus.psd1` release notes so they no longer claim those classes were added.
- **Group 7:** Synced roadmap/status docs to `v0.6.0`.
  - Updated `README.md`, `docs/concepts/strategy.md`, and `docs/concepts/evolution.md`.
- **Analyzer cleanup:** Made the full requested analyzer target clean.
  - Fixed new warnings in `scripts/Update-Docs.ps1`.
  - Cleaned pre-existing analyzer warnings in `scripts/demo-setup.ps1` so `Classes`, `Private`, `Public`, and `scripts` pass together.

### Verification completed
- `Invoke-Pester -Path tests -Output Normal`
  - **Result:** 669 passed, 0 failed, 6 skipped.
- `Invoke-ScriptAnalyzer -Path Classes/Private/Public/scripts -Recurse -Severity Error,Warning -ExcludeRule PSAvoidUsingWriteHost`
  - **Result:** no findings.
- `pwsh -NoLogo -NoProfile -File scripts/Update-Docs.ps1; rg -n "{{ Fill" docs/reference/`
  - **Result:** docs generation succeeded; no placeholder matches.

### Current handoff state
- Working tree is intentionally dirty with the completed implementation, tests, generated docs, and this updated `reeval.md`.
- Remaining Section 4 work is only **Group 9 shipping**:
  1. Review the diff.
  2. Commit as Adil only.
  3. Push to `origin/main`.
  4. Watch Docs and Test-and-Publish workflows until both complete successfully.

---

## Section 1 — Plan Compliance Check

### Task 1 — `Get-CloudContext` AWS expiry bug (plan §1.1)
- **Status:** Completed.
- **Evidence:** `Public/Get-CloudContext.ps1:62-72` now reads `$awsProfile.Expiration` via the filter assigned on line 62.
- **Delta:** None.

### Task 2 — `Get-CloudContext` GCP expiry dead branch (plan §1.2)
- **Status:** Completed.
- **Evidence:** `Public/Get-CloudContext.ps1:75-83` uses `gcloud auth list --format=json`; JWT parsing removed.
- **Delta:** None.

### Task 3 — `Set-CloudTag` Path branch + broken `Invoke-CloudProvider -ScriptBlock` (plan §1.3)
- **Status:** Completed.
- **Evidence:** `Public/Set-CloudTag.ps1` parameter block no longer declares a `Path` parameter set (lines 42-71). Dispatch switch at `Set-CloudTag.ps1:158-168` calls `Set-AzureTag`/`Set-AWSTag`/`Set-GCPTag` directly.
- **Delta:** None.

### Task 4 — Set-CloudTag VM-only hardcode (plan §1.4)
- **Status:** Completed.
- **Evidence:** Two Azure parameter sets exist: `AzureByName` (VM) and `AzureById` (any resource by `-AzureResourceId`). See `Public/Set-CloudTag.ps1:43-50` and the case handling at `Set-CloudTag.ps1:81-97`.
- **Delta:** None.

### Task 5 — `Get-CloudTag -All` Azure subscription scope (plan §1.5)
- **Status:** Completed.
- **Evidence:** `Public/Get-CloudTag.ps1:86-93` builds `/subscriptions/$subId` and skips if missing. Description block at `Get-CloudTag.ps1:13-15` updated.
- **Delta:** None.

### Task 6 — Argument completers (plan §1.6)
- **Status:** Completed.
- **Evidence:** File was renamed to `Private/Register-PSCumulusCompleters.ps1`; sourced from `PSCumulus.psm1:25`. Completers drop the invalid `-Provider` call, read `$script:PSCumulusContext` via module scope, cache resource groups with 60-second TTL (`Private/Register-PSCumulusCompleters.ps1:40-94`), and guard on missing commands (`Register-PSCumulusCompleters.ps1:65-67`).
- **Delta:** Minor — the region arrays (`$script:AzureRegions`, `$script:AWSRegions`, `$script:GCPRegions`) are declared **twice**, once in `Private/Register-PSCumulusCompleters.ps1:1-38` and once in `Private/Get-CloudRegionData.ps1:1-38`. Plan §2.6 step 2 called for moving them to one helper and reusing it from the completer file. Currently the second load just overwrites the first at dot-source time, so behavior is unaffected, but there are two sources of truth to keep in sync.

### Task 7 — Default `Test-CloudConnection` to `-All` (plan §1.7)
- **Status:** Completed.
- **Evidence:** `Public/Test-CloudConnection.ps1:47-55` defaults `$providersToTest` to all three when no parameters are supplied. New `.EXAMPLE` at `Test-CloudConnection.ps1:23-26`.
- **Delta:** None.

### Task 8 — `-Name` / `-Detailed` on Get-CloudStorage/Network/Disk/Function (plan §1.8)
- **Status:** Completed.
- **Evidence:** All four files now declare `[string]$Name` and `[switch]$Detailed` across Azure/AWS/GCP/All parameter sets (e.g. `Public/Get-CloudDisk.ps1:78-103`, `Get-CloudNetwork.ps1:78-103`, `Get-CloudStorage.ps1:78-103`, `Get-CloudFunction.ps1`). Filter lines (`$results = $results | Where-Object ...`) and a `decorateRecord` scriptblock match the `Get-CloudInstance` pattern.
- **Delta:** None.

### Task 9 — `-Wait`/`-PassThru` freshest record (plan §1.9)
- **Status:** Partially completed.
- **Evidence:** `$lastRecord` is tracked and honoured for the Azure/AWS/GCP/Piped sets in all three lifecycle commands (`Start-CloudInstance.ps1:267-312`, `Stop-CloudInstance.ps1:267-313`, `Restart-CloudInstance.ps1:236-282`). Restart-CloudInstance gained `-Wait`, `-TimeoutSeconds`, `-PollingIntervalSeconds`, and `-PassThru` (`Restart-CloudInstance.ps1:97-125`).
- **Delta:**
  - In the `Path` parameter set for Start/Stop, the wait loop still does *not* track `$lastRecord` and does not honour `-PassThru` (`Start-CloudInstance.ps1:174-209`, `Stop-CloudInstance.ps1:174-209`). Plan §1.9 step 3 explicitly required the same tracking for the Path set.
  - `Restart-CloudInstance` Path branch (`Restart-CloudInstance.ps1:128-180`) has no `-Wait` loop at all — the Path set lacks the wait/timeout/polling/PassThru behaviour that the non-Path paths now provide.

### Task 10 — Central error wrap in `Invoke-CloudProvider` (plan §1.10)
- **Status:** Completed.
- **Evidence:** `Private/Invoke-CloudProvider.ps1:35-63` wraps the call, prefixes the message, and uses `$CallerPSCmdlet.ThrowTerminatingError` when supplied, else throws `InvalidOperationException` with `InnerException`.
- **Delta:** None. Optional caller-`PSCmdlet` wiring from public functions was not called out in the plan.

### Task 11 — `Connect-Cloud -Region`/-Project optional (plan §1.11)
- **Status:** Completed.
- **Evidence:** `Public/Connect-Cloud.ps1:73-80` — no `Mandatory` flag on `-Region`/`-Project`; `.EXAMPLE` entries retained.
- **Delta:** None.

### Task 12 — `Disconnect-Cloud` GCP `-AccountEmail` (plan §1.16)
- **Status:** Partially completed.
- **Evidence:** `Public/Disconnect-Cloud.ps1:130-132` matches `AccountEmail` against `$context.Account` for GCP. `providerSpecificParams` for GCP lists `@('Project', 'AccountEmail')` at line 80.
- **Delta:** Plan §1.16 step 2 also asked to "Remove the unused `-Account` parameter declaration if nothing else uses it." `-Account` is still declared at `Disconnect-Cloud.ps1:48-49` and still appears in Azure's `providerSpecificParams` list (line 78), but is never read inside the match switch or anywhere else in the module. The dead parameter remains a user-facing footgun (passing `-Account` on Azure is silently accepted and ignored).

### Task 13 — Loosen `Set-CloudTag` pipeline type attribute (plan §1.17)
- **Status:** Completed.
- **Evidence:** `Public/Set-CloudTag.ps1:64-65` uses `[psobject]` without `PSTypeName`; validation is now inline in the `Piped` branch at `Set-CloudTag.ps1:117-121`, throwing `ArgumentException` if `Provider` or `Name` is null.
- **Delta:** None.

### Task 14 — `Get-CloudContext -Provider` filter (plan §1.18)
- **Status:** Completed.
- **Evidence:** `Public/Get-CloudContext.ps1:28-32` declares the `ValidateSet` parameter; loop at line 36 honours it.
- **Delta:** None.

### Task 15 — Build `Find-CloudResource` (plan §2.1)
- **Status:** Partially completed — ships but regresses Azure.
- **Evidence:** `Public/Find-CloudResource.ps1` exists, is exported (`PSCumulus.psd1:18`), aliased `fcr` (`PSCumulus.psm1:28`, `PSCumulus.psd1:39`), tested (`tests/Public/Find-CloudResource.Tests.ps1`).
- **Delta:** The Azure scope-resolution branch at `Find-CloudResource.ps1:72-78` reads `$ctx.ResourceGroup`, but the Azure session context built by `Connect-Cloud.ps1:120-133` never sets a `ResourceGroup` key. Against a real Azure session, the search is always skipped for Azure and nothing is found; see Section 2 Issue A below. Tests pass only because the test harness seeds a fake `ResourceGroup` field into the Azure context (`tests/Public/Find-CloudResource.Tests.ps1:24-29`). The `continue` statements inside `switch` inside `foreach` are also suspect (see Section 2 Issue B).

### Task 16 — Build `Export-CloudInventory` (plan §2.2)
- **Status:** Partially completed — same Azure regression as Task 15.
- **Evidence:** `Public/Export-CloudInventory.ps1` exists, exported (`PSCumulus.psd1:17`), tested (`tests/Public/Export-CloudInventory.Tests.ps1`).
- **Delta:** The Azure branch at `Export-CloudInventory.ps1:69-72` has the same `$ctx.ResourceGroup` mismatch as Find-CloudResource — Azure inventory is always skipped against a real connected session. See Section 2 Issue A.

### Task 17 — Build `Remove-CloudTag`
- **Status:** Deliberately removed from scope (plan header, task 17).
- **Evidence:** No `Remove-CloudTag.ps1` in `Public/`; not in manifest.
- **Delta:** Intentional, documented.

### Task 18 — Build `Get-CloudSnapshot`
- **Status:** Removed from scope; classes kept.
- **Evidence:** Snapshot record classes live at `Classes/PSCumulus.Types.ps1:1312-1410`; no `Get-CloudSnapshot.ps1`, no backend files, no export.
- **Delta:** Intentional per plan header, but see Section 2 Issue C (orphaned classes increase module load surface).

### Task 19 — Build `Get-CloudImage`
- **Status:** Removed from scope; classes kept.
- **Evidence:** Image record classes at `Classes/PSCumulus.Types.ps1:1412-1514`; no public command or backend.
- **Delta:** Intentional; orphaned classes noted in Section 2.

### Task 20 — Build `Get-CloudRegion` (plan §2.6)
- **Status:** Completed.
- **Evidence:** `Public/Get-CloudRegion.ps1` defined; `Private/Get-CloudRegionData.ps1` supplies the data; exported at `PSCumulus.psd1:24`; tests at `tests/Public/Get-CloudRegion.Tests.ps1`.
- **Delta:** Region arrays duplicated between `Get-CloudRegionData.ps1` and `Register-PSCumulusCompleters.ps1` (see Task 6 delta / Section 2 Issue D).

### Task 21 — README: 18 commands + Resolve-CloudPath row (plan §1.19)
- **Status:** Completed.
- **Evidence:** `README.md:24` says "Eighteen commands"; table at `README.md:26-45` includes all 18 functions including `Resolve-CloudPath`.
- **Delta:** None for command listing. See Section 3 for the `v0.5.0` reference at `README.md:131` that is now stale.

### Task 22 — `docs/index.md` command list (plan §1.13)
- **Status:** Completed.
- **Evidence:** `docs/index.md:17-34` lists all 18 commands in manifest order.
- **Delta:** None.

### Task 23 — Regenerate PlatyPS command reference (plan §1.14 and Section 3 task 23)
- **Status:** Partially completed — per-parameter placeholders remain.
- **Evidence:** All 18 command pages exist under `docs/reference/commands/`. `scripts/Update-Docs.ps1:30-31` strips the two module-level placeholders (`{{ Fill in the Description }}` and `{{ Fill in the related links here }}`).
- **Delta:** PlatyPS also emits `{{ Fill <ParamName> Description }}` markers for any parameter whose PowerShell source lacks a preceding `# …` help comment. Those markers persist in three generated files:
  - `docs/reference/commands/Disconnect-Cloud.md` — 9 placeholders at lines 74, 95, 116, 159, 180, 201, 222, 243, 264 (source `Public/Disconnect-Cloud.ps1:37-65` has no per-parameter help comments).
  - `docs/reference/commands/Set-CloudTag.md` — 10 placeholders at lines 103, 146, 167, 188, 209, 230, 251, 272, 293, 314 (source `Public/Set-CloudTag.ps1:42-71` lacks per-parameter comments; the file does have full comment-based help, but PlatyPS still needs per-param descriptions).
  - `docs/reference/commands/Resolve-CloudPath.md` — 1 placeholder at line 66.

  Plan task 23 promised "no residual `{{ Fill in }}` placeholders". These don't match that exact text, but they're the same class of PlatyPS output gap and the generated docs publicly advertise them on the docs site.

### Task 24 — `docs/reference/module.md` (plan §1.14)
- **Status:** Completed.
- **Evidence:** `docs/reference/module.md` contains all 18 commands with real synopses; no `{{ Fill in the Synopsis }}` remains.
- **Delta:** None.

### Task 25 — `mkdocs.yml` nav (Section 3 task 25)
- **Status:** Completed.
- **Evidence:** `mkdocs.yml:38-56` lists all 18 command pages.
- **Delta:** None.

### Task 26 — `docs/reference/about-pscumulus.md` (plan §1.12)
- **Status:** Completed.
- **Evidence:** `docs/reference/about-pscumulus.md:16-33` (commands) and 37-46 (aliases) match the manifest.
- **Delta:** None.

### Task 27 — `docs/getting-started.md` (plan §1.12)
- **Status:** Completed.
- **Evidence:** Aliases table at `docs/getting-started.md:97-106` matches the manifest; Cross-Cloud Helpers section at lines 77-91.
- **Delta:** None.

### Task 28 — `en-US/about_PSCumulus.help.txt` (plan §1.12)
- **Status:** Completed.
- **Evidence:** COMMANDS section at `en-US/about_PSCumulus.help.txt:26-44` lists all 18 functions; ALIASES at 46-54 match the manifest.
- **Delta:** None.

### Task 29 — Update concepts docs to v0.5.0 (plan §1.15)
- **Status:** Completed as written, but now stale.
- **Evidence:** `docs/concepts/strategy.md:171` and `docs/concepts/evolution.md:30,360` all say v0.5.0.
- **Delta:** `PSCumulus.psd1:3` is now `0.6.0`. Plan task 30 bumped the manifest but these docs were not re-synced. See Section 3 Issue E.

### Task 30 — `PSCumulus.psd1` release notes + version bump (Section 3 task 30)
- **Status:** Completed.
- **Evidence:** Version `0.6.0` at `PSCumulus.psd1:3`; release notes at `PSCumulus.psd1:53-100`.
- **Delta:** None.

### Task 31 — `tests/PSCumulus.Tests.ps1` aliases assertion (Section 3 task 31)
- **Status:** Completed.
- **Evidence:** `tests/PSCumulus.Tests.ps1:42-44` expects the 8-alias set; `tests/PSCumulus.Tests.ps1:30-33` asserts "exactly eighteen public functions".
- **Delta:** None.

### Task 32-36 — Local suite, PSScriptAnalyzer, commit, push, CI watch
- **Status:** Completed per plan narrative (cannot re-verify test runtime behaviour inside this plan-mode audit — artifacts `test-results.xml` and `testResults.xml` are present at the repo root). Working tree is clean and `main` is up to date with `origin/main`.
- **Delta:** None within this audit's permitted tool set.

---

## Section 2 — Net New Issues

### Issue A (blocking) — Find-CloudResource and Export-CloudInventory silently skip Azure in real use
- **Where:** `Public/Find-CloudResource.ps1:71-79`, `Public/Export-CloudInventory.ps1:68-73`.
- **Problem:** Both functions test `$ctx.ResourceGroup` against the Azure session context. `Public/Connect-Cloud.ps1:119-133` never writes a `ResourceGroup` key into the Azure provider hashtable (it writes `Account`, `AccountId`, `Scope`, `Region`, `ConnectedAt`, and then Azure adds `TenantId`, `Subscription`, `SubscriptionId`, `ContextName`). The check therefore always evaluates false for a real Azure session.
- **Severity:** Blocking. Two headline 0.6.0 commands are advertised in README, docs, and release notes as cross-cloud, but Azure is silently dropped.
- **Why it matters:** A user with Azure connected runs `Find-CloudResource -Name 'web-*'` expecting results from all clouds; it returns AWS+GCP and quietly omits Azure. No warning, no skipped-provider verbose message.
- **Detection note:** Tests (`tests/Public/Find-CloudResource.Tests.ps1:24-29` and `tests/Public/Export-CloudInventory.Tests.ps1:32-36`) manually stuff `ResourceGroup = 'test-rg'` into the mocked Azure context, so the regression is invisible under Pester.

### Issue B (significant) — `continue` inside `switch` inside `foreach`
- **Where:** `Public/Find-CloudResource.ps1:76, 84, 92`; `Public/Export-CloudInventory.ps1:72, 77, 82`.
- **Problem:** When the Azure/AWS/GCP case branch has no scope, the code uses `continue`. In PowerShell, `continue` inside a `switch` exits the switch (it doesn't continue the enclosing `foreach`). Control falls through to the `& $commandName @commandParams` call with no scope param, which will hit the mandatory-parameter validation of e.g. `Get-CloudDisk` and throw. In Find-CloudResource this is caught and emitted via `Write-Verbose`. In Export-CloudInventory the `-ErrorAction SilentlyContinue` applied to `& $commandName` does not suppress mandatory-parameter binding errors, so the outer `try`/`catch` catches them but writes nothing observable.
- **Severity:** Significant. The code works around itself via the outer try/catch, but the intended "skip providers without scope context" semantics are never actually exercised the way the comments suggest.
- **Why it matters:** The skipped-provider path is dead, so there is no verbose-level signal distinguishing "skipped because no context" from "backend call failed". Users debugging missing results have no hook.

### Issue C (minor) — Orphaned Snapshot/Image record classes increase surface area
- **Where:** `Classes/PSCumulus.Types.ps1:1312-1514` (AzureSnapshotRecord, AWSSnapshotRecord, GCPSnapshotRecord, AzureImageRecord, AWSImageRecord, GCPImageRecord) plus `enum CloudSnapshotStatus` at line 48.
- **Problem:** These classes were added for Get-CloudSnapshot/Get-CloudImage, which were pulled from scope (plan header). No public or private code references them; no tests exercise them.
- **Severity:** Minor. Dead code in a class file the whole module loads on import.
- **Why it matters:** Future readers see them, may try to call them, will find no command wiring. Either wire them up in a follow-up release or delete them until that work is actually on-deck.

### Issue D (minor) — Region arrays declared in two places
- **Where:** `Private/Register-PSCumulusCompleters.ps1:1-38` and `Private/Get-CloudRegionData.ps1:1-38`.
- **Problem:** Identical `$script:AzureRegions`/`$script:AWSRegions`/`$script:GCPRegions` definitions live in both files. Plan §2.6 step 2 said to centralize them in `Get-CloudRegionData.ps1` and let the completer consume that helper.
- **Severity:** Minor. Because dot-sourcing sorts alphabetically, both arrays end up in `$script:` scope. The completer still works.
- **Why it matters:** Any future addition of a region (a recurring maintenance task) has to be made twice, and if one copy drifts, the duplicate loaded last wins silently.

### Issue E (minor) — `-Account` parameter on Disconnect-Cloud is declared but unused
- **Where:** `Public/Disconnect-Cloud.ps1:48-49` (declaration) and `Public/Disconnect-Cloud.ps1:78` (Azure providerSpecificParams still lists 'Account').
- **Problem:** `-Account` has no consumer in the process block; the Azure match logic uses `AccountEmail`, AWS uses `AccountId`, GCP uses `AccountEmail`.
- **Severity:** Minor. Passing `-Account foo -Provider Azure` returns a successful disconnect with no match check; passing it to AWS/GCP triggers the "does not accept" exception.
- **Why it matters:** The plan explicitly flagged this for removal (§1.16 step 2). The dead parameter is a footgun and inconsistent with the rest of the command's shape.

### Issue F (minor) — Stale "v0.5.0" status claims after version bump
- **Where:** `README.md:131`, `docs/concepts/strategy.md:171`, `docs/concepts/evolution.md:30` and `:360`.
- **Problem:** All four locations still claim v0.5.0. `PSCumulus.psd1:3` is 0.6.0 and the 0.6.0 release notes (lines 54-100) describe roughly 30 changes, including Find-CloudResource, Export-CloudInventory, Get-CloudRegion, and fixes to Get-CloudContext/Set-CloudTag/completers/etc.
- **Severity:** Minor.
- **Why it matters:** The published site and README tell users the module is at v0.5.0 while PSGallery (and the manifest) will publish as 0.6.0. New readers will see the mismatch.

### Issue G (minor) — `$WhatIf` used in lifecycle Wait guards but not defined in param
- **Where:** `Public/Start-CloudInstance.ps1:174`, `Public/Start-CloudInstance.ps1:264`, `Public/Stop-CloudInstance.ps1:174,264`, `Public/Restart-CloudInstance.ps1:233`.
- **Problem:** The wait guards read `if ($Wait -and -not $WhatIf)`. `$WhatIf` is not a declared parameter; it is an automatic common-parameter preference, typically read as `$WhatIfPreference` or `$PSBoundParameters['WhatIf']`. Because `$WhatIf` is a simple unresolved variable reference, it evaluates to `$null`, so `-not $null` is `$true` — meaning the wait loop always runs, even under `-WhatIf`. The `ShouldProcess` wrapper suppresses the actual backend call in `-WhatIf` mode, but the polling loop still runs (and in tests with no backend mock it would error out after the full timeout).
- **Severity:** Minor — not introduced by this execution pass (it was present before), but the pass touched all three files and didn't fix it. Flagging so it isn't carried into v0.7.0.
- **Why it matters:** `-WhatIf` should be a fast, no-side-effect preview; the current code would sit in the polling loop until timeout if a user ever runs `Start-CloudInstance -Wait -WhatIf`.

---

## Section 3 — README and Docs Verification

- `README.md`, `docs/index.md`, `docs/reference/about-pscumulus.md`, `docs/getting-started.md`, `en-US/about_PSCumulus.help.txt`, `docs/reference/module.md` all list the canonical 18 commands and the 8-alias set. They agree with `PSCumulus.psd1:14-46`.
- `README.md:131`, `docs/concepts/strategy.md:171`, `docs/concepts/evolution.md:30` and `:360` still advertise `v0.5.0`. The manifest is `0.6.0`. This is the biggest visible user-facing inconsistency.
- Three PlatyPS-generated command pages still show `{{ Fill <ParamName> Description }}` placeholders (Disconnect-Cloud, Set-CloudTag, Resolve-CloudPath). These publish to the docs site and look unfinished.
- `scripts/Update-Docs.ps1:30-31` rewrites two module-level placeholders but has no rule for the per-parameter placeholders described above.
- No documentation was found that references `Get-CloudSnapshot`, `Get-CloudImage`, or `Remove-CloudTag` (which would be incorrect given they were pulled from scope). The scoping note lives in `plan.md` and the 0.6.0 release notes (`PSCumulus.psd1:86`), which is appropriate.

---

## Section 4 — Follow-up Execution Instructions

Work top-to-bottom. Run Pester after each group. PowerShell 5.1 compatibility and PSScriptAnalyzer (Error+Warning, excluding `PSAvoidUsingWriteHost`) must stay clean. Commits authored as the user only (no Claude co-author).

### Group 1 — Fix Azure regressions in the 0.6.0 cross-cloud helpers (Section 2 Issue A + B)

**Task 1.** In `Public/Find-CloudResource.ps1`, restructure the per-provider scope resolution so Azure works against a real connected session. Replace the `foreach ($providerName in $providersToSearch) { foreach ($kindName in $kindsToSearch) { ... switch { ... continue } ... }` block (lines 63-117) with logic that:
  - For Azure: iterates all resource groups visible in the subscription. Call `Get-AzResourceGroup -ErrorAction SilentlyContinue` once per Azure iteration, cache the result on `$script:__PSCumulusFcrAzureRgCache` for the duration of the call, then iterate and call `& $commandName -Provider Azure -ResourceGroup $rg.ResourceGroupName`. If `Get-AzResourceGroup` is unavailable or returns nothing, emit `Write-Verbose "Find-CloudResource: no resource groups returned for Azure subscription $($ctx.SubscriptionId); skipping."` and move on.
  - For AWS: keep `$ctx.Region` (already correct).
  - For GCP: keep `$ctx.Project` (already correct).
  - Replace the `continue` inside `switch` with a `$skipProvider = $true; break` flag read after the switch, so the outer `foreach` actually skips. This removes the dead-code skip path and makes the verbose message meaningful.

**Task 2.** Apply the same restructuring to `Public/Export-CloudInventory.ps1` (lines 57-92). Keep the same Azure behaviour: iterate visible resource groups, merge records, key the inventory dictionary by `"$providerName/$kindName"` with values being the concatenation across resource groups.

**Task 3.** Update `tests/Public/Find-CloudResource.Tests.ps1`:
  - Remove the `ResourceGroup = 'test-rg'` line from `$script:PSCumulusContext.Providers['Azure']` setup at lines 24-28 (it misrepresents the real context shape).
  - Add `Mock Get-AzResourceGroup` inside `InModuleScope PSCumulus` for each test that exercises the Azure branch, returning a stub object with `ResourceGroupName`.
  - Add a new test in the `Multi-provider behavior` context: "Should skip Azure when Get-AzResourceGroup returns no RGs and emit verbose", asserting no records from Azure and verifying verbose output.

**Task 4.** Apply the equivalent updates to `tests/Public/Export-CloudInventory.Tests.ps1` (lines 32-36, 46-50, 62-66). Mock `Get-AzResourceGroup` and drop the `ResourceGroup` mocked context key.

### Group 2 — Close the lifecycle Path parameter set gap (Task 9 delta)

**Task 5.** In `Public/Start-CloudInstance.ps1`, update the Path parameter-set `-Wait` loop at lines 174-209 to track `$lastRecord` the same way the Azure/AWS/GCP path does (lines 267-312). After the loop, add the same `if ($PassThru) { if ($lastRecord) { ... } }` block. `-PassThru` is already a declared parameter; it simply needs to be honoured.

**Task 6.** Apply the equivalent change to `Public/Stop-CloudInstance.ps1:174-209` (target state `'Stopped'`).

**Task 7.** In `Public/Restart-CloudInstance.ps1`, add the full `-Wait`/`-TimeoutSeconds`/`-PollingIntervalSeconds`/`-PassThru` loop to the Path parameter set branch (currently lines 128-180 call the backend and immediately return). Mirror the Azure/AWS/GCP branch (lines 233-282) with target state `'Running'`.

**Task 8.** In `tests/Public/Start-CloudInstance.Tests.ps1`, `Stop-CloudInstance.Tests.ps1`, and `Restart-CloudInstance.Tests.ps1`, add a `Context 'Path parameter set -Wait -PassThru'` block covering: `-Wait` emits the freshest polled record, `-PassThru` alone emits nothing when no wait was done, and `-Wait -PassThru` emits the last record.

### Group 3 — Clean up generated PlatyPS docs (Section 3 placeholders)

**Task 9.** In `scripts/Update-Docs.ps1`, after the existing `-replace '\{\{ Fill in the Description \}\}'` line (line 30), add a new rule: `$updated = $updated -replace '\{\{ Fill [A-Za-z0-9_]+ Description \}\}', 'See the description and examples above.'`. This converts any per-parameter placeholder PlatyPS emits into a stable value.

**Task 10.** Add per-parameter help comments (a single `# ...` line above each parameter in the `param(` block) to each of the three problem source files, so future re-generation does not need to rely on the scrub:
  - `Public/Disconnect-Cloud.ps1:42-65` — add short descriptions above `$TenantId`, `$Subscription`, `$Account`, `$AccountId`, `$ProfileName`, `$Region`, `$Project`, `$AccountEmail`.
  - `Public/Set-CloudTag.ps1:42-71` — add short descriptions above `$Name`, `$ResourceGroup`, `$AzureResourceId`, `$ResourceId`, `$Region`, `$Project`, `$Resource`, `$InputObject`, `$Tags`, `$Merge`.
  - `Public/Resolve-CloudPath.ps1:33-37` — add a description above `$Path`.

**Task 11.** After the comment-based help is added, re-run `scripts/Update-Docs.ps1` (or wait for the Docs workflow on the next push). Verify `grep -rn "{{ Fill" docs/reference/` returns zero results.

### Group 4 — Resolve Disconnect-Cloud -Account dead parameter (Section 2 Issue E)

**Task 12.** In `Public/Disconnect-Cloud.ps1`, delete the `-Account` parameter declaration at lines 48-49. Remove `'Account'` from the `Azure` entry of `$providerSpecificParams` at line 78. Update the Azure-example `.EXAMPLE` block if it references `-Account` (currently it does not — safe).

**Task 13.** If `tests/Public/Disconnect-Cloud.Tests.ps1` references `-Account` directly (it does not, per grep), no change needed. Otherwise update accordingly. Add a new `It` that asserts `Disconnect-Cloud -Provider Azure -Account foo` now errors with a parameter-binding error.

### Group 5 — Consolidate region arrays (Section 2 Issue D)

**Task 14.** In `Private/Register-PSCumulusCompleters.ps1`, remove the `$script:AzureRegions`/`$script:AWSRegions`/`$script:GCPRegions` declarations at lines 1-38. Keep only the `Register-ArgumentCompleter` blocks.

**Task 15.** Inside the Region completer script block at lines 44-56, replace the references with `Get-CloudRegionData -Provider Azure`, `Get-CloudRegionData -Provider AWS`, `Get-CloudRegionData -Provider GCP`. Because argument completers run outside the module scope, use `& (Get-Module PSCumulus) { Get-CloudRegionData -Provider $p }` the same way the RG completer reads `$script:PSCumulusContext`. (Alternatively, keep a module-local read; pick whichever is closer to the existing style. Do not reintroduce script-scope arrays in the completer file.)

### Group 6 — Remove orphan Snapshot/Image classes (Section 2 Issue C)

**Task 16.** In `Classes/PSCumulus.Types.ps1`, delete:
  - `enum CloudSnapshotStatus` (lines 48-54)
  - `class AzureSnapshotRecord` (lines 1312-1345)
  - `class AWSSnapshotRecord` (lines 1346-1380)
  - `class GCPSnapshotRecord` (lines 1381-1410)
  - `class AzureImageRecord` (lines 1412-1446)
  - `class AWSImageRecord` (lines 1447-1483)
  - `class GCPImageRecord` (lines 1484-1514)
  and their corresponding `...StatusMap` helpers if any. Re-run the full Pester suite to confirm nothing referenced them.

### Group 7 — Sync stage/version status docs (Section 3 Issue F + stale v0.5.0)

**Task 17.** In `README.md`, change `README.md:131` from `**Current status:** Stages 1, 2, and 3 are complete (v0.5.0).` to `**Current status:** Stages 1, 2, and 3 are complete (v0.6.0).`.

**Task 18.** In `docs/concepts/strategy.md:171`, change `v0.5.0` to `v0.6.0`.

**Task 19.** In `docs/concepts/evolution.md:30`, change `v0.5.0` to `v0.6.0`. In `docs/concepts/evolution.md:360`, change the heading `### What Has Landed (Stage 3 / v0.5.0)` to `### What Has Landed (Stage 3 / v0.6.0)` (only the version — keep the Stage 3 text, since 0.6.0 is still Stage 3).

### Group 8 — Fix -WhatIf side effect in lifecycle loops (Section 2 Issue G)

**Task 20.** In `Public/Start-CloudInstance.ps1:174` and `:264`, `Public/Stop-CloudInstance.ps1:174` and `:264`, `Public/Restart-CloudInstance.ps1:233`, replace `if ($Wait -and -not $WhatIf)` with `if ($Wait -and -not $WhatIfPreference)`. (Simpler and correct: when `-WhatIf` is supplied, `$WhatIfPreference` is `$true` inside the `process` block.) Re-run the `-Wait -WhatIf` test paths or add one if absent.

### Group 9 — Verify and ship

**Task 21.** Run the full Pester suite. Confirm every test passes. If a test fails after Group 1-2 changes, inspect whether the test was asserting the previous broken behaviour (e.g. Azure mocks with `ResourceGroup`) and update the assertion, adding a brief in-test comment explaining the change.

**Task 22.** Run PSScriptAnalyzer locally on `Classes/`, `Private/`, `Public/`, and `scripts/` with `-Severity Error,Warning -ExcludeRule PSAvoidUsingWriteHost`. Confirm no findings.

**Task 23.** Commit (authored as Adil Leghari only; no Claude co-author) with a single message summarizing the deltas: Azure cross-cloud helpers fixed, lifecycle Path sets completed, generated docs placeholders cleaned, dead parameter removed, region arrays consolidated, orphan classes dropped, stage/version docs synced to 0.6.0, `-WhatIf` leak fixed. Push to `origin/main`. Watch the Docs and Test-and-Publish workflows until both show `completed success`.

Stop when every task above is true. Do not open a PR — this repo ships directly from `main` per the existing commit history.
