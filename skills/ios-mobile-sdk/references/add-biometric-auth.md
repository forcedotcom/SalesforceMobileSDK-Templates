# iOS — Add Biometric Authentication

Configures Face ID / Touch ID session locking on an iOS Swift app that already has Mobile SDK initialized. The SDK manages the locked-state UI, presents the OS biometric prompt, and exposes opt-in / lock APIs to the app.

## Preconditions

- `AppDelegate.swift` calls `SalesforceManager.initializeSDK()` (or a subclass: `SmartStoreSDKManager`, `MobileSyncSDKManager`).
- `bootconfig.plist` exists in the target source folder.
- The Salesforce Connected App backing the consumer key in `bootconfig.plist` has a **Mobile App Policy** with biometric authentication enabled and a non-zero session timeout. Without that server-side policy, `biometricAuthenticationManager.enabled` is `false` and the SDK will never lock the session — there is no app-side switch that turns the feature on.

If the SDK is not yet wired up, run [`add-mobile-sdk.md`](add-mobile-sdk.md) first.

## API Surface

The biometric protocol's published API (`SFBiometricAuthenticationManager` in `SalesforceSDKCore`) is the complete set of biometric controls available to consumer code:

| Member | Kind | Purpose |
|---|---|---|
| `enabled` | `Bool` (read-only) | `true` when the org's Mobile App Policy enables biometric for the current user. |
| `locked` | `Bool` (read-only) | `true` while the SDK has the session locked behind biometrics. |
| `automaticPresentation` | `Bool` (read/write, default `true`) | When `true`, the SDK auto-presents the opt-in dialog after login and auto-presents the OS biometric prompt on next foreground when locked. |
| `lock()` | function | Locks the session immediately. Authenticated REST requests fail until unlocked. |
| `biometricOptIn(optIn:)` | function | Sets the opt-in state for the current user. |
| `hasBiometricOptedIn()` | `Bool` | `true` if the current user has opted in. |
| `presentOptInDialog(viewController:)` | function | Manually present the opt-in dialog (only needed when `automaticPresentation = false`). |
| `enableNativeBiometricLoginButton(enabled:)` | function | Toggles the biometric shortcut button on the SDK's native login screen. |

Access the singleton from app code with `SalesforceManager.shared.biometricAuthenticationManager()` (note the parentheses — the accessor is an Objective-C method, bridged to Swift).

## Step 1 — `Info.plist`

Add the Face ID usage description (without it, iOS aborts the biometric request):

```xml
<key>NSFaceIDUsageDescription</key>
<string>This app uses Face ID to verify your identity before accessing Salesforce data.</string>
```

## Step 2 — Default flow (recommended)

`automaticPresentation` defaults to `true`. With the org-side policy in place and `NSFaceIDUsageDescription` set, the SDK presents the opt-in dialog after login and locks/unlocks on backgrounding/foregrounding without further app code. No additional integration in `AppDelegate` or `SceneDelegate` is required.

To explicitly confirm or reset the default, configure during scene setup (after the SDK is initialized):

```swift
import SalesforceSDKCore

// inside SceneDelegate.scene(_:willConnectTo:options:)
SalesforceManager.shared.biometricAuthenticationManager().automaticPresentation = true
```

## Step 3 — Manual opt-in flow (only when `automaticPresentation = false`)

Use this only if the app needs to drive opt-in itself (e.g. defer the dialog to a custom screen). After `setupRootViewController()` installs a presenter, call `presentOptInDialog(viewController:)` with a non-nil `UIViewController`:

```swift
func setupRootViewController() {
    // … existing setupRootViewController body …

    let bioMgr = SalesforceManager.shared.biometricAuthenticationManager()
    if bioMgr.enabled,
       !bioMgr.locked,
       !bioMgr.hasBiometricOptedIn(),
       let presenter = window?.rootViewController {
        bioMgr.presentOptInDialog(viewController: presenter)
    }
}
```

`presentOptInDialog(viewController:)` requires a real `UIViewController` — there is no nil-supporting auto-discovery overload.

## Step 4 — Build

```bash
xcodebuild \
  -workspace <AppName>.xcworkspace \
  -scheme <AppName> \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

(For SPM, swap `-workspace <AppName>.xcworkspace` for `-project <AppName>.xcodeproj`.)

After login, the SDK presents the biometric opt-in (when the org's Mobile App Policy is configured for biometric auth and `automaticPresentation = true`). After the configured session timeout elapses while the app is backgrounded, the SDK locks the session on next foreground and presents the OS biometric prompt before installing the post-login UI.

## Symptoms

See [`troubleshooting.md`](troubleshooting.md) for "biometric prompt does not appear", "opt-in dialog appears every launch", and related issues.
