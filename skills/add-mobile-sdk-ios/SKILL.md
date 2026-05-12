---
name: add-mobile-sdk-ios
description: Add Salesforce Mobile SDK to an existing iOS Swift application. Handles dependency (CocoaPods or SPM), SDK initialization, OAuth login flow via AuthHelper, bootconfig.plist, and Info.plist configuration.
---

# Add Salesforce Mobile SDK to an iOS Swift App

This skill integrates the Salesforce Mobile SDK into an existing iOS Swift application, wiring up authentication so users are prompted to log in to Salesforce when the app launches.

## What This Skill Does

1. Adds the `SalesforceSDKCore` dependency (CocoaPods **or** Swift Package Manager, matching what the app already uses)
2. Adds a `LaunchScreen.storyboard` so iOS sizes the window correctly before the SDK presents the login screen
3. Initializes the SDK in `AppDelegate`
4. Creates `InitialViewController.swift` — the splash screen shown while the login flow runs
5. Wires `AuthHelper.loginIfRequired` and user-change notifications into `SceneDelegate`
6. Adds `bootconfig.plist` with OAuth configuration placeholders
7. Adds the required `SFDCOAuthLoginHost` and `UILaunchStoryboardName` keys to `Info.plist`

## Prerequisites

Before starting, ask the user for:
- **App target name** (the Xcode target to modify, e.g. `MyApp`)
- **Consumer Key** (OAuth connected app consumer key, or leave as placeholder)
- **Callback URL** (OAuth redirect URI, or leave as placeholder)
- **Login host** (default: `login.salesforce.com`, use `test.salesforce.com` for sandboxes)

Also detect which dependency manager the project uses:
- Project has a `Podfile` → use the CocoaPods path
- Project has `.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/` → use the SPM path

---

## Step 1: Add the SDK Dependency

### Option A — CocoaPods (project has a `Podfile`)

Add the Salesforce specs source and `SalesforceSDKCore` pod. `SalesforceSDKCore` pulls in `SalesforceAnalytics` and `SalesforceSDKCommon` transitively, so you only need to declare one pod.

```ruby
source 'https://cdn.cocoapods.org/'
source 'https://github.com/forcedotcom/SalesforceMobileSDK-iOS-Specs'

platform :ios, '18.0'

target 'YourApp' do
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

Then install:

```bash
pod install
```

Open `YourApp.xcworkspace` (not `.xcodeproj`) from now on.

> **Adding SmartStore or MobileSync later?** Add `pod 'SmartStore'` or `pod 'MobileSync'` to the same target block. MobileSync depends on SmartStore which depends on SalesforceSDKCore, so adding MobileSync alone is sufficient to pull in everything.

### Option B — Swift Package Manager (project uses SPM)

In Xcode:
1. **File → Add Package Dependencies…**
2. Enter: `https://github.com/forcedotcom/SalesforceMobileSDK-iOS-SPM`
3. Select branch `master` (or the version tag matching your desired SDK release)
4. Add these products to your app target:
   - `SalesforceSDKCore`
   - `SalesforceAnalytics`
   - `SalesforceSDKCommon`

> **Adding SmartStore or MobileSync later?** From the same package, add `SmartStore` or `MobileSync` to the target's frameworks.

---

## Step 2: Add LaunchScreen.storyboard

Without a launch storyboard, iOS does not properly establish the window's safe-area bounds before the SDK presents its login screen, which causes the login view controller to appear with black bars above and below it.

Create a minimal `LaunchScreen.storyboard` in the app target's source folder:

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

Add `LaunchScreen.storyboard` to the Xcode target's **Copy Bundle Resources** build phase.

---

## Step 3: Create InitialViewController.swift

Create `InitialViewController.swift` inside the app target's source folder. This is the splash screen that fills the window while the SDK presents the login flow. Using a named subclass instead of a bare `UIViewController` ensures UIKit presents the login screen full-screen rather than as a page sheet, which would leave black bars above and below it.

```swift
import UIKit

class InitialViewController: UIViewController {}
```

Add the file to the Xcode target (it must be compiled into the app module so `SceneDelegate` can reference it by name).

---

## Step 4: Update AppDelegate.swift

The key changes from a plain iOS app:
- `import SalesforceSDKCore`
- Call `SalesforceManager.initializeSDK()` in `init()` — must run before any SDK class is used

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

---

## Step 5: Update SceneDelegate.swift

The key Mobile SDK additions:
- `import SalesforceSDKCore`
- `AuthHelper.registerBlock(forCurrentUserChangeNotifications:)` in `scene(_:willConnectTo:)` — re-runs your root view controller setup whenever the logged-in user changes (switch user, logout/login)
- `AuthHelper.loginIfRequired` in `sceneWillEnterForeground` — presents the Salesforce login screen if no valid session exists

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
        // Replace with your post-login root view controller
        window?.rootViewController = UIViewController()
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

