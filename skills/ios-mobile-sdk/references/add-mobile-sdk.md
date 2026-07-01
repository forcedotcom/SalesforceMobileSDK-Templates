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

> **Anti-pattern: do not author a `Package.swift`.** A standalone `Package.swift` is **not one of the four supported integration paths** below. The Salesforce Mobile SDK is consumed via either CocoaPods (Option A — edit the existing `Podfile`), xcodegen (Option B-i — edit `project.yml`'s `packages:` map), or the Xcode UI (Option B-ii). If your initial plan included "create Package.swift" or "generate Package.swift for SPM dependencies," **drop that step now** before reading further — it does not match any option and produces a project that does not build.

## Step 0 — Detect Project Shape (required first action)
<!-- CANONICAL: project-shape detection — keep byte-identical across add-mobile-sdk / add-smartstore / add-mobilesync -->
**Do not skip this step. Do not assume a shape from the prompt or from training-data priors.** Before any file edits, list the contents of the project root and identify which of the four cases applies based on the actual files present. Agents that skip this step and pick a shape from training data routinely write to the wrong files and break the build.

Run a directory listing of the project root (the folder you'll be modifying — the same folder the prompt or task directive points at). Then pick **exactly one** option in priority order based on the files present:

1. `Podfile` AND `project.yml` both exist → **Hybrid (Option A for the SDK + xcodegen for sources)**. `project.yml` owns project structure (sources, schemes, entitlements); CocoaPods supplies third-party modules. For the SDK dependency, follow Option A only — **DO NOT** also add `SalesforceMobileSDK-iOS-SPM` to `project.yml` (linking the SDK via both Pods and SPM produces duplicate-symbol errors). After authoring new sources in Steps 2–8, run `xcodegen generate`, then `pod install`.
2. `Podfile`, no `project.yml` → **Option A — CocoaPods**. Edit only the `Podfile`; don't run xcodegen or text-edit the `.xcodeproj`.
3. `project.yml`, no `Podfile` → **Option B-i — xcodegen + SPM (autonomous)**. The `.xcodeproj` is regenerable output.
4. `.xcodeproj`, no `project.yml`, no `Podfile` → **Option B-ii — Plain SPM (human-instruction)**.

If none match, the project is bare — start from [`create-new-app.md`](create-new-app.md) instead.

**Commit to your choice and state it.** State which option you picked and which file(s) in the listing triggered the choice (e.g. *"Option A — found `Podfile`, no `project.yml`"*). Then read **only that option's section** in Step 1 — reading sections for options you didn't pick will mix workflows and break the build.

## Step 1 — SDK Dependency

### Option A — CocoaPods

> **DO NOT** author a `project.yml`. **DO NOT** run `xcodegen` or `xcodegen generate`. **DO NOT** recreate or overwrite the existing `.xcodeproj/`. **DO NOT** text-edit `project.pbxproj` (with a script or by hand) to add file references — the file format is hash-keyed and brittle, and edits silently corrupt the project.
>
> The `.xcodeproj` is hand-maintained by the project author. Edit only the existing `Podfile`, `Info.plist`, and existing source files. For new files (e.g. `.entitlements`, `bootconfig.plist`, `InitialViewController.swift`, `LaunchScreen.storyboard`), write them at the path the existing target already references — typically `<AppName>/<filename>`. Inspect `<AppName>.xcodeproj/project.pbxproj` for `CODE_SIGN_ENTITLEMENTS`, `INFOPLIST_FILE`, and the target's `path` to confirm the convention. If a new file's path is *not* already referenced and you can't add it via Xcode UI, emit a manual instruction asking the user to drag it into the target — do not attempt to wire it up programmatically.

Add the Salesforce specs source and `SalesforceSDKCore` pod. `SalesforceSDKCore` pulls in `SalesforceAnalytics` and `SalesforceSDKCommon` transitively.

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

**Verify before installing.** Re-read the Podfile after editing and confirm:

- The line `pod 'SalesforceSDKCore'` is present inside the `target` block.
- Both sources are declared: `cdn.cocoapods.org` AND `github.com/forcedotcom/SalesforceMobileSDK-iOS-Specs`.

If either is missing, your edit didn't land — `pod install` will succeed vacuously but the build will fail later with `Unable to find module dependency: 'SalesforceSDKCore'`.

Then install:

```bash
pod install
```

After this, all `xcodebuild` / open invocations use `<AppName>.xcworkspace` (not `.xcodeproj`).

### Option B-i — xcodegen + SPM (project has `project.yml`)

> `project.yml` is the source of truth. Running `xcodegen generate` is the correct move here — that's how new files and dependencies land in the `.xcodeproj`. **DO NOT** use Xcode's "Add Package Dependencies…" UI; those edits live in `project.pbxproj` and get wiped on the next regen.

This is the autonomous path. Edit `project.yml` to declare the package and its products, then re-run `xcodegen generate`.

**Step B-i.1: Edit `project.yml`.** Add a top-level `packages:` map and reference its products on the app target via `dependencies:`. Merge the snippet below into the existing file — do not replace the `targets:` block; add the `dependencies:` list (or extend it) inside the existing `<AppName>` target.

```yaml
packages:
  SalesforceMobileSDK-iOS-SPM:
    url: https://github.com/forcedotcom/SalesforceMobileSDK-iOS-SPM
    branch: master

targets:
  <AppName>:
    # ... existing fields stay ...
    dependencies:
      - package: SalesforceMobileSDK-iOS-SPM
        product: SalesforceSDKCore
      - package: SalesforceMobileSDK-iOS-SPM
        product: SalesforceAnalytics
      - package: SalesforceMobileSDK-iOS-SPM
        product: SalesforceSDKCommon
```

To pin a specific release instead of tracking `master`, replace `branch: master` with `version: <tag>` (e.g. `version: 13.1.0`).

**Verify before regenerating.** Re-read `project.yml` after editing and confirm both blocks landed: the `packages:` map at the top level, and the three `dependencies:` entries inside the `<AppName>` target. Without both, `xcodegen generate` will succeed silently and the build will fail later with `No such module 'SalesforceSDKCore'`.

**Step B-i.2: Regenerate the project.**

```bash
xcodegen generate
```

This rewrites `<AppName>.xcodeproj`. If a `.xcodeproj` already exists on disk, that's fine — `project.yml` is the source of truth and xcodegen owns the generated file.

**Step B-i.3: Resolve packages.**

```bash
xcodebuild -resolvePackageDependencies \
  -project <AppName>.xcodeproj \
  -scheme <AppName>
```

This pre-fetches and pins the SPM packages. Without it, the next build can fail on a clean checkout or after clearing DerivedData.

**Step B-i.4: Continue with Steps 2–9 below.** After authoring the new sources / resources / entitlements in those steps, re-run `xcodegen generate` once more so the new files end up in the regenerated project.

### Option B-ii — Plain SPM (project has only `.xcodeproj`)

> **DO NOT** author a `project.yml`. **DO NOT** run `xcodegen` or `xcodegen generate`. **DO NOT** create a `Podfile` or run `pod install`. **DO NOT** text-edit `project.pbxproj`. The `.xcodeproj` is hand-managed; any of the above silently converts it to a different shape and either drops later UI-added packages on the next regen or breaks the build.

This is the human-instruction path. The project's `.xcodeproj` is hand-managed, so adding the package via the Xcode UI is the only safe option.

**Step B-ii.1: Print the manual-step block and stop.** Emit the following block verbatim (substituting `<AppName>`), then halt — do not proceed to Step 2 of Add Mobile SDK until the user replies with a confirmation.

> **Manual step required — Xcode UI.** This project is a hand-managed `.xcodeproj` (no `project.yml`). I can't add the Swift package autonomously without risking corrupting your project file. Please do the following in Xcode, then reply with "done" so I can continue.
>
> 1. Open `<AppName>.xcodeproj` in Xcode.
> 2. **File → Add Package Dependencies…**
> 3. In the search field, paste: `https://github.com/forcedotcom/SalesforceMobileSDK-iOS-SPM`
> 4. Dependency Rule: **Branch** → `master` (or pick a version tag).
> 5. Click **Add Package**.
> 6. In the product picker, check these three products and assign each to the `<AppName>` target:
>    - `SalesforceSDKCore`
>    - `SalesforceAnalytics`
>    - `SalesforceSDKCommon`
> 7. Click **Add Package**.
> 8. Reply "done" (or "added") when finished.

**Step B-ii.2: Wait for user confirmation.** While waiting, do not edit files, run builds, or invent commands. If the user replies with anything other than a confirmation, re-emit the instructions or answer the user's question — but do not advance to Step 2.

**Step B-ii.3: After confirmation, continue with Steps 2–9 below in place.** Edit existing source files directly. **Do not** run `xcodegen generate` — the project is hand-managed, and any new files you create on disk are not automatically in the Xcode target. After authoring new files in Steps 2–8 (and before the Step 9 build), emit one more human instruction:

> **Manual step required — Xcode UI.** I've created `<list the files you authored — e.g. bootconfig.plist, InitialViewController.swift, LaunchScreen.storyboard, <AppName>.entitlements>`. In Xcode, please drag each of these files into the `<AppName>` target group and verify they appear in the right build phase, then reply "done":
> - `Copy Bundle Resources` for `bootconfig.plist`, `LaunchScreen.storyboard`.
> - `Compile Sources` for `.swift` files.
> - **Build Settings → Code Signing Entitlements** pointing at `<AppName>/<AppName>.entitlements`.

Wait again for confirmation before running the Step 9 build.

## Step 2 — `LaunchScreen.storyboard`

A launch storyboard is required so iOS establishes the window's safe-area bounds before the SDK presents login. If `LaunchScreen.storyboard` is not already in the target source folder, create it with this body:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="15400" targetRuntime="iOS.CocoaTouch" propertyAccessControl="none" useAutolayout="YES" launchScreen="YES" useTraitCollections="YES" useSafeAreas="YES" colorMatched="YES" initialViewController="01J-lp-oVM">
    <dependencies>
        <plugIn identifier="com.apple.InterfaceBuilder.IBCocoaTouchPlugin" version="15404"/>
        <capability name="Safe area layout guides" minToolsVersion="9.0"/>
        <capability name="documents saved in the Xcode 9 format" minToolsVersion="9.0"/>
    </dependencies>
    <scenes>
        <scene sceneID="EHf-IW-A2E">
            <objects>
                <viewController id="01J-lp-oVM" sceneMemberID="viewController">
                    <view key="view" contentMode="scaleToFill" id="Ze5-6b-2t3">
                        <rect key="frame" x="0.0" y="0.0" width="375" height="667"/>
                        <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
                        <color key="backgroundColor" systemColor="systemBackgroundColor"/>
                        <viewLayoutGuide key="safeArea" id="Bcu-3y-fUS"/>
                    </view>
                </viewController>
                <placeholder placeholderIdentifier="IBFirstResponder" id="iYj-Kq-Ea1" userLabel="First Responder" sceneMemberID="firstResponder"/>
            </objects>
        </scene>
    </scenes>
</document>
```

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

The file must be in the target's **Copy Bundle Resources** build phase.

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

- **Hand-maintained `.xcodeproj`** (no `project.yml`): merge the keys directly into `<AppName>/Info.plist`.

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

For **Option B-i (xcodegen + SPM)** and the **Option A+B-i hybrid** (`project.yml` is present): after creating the file, run `xcodegen generate` so the project picks it up. For the hybrid case, follow with `pod install`.

For **Option A (CocoaPods, no `project.yml`)** and **Option B-ii (plain SPM)**: do not run `xcodegen generate`. Drag `<AppName>.entitlements` into the `<AppName>` target in Xcode (or, for Option A, write it at the path the existing target already references), and confirm Build Settings → **Code Signing Entitlements** points at `<AppName>/<AppName>.entitlements`.

## Step 9 — Build

Expected: `** BUILD SUCCEEDED **`. On first launch, the Salesforce login screen appears; on successful login, the placeholder "Mobile SDK ready" view installs.

<!-- CANONICAL: build invocation — keep byte-identical across add-mobile-sdk / add-smartstore / add-mobilesync -->
**Option A (CocoaPods) and Hybrid:**

```bash
xcodebuild \
  -workspace <AppName>.xcworkspace \
  -scheme <AppName> \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

**Option B-i (xcodegen + SPM) and Option B-ii (Plain SPM):**

```bash
xcodebuild \
  -project <AppName>.xcodeproj \
  -scheme <AppName> \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

Do **not** pass `CODE_SIGNING_ALLOWED=NO` — it strips the keychain entitlement and login fails silently. Ad-hoc signing (`CODE_SIGN_IDENTITY=-`) is correct for the simulator.

## Next

- Encrypted local DB: [`add-smartstore.md`](add-smartstore.md)
- Cloud sync: [`add-mobilesync.md`](add-mobilesync.md)
- Biometric session locking: [`add-biometric-auth.md`](add-biometric-auth.md)
- Symptoms after build: [`troubleshooting.md`](troubleshooting.md)
