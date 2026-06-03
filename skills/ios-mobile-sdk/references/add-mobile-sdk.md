# iOS — Add Mobile SDK Authentication

Wires `SalesforceSDKCore` into an existing iOS Swift app so the OAuth login screen appears on first launch and the SDK manages token persistence.

## Inputs

| Variable | Example | Notes |
|---|---|---|
| `<AppName>` | `MyApp` | Xcode target and app source folder name |
| `<BundleID>` | `com.mycompany.myapp` | Final `PRODUCT_BUNDLE_IDENTIFIER` |
| `<ConsumerKey>` | `3MVG9...` | Connected App consumer key, or leave as the placeholder |
| `<CallbackURL>` | `myapp://oauth/callback` | OAuth redirect URI, or leave as the placeholder |
| `<LoginHost>` | `login.salesforce.com` | `test.salesforce.com` for sandboxes |

## Detect Dependency Manager

Inspect the workspace before Step 1:

- `Podfile` at the project root → use **Option A — CocoaPods**.
- `*.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/` exists → use **Option B — Swift Package Manager**.

## Step 1 — SDK Dependency

### Option A — CocoaPods

Edit / create `Podfile`:

```ruby
source 'https://cdn.cocoapods.org/'
source 'https://github.com/forcedotcom/SalesforceMobileSDK-iOS-Specs'

platform :ios, '18.0'

target '<AppName>' do
  use_frameworks!
  pod 'SalesforceSDKCore'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '18.0'
    end
  end
end
```

`SalesforceSDKCore` pulls `SalesforceAnalytics` and `SalesforceSDKCommon` transitively. Then:

```bash
pod install
```

After this, all `xcodebuild` / open invocations use `<AppName>.xcworkspace` (not `.xcodeproj`).

### Option B — Swift Package Manager

Add to the project's package dependencies:

- URL: `https://github.com/forcedotcom/SalesforceMobileSDK-iOS-SPM`
- Branch: `master` (or the version tag for the desired SDK release).
- Products to link to the app target: `SalesforceSDKCore`, `SalesforceAnalytics`, `SalesforceSDKCommon`.

For programmatic / `xcodebuild`-driven flows, add the package via `Package.resolved` or a `Package.swift` referencing the same URL.

## Step 2 — `LaunchScreen.storyboard`

A launch storyboard is required so iOS establishes the window's safe-area bounds before the SDK presents login. If `LaunchScreen.storyboard` is not already in the target source folder, create it with the XML body shown in [`create-new-app.md`](create-new-app.md) Step 4.

Verify it appears in the Xcode target's **Copy Bundle Resources** build phase.

## Step 3 — `<AppName>/InitialViewController.swift`

This is the splash view installed during scene connection while the SDK presents the login flow.

```swift
import UIKit

class InitialViewController: UIViewController {}
```

