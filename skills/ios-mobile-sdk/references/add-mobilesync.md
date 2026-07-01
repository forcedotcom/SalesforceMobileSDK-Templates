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
| `<SyncUpName>` | `syncUpAccounts` | The sync-up entry's `syncName` |

## Step 0 — Detect Project Shape (required first action)
<!-- CANONICAL: project-shape detection — keep byte-identical across add-mobile-sdk / add-smartstore / add-mobilesync -->
**Do not skip this step. Do not assume a shape from the prompt or from training-data priors.** Before any file edits, list the contents of the project root and identify which of the four cases applies based on the actual files present. Agents that skip this step and pick a shape from training data routinely write to the wrong files and break the build.

Run a directory listing of the project root (the folder you'll be modifying — the same folder the prompt or task directive points at). Then pick **exactly one** option in priority order based on the files present:

1. `Podfile` AND `project.yml` both exist → **Hybrid (Option A for the SDK + xcodegen for sources)**. `project.yml` owns project structure (sources, schemes, entitlements); CocoaPods supplies third-party modules. For the MobileSync dependency, follow Option A only — **DO NOT** also add the `MobileSync` SPM product to `project.yml` (linking the SDK via both Pods and SPM produces duplicate-symbol errors). After authoring the new resources in Steps 2–4, run `xcodegen generate`, then `pod install`.
2. `Podfile`, no `project.yml` → **Option A — CocoaPods**. Edit only the `Podfile`; don't run xcodegen or text-edit the `.xcodeproj`.
3. `project.yml`, no `Podfile` → **Option B-i — xcodegen + SPM (autonomous)**. The `.xcodeproj` is regenerable output.
4. `.xcodeproj`, no `project.yml`, no `Podfile` → **Option B-ii — Plain SPM (human-instruction)**.

If none match, the project has SmartStore unconfigured — run [`add-smartstore.md`](add-smartstore.md) first.

**Commit to your choice and state it.** State which option you picked and which file(s) in the listing triggered the choice (e.g. *"Option A — found `Podfile`, no `project.yml`"*). Then read **only that option's section** in Step 1 — reading sections for options you didn't pick will mix workflows and break the build.

## Step 1 — Dependency

### Option A — CocoaPods

> **DO NOT** author a `project.yml` (if one isn't already present). **DO NOT** recreate or overwrite the existing `.xcodeproj/`. **DO NOT** text-edit `project.pbxproj`.
>
> **For pure CocoaPods (Step 0 case 2):** also **DO NOT** run `xcodegen` — the `.xcodeproj` is hand-maintained.
>
> **For Hybrid (Step 0 case 1):** xcodegen owns source-file inclusion. After authoring the new files in Steps 2–4, run `xcodegen generate`, then `pod install`.
>
> Edit only the existing `Podfile`. `MobileSync` depends on `SmartStore` transitively, so **swap** (don't add) the pod entry.

```ruby
# was: pod 'SmartStore'
pod 'MobileSync'
```

```bash
pod install
```

After this, all `xcodebuild` / open invocations use `<AppName>.xcworkspace`.

### Option B-i — xcodegen + SPM (project has `project.yml`)

> `project.yml` is the source of truth. Running `xcodegen generate` is the correct move — that's how new files and dependencies land in the `.xcodeproj`. **DO NOT** use Xcode's "Add Package Dependencies…" UI; those edits live in `project.pbxproj` and get wiped on the next regen.

This is the autonomous path. The `SalesforceMobileSDK-iOS-SPM` package is already declared in `project.yml`'s `packages:` map. **Add** the `MobileSync` product to the app target's `dependencies:` list, alongside the existing `SalesforceSDKCore`, `SalesforceAnalytics`, `SalesforceSDKCommon`, and `SmartStore` entries. **Do not remove** the existing entries — `SceneDelegate.swift` still imports `SalesforceSDKCore` (for `AuthHelper`), and keeping `SmartStore` is harmless (same package, distinct module).

```yaml
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
      - package: SalesforceMobileSDK-iOS-SPM
        product: SmartStore
      - package: SalesforceMobileSDK-iOS-SPM
        product: MobileSync         # new
```

Then regenerate and resolve:

```bash
xcodegen generate
xcodebuild -resolvePackageDependencies -project <AppName>.xcodeproj -scheme <AppName>
```

After authoring `usersyncs.json` in Step 4, re-run `xcodegen generate` once more so the new file lands in the regenerated project.

### Option B-ii — Plain SPM (project has only `.xcodeproj`)

> **DO NOT** author a `project.yml`. **DO NOT** run `xcodegen`. **DO NOT** create a `Podfile`. **DO NOT** text-edit `project.pbxproj`.

This is the human-instruction path. Emit the following block verbatim (substituting `<AppName>`), then halt until the user replies "done":

> **Manual step required — Xcode UI.** This project is a hand-managed `.xcodeproj` (no `project.yml`). Please do the following in Xcode, then reply "done":
>
> 1. Open `<AppName>.xcodeproj`.
> 2. Select the project, then the `<AppName>` target.
> 3. **General** tab → **Frameworks, Libraries, and Embedded Content** → **+**.
> 4. Expand **SalesforceMobileSDK-iOS-SPM**, select `MobileSync`, click **Add**.
> 5. Leave the existing `SalesforceSDKCore`, `SalesforceAnalytics`, `SalesforceSDKCommon`, and `SmartStore` entries in place.
> 6. Reply "done" when finished.

Wait for confirmation before continuing to Step 2. After authoring `usersyncs.json` in Step 4, emit one more instruction asking the user to drag `<AppName>/usersyncs.json` into the target and verify it appears in **Build Phases → Copy Bundle Resources**, then reply "done".

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

`setupUserSyncsFromDefaultConfig()` **registers** the syncs declared in `usersyncs.json` with the user's `SyncManager`. It does **not** run them. Trigger a registered sync by name with `reSync(named:onUpdate:)`.

> **The `onUpdate` block fires asynchronously** as the sync transitions through `.running` → `.done` / `.failed`. `reSync(named:onUpdate:)` returns the initial `SyncState` immediately, so any UI you build before the block fires will show pre-sync state. Reload your data source from SmartStore **inside** the `onUpdate` block when status reaches `.done`, otherwise your view stays empty even after the sync succeeds.

```swift
import MobileSync
import SalesforceSDKCore

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    // … scene(_:willConnectTo:options:) and sceneWillEnterForeground(_:) unchanged …

    func setupRootViewController() {
        MobileSyncSDKManager.shared.setupUserStoreFromDefaultConfig()
        MobileSyncSDKManager.shared.setupUserSyncsFromDefaultConfig()

        // Build the post-login UI first; it will start empty.
        let listVC = MyAccountsViewController()
        window?.rootViewController = UINavigationController(rootViewController: listVC)

        // Run the sync registered in usersyncs.json by name. The onUpdate
        // block fires across .running → .done / .failed; reload the UI
        // from SmartStore once the sync is .done.
        if let user = UserAccountManager.shared.currentUserAccount {
            let syncManager = SyncManager.sharedInstance(forUserAccount: user)
            try? syncManager.reSync(named: "<SyncName>") { sync in
                if sync.status == .done {
                    DispatchQueue.main.async {
                        listVC.reloadFromStore()
                    }
                } else if sync.status == .failed {
                    NSLog("Sync \(sync.name ?? "<unnamed>") failed")
                }
            }
        }
    }
}
```

`MyAccountsViewController` stands in for whatever view you want to populate from SmartStore — its `reloadFromStore()` is your responsibility (typically a query against the soup followed by a `tableView.reloadData()` or equivalent). Replace `<SyncName>` with the `syncName` declared in `usersyncs.json`.

### Minimal stand-in view controller

`MyAccountsViewController` above is a stand-in for your real post-login list view. So the project compiles end-to-end, create `<AppName>/MyAccountsViewController.swift`:

```swift
import UIKit

/// Stand-in for the real post-login list view. Replace with your own view
/// controller. `reloadFromStore()` is where you re-query the Account soup and
/// refresh the UI once a sync reaches `.done`.
class MyAccountsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Accounts"

        let label = UILabel()
        label.text = "MobileSync ready"
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    /// Re-query the soup and refresh the UI. Stubbed for the smoke test.
    func reloadFromStore() {
        // Query the Account soup via SmartStore and reload your data source here.
    }
}
```

The Swift type names above are the published `NS_SWIFT_NAME` aliases for Objective-C SDK types (`SyncManager` ↔ `SFMobileSyncSyncManager`, `SoqlSyncDownTarget` ↔ `SFSoqlSyncDownTarget`, etc.). See [`api-reference.md`](api-reference.md).

## Step 4 — `<AppName>/usersyncs.json`

Place this in the app target's source folder. The default filename the SDK looks for is `usersyncs.json` (plural).

```json
{
  "syncs": [
    {
      "syncName": "<SyncName>",
      "syncType": "syncDown",
      "soupName": "<SoupName>",
      "target": {
        "type": "soql",
        "query": "SELECT Id, Name FROM <SObjectType>"
      },
      "options": {
        "mergeMode": "OVERWRITE"
      }
    },
    {
      "syncName": "<SyncUpName>",
      "syncType": "syncUp",
      "soupName": "<SoupName>",
      "target": {
        "createFieldlist": ["Name"],
        "updateFieldlist": ["Name"]
      },
      "options": {
        "fieldlist": ["Name"],
        "mergeMode": "OVERWRITE"
      }
    }
  ]
}
```

Replace `<SyncName>`, `<SyncUpName>`, `<SoupName>`, and `<SObjectType>` with actual values, and tailor the field lists to the columns you want to push.

The sync-up entry deliberately omits `target.type`; the SDK defaults to `"rest"` (`SFCollectionSyncUpTarget`), the standard sync-up target. Set `target.type` only if you ship a custom `SFSyncUpTarget` subclass (in which case use `"custom"` and add an `iOSImpl` key naming it).

`syncName` is required on each entry — it's the identifier you pass to `syncManager.reSync(named:)` to run the sync.

Constraints:

- `syncType` is `"syncDown"` or `"syncUp"`.
- `soupName` must match a `soupName` from `userstore.json`.
- `target.type` for sync-down is one of `"soql"`, `"sosl"`, `"mru"`, `"refresh"`, `"parent_children"`, `"layout"`, `"metadata"`, `"briefcase"`, `"custom"`. SOQL is the default for record-set syncs.
- `options.mergeMode` is `"OVERWRITE"` or `"LEAVE_IF_CHANGED"`.

<!-- CANONICAL: copy-bundle-resources mechanism — keep identical across add-smartstore / add-mobilesync except the resource filename (userstore.json vs usersyncs.json) -->
After adding the file, ensure it lands in **Copy Bundle Resources** for the app target. The mechanism depends on the shape you picked in Step 0:

- **Option A (CocoaPods, pure — Step 0 case 2)**: drag the file into the project navigator in Xcode, or write it at the path the existing target already references; verify Build Phases → Copy Bundle Resources lists it.
- **Hybrid (Step 0 case 1)**: write the file at `<AppName>/usersyncs.json` — the `sources:` glob in `project.yml` covers it. Run `xcodegen generate`, followed by `pod install`. Do **not** also drag the file into Xcode — that would create a duplicate reference after regen.
- **Option B-i (xcodegen + SPM)**: the `<AppName>` target's `sources:` glob in `project.yml` already covers `<AppName>/*.json`. Run `xcodegen generate` to land the new file in the regenerated project.
- **Option B-ii (Plain SPM)**: emit the human-instruction block from Step 1 (Option B-ii) asking the user to drag the file into the target.

## Step 5 — Creating local rows from app code

When the user creates a record in your app *before* it has been pushed to Salesforce, the row exists only in SmartStore and has no server `Id`. Flag it as locally created so sync-up will push it; the server `Id` is filled in on the next sync-up.

```swift
import MobileSync
import SalesforceSDKCore

func createLocalAccount(name: String, phone: String) {
    guard let user = UserAccountManager.shared.currentUserAccount,
          let store = SmartStore.shared(withName: SmartStore.defaultStoreName, forUserAccount: user)
    else { return }

    let entry: [String: Any] = [
        "Name": name,
        "Phone": phone,
        "attributes": ["type": "Account"],
        "__local__": true,
        "__locally_created__": true,
        "__locally_updated__": false,
        "__locally_deleted__": false
    ]
    _ = store.upsert(entries: [entry], forSoupNamed: "<SoupName>")
}
```

Use the two-arg `upsert(entries:forSoupNamed:)` overload for local creates — it keys on the soup's internal `_soupEntryId`. The three-arg `upsert(entries:forSoupNamed:withExternalIdPath:)` overload is for upsert-by-server-`Id` *after* a sync-down has populated the row; passing it for a brand-new local row throws because the external-id field is nil.

## Step 6 — Build

**Preflight — verify before invoking `xcodebuild`.** Re-list the project root and the target source folder and confirm:

- [ ] **Dependency**: Option A/Hybrid `Podfile` declares `pod 'MobileSync'`; Option B-i/B-ii `project.yml` (or Xcode UI) lists `MobileSync` alongside the existing products.
- [ ] **`AppDelegate.swift`**: `import MobileSync` and `MobileSyncSDKManager.initializeSDK()`.
- [ ] **`SceneDelegate.swift`**: `import MobileSync`, `setupUserSyncsFromDefaultConfig()`, and the named `reSync`.
- [ ] **`MyAccountsViewController.swift`**: exists and compiles.
- [ ] **`usersyncs.json`**: exists with the `syncs` array; for B-i/Hybrid, `xcodegen generate` re-run after writing it.

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

After login, the configured sync runs and populates the soup. Confirm the launch log line `Setting up user syncs using config found in usersyncs.json` appears — if not, the file isn't in the bundle.

## Next

- Biometric session locking: [`add-biometric-auth.md`](add-biometric-auth.md)
- API name resolution: [`api-reference.md`](api-reference.md)
- Symptoms: [`troubleshooting.md`](troubleshooting.md)
