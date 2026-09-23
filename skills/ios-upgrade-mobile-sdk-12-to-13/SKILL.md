---
name: ios-upgrade-mobile-sdk-12-to-13
description: >
  Upgrades an existing iOS app from Salesforce Mobile SDK 12.x to 13.2.1.
  Use when the user asks to upgrade the Mobile SDK version, or when you detect
  SDK 12.x version strings in a Podfile, Package.swift, or Package.resolved.
  Covers: iOS deployment target bump (16→17), removed API fixes, login
  customization migration, Xcode 16 compatibility, and SQLCipher upgrade.
  Does NOT cover React Native or Hybrid/Cordova upgrades.
---

# iOS Salesforce Mobile SDK — Upgrade 12.x to 13.2.1

This skill upgrades an existing iOS app from Salesforce Mobile SDK 12.x to 13.2.1. It is consumed by autonomous coding agents — every reference file is self-contained and contains exact source-of-truth code, file paths, and CLI commands.

## Scenarios

| Scenario | Reference | Preconditions |
|---|---|---|
| Upgrade SDK 12.x → 13.2.1 | [`references/upgrade-12-to-13.md`](references/upgrade-12-to-13.md) | SDK 12.x is already integrated |

Cross-cutting references:

| Topic | Reference |
|---|---|
| Removed APIs, protocol changes, deprecated members, new APIs | [`references/api-changes.md`](references/api-changes.md) |
| Build / runtime / behavioral error symptoms | [`references/troubleshooting.md`](references/troubleshooting.md) |

## Detection Rules

Run these checks against the working directory before proceeding:

1. Check `Podfile` for `pod 'SalesforceSDKCore', '12.` version string.
2. Check `Package.resolved` for `"SalesforceSDKCore"` with version starting with `12.`.
3. Check `Package.swift` dependencies for `SalesforceMobileSDK-iOS-SPM` pinned at version `12.x`.
4. If SDK 12 is detected AND `pod 'SalesforceSDKCore', '13.` (or equivalent SPM version) is NOT present → this skill applies.

## Invariants

These hold regardless of the project shape (CocoaPods or SPM):

- **Do NOT recreate the Xcode project from scratch.** Preserve all hand-maintained target configuration, signing settings, and scheme setup.
- **Do NOT rename or move app source files.** Only the SDK version identifiers and any removed/renamed APIs change.
- **Do NOT change non-SDK build settings** (bundle ID, signing identity, capabilities) unless the upgrade explicitly requires it.
- **Raise deployment target ONLY in both places simultaneously.** The Podfile/Package.swift declaration AND the Xcode project's `IPHONEOS_DEPLOYMENT_TARGET` must match. A mismatch causes CocoaPods to refuse install or produces an archive that fails App Store validation.
- **After `pod install`, stage `.xcworkspace` and `Podfile.lock` changes but do NOT stage the full `Pods/` directory.** The `Pods/` directory is a generated artifact; committing it bloats the repo and causes merge conflicts.
- **Never pass `CODE_SIGNING_ALLOWED=NO` to xcodebuild.** It strips the keychain entitlement and silently breaks login after the upgrade.

## Source of Truth

When the SDK API in this skill disagrees with reality, the upstream release notes and Objective-C headers win.

Release: <https://github.com/forcedotcom/SalesforceMobileSDK-iOS/releases/tag/v13.2.1>
