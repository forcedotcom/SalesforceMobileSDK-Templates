# iOS — Add Dark Mode

Configures dark mode for the SDK-managed UI in an iOS Swift app that already has Mobile SDK initialized. Two mechanisms exist: a static `Info.plist UIUserInterfaceStyle` key applied at launch, and a runtime `SFSDKWindowManager.sharedManager().userInterfaceStyle` property that can be flipped while the app runs. Both target the SDK's own windows (login host picker, OAuth web login, Switch User, passcode/biometric prompts, snapshot window). Your own view controllers use standard iOS dark-mode handling — see Apple's docs linked at the bottom.

## Preconditions

- `AppDelegate.swift` calls `SalesforceManager.initializeSDK()` (or a subclass: `SmartStoreSDKManager`, `MobileSyncSDKManager`).

If the SDK is not yet wired up, run [`add-mobile-sdk.md`](add-mobile-sdk.md) first.

## Decision — Pick One Option

| Intent | Pick |
|---|---|
| Follow the iOS system dark/light setting (no force, no user toggle) | **Neither needed** — the SDK default (`.unspecified`) already follows the system. Skip this scenario. |
| Force light always, OR force dark always, no user toggle, applied at launch | **Option A** (`Info.plist`) |
| Follow user preference / app-level toggle that changes appearance at runtime without a restart | **Option B** (`SFSDKWindowManager`) |
| Both wired (e.g. `Info.plist` sets a default and the user can override at runtime) | Wire both — **runtime wins** wherever it is set to anything other than `.unspecified`, which is its default |

Read **only** the chosen option's section below.

## Option A — Static via `Info.plist`

### Step 1 — `Info.plist`

Add the `UIUserInterfaceStyle` key with one of the three accepted values:

```xml
<key>UIUserInterfaceStyle</key>
<string>Dark</string>
```

Accepted values: `Light` (force light always), `Dark` (force dark always), `Automatic` (follow system — same as omitting the key).

How to apply this depends on project type. **Detect first:** check whether `project.yml` exists at the repo root (`test -f project.yml`). If present, the project is xcodegen-managed; otherwise, it is hand-maintained.

- **xcodegen-managed** (`project.yml` at the repo root): `Info.plist` is generated from `project.yml`'s `targets.<AppName>.info.properties` block. Add the key there and run `xcodegen generate` — direct edits to `Info.plist` are overwritten on the next regeneration:

  ```yaml
  targets:
    <AppName>:
      info:
        path: <AppName>/Info.plist
        properties:
          UIUserInterfaceStyle: Dark
          # … existing keys stay …
  ```

- **Hand-maintained `.xcodeproj`** (no `project.yml`): merge the key directly into `<AppName>/Info.plist`.

This key is read once at app launch. To change appearance without relaunching, use Option B.

### Step 2 — Build

```bash
xcodebuild \
  -workspace <AppName>.xcworkspace \   # or: -project <AppName>.xcodeproj for SPM
  -scheme <AppName> \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

Then verify against the [Verify](#verify-applies-to-both-options) section below.

## Option B — Runtime via `SFSDKWindowManager`

Setting `SFSDKWindowManager.sharedManager().userInterfaceStyle` propagates `overrideUserInterfaceStyle` to every SDK-managed window. The change applies immediately and to all subsequent SDK window presentations.

### Step 1 — `AppDelegate.swift`

Apply the desired style after `SalesforceManager.initializeSDK()` but inside `application(_:didFinishLaunchingWithOptions:)` — **not** inside `override init()`. The SDK init must complete first, and UIKit appearance API is only safe to touch once the application has finished launching.

```swift
import UIKit
import SalesforceSDKCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    override init() {
        super.init()
        SalesforceManager.initializeSDK()
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        SFSDKWindowManager.sharedManager().userInterfaceStyle = .dark
        return true
    }
    // … the rest of AppDelegate is unchanged
}
```

Objective-C variant (parity, for projects with an Obj-C `AppDelegate`):

```objc
[SFSDKWindowManager sharedManager].userInterfaceStyle = UIUserInterfaceStyleDark;
```

Notes on the API:

- `SFSDKWindowManager.sharedManager()` is the singleton (Obj-C `+ sharedManager`).
- `userInterfaceStyle` is a `UIUserInterfaceStyle` — `.unspecified`, `.light`, or `.dark`. Default is `.unspecified` (the SDK's own windows follow the system).
- Setting it overrides any value declared via `Info.plist UIUserInterfaceStyle`.
- Scope: SDK-managed windows only. Your own view controllers are not affected.

### Step 2 — (Optional) User Toggle Backed by `UserDefaults`

To let the user toggle appearance from app settings and persist the choice across launches, write the chosen style to `UserDefaults` and read it on launch.

```swift
import UIKit
import SalesforceSDKCore

enum AppearancePreference: Int {
    case system = 0, light = 1, dark = 2

    var uiStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

private let appearanceKey = "appearance.preference"

// Launch-time restore — call from didFinishLaunchingWithOptions.
func applyPersistedAppearance() {
    let raw = UserDefaults.standard.integer(forKey: appearanceKey)
    let pref = AppearancePreference(rawValue: raw) ?? .system
    SFSDKWindowManager.sharedManager().userInterfaceStyle = pref.uiStyle
}

// Toggle handler — call this from your settings UI (e.g. on a segmented control's
// .valueChanged action). It persists the choice AND applies it immediately to the SDK windows.
func setAppearance(_ pref: AppearancePreference) {
    UserDefaults.standard.set(pref.rawValue, forKey: appearanceKey)
    SFSDKWindowManager.sharedManager().userInterfaceStyle = pref.uiStyle
}
```

Wire the launch-time restore in place of the hardcoded `.dark` assignment from Step 1:

```swift
func application(_ application: UIApplication,
                 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    applyPersistedAppearance()
    return true
}
```

### Step 3 — Build

```bash
xcodebuild \
  -workspace <AppName>.xcworkspace \   # or: -project <AppName>.xcodeproj for SPM
  -scheme <AppName> \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

Then verify against the [Verify](#verify-applies-to-both-options) section below.

## Verify (applies to both Options)

After login, exercise each SDK-managed window and confirm it renders in the configured appearance:

- **Login host picker** — the screen offering Production / Sandbox / custom hosts.
- **OAuth web login** — the in-app web view that hosts the Salesforce login page.
- **Switch User** — the user-switching list reachable from the SDK's account UI.
- **Passcode / biometric prompts** — the screen-lock unlock screen shown after the policy's idle timeout (or on `lock()`).
- **Snapshot window** — the privacy view shown briefly while the app is backgrounded.

App-owned UI (your own view controllers) is **not** governed by `SFSDKWindowManager`. Use standard iOS dark-mode handling — see Apple's docs in the [References](#references) section.

## Symptoms

See [`troubleshooting.md`](troubleshooting.md).

## References

- Mobile SDK — Set Dark Mode in iOS Apps: <https://developer.salesforce.com/docs/platform/mobile-sdk/guide/ui-dark-settings.html>
- Apple — Supporting Dark Mode in Your Interface: <https://developer.apple.com/documentation/uikit/supporting-dark-mode-in-your-interface>
