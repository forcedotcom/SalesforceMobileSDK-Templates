---
name: ios-mobile-sdk
description: Integrate or upgrade Salesforce Mobile SDK in iOS Swift apps. Covers creating a new app, adding SDK auth, SmartStore (encrypted local DB), MobileSync (cloud sync), briefcase sync (offline priming records), biometric auth (Face ID / Touch ID), DPoP refresh-token migration (move existing Bearer sessions to DPoP-bound ones), and upgrading an existing app between SDK versions (12.x → 13.2.1 → 14.0). Use when an iOS Swift project needs Salesforce login, encrypted local storage backed by SmartStore, sObject-to-soup synchronization, biometric session locking, or migrating signed-in users' sessions to DPoP, or when the user asks to upgrade / update / migrate the Mobile SDK version (or SDK 12.x / 13.x version strings appear in a Podfile, Package.resolved, project.pbxproj, or project.yml).
---

# iOS Salesforce Mobile SDK Integration

This skill integrates the Salesforce Mobile SDK into iOS Swift applications and upgrades existing apps between SDK versions. It is consumed by autonomous coding agents — every reference file is self-contained and contains exact source-of-truth code, file paths, and CLI commands.

## Scenarios

Pick the reference file that matches the task. Scenarios are layered: each later one assumes the previous is already wired up.

| Scenario | Reference | Preconditions |
|---|---|---|
| Create a new iOS Swift app from scratch | [`references/create-new-app.md`](references/create-new-app.md) | none |
| Add Mobile SDK authentication to an existing app | [`references/add-mobile-sdk.md`](references/add-mobile-sdk.md) | An iOS Swift app target exists |
| Add SmartStore (encrypted local DB) | [`references/add-smartstore.md`](references/add-smartstore.md) | `SalesforceManager.initializeSDK()` is called and `bootconfig.plist` exists |
| Add MobileSync (sObject ⇄ soup sync) | [`references/add-mobilesync.md`](references/add-mobilesync.md) | `SmartStoreSDKManager.initializeSDK()` is called and `userstore.json` exists |
| Add Briefcase sync (offline priming records → soups) | [`references/add-briefcase-sync.md`](references/add-briefcase-sync.md) | `MobileSyncSDKManager.initializeSDK()` is called, and `userstore.json` and `usersyncs.json` exist |
| Add Biometric Authentication (Face ID / Touch ID) | [`references/add-biometric-auth.md`](references/add-biometric-auth.md) | Mobile SDK is initialized in `AppDelegate` |
| Add Dark Mode (system / forced / user toggle) | [`references/add-dark-mode.md`](references/add-dark-mode.md) | Mobile SDK is initialized in `AppDelegate` |
| Add DPoP refresh-token migration (upgrade existing Bearer sessions to DPoP at launch, with a progress screen) | [`references/add-dpop-token-migration.md`](references/add-dpop-token-migration.md) | SDK 14.0.1+ is integrated and `AuthHelper.loginIfRequired` is used in `SceneDelegate` |

Upgrade scenarios (not layered on the above — they apply to an app that already integrates an older SDK):

| Scenario | Reference | Preconditions |
|---|---|---|
| Upgrade SDK 12.x → 13.2.1 | [`references/upgrade-12-to-13.md`](references/upgrade-12-to-13.md) | SDK 12.x is already integrated |
| Upgrade SDK 13.x → 14.0 | [`references/upgrade-13-to-14.md`](references/upgrade-13-to-14.md) | SDK 13.x is already integrated |
| Upgrade SDK 12.x → 14.0 | [`references/upgrade-12-to-13.md`](references/upgrade-12-to-13.md), then [`references/upgrade-13-to-14.md`](references/upgrade-13-to-14.md) | SDK 12.x is already integrated. Run sequentially; build green between steps. |

Cross-cutting references:

| Topic | Reference |
|---|---|
| Swift ↔ Objective-C name mapping (`NS_SWIFT_NAME`) | [`references/api-reference.md`](references/api-reference.md) |
| Build / login / SmartStore / biometric error symptoms | [`references/troubleshooting.md`](references/troubleshooting.md) |
| 12 → 13 removed APIs, protocol changes, deprecated members, new APIs | [`references/upgrade-12-to-13-api-changes.md`](references/upgrade-12-to-13-api-changes.md) |
| 12 → 13 upgrade error symptoms | [`references/upgrade-12-to-13-troubleshooting.md`](references/upgrade-12-to-13-troubleshooting.md) |
| 13 → 14 removed APIs, protocol changes, deprecated members, new APIs, version bumps | [`references/upgrade-13-to-14-breaking-changes.md`](references/upgrade-13-to-14-breaking-changes.md) |
| DPoP migration symptoms (compile errors, screen never shows, repeated `upgrade failed`) | [`references/troubleshooting.md`](references/troubleshooting.md) → DPoP Migration |
| 13 → 14 upgrade error symptoms | [`references/upgrade-13-to-14-troubleshooting.md`](references/upgrade-13-to-14-troubleshooting.md) |

