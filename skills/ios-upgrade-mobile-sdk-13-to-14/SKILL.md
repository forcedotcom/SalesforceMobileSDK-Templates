---
name: ios-upgrade-mobile-sdk-13-to-14
description: >
  Upgrades an existing iOS app from Salesforce Mobile SDK 13.x to 14.0.
  Use when the user asks to upgrade the Mobile SDK version, or when you detect
  SDK 13.x version strings in a Podfile, project.pbxproj (SPM pin), or project.yml.
  Covers: iOS deployment target bump (17→18), Podfile signposts removal,
  SwiftUI preview macro migration, removed API fixes, DPoP/AA default changes.
  Does NOT cover React Native or Hybrid/Cordova upgrades.
---

# iOS Salesforce Mobile SDK — Upgrade 13.x to 14.0

This skill upgrades an existing iOS app from Salesforce Mobile SDK 13.x to 14.0. It is consumed by autonomous coding agents — every reference file is self-contained and contains exact source-of-truth code, file paths, and CLI commands.

## Scenarios

| Scenario | Reference | Preconditions |
|---|---|---|
| Upgrade SDK 13.x → 14.0 | [`references/upgrade-13-to-14.md`](references/upgrade-13-to-14.md) | SDK 13.x is already integrated |

Cross-cutting references:

| Topic | Reference |
|---|---|
| Removed APIs, protocol changes, deprecated members, new APIs, version bumps | [`references/breaking-changes.md`](references/breaking-changes.md) |
| Build / runtime / behavioral error symptoms | [`references/troubleshooting.md`](references/troubleshooting.md) |

## Detection Rules

Run these checks against the working directory before proceeding:

1. Check `Podfile` for `platform :ios, '17.` or any pod pinned at version `'13.`.
2. Check `<ProjectName>.xcodeproj/project.pbxproj` for `XCRemoteSwiftPackageReference` with `version = 13.` under the `SalesforceMobileSDK-iOS-SPM` entry.
3. Check `project.yml` for `SalesforceMobileSDK-iOS-SPM` with a `version: 13.` entry.
4. If SDK 13 is detected AND SDK 14 is NOT already present → this skill applies.

## Invariants

These hold regardless of the project shape (CocoaPods, hand-managed SPM, or xcodegen + SPM):

- **Do NOT recreate the Xcode project from scratch.** Preserve all hand-maintained target configuration, signing settings, and scheme setup.
- **Do NOT rename or move app source files.** Only the SDK version identifiers and any removed/renamed APIs change.
- **Do NOT change non-SDK build settings** (bundle ID, signing identity, capabilities) unless the upgrade explicitly requires it.
- **Raise deployment target ONLY in both places simultaneously.** The Podfile/project.yml/project.pbxproj declaration AND the Xcode project's `IPHONEOS_DEPLOYMENT_TARGET` must match. A mismatch causes CocoaPods to refuse install or produces an archive that fails App Store validation.
- **After `pod install`, stage `.xcworkspace` and `Podfile.lock` changes but do NOT stage the full `Pods/` directory.** The `Pods/` directory is a generated artifact; committing it bloats the repo and causes merge conflicts.
- **Never pass `CODE_SIGNING_ALLOWED=NO` to xcodebuild.** It strips the keychain entitlement and silently breaks login after the upgrade.

## Source of Truth

When the SDK API in this skill disagrees with reality, the upstream release notes and Objective-C headers win.

Release: <https://github.com/forcedotcom/SalesforceMobileSDK-iOS/releases/tag/v14.0.0-rc.2>
