# Android — Troubleshooting

Symptom-first reference for Android Mobile SDK integration failures.

## Build / Linking

| Symptom | Cause | Fix |
|---|---|---|
| `Unresolved reference: SalesforceSDKManager` (or `SmartStoreSDKManager`, `MobileSyncSDKManager`) | The SDK Maven artifact is not on the classpath, or Gradle has not synced. | Add the matching `implementation("com.salesforce.mobilesdk:<artifact>:14.0.1-rc.1")` to `app/build.gradle.kts` and run `./gradlew assembleDebug` to force resolution. |
| `Unresolved reference: SalesforceActivity` | Same cause — SDK artifact not synced. | Run `./gradlew assembleDebug`. |
| `Unresolved reference: SyncManager` | Missing import or wrong access path. | Add `import com.salesforce.androidsdk.mobilesync.manager.SyncManager`. The `MobileSyncSDKManager` does **not** expose `SyncManager` as a property — always access it via `SyncManager.getInstance(user)`. |
| `Unresolved reference: BiometricManager` | `androidx.biometric:biometric` dependency missing. | Add `implementation("androidx.biometric:biometric:1.1.0")`. |
| `Unresolved reference: upgradeToDPoP` | `upgradeToDPoP` is a Kotlin **extension function** on `UserAccountManager` in `com.salesforce.androidsdk.accounts`; it is not a member, so it needs an import. (It also does not exist in SDK 13.x.) | Add `import com.salesforce.androidsdk.accounts.upgradeToDPoP` and confirm the SDK dependency is 14.x. See [`add-dpop-token-migration.md`](add-dpop-token-migration.md) Step 3. |
| Build error: `aidl` or `renderScript` feature not found | These features require explicit opt-in in AGP 8+. | Add `buildFeatures { aidl = true; renderScript = true }` to the `android` block. |
| Packaging error: `Duplicate file ... META-INF/LICENSE` | Two transitive dependencies ship the same legal-notice file. | Add the `packaging.resources.excludes` block from [`add-mobile-sdk.md`](add-mobile-sdk.md) Step 1. |

## Login

| Symptom | Cause | Fix |
|---|---|---|
| Login screen does not appear at launch | `MainApplication` not registered in `AndroidManifest.xml`, or `initNative(...)` not called. | Set `android:name=".MainApplication"` on the `<application>` element and verify `<Manager>.initNative(applicationContext, MainActivity::class.java)` runs in `onCreate()`. |
| `MainActivity.onResume(client)` is never called | `MainActivity` does not extend `SalesforceActivity`, or its `onResume()` override doesn't call `super.onResume()`. | Make `MainActivity : SalesforceActivity()`. If `onResume()` is overridden, the override must call `super.onResume()`. |

## Dark Mode

| Symptom | Cause | Fix |
|---|---|---|
| SDK screens revert to the default appearance after a process restart | `SalesforceSDKManager.theme` is **not persisted by the SDK** across process launches (KDoc: *"not persistent across instances of Salesforce SDK Manager"*). | Re-apply `theme` every launch in `MainApplication.onCreate()` after `initNative(...)`. For a user toggle, persist the choice yourself (e.g. `SharedPreferences`) and restore it at launch. See [`add-dark-mode.md`](add-dark-mode.md) Options A and B. |
| SDK-managed screens don't match your app's theme (only your own screens, or only the SDK screens, changed) | `SalesforceSDKManager.theme` governs **SDK-managed screens only** (login, host picker, Switch User, screen lock). App-owned UI is themed separately, and the SDK never drives it. | Set both levers to the same appearance: SDK screens via `SalesforceSDKManager.theme`; app-owned UI via the standard Android lever — **View / AppCompat** → `AppCompatDelegate.setDefaultNightMode(...)`, **Jetpack Compose** → `isSystemInDarkTheme()` / your own app state. See [`add-dark-mode.md`](add-dark-mode.md). |
| Toggling appearance at runtime doesn't change the screen currently on-screen | Each SDK screen reads its color scheme once when composed; a `theme` change repaints only **subsequently presented** SDK screens. The activity on-screen at the toggle moment is your own app-owned UI and won't repaint from the property change alone. | No action needed for SDK screens — the next SDK screen presented picks up the new value. To update the app-owned activity the user is on, call `recreate()` on it (or recompose from your own state). See [`add-dark-mode.md`](add-dark-mode.md) Option B. |

