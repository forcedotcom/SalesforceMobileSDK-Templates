# iOS — Create a New Swift App

Generates a bare iOS Swift app via `xcodegen`, then chains into [`add-mobile-sdk.md`](add-mobile-sdk.md) to wire up Salesforce authentication.

## Inputs

| Variable | Example | Notes |
|---|---|---|
| `<AppName>` | `MyApp` | Xcode target, directory, bundle name |
| `<BundleIDPrefix>` | `com.mycompany` | Used by `bundleIdPrefix` |
| `<BundleID>` | `com.mycompany.myapp` | Final `PRODUCT_BUNDLE_IDENTIFIER` |
| `<OutputDir>` | `~/Projects` | Parent directory |

## Tooling

`xcodegen` must be installed:

```bash
brew install xcodegen
```

## Step 1 — Project tree

```bash
mkdir -p <OutputDir>/<AppName>/<AppName>
cd <OutputDir>/<AppName>
```

## Step 2 — `<AppName>/AppDelegate.swift`

```swift
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

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

## Step 3 — `<AppName>/SceneDelegate.swift`

```swift
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window?.windowScene = windowScene
        window?.rootViewController = UIViewController()
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}
```

## Step 4 — `<AppName>/LaunchScreen.storyboard`

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

## Step 5 — `project.yml` (project root)

```yaml
name: <AppName>
options:
  bundleIdPrefix: <BundleIDPrefix>
  deploymentTarget:
    iOS: "18.0"
settings:
  PRODUCT_BUNDLE_IDENTIFIER: <BundleID>
schemes:
  <AppName>:
    build:
      targets:
        <AppName>: all
targets:
  <AppName>:
    type: application
    platform: iOS
    supportedDestinations: [iOS, iPadOS, iOSSimulator]
    settings:
      CODE_SIGN_ENTITLEMENTS: <AppName>/<AppName>.entitlements
      CODE_SIGN_STYLE: Automatic
      CODE_SIGN_IDENTITY: "-"
    sources:
      - <AppName>
    info:
      path: <AppName>/Info.plist
      properties:
        UILaunchStoryboardName: LaunchScreen
        UIApplicationSceneManifest:
          UIApplicationSupportsMultipleScenes: false
          UISceneConfigurations:
            UIWindowSceneSessionRoleApplication:
              - UISceneConfigurationName: Default Configuration
                UISceneDelegateClassName: $(PRODUCT_MODULE_NAME).SceneDelegate
```

Required settings (each is load-bearing — do not omit):

- `supportedDestinations: [iOS, iPadOS, iOSSimulator]` — Xcode 16+ excludes the simulator unless this is set explicitly. Without it `xcodebuild -showdestinations` returns empty and headless builds fail with `Found no destinations for the scheme`.
- Top-level `schemes:` block — without it, xcodegen generates a user-only scheme that `xcodebuild` cannot see.
- `CODE_SIGN_IDENTITY: "-"` plus `CODE_SIGN_ENTITLEMENTS` pointing at `<AppName>/<AppName>.entitlements` — entitlements only attach when the build is code-signed, and ad-hoc signing is sufficient on the simulator.

The `<AppName>.entitlements` file referenced above is created in [`add-mobile-sdk.md`](add-mobile-sdk.md) Step 8.

## Step 6 — Generate the Xcode project

```bash
xcodegen generate
```

This writes `<AppName>.xcodeproj`. Do not run `xcodebuild` between this step and [`add-mobile-sdk.md`](add-mobile-sdk.md) Step 8 — the `project.yml` references `<AppName>/<AppName>.entitlements` which is created in that step. Building before then fails with `error: Build input file cannot be found: '<AppName>/<AppName>.entitlements'`.

## Step 7 — Add Mobile SDK

Continue at [`add-mobile-sdk.md`](add-mobile-sdk.md). The seed from this scenario is **Option B-i** (`project.yml` + no `Podfile`). After completing `add-mobile-sdk.md`, re-run `xcodegen generate` so the project picks up newly created files. **Only** if you switched to CocoaPods inside `add-mobile-sdk.md` (the **Option A+B-i hybrid** case — added a `Podfile` to the existing `project.yml`), follow `xcodegen generate` with `pod install`.

> **Important — re-run `xcodegen generate` after adding new files**: xcodegen only picks up files that exist on disk at generation time. Whenever you add a new `.swift`, `.plist`, `.entitlements`, `.storyboard`, or `.json` file to the source folder, re-run `xcodegen generate` so the Xcode project includes it. For CocoaPods projects, follow with `pod install` because regenerating the `.xcodeproj` invalidates the Pods workspace integration. The workflow is: `xcodegen generate` → add new files → `xcodegen generate` → `pod install`.