## Detection Rules

When the user request is ambiguous, run these checks against the working directory and pick the **first** scenario in the list below whose precondition is **not** met — even if the user asked for a later capability (e.g. a "sync" request lands on `add-smartstore.md` if `userstore.json` is not yet present, then chains forward):

1. No Xcode project (`*.xcodeproj` or `*.xcworkspace`) at the repo root → `create-new-app.md`.
2. Project exists but no `import SalesforceSDKCore` (or any SDK module) anywhere in `*.swift` → `add-mobile-sdk.md`.
3. SDK imported, but no `userstore.json` in the target's source folder → `add-smartstore.md`.
4. `userstore.json` exists, but no `usersyncs.json` → `add-mobilesync.md`.
   - Briefcase sync requested ("briefcase", "offline priming records") and MobileSync is wired up → `add-briefcase-sync.md`. If MobileSync is not wired up, chain through `add-mobilesync.md` first.
5. Biometric requested but no `biometricAuthenticationManager()` reference → `add-biometric-auth.md`.
6. DPoP token migration requested ("migrate users / existing sessions / refresh tokens to DPoP", "secure existing sessions", "call `upgradeToDPoP`") and the SDK is already integrated at 14.0.1 or later → `add-dpop-token-migration.md`. If the SDK is 13.x or 14.0.0, run the matching upgrade reference first. Do not route this to the upgrade references: they only cover the `usesDPoP` default, not migrating existing users.

**Upgrade requests** ("upgrade / update / migrate the Mobile SDK", "move to SDK 14") skip the list above. Detect the currently integrated SDK version first, then route:

- **12.x** — `Podfile` has `pod 'SalesforceSDKCore', '12.`; or `Package.resolved` has `"SalesforceSDKCore"` at `12.`; or `Package.swift` pins `SalesforceMobileSDK-iOS-SPM` at `12.x` → `upgrade-12-to-13.md`. If the target is 14.0, continue with `upgrade-13-to-14.md` after the 13 build is green.
- **13.x** — `Podfile` has `platform :ios, '17.` or any SDK pod pinned at `'13.`; or `<ProjectName>.xcodeproj/project.pbxproj` has an `XCRemoteSwiftPackageReference` for `SalesforceMobileSDK-iOS-SPM` with `version = 13.`; or `project.yml` lists `SalesforceMobileSDK-iOS-SPM` with `version: 13.` → `upgrade-13-to-14.md`.
- **Already at the target version** → nothing to upgrade; tell the user.

## Invariants Across All Scenarios

These hold regardless of which scenario runs:

- **Project shape**: detect from disk in priority order. (1) `Podfile` + `project.yml` → hybrid (Option A for the SDK; xcodegen for sources). (2) `Podfile` only → CocoaPods (Option A). (3) `project.yml` only → xcodegen + SPM (Option B-i). (4) `.xcodeproj` only → plain SPM (Option B-ii). Use the matching path in [`references/add-mobile-sdk.md`](references/add-mobile-sdk.md).
- **CocoaPods workspace rule**: after `pod install`, the build/open target is `<AppName>.xcworkspace`, never `<AppName>.xcodeproj`.
- **`project.yml` is the source-of-truth signal.** When `project.yml` is **not** present, do not author one and do not run `xcodegen generate` against the existing `.xcodeproj` — regenerating drops the project's hand-maintained target/scheme configuration. When `project.yml` **is** present (with or without a `Podfile`), it is the source of truth and `xcodegen generate` is the correct way to land new files. The "Create New App" scenario authors `project.yml` and runs `xcodegen generate` from scratch.
- **Code signing for simulator builds**: use ad-hoc signing (`CODE_SIGN_IDENTITY=-`). Never pass `CODE_SIGNING_ALLOWED=NO` — it strips the keychain entitlement and silently breaks login (see [`references/troubleshooting.md`](references/troubleshooting.md)).
- **Login host default**: `login.salesforce.com` for production, `test.salesforce.com` for sandboxes.
- **Smoke test UI**: each `setupRootViewController()` example installs a labeled placeholder view — replace it with the real root view controller after the smoke test passes.

## Source of Truth

When the SDK API in this skill disagrees with reality, the upstream Objective-C headers in <https://github.com/forcedotcom/SalesforceMobileSDK-iOS> win. Resolve a Swift name by grepping the SDK source for `NS_SWIFT_NAME(<name>)`.
