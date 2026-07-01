# iOS — Add Biometric Authentication

Adds Face ID / Touch ID biometric session locking to an iOS Swift app that already has Mobile SDK initialized. The SDK manages the locked-state UI, presents the OS biometric prompt, and exposes opt-in / lock APIs to the app.

## Preconditions

- `AppDelegate.swift` calls `SalesforceManager.initializeSDK()` (or a subclass: `SmartStoreSDKManager`, `MobileSyncSDKManager`).
- `bootconfig.plist` exists in the target source folder.
- The Salesforce Connected App backing the consumer key in `bootconfig.plist` already publishes the biometric policy custom attributes. This skill assumes that's done — if `SalesforceManager.shared.biometricAuthenticationManager().enabled` returns `false` at runtime, talk to your Salesforce admin before debugging the client.

If the SDK is not yet wired up, run [`add-mobile-sdk.md`](add-mobile-sdk.md) first.

## Step 1 — `Info.plist`

Add the Face ID usage description (without it, iOS aborts the biometric request):

```xml
<key>NSFaceIDUsageDescription</key>
<string>This app uses Face ID to verify your identity before accessing Salesforce data.</string>
```

## Step 2 — Prompt for Biometric Opt-In After Login

In `SceneDelegate.swift`, present the SDK's opt-in dialog after successful login. Guard on `enabled` and `hasBiometricOptedIn()` so the dialog only appears once and only when the policy is in force for the current user.

```swift
import SalesforceSDKCore

func setupRootViewController() {
    // … build your post-login root view controller …

    let bioAuth = SalesforceManager.shared.biometricAuthenticationManager()
    if bioAuth.enabled, !bioAuth.hasBiometricOptedIn(), let root = window?.rootViewController {
        bioAuth.presentOptInDialog(viewController: root)
    }
}
```

Notes on the API:

- `SalesforceManager.shared.biometricAuthenticationManager()` is the singleton. It conforms to the public `BiometricAuthenticationManager` protocol (`@objc(SFBiometricAuthenticationManager)`).
- `enabled` is a **read-only** `Bool` derived from the Connected App policy stored at login. There is no client-side switch — biometric is enabled server-side via the Connected App, not from app code.
- `hasBiometricOptedIn()` lets you avoid re-prompting users who have already opted in or out.
- `presentOptInDialog(viewController:)` requires a real `UIViewController`. There is no nil-supporting auto-discovery overload.

## Step 3 — (Optional) Lock the App On Demand

To lock immediately — for example, from an overflow menu's "Lock now" action — call `lock()`:

```swift
SalesforceManager.shared.biometricAuthenticationManager().lock()
```

The SDK also relocks automatically when the app comes to the foreground after the policy's configured idle timeout has elapsed.

## Step 4 — Build and Verify

Build and run. After login on a user whose Connected App has the biometric policy in force:

1. The opt-in dialog appears once. Tap **Enable**.
2. Background the app and wait the configured timeout, or call `lock()`.
3. Bring the app to the foreground — the SDK presents the Face ID / Touch ID unlock screen with a "Log In with Biometric" button.

## Symptoms

See [`troubleshooting.md`](troubleshooting.md) for "biometric prompt does not appear", and other related issues.