## SmartStore

| Symptom | Cause | Fix |
|---|---|---|
| `setupUserStoreFromDefaultConfig()` returns without error and no soup is created | `userstore.json` is not at `app/src/main/res/raw/userstore.json` (Android resource lookup is by exact path). | Move/rename so the resource path matches exactly. Re-run `./gradlew assembleDebug`. |
| App crashes on first store access with "Soup not found" | Code reads/writes a soup name that isn't declared in `userstore.json`, or the JSON failed to parse. | Validate the JSON (`python3 -m json.tool < app/src/main/res/raw/userstore.json`) and confirm the `soupName` referenced in code matches a declared soup. |

## MobileSync

| Symptom | Cause | Fix |
|---|---|---|
| Sync fails at runtime with "Soup not found" | The `soupName` in `usersyncs.json` does not match a `soupName` declared in `userstore.json`. | Align the two files. |
| `setupUserSyncsFromDefaultConfig()` silently does nothing | `usersyncs.json` must be in `app/src/main/res/raw/`. | Place the file at the exact path. |
| No data appears in the soup after login | `setupUserSyncsFromDefaultConfig()` only **registers** the named syncs from `usersyncs.json`; it does not run them. Symptoms: `SyncManager.getInstance().getSyncStatus("<syncName>")` returns a `SyncState` with status `NEW` and `progress == 0`. | Trigger one explicitly with `SyncManager.getInstance(user).reSync(syncName, callback)`. See [`add-mobilesync.md`](add-mobilesync.md) Step 5. |
| UI stays empty after sync completes | Reload was issued before `onUpdate` fired with `DONE`. | Move the data-source reload **inside** the `onUpdate` block, gated on `sync.status == SyncState.Status.DONE`. |
| Compile error: `SyncManager.SyncUpdateCallback` lambda doesn't compile | `SyncUpdateCallback` is a regular `interface`, not `fun interface`. SAM-conversion lambdas don't apply. | Use the `object : SyncManager.SyncUpdateCallback { override fun onUpdate(sync: SyncState) { … } }` form. |
| `__local__` rows never push during sync-up | `__local__` was set to integer `1` instead of JSON boolean `true`. The SDK's dirty-record query is `WHERE {soup:__local__} = 'true'` (string comparison). | Use `put("__local__", true)` (boolean), not `put("__local__", 1)`. Index `__local__` as `"string"` in `userstore.json`. |
| `upsert` for a brand-new local row is a silent no-op | `_soupEntryId` was pre-set on the entry. SmartStore treats that as an update request; if the ID doesn't exist, it no-ops. | Do not pre-set `_soupEntryId` — let SmartStore assign it. |
| Briefcase sync completes but soups are empty | The user has no briefcase assigned, or the briefcase is empty. The sync succeeds with zero records rather than failing. | Check in the org that a briefcase exists and is assigned to the logged-in user. Nothing to fix client-side. |
| Records of one object type never arrive | That type has no entry in `target.infos` (types in the briefcase but not in `infos` are skipped), or its `sobjectType` is misspelled. | Add an `infos` entry with `sobjectType`, `soupName` and `fieldlist` for the type. |
| Briefcase sync fails or drops records for a type: soup not found | An `infos[].soupName` is not declared in `userstore.json`. The top-level `soupName` of a briefcase sync is ignored; each `infos` entry needs its own soup. | Declare one soup per object type in `userstore.json` and align the names. |

## Biometric

