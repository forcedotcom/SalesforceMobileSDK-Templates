---
name: android-mobile-sdk
description: Add Salesforce Mobile SDK capabilities to Android Kotlin applications. Covers creating new apps with the SDK pre-integrated, or adding base SDK, SmartStore (encrypted database), MobileSync (cloud sync), and biometric authentication to existing applications.
---

# Android Salesforce Mobile SDK Integration

This skill integrates the Salesforce Mobile SDK into Android Kotlin applications. It is consumed by autonomous coding agents — every reference file is self-contained and contains exact source-of-truth code, file paths, and CLI commands.

## Scenarios

Pick the reference file that matches the task. Scenarios are layered: each later one assumes the previous is already wired up.

| Scenario | Reference | Preconditions |
|---|---|---|
| Create a new Android Kotlin app from scratch | [`references/create-new-app.md`](references/create-new-app.md) | none |
| Add Mobile SDK authentication to an existing app | [`references/add-mobile-sdk.md`](references/add-mobile-sdk.md) | Gradle Android module exists |
| Add SmartStore (encrypted local DB) | [`references/add-smartstore.md`](references/add-smartstore.md) | `SalesforceSDKManager.initNative(...)` called and `bootconfig.xml` exists |
| Add MobileSync (sObject ⇄ soup sync) | [`references/add-mobilesync.md`](references/add-mobilesync.md) | `SmartStoreSDKManager.initNative(...)` called and `userstore.json` exists |
| Add Biometric Authentication (fingerprint / face / iris) | [`references/add-biometric-auth.md`](references/add-biometric-auth.md) | Mobile SDK is initialized in the `Application` subclass |

Cross-cutting references:

| Topic | Reference |
|---|---|
| API class map (manager hierarchy, key types) | [`references/api-reference.md`](references/api-reference.md) |
| Build / login / SmartStore / sync / biometric error symptoms | [`references/troubleshooting.md`](references/troubleshooting.md) |

## Detection Rules

When the user request is ambiguous, run these checks against the working directory and pick the **first** scenario in the list below whose precondition is **not** met — even if the user asked for a later capability (e.g. a "sync" request lands on `add-smartstore.md` if `userstore.json` is not yet present, then chains forward):

1. No `settings.gradle.kts` or `build.gradle.kts` at the repo root → `create-new-app.md`.
2. Gradle module exists, but no `import com.salesforce.androidsdk.*` (or any SDK class) anywhere in `*.kt` → `add-mobile-sdk.md`.
3. SDK initialized, but no `app/src/main/res/raw/userstore.json` → `add-smartstore.md`.
4. `userstore.json` exists, but no `usersyncs.json` next to it → `add-mobilesync.md`.
5. Biometric requested but no `BiometricManager` reference and no `biometricAuthenticationManager` call → `add-biometric-auth.md`.

## Invariants Across All Scenarios

- **Manager class hierarchy** (each subclasses the previous): `SalesforceSDKManager` ← `SmartStoreSDKManager` ← `MobileSyncSDKManager`. Each scenario's `initNative(...)` call uses the lowest manager that covers the modules in use. The base scenario uses `SalesforceSDKManager`; SmartStore swaps to `SmartStoreSDKManager`; MobileSync swaps to `MobileSyncSDKManager`. Each swap is additive — nothing is lost.
- **Maven artifact follows the manager.** Base scenario: `com.salesforce.mobilesdk:SalesforceSDK`. SmartStore: `com.salesforce.mobilesdk:SmartStore`. MobileSync: `com.salesforce.mobilesdk:MobileSync`. Each artifact transitively pulls the lower ones — do not pre-emptively pull `MobileSync` for an app that only needs base auth.
- **`Application` subclass is mandatory**: `<Manager>.initNative(applicationContext, MainActivity::class.java)` must run from `Application.onCreate()` before any SDK class is touched. Register the subclass with `android:name=".MainApplication"` in `AndroidManifest.xml`.
- **`MainActivity` extends `SalesforceActivity`**: the SDK manages the OAuth/login lifecycle through this base class. Override `onResume(client: RestClient?)` from `SalesforceActivityInterface` for **post-login** logic — the SDK calls it once a `RestClient` is available (or with `null` when no user is currently authenticated).
- **Resource folders**: `userstore.json` and `usersyncs.json` must live under `app/src/main/res/raw/`. The SDK resolves them by Android resource name.
- **Login host**: configured via `app/src/main/res/xml/servers.xml`. `https://login.salesforce.com` is production; `https://test.salesforce.com` is sandboxes.
- **Do not recreate Gradle scaffolding for an existing app.** When adding the SDK to an existing project, only modify `app/build.gradle.kts`, `AndroidManifest.xml`, and `MainActivity.kt`, and create the new files (`MainApplication.kt`, `bootconfig.xml`, `servers.xml`, `strings.xml`). Do **not** overwrite `gradle.properties`, `settings.gradle.kts`, root `build.gradle.kts`, or `gradle-wrapper.properties` — those belong to "Create New App" only.
- **Build target**: `./gradlew assembleDebug` from the project root unless the agent has reason to use a different variant.

## Source of Truth

When the SDK API in this skill disagrees with reality, the upstream Kotlin/Java in <https://github.com/forcedotcom/SalesforceMobileSDK-Android> wins.
