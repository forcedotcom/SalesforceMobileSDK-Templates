---
name: android-mobile-sdk
description: Add or upgrade Salesforce Mobile SDK capabilities in Android Kotlin applications. Covers creating new apps with the SDK pre-integrated, adding base SDK, SmartStore (encrypted database), MobileSync (cloud sync), briefcase sync (offline priming records), biometric authentication, and a DPoP refresh-token migration (move already-logged-in users from Bearer to DPoP without re-login) to existing applications, and upgrading an existing app between SDK versions (12.x → 13.2.1 → 14.0). Use when the user asks to upgrade / update / migrate the Mobile SDK version, or when SDK 12.x / 13.x version strings appear in build.gradle(.kts) or libs.versions.toml.
---

# Android Salesforce Mobile SDK Integration

This skill integrates the Salesforce Mobile SDK into Android Kotlin applications and upgrades existing apps between SDK versions. It is consumed by autonomous coding agents — every reference file is self-contained and contains exact source-of-truth code, file paths, and CLI commands.

## Scenarios

Pick the reference file that matches the task. Scenarios are layered: each later one assumes the previous is already wired up.

| Scenario | Reference | Preconditions |
|---|---|---|
| Create a new Android Kotlin app from scratch | [`references/create-new-app.md`](references/create-new-app.md) | none |
| Add Mobile SDK authentication to an existing app | [`references/add-mobile-sdk.md`](references/add-mobile-sdk.md) | Gradle Android module exists |
| Add SmartStore (encrypted local DB) | [`references/add-smartstore.md`](references/add-smartstore.md) | `SalesforceSDKManager.initNative(...)` called and `bootconfig.xml` exists |
| Add MobileSync (sObject ⇄ soup sync) | [`references/add-mobilesync.md`](references/add-mobilesync.md) | `SmartStoreSDKManager.initNative(...)` called and `userstore.json` exists |
| Add Briefcase sync (offline priming records → soups) | [`references/add-briefcase-sync.md`](references/add-briefcase-sync.md) | `MobileSyncSDKManager.initNative(...)` is called, and `userstore.json` and `usersyncs.json` exist |
| Add Biometric Authentication (fingerprint / face / iris) | [`references/add-biometric-auth.md`](references/add-biometric-auth.md) | Mobile SDK is initialized in the `Application` subclass |
| Add Dark Mode (system / forced / user toggle) | [`references/add-dark-mode.md`](references/add-dark-mode.md) | Mobile SDK is initialized in the `Application` subclass |
| Migrate logged-in users' refresh tokens to DPoP ("Securing your session" screen at launch) | [`references/add-dpop-token-migration.md`](references/add-dpop-token-migration.md) | Mobile SDK **14.0.1+** is initialized in the `Application` subclass; `MainActivity` extends `SalesforceActivity`; app is View-based (Compose: the reference covers it) |

Upgrade scenarios (not layered on the above — they apply to an app that already integrates an older SDK):

| Scenario | Reference | Preconditions |
|---|---|---|
| Upgrade SDK 12.x → 13.2.1 | [`references/upgrade-12-to-13.md`](references/upgrade-12-to-13.md) | SDK 12.x is already integrated |
| Upgrade SDK 13.x → 14.0 | [`references/upgrade-13-to-14.md`](references/upgrade-13-to-14.md) | SDK 13.x is already integrated; app is Kotlin |
| Upgrade SDK 12.x → 14.0 | [`references/upgrade-12-to-13.md`](references/upgrade-12-to-13.md), then [`references/upgrade-13-to-14.md`](references/upgrade-13-to-14.md) | SDK 12.x is already integrated; app is Kotlin. Run sequentially; build green between steps. |

Cross-cutting references:

| Topic | Reference |
|---|---|
| API class map (manager hierarchy, key types) | [`references/api-reference.md`](references/api-reference.md) |
| Build / login / SmartStore / sync / biometric error symptoms | [`references/troubleshooting.md`](references/troubleshooting.md) |
| 12 → 13 removed APIs, changed signatures, new APIs | [`references/upgrade-12-to-13-api-changes.md`](references/upgrade-12-to-13-api-changes.md) |
| 12 → 13 upgrade error symptoms | [`references/upgrade-12-to-13-troubleshooting.md`](references/upgrade-12-to-13-troubleshooting.md) |
| 13 → 14 removed APIs, changed signatures, new APIs | [`references/upgrade-13-to-14-breaking-changes.md`](references/upgrade-13-to-14-breaking-changes.md) |
| 13 → 14 upgrade error symptoms | [`references/upgrade-13-to-14-troubleshooting.md`](references/upgrade-13-to-14-troubleshooting.md) |

## Detection Rules

When the user request is ambiguous, run these checks against the working directory and pick the **first** scenario in the list below whose precondition is **not** met — even if the user asked for a later capability (e.g. a "sync" request lands on `add-smartstore.md` if `userstore.json` is not yet present, then chains forward):

