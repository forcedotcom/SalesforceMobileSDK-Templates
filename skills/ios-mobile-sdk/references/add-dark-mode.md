# iOS — Add Dark Mode

Configures dark mode for the SDK-managed UI in an iOS Swift app that already has Mobile SDK initialized. Two mechanisms exist: a static `Info.plist UIUserInterfaceStyle` key applied at launch, and a runtime `SFSDKWindowManager.shared().userInterfaceStyle` property that can be flipped while the app runs. Both target the SDK's own windows (login host picker, OAuth web login, Switch User, passcode/biometric prompts, snapshot window). Your own view controllers use standard iOS dark-mode handling — see Apple's docs linked at the bottom.

## Preconditions

- `AppDelegate.swift` calls `SalesforceManager.initializeSDK()` (or a subclass: `SmartStoreSDKManager`, `MobileSyncSDKManager`).

If the SDK is not yet wired up, run [`add-mobile-sdk.md`](add-mobile-sdk.md) first.

## Decision — Pick One Option

The two mechanisms differ by **how** the value is applied, not by which value you set. Route on the mechanism the request calls for, not on the fact that it says "dark" or "at launch" — a fixed dark value can be delivered either way:

- **Option A (`Info.plist`)** — a *static* value baked into the bundle and read once at launch. Pick it only when a fixed appearance is acceptable **and** there is no need to change it from code or at runtime.
- **Option B (`SFSDKWindowManager`)** — the value is set *from code* and can be changed while the app runs, with no relaunch. Pick it whenever the request wants runtime/programmatic control — **even if the only value wanted right now is a fixed dark at launch.**

| Intent | Pick |
|---|---|
| Follow the iOS system dark/light setting (no force, no user toggle) | **Neither needed** — the SDK default (`.unspecified`) already follows the system. Skip this scenario. |
| Force light or dark always, purely static, set in `Info.plist`, no need to change it from code or at runtime | **Option A** (`Info.plist`) |
| Set the appearance **from code / programmatically**, or so it can be **changed later at runtime without relaunching**, or the request says **not to use `Info.plist`** — including when the initial value is just a fixed dark at launch | **Option B** (`SFSDKWindowManager`) |
| Follow user preference / an app-level toggle that changes appearance at runtime | **Option B** (`SFSDKWindowManager`) |
| Both wired (e.g. `Info.plist` sets a default and the user can override at runtime) | Wire both — **runtime wins** wherever it is set to anything other than `.unspecified`, which is its default |

**Tie-breaker:** if the request contains any of "from code", "programmatically", "at runtime", "without relaunching", "so it can be changed later", or "not in `Info.plist`", choose **Option B** — regardless of whether a user-facing toggle is being built yet.

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

Setting `SFSDKWindowManager.shared().userInterfaceStyle` propagates `overrideUserInterfaceStyle` to every SDK-managed window. The change applies immediately and to all subsequent SDK window presentations.

### Step 1 — `AppDelegate.swift`

This is a **one-line, additive edit** to the existing `AppDelegate.swift`. Open the file already in the project and insert a single statement — do **not** rewrite, reorder, or regenerate the file, and **keep every method already there** (e.g. the `UISceneSession` lifecycle methods `configurationForConnecting` / `didDiscardSceneSessions`, and any others). Removing existing members is a regression, not part of this task.

Add exactly this line inside the existing `application(_:didFinishLaunchingWithOptions:)` method (after `SalesforceManager.initializeSDK()` has run), and **not** inside `override init()` — the SDK init must complete first, and UIKit appearance API is only safe to touch once the application has finished launching:

```swift
SFSDKWindowManager.shared().userInterfaceStyle = .dark
```

If the app has no `didFinishLaunchingWithOptions` yet, add just that method (returning `true`) with this one line in it — leaving every other existing method in place. In context the method reads:

```swift
func application(_ application: UIApplication,
                 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    SFSDKWindowManager.shared().userInterfaceStyle = .dark
    return true
}
```

**That single assignment is the entire change** for a fixed-appearance request (e.g. "set the SDK UI to dark at launch"). Do not add the `import`s if they are already present, do not add a `UIUserInterfaceStyle` key to `Info.plist`, and do not edit `project.yml` — the runtime property is self-sufficient and overrides any static value. Touch no file other than `AppDelegate.swift`. Only continue to Step 2 if the user explicitly asked for a user-facing toggle now.

Objective-C variant (parity, for projects with an Obj-C `AppDelegate`):

```objc
[SFSDKWindowManager sharedManager].userInterfaceStyle = UIUserInterfaceStyleDark;
```

Notes on the API:

- `SFSDKWindowManager.shared()` is the singleton in Swift (the Obj-C `+ sharedManager` is imported into Swift under the name `shared()`).
- `userInterfaceStyle` is a `UIUserInterfaceStyle` — `.unspecified`, `.light`, or `.dark`. Default is `.unspecified` (the SDK's own windows follow the system).
- Setting it overrides any value declared via `Info.plist UIUserInterfaceStyle`.
- Scope: SDK-managed windows only. Your own view controllers are not affected.

### Step 2 — (Optional) User Toggle Backed by `UserDefaults`

> **Scope check — do this step only if the user asked for the toggle now.** Step 1's single assignment is the complete answer when the request is just to set a fixed appearance (e.g. "set it to dark at launch"), or when the user says they will wire up the toggle themselves later. In those cases **stop after Step 1** — do not add the `UserDefaults` / `AppearancePreference` scaffolding below, and do not touch `Info.plist`.

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
    SFSDKWindowManager.shared().userInterfaceStyle = pref.uiStyle
}

// Toggle handler — call this from your settings UI (e.g. on a segmented control's
// .valueChanged action). It persists the choice AND applies it immediately to the SDK windows.
func setAppearance(_ pref: AppearancePreference) {
    UserDefaults.standard.set(pref.rawValue, forKey: appearanceKey)
    SFSDKWindowManager.shared().userInterfaceStyle = pref.uiStyle
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
