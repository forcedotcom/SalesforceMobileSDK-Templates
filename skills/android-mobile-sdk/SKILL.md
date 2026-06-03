---
name: android-mobile-sdk
description: Integrate Salesforce Mobile SDK into Android Kotlin apps. Covers creating a new app, adding SDK auth, SmartStore (encrypted local DB), MobileSync (cloud sync), and biometric auth (fingerprint / face / iris). Use when an Android Kotlin project needs Salesforce login, encrypted local storage backed by SmartStore, sObject-to-soup synchronization, or biometric session locking.
---

# Android Salesforce Mobile SDK Integration

This skill integrates the Salesforce Mobile SDK into Android Kotlin applications. It is consumed by autonomous coding agents — every reference file is self-contained and contains exact source-of-truth code, file paths, and CLI commands.

## Scenarios

Pick the reference file that matches the task. Scenarios are layered: each later one assumes the previous is already wired up.

| Scenario | Reference | Preconditions |
|---|---|---|
| Create a new Android Kotlin app from scratch | [`references/create-new-app.md`](references/create-new-app.md) | none |
| Add Mobile SDK authentication to an existing app | [`references/add-mobile-sdk.md`](references/add-mobile-sdk.md) | Gradle Android module exists |
| Add SmartStore (encrypted local DB) | [`references/add-smartstore.md`](references/add-smartstore.md) | `MobileSyncSDKManager.initNative(...)` called and `bootconfig.xml` exists |
| Add MobileSync (sObject ⇄ soup sync) | [`references/add-mobilesync.md`](references/add-mobilesync.md) | `SmartStoreSDKManager.initNative(...)` (or `MobileSyncSDKManager.initNative(...)`) called and `userstore.json` exists |
| Add Biometric Authentication (fingerprint / face / iris) | [`references/add-biometric-auth.md`](references/add-biometric-auth.md) | Mobile SDK is initialized in the `Application` subclass |

Cross-cutting references:

| Topic | Reference |
|---|---|
| API class map (manager hierarchy, key types) | [`references/api-reference.md`](references/api-reference.md) |
| Build / login / SmartStore / sync / biometric error symptoms | [`references/troubleshooting.md`](references/troubleshooting.md) |

## Detection Rules

When the user request is ambiguous, run these checks against the working directory and pick the lowest scenario whose precondition is **not** met:

1. No `settings.gradle.kts` or `build.gradle.kts` at the repo root → `create-new-app.md`.
2. Gradle module exists, but no `import com.salesforce.androidsdk.*` (or any SDK class) anywhere in `*.kt` → `add-mobile-sdk.md`.
3. SDK initialized, but no `app/src/main/res/raw/userstore.json` → `add-smartstore.md`.
4. `userstore.json` exists, but no `usersyncs.json` next to it → `add-mobilesync.md`.
5. Biometric requested but no `BiometricManager` reference and no `biometricAuthenticationManager` call → `add-biometric-auth.md`.

## Invariants Across All Scenarios

- **Single artifact**: the `com.salesforce.mobilesdk:MobileSync` Maven artifact transitively pulls `SmartStore` and `SalesforceSDKCore`. SmartStore and MobileSync scenarios change Kotlin imports and the manager class — they do not require additional artifacts.
- **Manager class hierarchy** (each subclasses the previous): `SalesforceSDKManager` ← `SmartStoreSDKManager` ← `MobileSyncSDKManager`. Every scenario's `initNative(...)` call must use the lowest manager that covers the modules in use.
- **`Application` subclass is mandatory**: `MobileSyncSDKManager.initNative(applicationContext, MainActivity::class.java)` must run from `Application.onCreate()` before any SDK class is touched. Register the subclass with `android:name=".MainApplication"` in `AndroidManifest.xml`.
- **`MainActivity` extends `SalesforceActivity`**: the SDK manages the OAuth/login lifecycle through this base class. Override `onResume(client: RestClient?)` from `SalesforceActivityInterface` for **post-login** logic — the SDK calls it once a `RestClient` is available (or with `null` when no user is currently authenticated). The activity-only `onResume()` may also be overridden for pre-login UI setup, but it must call `super.onResume()` so the SDK can drive login.
- **Resource folders**: `userstore.json` and `usersyncs.json` must live under `app/src/main/res/raw/`. The SDK resolves them by Android resource name.
- **Login host**: configured via `app/src/main/res/xml/servers.xml`. `https://login.salesforce.com` is production; `https://test.salesforce.com` is sandboxes.
- **`account_type` string**: `app/src/main/res/values/strings.xml` must declare `<string name="account_type">…</string>` (used by the SDK's account authenticator).
- **Build target**: assume the build invocation is `./gradlew assembleDebug` from the project root unless the agent has reason to use a different variant.

## Source of Truth

When the SDK API in this skill disagrees with reality, the upstream Kotlin/Java in <https://github.com/forcedotcom/SalesforceMobileSDK-Android> wins. Working examples of every scenario are present in <https://github.com/forcedotcom/SalesforceMobileSDK-Templates/tree/dev/AndroidNativeKotlinTemplate>.