## Step 4 — `<AppName>/AppDelegate.swift`

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

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication,
                     didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
}
```

`SalesforceManager.initializeSDK()` must run before any other SDK call. `init()` is the earliest legal point.

## Step 5 — `<AppName>/SceneDelegate.swift`

```swift
import UIKit
import SalesforceSDKCore

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window?.windowScene = windowScene

        AuthHelper.registerBlock(forCurrentUserChangeNotifications: {
            self.resetViewState {
                self.setupRootViewController()
            }
        })
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        initializeAppViewState()
        AuthHelper.loginIfRequired {
            self.setupRootViewController()
        }
    }

    // MARK: - Private

    func initializeAppViewState() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { self.initializeAppViewState() }
            return
        }
        window?.rootViewController = InitialViewController(nibName: nil, bundle: nil)
        window?.makeKeyAndVisible()
    }

    func setupRootViewController() {
        // Smoke test view — replace with the real root view controller after login works.
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground
        let label = UILabel()
        label.text = "Mobile SDK ready"
        label.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor)
        ])
        window?.rootViewController = vc
    }

    func resetViewState(_ postResetBlock: @escaping () -> Void) {
        if let root = window?.rootViewController, root.presentedViewController != nil {
            root.dismiss(animated: false, completion: postResetBlock)
        } else {
            postResetBlock()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}
```

`AuthHelper` lives in `SalesforceSDKCore` and is the published OAuth-flow entry point — `loginIfRequired` returns immediately when a session already exists.

## Step 6 — `<AppName>/bootconfig.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>remoteAccessConsumerKey</key>
    <string><ConsumerKey></string>
    <key>oauthRedirectURI</key>
    <string><CallbackURL></string>
    <key>shouldAuthenticate</key>
    <true/>
</dict>
</plist>
```

The file must be in the target's **Copy Bundle Resources** build phase. xcodegen picks this up automatically when the file is in the `sources:` folder.

## Step 7 — `Info.plist` additions

The keys to set are:

```xml
<key>SFDCOAuthLoginHost</key>
<string><LoginHost></string>
<key>UILaunchStoryboardName</key>
<string>LaunchScreen</string>
```

How to apply them depends on project type:

- **xcodegen-managed** (`project.yml` at the repo root, e.g. when the project came from [`create-new-app.md`](create-new-app.md)): `Info.plist` is generated from `project.yml`'s `targets.<AppName>.info.properties` block. Edit `project.yml` and run `xcodegen generate` — direct edits to `Info.plist` are overwritten on the next regeneration. The `UILaunchStoryboardName` key is already in the `project.yml` from `create-new-app.md`; only `SFDCOAuthLoginHost` needs to be added:

  ```yaml
  targets:
    <AppName>:
      info:
        path: <AppName>/Info.plist
        properties:
          SFDCOAuthLoginHost: <LoginHost>
          # … existing UILaunchStoryboardName + UIApplicationSceneManifest from create-new-app.md
  ```

- **Hand-maintained `.xcodeproj`** (no `project.yml`, e.g. the pattern used by `iOSNativeSwiftTemplate`): merge the keys directly into `<AppName>/Info.plist`.

## Step 8 — `<AppName>/<AppName>.entitlements`

Mobile SDK persists OAuth tokens to the iOS keychain. Without a `keychain-access-groups` entitlement, login appears to succeed in the UI but tokens cannot be stored — auth fails silently with `errSecMissingEntitlement (-34018)` and the post-login UI never appears.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>keychain-access-groups</key>
    <array>
        <string>$(AppIdentifierPrefix)<BundleID></string>
    </array>
</dict>
</plist>
```

If the project was generated from [`create-new-app.md`](create-new-app.md), `CODE_SIGN_ENTITLEMENTS` already references this file. For an existing project, set Build Settings → **Code Signing Entitlements** to `<AppName>/<AppName>.entitlements`.

After creating the file, ensure the project includes it. For xcodegen-managed projects, run `xcodegen generate` (and `pod install` if using CocoaPods, since `xcodegen generate` rewrites the `.xcodeproj`). For hand-maintained `.xcodeproj` (the pattern used by `iOSNativeSwiftTemplate`), drag the file into the project navigator and set Build Settings → **Code Signing Entitlements** to `<AppName>/<AppName>.entitlements`.

## Step 9 — Build

CocoaPods:

```bash
xcodebuild \
  -workspace <AppName>.xcworkspace \
  -scheme <AppName> \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

SPM:

```bash
xcodebuild \
  -project <AppName>.xcodeproj \
  -scheme <AppName> \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

Expected: `** BUILD SUCCEEDED **`. On first launch, the Salesforce login screen appears; on successful login, the placeholder "Mobile SDK ready" view installs.

Do **not** pass `CODE_SIGNING_ALLOWED=NO` — it strips the keychain entitlement and login fails silently. Ad-hoc signing (`CODE_SIGN_IDENTITY=-`) is correct for the simulator.

## Next

- Encrypted local DB: [`add-smartstore.md`](add-smartstore.md)
- Cloud sync: [`add-mobilesync.md`](add-mobilesync.md)
- Biometric session locking: [`add-biometric-auth.md`](add-biometric-auth.md)
- Symptoms after build: [`troubleshooting.md`](troubleshooting.md)
