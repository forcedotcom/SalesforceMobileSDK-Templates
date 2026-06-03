# iOS — Add SmartStore

Adds the encrypted local database `SmartStore` to an iOS Swift app that already has `SalesforceSDKCore` wired up.

## Preconditions

- `AppDelegate.swift` calls `SalesforceManager.initializeSDK()` (or a subclass — `SmartStoreSDKManager`, `MobileSyncSDKManager`).
- `bootconfig.plist` exists in the target source folder and is in **Copy Bundle Resources**.
- Keychain entitlement is in place (see [`add-mobile-sdk.md`](add-mobile-sdk.md) Step 8).

If any of these fail, run [`add-mobile-sdk.md`](add-mobile-sdk.md) first.

## Inputs

| Variable | Example | Notes |
|---|---|---|
| `<SoupName>` | `Account` | The local SmartStore table name |
| `<AppName>` | `MyApp` | Xcode target / source folder |

## Step 1 — Dependency

### Option A — CocoaPods

Replace the `SalesforceSDKCore` pod with `SmartStore` (which depends on `SalesforceSDKCore` transitively):

```ruby
# was: pod 'SalesforceSDKCore'
pod 'SmartStore'
```

```bash
pod install
```

### Option B — Swift Package Manager

Add the `SmartStore` product from the existing `SalesforceMobileSDK-iOS-SPM` package to the app target's **Frameworks, Libraries, and Embedded Content**.

## Step 2 — `AppDelegate.swift`

Swap the SDK manager:

```swift
import SmartStore   // was: import SalesforceSDKCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    override init() {
        super.init()
        SmartStoreSDKManager.initializeSDK()   // was: SalesforceManager.initializeSDK()
    }
    // … the rest of AppDelegate is unchanged
}
```

`SmartStoreSDKManager` is a subclass of `SalesforceSDKManager` and preserves all OAuth + REST behavior.

## Step 3 — `SceneDelegate.swift`

Register the store after a successful login by calling `setupUserStoreFromDefaultConfig()` inside `setupRootViewController()`:

```swift
import SmartStore
import SalesforceSDKCore   // AuthHelper still lives here

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    // … scene(_:willConnectTo:options:) and sceneWillEnterForeground(_:) unchanged …

    func setupRootViewController() {
        SmartStoreSDKManager.shared.setupUserStoreFromDefaultConfig()

        // Smoke test view — replace after the store is wired up.
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground
        let label = UILabel()
        label.text = "SmartStore ready"
        label.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor)
        ])
        window?.rootViewController = vc
    }
}
```

`setupUserStoreFromDefaultConfig()` reads `userstore.json` from the app bundle and creates the configured soups in the encrypted store for the current user. It silently no-ops if the file isn't in **Copy Bundle Resources**.

## Step 4 — `<AppName>/userstore.json`

Place this in the app target's source folder:

```json
{
  "soups": [
    {
      "soupName": "<SoupName>",
      "indexes": [
        { "path": "Id",        "type": "string" },
        { "path": "Name",      "type": "string" },
        { "path": "__local__", "type": "string" }
      ]
    }
  ]
}
```

Constraints (enforced by the SDK at parse time):

- `soupName` must be a non-empty string.
- Each index entry needs `path` and `type`. Supported `type` values: `string`, `integer`, `floating`, `full_text`, `json1`.
- `__local__` is reserved for marking dirty rows that need to be uploaded by MobileSync.

After adding the file, ensure it lands in **Copy Bundle Resources** for the app target. For xcodegen-managed projects, run `xcodegen generate` (and `pod install` for CocoaPods). For hand-maintained `.xcodeproj` (the pattern used by `iOSNativeSwiftTemplate`), drag the file into the project navigator and verify Build Phases → Copy Bundle Resources lists it.

## Step 5 — Build

```bash
xcodebuild \
  -workspace <AppName>.xcworkspace \
  -scheme <AppName> \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

(For SPM, swap `-workspace <AppName>.xcworkspace` for `-project <AppName>.xcodeproj`.)

After login, the placeholder view reads "SmartStore ready" and `<SoupName>` is registered.

## Next

- Cloud sync into the same soup: [`add-mobilesync.md`](add-mobilesync.md)
- Symptoms (e.g. `setupUserStoreFromDefaultConfig()` silently does nothing): [`troubleshooting.md`](troubleshooting.md)
