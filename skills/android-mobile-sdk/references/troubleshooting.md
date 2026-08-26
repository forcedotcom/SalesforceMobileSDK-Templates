# Android — Troubleshooting

Symptom-first reference for Android Mobile SDK integration failures.

## Build / Linking

| Symptom | Cause | Fix |
|---|---|---|
| `Unresolved reference: SalesforceSDKManager` (or `SmartStoreSDKManager`, `MobileSyncSDKManager`) | The SDK Maven artifact is not on the classpath, or Gradle has not synced. | Add the matching `implementation("com.salesforce.mobilesdk:<artifact>:13.2.0")` to `app/build.gradle.kts` and run `./gradlew assembleDebug` to force resolution. |
| `Unresolved reference: SalesforceActivity` | Same cause — SDK artifact not synced. | Run `./gradlew assembleDebug`. |
| `Unresolved reference: SyncManager` | Missing import or wrong access path. | Add `import com.salesforce.androidsdk.mobilesync.manager.SyncManager`. The `MobileSyncSDKManager` does **not** expose `SyncManager` as a property — always access it via `SyncManager.getInstance(user)`. |
| `Unresolved reference: BiometricManager` | `androidx.biometric:biometric` dependency missing. | Add `implementation("androidx.biometric:biometric:1.1.0")`. |
| Build error: `aidl` or `renderScript` feature not found | These features require explicit opt-in in AGP 8+. | Add `buildFeatures { aidl = true; renderScript = true }` to the `android` block. |
| Packaging error: `Duplicate file ... META-INF/LICENSE` | Two transitive dependencies ship the same legal-notice file. | Add the `packaging.resources.excludes` block from [`add-mobile-sdk.md`](add-mobile-sdk.md) Step 1. |

## Login

| Symptom | Cause | Fix |
|---|---|---|
| Login screen does not appear at launch | `MainApplication` not registered in `AndroidManifest.xml`, or `initNative(...)` not called. | Set `android:name=".MainApplication"` on the `<application>` element and verify `<Manager>.initNative(applicationContext, MainActivity::class.java)` runs in `onCreate()`. |
| `MainActivity.onResume(client)` is never called | `MainActivity` does not extend `SalesforceActivity`, or its `onResume()` override doesn't call `super.onResume()`. | Make `MainActivity : SalesforceActivity()`. If `onResume()` is overridden, the override must call `super.onResume()`. |

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

## Biometric

| Symptom | Cause | Fix |
|---|---|---|
| Opt-in dialog never appears | One of: (1) The Connected App lacks the `ENABLE_BIOMETRIC_AUTHENTICATION` Custom Attribute set to `"true"` (with quotes). (2) Code triggers `presentOptInDialog` from `onPostResume()` rather than `onResume(client: RestClient?)` — on a fresh login the user account isn't bound during `onPostResume`, so `mgr.enabled` reads `false`. (3) The user wasn't logged in fresh after the Custom Attribute was added. | (1) Set the Custom Attribute (with literal quotes). (2) Trigger from `onResume(client)`. (3) Log out and back in. |
| `IllegalStateException`: Can not perform this action after onSaveInstanceState (right after fresh login) | The SDK's `onResume(client)` is invoked from a `USERSWITCHED` broadcast receiver after a fresh login, when the FragmentManager has already saved state. | Defer the dialog presentation to the next main-thread tick and guard against state loss: `window.decorView.post { if (!supportFragmentManager.isStateSaved && !mgr.hasBiometricOptedIn()) { mgr.presentOptInDialog(supportFragmentManager) } }`. |
| `Fragment$InstantiationException: could not find Fragment constructor` for `BiometricAuthOptInPrompt` | On activity recreate (rotation, theme change, process restore), FragmentManager tries to restore the SDK's opt-in dialog using a no-arg constructor that doesn't exist. | Pass `null` to `super.onCreate(savedInstanceState)` in `MainActivity.onCreate` to discard fragment state. The SDK fragments re-present themselves on next resume, so nothing is lost. |
| Biometric prompt succeeds, then app immediately shows fresh login screen | After successful biometric, the SDK refreshes the access token. If the Connected App has **"Require Secret for Refresh Token Flow"** *checked*, the refresh fails with `invalid_client` (visible in `adb logcat \| grep ClientManager`: `Invalid Refresh Token: (Error: invalid_client, Status Code: 400)`), and the SDK silently logs the user out. | Uncheck **"Require Secret for Refresh Token Flow"** on the Connected App's OAuth Policies. |
| `biometricAuthenticationManager` is null | No user is currently authenticated. Expected pre-login. | Use the `?.run { … }` safe-call form so the block no-ops before login, or guard with `if (client != null) { … }` in `onResume(client)`. |
