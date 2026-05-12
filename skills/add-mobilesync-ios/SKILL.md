---
name: add-mobilesync-ios
description: Add Salesforce MobileSync (cloud data sync) to an existing iOS Swift app that already has SmartStore integrated.
---

# Add MobileSync to an iOS Swift App

This skill adds Salesforce MobileSync to an existing iOS Swift app that already has `SmartStore` integrated via the `add-smartstore-ios` skill.

## What This Skill Does

1. Adds the `MobileSync` dependency (CocoaPods **or** SPM, matching what the app already uses)
2. Upgrades the SDK manager initializer from `SmartStoreSDKManager` to `MobileSyncSDKManager`
3. Calls `MobileSyncSDKManager.shared.setupUserSyncsFromDefaultConfig()` after login (alongside the existing store setup)
4. Creates `usersyncs.json` with placeholder sync definitions and adds it to the Xcode target

## Prerequisites

The app must already have SmartStore integrated. **Check `AppDelegate.swift` for `SmartStoreSDKManager.initializeSDK()` (or `MobileSyncSDKManager`) and `SceneDelegate.swift` for `setupUserStoreFromDefaultConfig()`.** If not present:

1. If the app has no Mobile SDK at all, run `add-mobile-sdk-ios` first.
2. Then run `add-smartstore-ios`.
3. Then return here.

Before starting, confirm:
- **App target name** (e.g. `MyApp`)
- **Soup name** used in `userstore.json` (the sync will target this soup)
- Which dependency manager is in use (detected from `Podfile` vs `.xcodeproj` SPM references)

---

## Step 1: Add the MobileSync Dependency

### Option A — CocoaPods (project has a `Podfile`)

Replace the `SmartStore` pod with `MobileSync`. MobileSync depends on SmartStore transitively, so only one pod declaration is needed.

**Before:**
```ruby
target 'YourApp' do
  use_frameworks!
  pod 'SmartStore'
end
```

**After:**
```ruby
target 'YourApp' do
  use_frameworks!
  pod 'MobileSync'
end
```

Then run:

```bash
pod install
```

### Option B — Swift Package Manager

In Xcode, add the `MobileSync` product from the existing `SalesforceMobileSDK-iOS-SPM` package to the app target's **Frameworks, Libraries, and Embedded Content**.

---

## Step 2: Upgrade the SDK Manager in AppDelegate.swift

MobileSync requires a richer SDK manager than `SmartStoreSDKManager`. Replace the import and initializer.

**Before:**
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

**After:**
```swift
import MobileSync

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    override init() {
        super.init()
        MobileSyncSDKManager.initializeSDK()
    }
    // ...
}
```

> `MobileSyncSDKManager` is a subclass of `SmartStoreSDKManager`. Replacing the initializer is sufficient — no other AppDelegate changes are needed.

---

## Step 3: Add Sync Setup in SceneDelegate.swift

Replace the `SmartStore` import with `MobileSync` and add `setupUserSyncsFromDefaultConfig()` alongside the existing store setup call.

**Before:**
```swift
import SmartStore

// ...

func setupRootViewController() {
    SmartStoreSDKManager.shared.setupUserStoreFromDefaultConfig()
    window?.rootViewController = UIViewController()
}
```

**After:**
```swift
import MobileSync
import SalesforceSDKCore   // keep this — AuthHelper lives here

// ...

func setupRootViewController() {
    MobileSyncSDKManager.shared.setupUserStoreFromDefaultConfig()
    MobileSyncSDKManager.shared.setupUserSyncsFromDefaultConfig()
    let vc = UIViewController()
    vc.view.backgroundColor = .systemBackground
    let label = UILabel()
    label.text = "SmartStore + MobileSync ready"
    label.translatesAutoresizingMaskIntoConstraints = false
    vc.view.addSubview(label)
    NSLayoutConstraint.activate([
        label.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
        label.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor)
    ])
    window?.rootViewController = vc
}
```

After login, you should see **"SmartStore + MobileSync ready"** centered on the screen. This is a smoke test placeholder — replace with your real app UI once verified.

---

## Step 4: Create usersyncs.json

Create `usersyncs.json` inside the app target's source folder (next to `userstore.json`):

```json
{
  "syncs": [
    {
      "syncName": "syncDown<SoupName>",
      "syncType": "syncDown",
      "soupName": "<SoupName>",
      "target": {
        "type": "soql",
        "query": "SELECT Id, Name FROM <SalesforceObject> LIMIT 100"
      },
      "options": {
        "mergeMode": "LEAVE_IF_CHANGED"
      }
    }
  ]
}
```

Replace:
- `<SoupName>` with the soup name used in `userstore.json` — this is the **local** SmartStore table name
- `<SalesforceObject>` in the SOQL `FROM` clause with the **Salesforce sObject API name** to sync from (e.g. `Account`, `Contact`, `Opportunity`) — this query runs on the server, not against the local store

> The soup name and the sObject name are often the same (e.g. soup `Account`, query `FROM Account`) but they don't have to be. The soup is a local storage concept; the SOQL target is a server-side Salesforce object.

Then add `usersyncs.json` to the Xcode target:
- In Xcode, right-click the app target group → **Add Files to "YourApp"**
- Select `usersyncs.json`
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

- [ ] `MobileSync` pod added (CocoaPods) or SPM product added (SPM)
- [ ] `pod install` run (CocoaPods path)
- [ ] `AppDelegate.swift` imports `MobileSync` and calls `MobileSyncSDKManager.initializeSDK()`
- [ ] `SceneDelegate.swift` imports `MobileSync` and calls both `setupUserStoreFromDefaultConfig()` and `setupUserSyncsFromDefaultConfig()` in `setupRootViewController()`
- [ ] `usersyncs.json` created with at least one sync definition targeting the correct soup
- [ ] `usersyncs.json` is in the **Copy Bundle Resources** build phase
- [ ] Project builds without errors
- [ ] "SmartStore + MobileSync ready" label is shown after login

---

## Troubleshooting

**Build error: `Cannot find type 'MobileSyncSDKManager'`**
`MobileSync` is not linked. For CocoaPods, verify `pod install` completed and you opened `.xcworkspace`. For SPM, verify `MobileSync` is in the target's Frameworks.

**`setupUserSyncsFromDefaultConfig()` silently does nothing**
`usersyncs.json` is missing from Copy Bundle Resources. Open Build Phases and add it.

**Sync fails at runtime with "Soup not found"**
The `soupName` in `usersyncs.json` must exactly match the `soupName` in `userstore.json`.