| Symptom | Cause | Fix |
|---|---|---|
| Opt-in dialog never appears | One of: (1) The Connected App lacks the `ENABLE_BIOMETRIC_AUTHENTICATION` Custom Attribute set to `"true"` (with quotes). (2) Code triggers `presentOptInDialog` from `onPostResume()` rather than `onResume(client: RestClient?)` — on a fresh login the user account isn't bound during `onPostResume`, so `mgr.enabled` reads `false`. (3) The user wasn't logged in fresh after the Custom Attribute was added. | (1) Set the Custom Attribute (with literal quotes). (2) Trigger from `onResume(client)`. (3) Log out and back in. |
| `IllegalStateException`: Can not perform this action after onSaveInstanceState (right after fresh login) | The SDK's `onResume(client)` is invoked from a `USERSWITCHED` broadcast receiver after a fresh login, when the FragmentManager has already saved state. | Defer the dialog presentation to the next main-thread tick and guard against state loss: `window.decorView.post { if (!supportFragmentManager.isStateSaved && !mgr.hasBiometricOptedIn()) { mgr.presentOptInDialog(supportFragmentManager) } }`. |
| `Fragment$InstantiationException: could not find Fragment constructor` for `BiometricAuthOptInPrompt` | On activity recreate (rotation, theme change, process restore), FragmentManager tries to restore the SDK's opt-in dialog using a no-arg constructor that doesn't exist. | Pass `null` to `super.onCreate(savedInstanceState)` in `MainActivity.onCreate` to discard fragment state. The SDK fragments re-present themselves on next resume, so nothing is lost. |
| Biometric prompt succeeds, then app immediately shows fresh login screen | After successful biometric, the SDK refreshes the access token. If the Connected App has **"Require Secret for Refresh Token Flow"** *checked*, the refresh fails with `invalid_client` (visible in `adb logcat \| grep ClientManager`: `Invalid Refresh Token: (Error: invalid_client, Status Code: 400)`), and the SDK silently logs the user out. | Uncheck **"Require Secret for Refresh Token Flow"** on the Connected App's OAuth Policies. |
| `biometricAuthenticationManager` is null | No user is currently authenticated. Expected pre-login. | Use the `?.run { … }` safe-call form so the block no-ops before login, or guard with `if (client != null) { … }` in `onResume(client)`. |

## DPoP Migration

| Symptom | Cause | Fix |
|---|---|---|
| `Unresolved reference: DpopMigrationManager` | `DpopMigrationManager` ships in the SDK from **14.0.1**; the app is on 13.x or 14.0.0. | Set every SDK dependency (`SalesforceSDK`, `SmartStore`, `MobileSync`) to `14.0.1-rc.1` or later and sync. |
| "Securing your session…" screen stays up for a long time | The SDK never called back (for example the user pressed Back in `TokenMigrationActivity`), so the manager's timeout fallback (90 s default) applies: it reports `Failed("timed out")`, which dismisses the screen. Look for `timed out after …ms` in `adb logcat -s DPoPMigration`. If it NEVER dismisses, the callback passed to `DpopMigrationManager.migrateIfNeeded` does not hide the overlay (or `onResume(client)` returned before calling it). | Hide the overlay inside the `migrateIfNeeded` callback, as in [`add-dpop-token-migration.md`](add-dpop-token-migration.md) Step 3. Pass `timeoutMs` to tune the wait. |
| Migration runs on every launch | A failure leaves the session on Bearer on purpose so the next launch retries (nothing is persisted). The log shows `upgrade needed, starting` then `failed, existing session kept`. | Read the failure reason. If it is `invalid_grant` or a DPoP error, the Connected App / External Client App is not DPoP-enabled in the org: enable it there. Otherwise check the device has network at launch. |
| Log shows `skipped: already DPoP` and the screen is never shown, although the user was on Bearer | The user logged in after DPoP became the default (SDK 14), so the session is already DPoP-bound. | None. To re-test, log in with `SalesforceSDKManager.getInstance().useDPoP = false`, install the migration-enabled build over it and relaunch. |
| App content flashes or runs twice when the SDK's web view closes | `onResume(client)` runs again when `TokenMigrationActivity` finishes, so `continueIntoApp()` can run twice. The `migrationAttempted` / `migrationRunning` flags keep it to one upgrade (log: one `upgrade needed, starting`). | Make `continueIntoApp()` idempotent. |
| After a failed upgrade the SDK's migration screen reopens repeatedly | `onResume(client)` has no per-launch gate: the SDK reports the failure before finishing `TokenMigrationActivity`, so the return resume starts a new upgrade. | Add the `migrationAttempted` / `migrationRunning` flags as in [`add-dpop-token-migration.md`](add-dpop-token-migration.md) Step 3. |
| Migration fails with `invalid_grant` / `DPoP proof verification failed` | The Connected App / External Client App is not configured for DPoP in the org. | Enable DPoP on the app in Salesforce Setup. Users keep their existing session meanwhile (by design) and are retried on the next launch. See also [`upgrade-13-to-14-troubleshooting.md`](upgrade-13-to-14-troubleshooting.md). |
