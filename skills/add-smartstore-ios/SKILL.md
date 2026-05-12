---
name: add-smartstore-ios
description: Add Salesforce SmartStore (encrypted local database) to an existing iOS Swift app that already has the Mobile SDK integrated.
---

# Add SmartStore to an iOS Swift App

This skill adds the Salesforce SmartStore encrypted local database to an existing iOS Swift app that already has `SalesforceSDKCore` integrated via the `add-mobile-sdk-ios` skill.

## What This Skill Does

1. Adds the `SmartStore` dependency (CocoaPods **or** SPM, matching what the app already uses)
2. Upgrades the SDK manager initializer from `SalesforceManager` to `SmartStoreSDKManager`
3. Calls `SmartStoreSDKManager.shared.setupUserStoreFromDefaultConfig()` after login
4. Creates `userstore.json` with a placeholder soup and adds it to the Xcode target

## Prerequisites

The app must already have the Mobile SDK wired up. **Check `AppDelegate.swift` for `SalesforceManager.initializeSDK()` (or `SmartStoreSDKManager` / `MobileSyncSDKManager`) and that `bootconfig.plist` exists in the app target.** If not, run the `add-mobile-sdk-ios` skill first, then return here.

Before starting, confirm:
- **App target name** (e.g. `MyApp`)
- **Soup name** for the initial store table (default: `Item`)
- Which dependency manager is in use (detected from `Podfile` vs `.xcodeproj` SPM references)

---

## Step 1: Add the SmartStore Dependency

### Option A — CocoaPods (project has a `Podfile`)

Replace the `SalesforceSDKCore` pod with `SmartStore`. SmartStore depends on SalesforceSDKCore transitively, so only one pod declaration is needed.

**Before:**
```ruby
target 'YourApp' do
  use_frameworks!
  pod 'SalesforceSDKCore'
end
```

**After:**
```ruby
target 'YourApp' do
  use_frameworks!
  pod 'SmartStore'
end
```

Then run:

```bash
pod install
```

### Option B — Swift Package Manager

In Xcode:
1. **File → Add Package Dependencies…** (or open the existing `SalesforceMobileSDK-iOS-SPM` package dependency)
2. Add the `SmartStore` product to the app target's **Frameworks, Libraries, and Embedded Content**

If `SalesforceMobileSDK-iOS-SPM` is not yet added, add it first:
- URL: `https://github.com/forcedotcom/SalesforceMobileSDK-iOS-SPM`
- Branch: `master`
- Add these products: `SalesforceSDKCore`, `SalesforceAnalytics`, `SalesforceSDKCommon`, `SmartStore`

---

## Step 2: Upgrade the SDK Manager in AppDelegate.swift

SmartStore requires a richer SDK manager than the base `SalesforceManager`. Replace the import and initializer.

**Before:**
```swift
import SalesforceSDKCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    override init() {
        super.init()
        SalesforceManager.initializeSDK()
    }
    // ...
}
```

**After:**
```swift
import SmartStore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    override init() {
        super.init()
        SmartStoreSDKManager.initializeSDK()
    }
    // ...
}
```

> `SmartStoreSDKManager` is a subclass of `SalesforceManager`. Replacing the initializer is sufficient — no other AppDelegate changes are needed.

---

## Step 3: Set Up the Store After Login in SceneDelegate.swift

Add a `SmartStore` import and call `setupUserStoreFromDefaultConfig()` inside `setupRootViewController()`. Also add a smoke test label so you can confirm SmartStore is initializing correctly.

**Before:**
```swift
import SalesforceSDKCore

// ...

func setupRootViewController() {
    window?.rootViewController = UIViewController()
}
```

**After:**
```swift
import SmartStore
import SalesforceSDKCore   // keep this — AuthHelper lives here

// ...

func setupRootViewController() {
    SmartStoreSDKManager.shared.setupUserStoreFromDefaultConfig()
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
```

After login, you should see **"SmartStore ready"** centered on the screen. This is a smoke test placeholder — replace with your real app UI once verified.

---

## Step 4: Create userstore.json

Create `userstore.json` inside the app target's source folder (next to `AppDelegate.swift`):

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

Replace `<SoupName>` with the soup name agreed with the user (default: `Item`).

Then add `userstore.json` to the Xcode target:
- In Xcode, right-click the app target group → **Add Files to "YourApp"**
- Select `userstore.json`
- Ensure it appears in the **Copy Bundle Resources** build phase

---

## Step 5: Build and Verify

```bash
# CocoaPods
xcodebuild -workspace <AppName>.xcworkspace \
  -scheme <AppName> \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build

# SPM (no workspace)
xcodebuild -project <AppName>.xcodeproj \
  -scheme <AppName> \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

Expected: `** BUILD SUCCEEDED **`

---

## Checklist

- [ ] `SmartStore` pod added (CocoaPods) or SPM product added (SPM)
- [ ] `pod install` run (CocoaPods path)
- [ ] `AppDelegate.swift` imports `SmartStore` and calls `SmartStoreSDKManager.initializeSDK()`
- [ ] `SceneDelegate.swift` imports `SmartStore` and calls `setupUserStoreFromDefaultConfig()` in `setupRootViewController()`
- [ ] `userstore.json` created with at least one soup
- [ ] `userstore.json` is in the **Copy Bundle Resources** build phase
- [ ] Project builds without errors
- [ ] "SmartStore ready" label is shown after login

---

## Troubleshooting

**Build error: `Cannot find type 'SmartStoreSDKManager'`**
`SmartStore` is not linked. For CocoaPods, verify `pod install` completed and you opened `.xcworkspace`. For SPM, verify `SmartStore` is in the target's Frameworks.

**`setupUserStoreFromDefaultConfig()` silently does nothing**
`userstore.json` is missing from Copy Bundle Resources. Open Build Phases and add it.

**`pod install` fails with "Unable to find a specification for `SmartStore`"**
Ensure both sources are declared in the Podfile — `cdn.cocoapods.org` and `github.com/forcedotcom/SalesforceMobileSDK-iOS-Specs`.
