---
name: android-upgrade-mobile-sdk-13-to-14
description: >
  Upgrades an existing Android Kotlin app from Salesforce Mobile SDK 13.x to 14.0.
  Use when the user asks to upgrade the Mobile SDK version, or when you detect
  SDK 13.x version strings in build.gradle.kts or libs.versions.toml.
  Covers: AGP 8→9 migration (plugin removal), minSdk/compileSdk/targetSdk bump,
  Gradle 9.4.1 upgrade, Kotlin plugin removal, account_type enforcement,
  manifest LoginActivity intent-filter, DPoP/AA defaults, biometric API change,
  logout() signature, ClientManager redesign.
  Does NOT cover React Native or Hybrid/Cordova upgrades. Does NOT cover Java apps.
---

# Android Salesforce Mobile SDK — Upgrade 13.x to 14.0

This skill upgrades an existing Android Kotlin app from Salesforce Mobile SDK 13.x to 14.0. It is consumed by autonomous coding agents — every reference file is self-contained and contains exact source-of-truth code, file paths, and CLI commands.

## Scenarios

| Scenario | Reference | Preconditions |
|---|---|---|
| Upgrade SDK 13.x → 14.0 | [`references/upgrade-13-to-14.md`](references/upgrade-13-to-14.md) | SDK 13.x is already integrated; app is Kotlin |

Cross-cutting references:

| Topic | Reference |
|---|---|
| Removed APIs, changed signatures, new APIs | [`references/breaking-changes.md`](references/breaking-changes.md) |
| Build / runtime / behavioral error symptoms | [`references/troubleshooting.md`](references/troubleshooting.md) |

## Detection Rules

Run these checks against the working directory before proceeding:

1. Check `app/build.gradle.kts` for `com.salesforce.mobilesdk:` with version string containing `13.`.
2. Check `libs.versions.toml` for `salesforceSDK = "13.` version string.
3. If SDK 13 is detected AND `14.` is NOT present anywhere in the same file → this skill applies.

## Invariants

These hold regardless of the project shape (version catalog or inline dependencies):

- **Do NOT recreate the Android project from scratch.** Preserve all hand-maintained module configuration, signing config, and build variants.
- **Do NOT rename or move app source files.** Only SDK version identifiers and removed/renamed APIs change.
- **Do NOT change `applicationId`, signing config, or non-SDK build settings** unless the upgrade explicitly requires it.
- **`minSdk` MUST be raised to 31.** SDK 14.0 requires Android 12 (API 31) as the minimum. This drops support for Android 9, 10, and 11 — confirm the app's Play Store minimum version policy before applying.
- **`compileSdk` and `targetSdk` must be at least 36.** The SDK 14.0 library itself targets `compileSdk = 36` (`libs/SalesforceSDK/build.gradle.kts` has an explicit `// TODO: MSDK 14 will remain on 36. The next increment will be in MSDK 15.`), so an app on 36 is fully compatible — this matches the `android-mobile-sdk` skill, which generates apps at 36. `37` also builds but is not required; it comes only from sample apps. Do not force a bump to 37.
- **Gradle wrapper MUST be updated to 9.4.1; AGP MUST be updated to 9.1.1.**
- **Reconcile the Kotlin plugin with the `android.builtInKotlin` flag.** Two valid configurations exist: with AGP built-in Kotlin active (`android.builtInKotlin` true/unset) remove `id("org.jetbrains.kotlin.android")` from `plugins { }`, since leaving it in conflicts; or set `android.builtInKotlin=false` in `gradle.properties` and keep the plugin. (The Mobile SDK library itself sets `builtInKotlin=false`, but that is the library's internal build choice and does **not** propagate to consuming apps via Maven — a consuming app on AGP 9 gets built-in Kotlin by default, so prefer Path A and choose Path B only deliberately.) Do not remove the plugin without confirming the flag. See [`references/upgrade-13-to-14.md`](references/upgrade-13-to-14.md) Step 4.
- **Build target**: `./gradlew assembleDebug` from the project root unless there is reason to use a different variant.

## Source of Truth

When the SDK API in this skill disagrees with reality, the upstream Kotlin source in the release wins.

Release: <https://github.com/forcedotcom/SalesforceMobileSDK-Android/releases/tag/v14.0.0-rc.1>
