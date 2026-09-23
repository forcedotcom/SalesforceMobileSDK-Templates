# Android — Add Biometric Authentication

Adds fingerprint / face / iris session locking to an Android Kotlin app that already has Mobile SDK initialized. The SDK presents the OS biometric prompt, manages the locked-state UI, and handles user opt-in.

## Preconditions

- `MainApplication.kt` calls one of `SalesforceSDKManager.initNative(...)`, `SmartStoreSDKManager.initNative(...)`, or `MobileSyncSDKManager.initNative(...)`.
- `MainActivity` extends `SalesforceActivity`.

If not, run [`add-mobile-sdk.md`](add-mobile-sdk.md) first.

The SDK handles all locking, unlocking, and the native biometric prompt automatically once the user opts in.

## Connected App Configuration (required, in your Salesforce org)

- **Setup → App Manager → your Connected App → drop-down → View → Custom Attributes → New**
  - Key: `ENABLE_BIOMETRIC_AUTHENTICATION`
  - Value: `"true"` (with the literal quotes — Custom Attribute values are JSON literals; `true` without quotes will not enable the policy)
- **Setup → App Manager → your Connected App → Edit Policies → OAuth Policies**: **uncheck "Require Secret for Refresh Token Flow"**. Mobile SDK uses PKCE without a client secret. If this is checked, biometric success → token refresh → `invalid_client` 400 → SDK silently logs the user out and shows fresh OAuth (see Troubleshooting below).
- The user must log in *fresh* after these changes — Custom Attributes and OAuth policies are read from the userinfo response at login time, so a re-login picks up the new values immediately.

## Step 1 — Add the `androidx.biometric` Dependency

In `app/build.gradle.kts`, add the AndroidX Biometric library. The SDK's `biometricAuthenticationManager` API drives the prompt, but the device-capability check uses `androidx.biometric.BiometricManager`.

```kotlin
dependencies {
    implementation("com.salesforce.mobilesdk:MobileSync:14.0.0-rc.2")
    implementation("androidx.biometric:biometric:1.1.0")
}
```

If the app is on the base `SalesforceSDK` artifact, swap it for `MobileSync` (or use the manager already in place — every manager in the hierarchy exposes `biometricAuthenticationManager`).

Sync Gradle after editing.

## Step 2 — Update `MainActivity.kt`

Trigger the opt-in check from `onResume(client: RestClient?)` — the SDK callback that fires *after* the user account is bound. Triggering it from `onPostResume()` will silently skip the dialog on first login because the user isn't bound yet, and `enabled` reads `false`.

**Add these imports** (at the top of `MainActivity.kt`):

```kotlin
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricManager.Authenticators.BIOMETRIC_STRONG
import androidx.biometric.BiometricManager.Authenticators.BIOMETRIC_WEAK
import com.salesforce.androidsdk.mobilesync.app.MobileSyncSDKManager
```

**Extend your existing `onResume(client: RestClient?)`** to enable automatic biometric presentation:

```kotlin
override fun onResume(client: RestClient?) {
    if (client == null) return
    // … existing post-login logic (e.g. setupUserStoreFromDefaultConfig) …
    maybePresentBiometricOptIn()
}

private fun maybePresentBiometricOptIn() {
    val mgr = MobileSyncSDKManager.getInstance().biometricAuthenticationManager ?: return
    val deviceHasBiometrics = BiometricManager.from(this).canAuthenticate(
        BIOMETRIC_STRONG or BIOMETRIC_WEAK
    ) == BiometricManager.BIOMETRIC_SUCCESS
    if (mgr.enabled && deviceHasBiometrics) {
        mgr.automaticPresentation = true
    }
}
```

Setting `automaticPresentation = true` tells the SDK to present the OS biometric prompt automatically whenever the session needs to be unlocked — no manual opt-in dialog invocation required.

> **`biometricAuthenticationManager`** is a nullable property on `SalesforceSDKManager`. It's null until a user is authenticated.

If the app uses `SmartStoreSDKManager` or `SalesforceSDKManager` directly, swap the import and the `getInstance()` call accordingly — every manager in the hierarchy exposes the same `biometricAuthenticationManager` property.

## Step 3 — Build and Verify

```bash
./gradlew assembleDebug
```

Expected: `BUILD SUCCESSFUL`. After login, the SDK presents the biometric opt-in. After opt-in, the OS biometric prompt is required to unlock the session on subsequent launches.

### Runtime verification (emulator or device)

1. Launch the app — Salesforce login screen appears.
2. Log in — the OS biometric prompt appears automatically on next foreground.
3. Authenticate successfully — the app unlocks without re-entering credentials.
4. Background the app, then foreground again — the OS biometric prompt reappears.

> **Emulator note:** Fingerprint can be enrolled in the emulator via **Extended controls → Fingerprint**. Use `adb -e emu finger touch 1` to simulate a fingerprint scan.

## Symptoms

See [`troubleshooting.md`](troubleshooting.md) for opt-in dialog issues, `IllegalStateException`, fragment-restore crashes, and `invalid_client` token-refresh failures.