1. No `settings.gradle.kts` or `build.gradle.kts` at the repo root → `create-new-app.md`.
2. Gradle module exists, but no `import com.salesforce.androidsdk.*` (or any SDK class) anywhere in `*.kt` → `add-mobile-sdk.md`.
3. SDK initialized, but no `app/src/main/res/raw/userstore.json` → `add-smartstore.md`.
4. `userstore.json` exists, but no `usersyncs.json` next to it → `add-mobilesync.md`.
   - Briefcase sync requested ("briefcase", "offline priming records") and MobileSync is wired up → `add-briefcase-sync.md`. If MobileSync is not wired up, chain through `add-mobilesync.md` first.
5. Biometric requested but no `BiometricManager` reference and no `biometricAuthenticationManager` call → `add-biometric-auth.md`.
6. DPoP migration requested ("migrate my users / refresh tokens to DPoP", "secure existing sessions", "existing users are still on Bearer") and no `upgradeToDPoP` / `DpopMigrationManager` reference in `*.kt` → `add-dpop-token-migration.md`. If the SDK version is still 13.x, run `upgrade-13-to-14.md` first (`DpopMigrationManager` exists only in SDK 14.0.1 and later; bump every SDK dependency to 14.0.1+).

**Upgrade requests** ("upgrade / update / migrate the Mobile SDK", "move to SDK 14") skip the list above. Detect the currently integrated SDK version first, then route:

- **12.x** — `app/build.gradle.kts` has `com.salesforce.mobilesdk:` at a `12.` version; or `libs.versions.toml` has `salesforceSDK = "12.`; or `app/build.gradle` (Groovy DSL) has `'com.salesforce.mobilesdk:` with `:12.` → `upgrade-12-to-13.md`. If the target is 14.0, continue with `upgrade-13-to-14.md` after the 13 build is green.
- **13.x** — `app/build.gradle.kts` has `com.salesforce.mobilesdk:` at a `13.` version; or `libs.versions.toml` has `salesforceSDK = "13.` → `upgrade-13-to-14.md`.
- **Already at the target version** → nothing to upgrade; tell the user.

## Invariants Across All Scenarios

- **Manager class hierarchy** (each subclasses the previous): `SalesforceSDKManager` ← `SmartStoreSDKManager` ← `MobileSyncSDKManager`. Each scenario's `initNative(...)` call uses the lowest manager that covers the modules in use. The base scenario uses `SalesforceSDKManager`; SmartStore swaps to `SmartStoreSDKManager`; MobileSync swaps to `MobileSyncSDKManager`. Each swap is additive — nothing is lost.
- **Maven artifact follows the manager.** Base scenario: `com.salesforce.mobilesdk:SalesforceSDK`. SmartStore: `com.salesforce.mobilesdk:SmartStore`. MobileSync: `com.salesforce.mobilesdk:MobileSync`. Each artifact transitively pulls the lower ones — do not pre-emptively pull `MobileSync` for an app that only needs base auth.
- **`Application` subclass is mandatory**: `<Manager>.initNative(applicationContext, MainActivity::class.java)` must run from `Application.onCreate()` before any SDK class is touched. Register the subclass with `android:name=".MainApplication"` in `AndroidManifest.xml`.
- **`MainActivity` extends `SalesforceActivity`**: the SDK manages the OAuth/login lifecycle through this base class. Override `onResume(client: RestClient?)` from `SalesforceActivityInterface` for **post-login** logic — the SDK calls it once a `RestClient` is available (or with `null` when no user is currently authenticated).
- **Resource folders**: `userstore.json` and `usersyncs.json` must live under `app/src/main/res/raw/`. The SDK resolves them by Android resource name.
- **Login host**: configured via `app/src/main/res/xml/servers.xml`. `https://login.salesforce.com` is production; `https://test.salesforce.com` is sandboxes.
- **Do not recreate Gradle scaffolding for an existing app** (upgrades excepted: an upgrade reference's Gradle wrapper, AGP, and `gradle.properties` edits are required, so make them exactly as it specifies). When adding the SDK to an existing project, only modify `app/build.gradle.kts`, `AndroidManifest.xml`, and `MainActivity.kt`, and create the new files (`MainApplication.kt`, `bootconfig.xml`, `servers.xml`, `strings.xml`). Do **not** overwrite `gradle.properties`, `settings.gradle.kts`, root `build.gradle.kts`, or `gradle-wrapper.properties` — those belong to "Create New App" only.
- **Build target**: `./gradlew assembleDebug` from the project root unless the agent has reason to use a different variant.

## Source of Truth

When the SDK API in this skill disagrees with reality, the upstream Kotlin/Java in <https://github.com/forcedotcom/SalesforceMobileSDK-Android> wins.
