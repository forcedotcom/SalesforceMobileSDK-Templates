---
name: android-upgrade-mobile-sdk-12-to-13
description: >
  Upgrades an existing Android app from Salesforce Mobile SDK 12.x to 13.2.1.
  Use when the user asks to upgrade the Mobile SDK version, or when you detect
  SDK 12.x version strings in build.gradle.kts, libs.versions.toml, or
  build.gradle files. Covers: minSdk bump (26→28), compileSdk bump (34→36),
  Gradle/AGP upgrade, removed API fixes (OAuthWebviewHelper, LoginOptions,
  ServerPickerActivity, LogoutCompleteReceiver), login customization migration
  to LoginViewModel, and ProGuard/R8 rule cleanup.
  Does NOT cover React Native or Hybrid/Cordova upgrades.
---

# Android Salesforce Mobile SDK — Upgrade 12.x to 13.2.1

This skill upgrades an existing Android app from Salesforce Mobile SDK 12.x to 13.2.1. It is consumed by autonomous coding agents — every reference file is self-contained and contains exact source-of-truth code, file paths, and CLI commands.

## Scenarios

| Scenario | Reference | Preconditions |
|---|---|---|
| Upgrade SDK 12.x → 13.2.1 | [`references/upgrade-12-to-13.md`](references/upgrade-12-to-13.md) | SDK 12.x is already integrated |

Cross-cutting references:

| Topic | Reference |
|---|---|
| Removed APIs, changed signatures, new APIs | [`references/api-changes.md`](references/api-changes.md) |
| Build / runtime / behavioral error symptoms | [`references/troubleshooting.md`](references/troubleshooting.md) |

## Detection Rules

Run these checks against the working directory before proceeding:

1. Check `app/build.gradle.kts` for `com.salesforce.mobilesdk:` with version string containing `12.`.
2. Check `libs.versions.toml` for `salesforceSDK = "12.` version string.
3. Check `app/build.gradle` (Groovy DSL) for `'com.salesforce.mobilesdk:` with `:12.`.
4. If SDK 12 is detected AND `13.` is NOT present anywhere in the same file → this skill applies.

## Invariants

These hold regardless of the project shape (version catalog or inline dependencies):

- **Do NOT recreate the Android project from scratch.** Preserve all hand-maintained module configuration, signing config, and build variants.
- **Do NOT rename or move app source files.** Only SDK version identifiers and removed/renamed APIs change.
- **Do NOT change applicationId, signing config, or non-SDK build settings** unless the upgrade explicitly requires it.
- **`minSdk` MUST be raised to 28.** SDK 13.x requires Android 9 (API 28) as the minimum. This drops support for Android 8.0 (API 26) and 8.1 (API 27) — confirm the app's Play Store minimum version policy before applying.
- **`compileSdk` and `targetSdk` MUST be raised to 36.**
- **Gradle wrapper MUST be updated to 8.14.3; AGP MUST be updated to 8.12.0.**
- **Build target**: `./gradlew assembleDebug` from the project root unless there is reason to use a different variant.

## Source of Truth

When the SDK API in this skill disagrees with reality, the upstream Kotlin/Java in the release wins.

Release: <https://github.com/forcedotcom/SalesforceMobileSDK-Android/releases/tag/v13.2.1>
