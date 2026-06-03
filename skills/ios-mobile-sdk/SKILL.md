---
name: ios-mobile-sdk
description: Integrate Salesforce Mobile SDK into iOS Swift apps. Covers creating a new app, adding SDK auth, SmartStore (encrypted local DB), MobileSync (cloud sync), and biometric auth (Face ID / Touch ID). Use when an iOS Swift project needs Salesforce login, encrypted local storage backed by SmartStore, sObject-to-soup synchronization, or biometric session locking.
---

# iOS Salesforce Mobile SDK Integration

This skill integrates the Salesforce Mobile SDK into iOS Swift applications. It is consumed by autonomous coding agents — every reference file is self-contained and contains exact source-of-truth code, file paths, and CLI commands.

## Scenarios

Pick the reference file that matches the task. Scenarios are layered: each later one assumes the previous is already wired up.

| Scenario | Reference | Preconditions |
|---|---|---|
| Create a new iOS Swift app from scratch | [`references/create-new-app.md`](references/create-new-app.md) | none |
| Add Mobile SDK authentication to an existing app | [`references/add-mobile-sdk.md`](references/add-mobile-sdk.md) | An iOS Swift app target exists |
| Add SmartStore (encrypted local DB) | [`references/add-smartstore.md`](references/add-smartstore.md) | `SalesforceManager.initializeSDK()` is called and `bootconfig.plist` exists |
| Add MobileSync (sObject ⇄ soup sync) | [`references/add-mobilesync.md`](references/add-mobilesync.md) | `SmartStoreSDKManager.initializeSDK()` is called and `userstore.json` exists |
| Add Biometric Authentication (Face ID / Touch ID) | [`references/add-biometric-auth.md`](references/add-biometric-auth.md) | Mobile SDK is initialized in `AppDelegate` |

Cross-cutting references:

| Topic | Reference |
|---|---|
| Swift ↔ Objective-C name mapping (`NS_SWIFT_NAME`) | [`references/api-reference.md`](references/api-reference.md) |
| Build / login / SmartStore / biometric error symptoms | [`references/troubleshooting.md`](references/troubleshooting.md) |

## Detection Rules

When the user request is ambiguous, run these checks against the working directory and pick the lowest scenario whose precondition is **not** met:

1. No Xcode project (`*.xcodeproj` or `*.xcworkspace`) at the repo root → `create-new-app.md`.
2. Project exists but no `import SalesforceSDKCore` (or any SDK module) anywhere in `*.swift` → `add-mobile-sdk.md`.
3. SDK imported, but no `userstore.json` in the target's source folder → `add-smartstore.md`.
4. `userstore.json` exists, but no `usersyncs.json` → `add-mobilesync.md`.
5. Biometric requested but no `BiometricAuthenticationManager` reference → `add-biometric-auth.md`.

## Invariants Across All Scenarios

These hold regardless of which scenario runs:

- **Dependency manager**: detect from disk. `Podfile` → CocoaPods. `*.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/` → Swift Package Manager. Use the matching path in each reference.
- **CocoaPods workspace rule**: after `pod install`, the build/open target is `<AppName>.xcworkspace`, never `<AppName>.xcodeproj`.
- **Project type**: detect from disk. `project.yml` at the repo root → xcodegen-managed (use `xcodegen generate` after every new file is added on disk; for CocoaPods follow with `pod install` because `xcodegen generate` rewrites `.xcodeproj`). No `project.yml`, but a hand-maintained `<AppName>.xcodeproj` (the pattern used by `iOSNativeSwiftTemplate`) → add new files via the Xcode project itself; for resources, verify Build Phases → Copy Bundle Resources lists the file.
- **Code signing for simulator builds**: use ad-hoc signing (`CODE_SIGN_IDENTITY=-`). Never pass `CODE_SIGNING_ALLOWED=NO` — it strips the keychain entitlement and silently breaks login (see [`references/troubleshooting.md`](references/troubleshooting.md)).
- **Login host default**: `login.salesforce.com` for production, `test.salesforce.com` for sandboxes.
- **Smoke test UI**: each `setupRootViewController()` example installs a labeled placeholder view — replace it with the real root view controller after the smoke test passes.

## Source of Truth

When the SDK API in this skill disagrees with reality, the upstream Objective-C headers in <https://github.com/forcedotcom/SalesforceMobileSDK-iOS> win. Resolve a Swift name by grepping the SDK source for `NS_SWIFT_NAME(<name>)`. Working examples of every scenario in this skill are present in the `iOSNativeSwiftTemplate/` directory of <https://github.com/forcedotcom/SalesforceMobileSDK-Templates>.
