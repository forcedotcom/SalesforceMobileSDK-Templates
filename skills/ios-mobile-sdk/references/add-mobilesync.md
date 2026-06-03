# iOS — Add MobileSync

Adds the `MobileSync` library — sObject ⇄ soup sync down/up — on top of an iOS Swift app that already has SmartStore.

## Preconditions

- `AppDelegate.swift` calls `SmartStoreSDKManager.initializeSDK()`.
- `userstore.json` exists in the target source folder and is in **Copy Bundle Resources**.

If not, run [`add-smartstore.md`](add-smartstore.md) first.

## Inputs

| Variable | Example | Notes |
|---|---|---|
| `<SoupName>` | `Account` | Must match a soup in `userstore.json` |
| `<SObjectType>` | `Account` | Salesforce sObject API name |
| `<SyncName>` | `syncDownAccounts` | The `syncName` in `usersyncs.json` |

## Step 1 — Dependency

### Option A — CocoaPods

Replace `SmartStore` with `MobileSync` (which depends on `SmartStore` transitively):

```ruby
# was: pod 'SmartStore'
pod 'MobileSync'
```

```bash
pod install
```

### Option B — Swift Package Manager

Add the `MobileSync` product from the existing `SalesforceMobileSDK-iOS-SPM` package to the app target's **Frameworks, Libraries, and Embedded Content**.

## Step 2 — `AppDelegate.swift`

Swap the SDK manager:

```swift
import MobileSync   // was: import SmartStore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    override init() {
        super.init()
        MobileSyncSDKManager.initializeSDK()   // was: SmartStoreSDKManager.initializeSDK()
    }
    // … unchanged …
}
```

`MobileSyncSDKManager` is a subclass of `SmartStoreSDKManager`.

## Step 3 — `SceneDelegate.swift`

`setupUserSyncsFromDefaultConfig()` **registers** the syncs declared in `usersyncs.json` with the user's `SyncManager`. It does **not** run them. Trigger a registered sync by name with `reSync(named:onUpdate:)`, or run a one-off sync by constructing a target inline.

```swift
import MobileSync
import SalesforceSDKCore   // UserAccountManager lives here

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    // … scene(_:willConnectTo:options:) and sceneWillEnterForeground(_:) unchanged …

    func setupRootViewController() {
        MobileSyncSDKManager.shared.setupUserStoreFromDefaultConfig()
        MobileSyncSDKManager.shared.setupUserSyncsFromDefaultConfig()

        if let user = UserAccountManager.shared.currentUserAccount {
            let syncManager = SyncManager.sharedInstance(forUserAccount: user)

            // Run a sync registered in usersyncs.json.
            try? syncManager.reSync(named: "<SyncName>") { sync in
                // SyncState exposes the human-readable name as `name`, not `syncName` (the JSON-config key).
                print("Sync \(sync.name ?? "") status: \(sync.status)")
            }

            // Or run a one-off sync that isn't declared in usersyncs.json.
            let target = SoqlSyncDownTarget.newSyncTarget("SELECT Id, Name FROM <SObjectType>")
            let options = SyncOptions.newSyncOptions(forSyncDown: .overwrite)
            syncManager.syncDown(target: target,
                                 options: options,
                                 soupName: "<SoupName>") { sync in
                print("Initial sync status: \(sync.status)")
            }
        }

        // Smoke test view.
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
}
```

The Swift type names above are the published `NS_SWIFT_NAME` aliases for Objective-C SDK types (`SyncManager` ↔ `SFMobileSyncSyncManager`, `SoqlSyncDownTarget` ↔ `SFSoqlSyncDownTarget`, etc.). See [`api-reference.md`](api-reference.md).

## Step 4 — `<AppName>/usersyncs.json`

Place this in the app target's source folder. The default filename the SDK looks for is `usersyncs.json` (plural); a single-sync configuration looks like:

```json
{
  "syncs": [
    {
      "syncName": "<SyncName>",
      "syncType": "syncDown",
      "soupName": "<SoupName>",
      "target": {
        "type": "soql",
        "query": "SELECT Id, Name FROM <SObjectType> LIMIT 100"
      },
      "options": {
        "fieldlist": ["Id", "Name", "LastModifiedDate"],
        "mergeMode": "LEAVE_IF_CHANGED"
      }
    }
  ]
}
```

Constraints:

- `syncType` is `"syncDown"` or `"syncUp"`.
- `soupName` must match a `soupName` from `userstore.json`.
- `target.type` for sync-down is one of `"soql"`, `"sosl"`, `"mru"`, `"refresh"`, `"parent_children"`, `"layout"`, `"metadata"`, `"briefcase"`, `"custom"`. SOQL is the default for record-set syncs.
- `options.mergeMode` is `"OVERWRITE"` or `"LEAVE_IF_CHANGED"`.

After adding the file, ensure it lands in **Copy Bundle Resources** for the app target. For xcodegen-managed projects, run `xcodegen generate` (and `pod install` for CocoaPods, since regenerating the `.xcodeproj` invalidates the Pods workspace integration). For hand-maintained `.xcodeproj` (the pattern used by `iOSNativeSwiftTemplate`), drag the file into the project navigator and verify the target's Build Phases → Copy Bundle Resources lists it.

## Step 5 — Build

```bash
xcodebuild \
  -workspace <AppName>.xcworkspace \
  -scheme <AppName> \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

After login, the placeholder view reads "SmartStore + MobileSync ready" and the configured sync runs.

## Next

- Biometric session locking: [`add-biometric-auth.md`](add-biometric-auth.md)
- API name resolution: [`api-reference.md`](api-reference.md)
- Symptoms: [`troubleshooting.md`](troubleshooting.md)
