# Android — Troubleshooting

Symptom-first reference for Android Mobile SDK integration failures.

## Build / Linking

| Symptom | Cause | Fix |
|---|---|---|
| `Unresolved reference: MobileSyncSDKManager` (or `SmartStoreSDKManager`, `SalesforceSDKManager`) | The `MobileSync` Maven artifact is not on the classpath, or Gradle has not synced. | Add `implementation("com.salesforce.mobilesdk:MobileSync:13.2.1")` to `app/build.gradle.kts` and run `./gradlew assembleDebug` to force resolution. |
| `Unresolved reference: SalesforceActivity` | Same cause — `MobileSync` artifact not synced. | Run `./gradlew assembleDebug`. |
| `Unresolved reference: BiometricManager` | `androidx.biometric:biometric` dependency missing. | Add `implementation("androidx.biometric:biometric:1.1.0")`. |
| Packaging error: `Duplicate file ... META-INF/LICENSE` | Two transitive dependencies ship the same legal-notice file. | Add the `packaging.resources.excludes` block from [`add-mobile-sdk.md`](add-mobile-sdk.md) Step 1. |

## Login

| Symptom | Cause | Fix |
|---|---|---|
| Login screen does not appear at launch | `MainApplication` not registered in `AndroidManifest.xml`, or `initNative(...)` not called. | Set `android:name=".MainApplication"` on the `<application>` element and verify `MobileSyncSDKManager.initNative(applicationContext, MainActivity::class.java)` runs in `onCreate()`. |
| App crashes on first launch with `RuntimeException: Apps must call SalesforceSDKManager.init() first.` | Code touches an SDK class before `initNative(...)` runs (the SDK throws from `SalesforceSDKManager.getInstance()` when its singleton is null). | Move all SDK calls behind `onCreate()` of `Application`, and ensure `MainApplication` is the registered application class via `android:name=".MainApplication"` in `AndroidManifest.xml`. |
| `MainActivity.onResume(client)` is never called | `MainActivity` does not extend `SalesforceActivity`, or its `onResume()` override doesn't call `super.onResume()`. | Make `MainActivity : SalesforceActivity()`. If `onResume()` is overridden, the override must call `super.onResume()`. |
| Login error: `account_type` is null / authenticator missing | `account_type` string missing from `app/src/main/res/values/strings.xml`. | Add `<string name="account_type"><PackageName>.login</string>`. |

## SmartStore

| Symptom | Cause | Fix |
|---|---|---|
| `setupUserStoreFromDefaultConfig()` returns without error and no soup is created | `userstore.json` is not at `app/src/main/res/raw/userstore.json` (Android resource lookup is by exact path). | Move/rename so the resource path matches exactly. Re-run `./gradlew assembleDebug`. |
| App crashes on first store access with `SmartStoreException: Soup: <soupName> does not exist` | Code reads/writes a soup name that isn't declared in `userstore.json`, or the JSON failed to parse. | Validate the JSON (`python3 -m json.tool < app/src/main/res/raw/userstore.json`) and confirm the `soupName` referenced in code matches a declared soup. |

## MobileSync

| Symptom | Cause | Fix |
|---|---|---|
| `setupUserSyncsFromDefaultConfig()` runs but no sync executes | The `setup*` calls only **register** syncs — they do not run them. | Run a registered sync explicitly with the `SyncManager` for the current user (`SyncManager.runSync(...)` / `reSync(...)`), or pre-load data ahead of time. |
| Sync fails at runtime with `SmartStoreException: Soup: <soupName> does not exist` | The `soupName` in `usersyncs.json` does not match a `soupName` declared in `userstore.json`. | Align the two files. |
| `usersyncs.json` is ignored | File missing from `app/src/main/res/raw/`, or named differently. The Android template uses the plural filename `usersyncs.json`. | Place at `app/src/main/res/raw/usersyncs.json`. |

## Biometric

| Symptom | Cause | Fix |
|---|---|---|
| Opt-in dialog never appears | `enabled` is `false` because the connected app in the org does not have biometric authentication enabled. | Enable biometric auth on the connected app in Salesforce. The dialog correctly does not appear until the org-side flag is set. |
| `IllegalStateException: Can not perform this action after onSaveInstanceState` | Dialog is presented from `onResume()` instead of `onPostResume()`. | Move `presentOptInDialog(supportFragmentManager)` into `onPostResume()`. |
| `biometricAuthenticationManager?.enabled` is `false` pre-login | The manager itself is non-null in normal use — its getter lazily constructs a `BiometricAuthenticationManager()` on first read. `enabled` depends on the current user, which is `null` before login, so it returns `false`. | Guard the call: `if (SalesforceSDKManager.getInstance().biometricAuthenticationManager?.enabled == true) { … }`, or use `?.takeIf { it.enabled }?.run { … }` so the block no-ops before login. |