> **`setupRootViewController()`** is called after a successful login and after every user switch. Replace both `UIViewController()` placeholders with your actual screens.

---

## Step 6: Add bootconfig.plist

Create `bootconfig.plist` inside your app target's source folder (next to `Info.plist`), then add it to the Xcode target via **Add Files to "YourApp"**.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>remoteAccessConsumerKey</key>
    <string>YOUR_CONSUMER_KEY</string>
    <key>oauthRedirectURI</key>
    <string>YOUR_CALLBACK_URL</string>
    <key>shouldAuthenticate</key>
    <true/>
</dict>
</plist>
```

Replace `YOUR_CONSUMER_KEY` and `YOUR_CALLBACK_URL` with the values from your Salesforce Connected App. If the user provided them in the prerequisites, substitute them now.

Verify `bootconfig.plist` appears in the **Copy Bundle Resources** build phase for the target.

---

## Step 7: Update Info.plist

Add the following keys to the app target's `Info.plist`:

```xml
<key>SFDCOAuthLoginHost</key>
<string>login.salesforce.com</string>
<key>UILaunchStoryboardName</key>
<string>LaunchScreen</string>
```

Use the login host provided by the user, or `login.salesforce.com` as the default.

Also ensure the Scene configuration is present (required for `SceneDelegate` to be invoked). If the app was created with Xcode's default template it will already have this — verify `UISceneDelegateClassName` matches your module name:

```xml
<key>UIApplicationSceneManifest</key>
<dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <false/>
    <key>UISceneConfigurations</key>
    <dict>
        <key>UIWindowSceneSessionRoleApplication</key>
        <array>
            <dict>
                <key>UISceneConfigurationName</key>
                <string>Default Configuration</string>
                <key>UISceneDelegateClassName</key>
                <string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
            </dict>
        </array>
    </dict>
</dict>
```

---

## Step 8: Add a Smoke Test UI

Replace the placeholder `setupRootViewController()` with a minimal labeled view so you can confirm the SDK is working after login. This is a temporary smoke test — replace the label and view controller with your real app UI once verified.

```swift
func setupRootViewController() {
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
```

After login, you should see **"Mobile SDK ready"** centered on a white screen.

---

## Step 9: Build and Verify

Build and run. On first launch, the Salesforce login screen should appear. After a successful login, `setupRootViewController()` is called and the label is shown.

### Checklist

- [ ] SDK dependency added and project builds without errors
- [ ] `LaunchScreen.storyboard` added and in Copy Bundle Resources
- [ ] `UILaunchStoryboardName` set to `LaunchScreen` in `Info.plist`
- [ ] `InitialViewController.swift` created and added to the Xcode target
- [ ] `SalesforceManager.initializeSDK()` called in `AppDelegate.init()`
- [ ] `initializeAppViewState()` uses `InitialViewController(nibName: nil, bundle: nil)`
- [ ] `AuthHelper.registerBlock(forCurrentUserChangeNotifications:)` called in `scene(_:willConnectTo:)`
- [ ] `AuthHelper.loginIfRequired` called in `sceneWillEnterForeground`
- [ ] `bootconfig.plist` is in the target and in Copy Bundle Resources
- [ ] `remoteAccessConsumerKey` and `oauthRedirectURI` are set in `bootconfig.plist`
- [ ] `SFDCOAuthLoginHost` is present in `Info.plist`
- [ ] App prompts for Salesforce login on first launch
- [ ] "Mobile SDK ready" label is shown after login

---

## Troubleshooting

**Build error: `Cannot find type 'SalesforceManager'`**
The import is missing or the framework is not linked. For CocoaPods, verify `pod install` completed and you opened `.xcworkspace`. For SPM, verify `SalesforceSDKCore` is in the target's Frameworks.

**Login screen does not appear**
Check that `SFDCOAuthLoginHost` is in `Info.plist` and `bootconfig.plist` is included in Copy Bundle Resources.

**Login screen has black bars above and below it**
`LaunchScreen.storyboard` is missing or not set in `Info.plist` as `UILaunchStoryboardName`. Without it, iOS does not properly establish window bounds before the SDK presents its auth window.

**Login succeeds but app shows blank screen**
`setupRootViewController()` still has the placeholder `UIViewController()`. Replace it with your app's actual root view controller.

**`pod install` fails with "Unable to find a specification for `SalesforceSDKCore`"**
Ensure both sources are declared in the Podfile — `cdn.cocoapods.org` and `github.com/forcedotcom/SalesforceMobileSDK-iOS-Specs`.
