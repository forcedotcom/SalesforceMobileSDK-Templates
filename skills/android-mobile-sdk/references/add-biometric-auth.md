# Android — Add Biometric Authentication

Adds fingerprint / face / iris session locking to an Android Kotlin app that already has Mobile SDK initialized. The SDK presents the OS biometric prompt, manages the locked-state UI, and handles user opt-in.

## Preconditions

- `MainApplication.kt` calls one of `MobileSyncSDKManager.initNative(...)`, `SmartStoreSDKManager.initNative(...)`, or `SalesforceSDKManager.initNative(...)`.
- `MainActivity` extends `SalesforceActivity`.
- The connected app in the Salesforce org has biometric authentication enabled — without that org-side flag, `biometricAuthenticationManager.enabled` is `false` and the dialog correctly does not appear.

If not, run [`add-mobile-sdk.md`](add-mobile-sdk.md) first.

## Step 1 — `app/build.gradle.kts`

Add the AndroidX biometric dependency. The SDK's `biometricAuthenticationManager` API drives the prompt, but the device-capability check uses `androidx.biometric.BiometricManager`.

```kotlin
dependencies {
    implementation("com.salesforce.mobilesdk:MobileSync:13.2.1")
    implementation("androidx.biometric:biometric:1.1.0")
}
```

## Step 2 — `MainActivity.kt`

Override `onPostResume()` and present the SDK's opt-in dialog when:

1. The device has at least weak biometrics enrolled.
2. The connected app has biometric auth enabled (`enabled == true`).
3. The user has not already opted in (`hasBiometricOptedIn() == false`).

```kotlin
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricManager.Authenticators.BIOMETRIC_STRONG
import androidx.biometric.BiometricManager.Authenticators.BIOMETRIC_WEAK
import com.salesforce.androidsdk.mobilesync.app.MobileSyncSDKManager

class MainActivity : SalesforceActivity() {

    // … existing onCreate / onResume(client) …

    override fun onPostResume() {
        super.onPostResume()

        val deviceHasBiometrics = BiometricManager.from(this).canAuthenticate(
            BIOMETRIC_STRONG or BIOMETRIC_WEAK
        ) == BiometricManager.BIOMETRIC_SUCCESS

        MobileSyncSDKManager.getInstance().biometricAuthenticationManager?.run {
            if (enabled && deviceHasBiometrics && !hasBiometricOptedIn()) {
                presentOptInDialog(supportFragmentManager)
            }
        }
    }
}
```

Why `onPostResume()` rather than `onResume()`: the activity window must be fully attached before presenting a `DialogFragment`. Calling `presentOptInDialog(supportFragmentManager)` from `onResume()` can throw `IllegalStateException: Can not perform this action after onSaveInstanceState`.

`biometricAuthenticationManager` is a nullable property on `SalesforceSDKManager`. The `?.run { }` block safely no-ops when no user is logged in.

If the app uses `SmartStoreSDKManager` or `SalesforceSDKManager` directly, swap the import and the `getInstance()` call accordingly — every manager in the hierarchy exposes the same `biometricAuthenticationManager` property.

## Step 3 — Build

```bash
./gradlew assembleDebug
```

Expected: `BUILD SUCCESSFUL`. After login, the SDK presents the biometric opt-in. After opt-in, the OS biometric prompt is required to unlock the session on subsequent launches.

The Android emulator simulates a fingerprint via:

```bash
adb -e emu finger touch 1
```

(Fingerprints must be enrolled in the emulator first via Extended controls → Fingerprint, or `adb shell` equivalent.)

## Symptoms

See [`troubleshooting.md`](troubleshooting.md) for opt-in dialog issues, `IllegalStateException`, and unresolved references.
