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

## Step 0 — Detect Project Shape (required first action)
<!-- CANONICAL: project-shape detection — keep byte-identical across add-mobile-sdk / add-smartstore / add-mobilesync -->
**Do not skip this step. Do not assume a shape from the prompt or from training-data priors.** Before any file edits, list the contents of the project root and identify which of the four cases applies based on the actual files present. Agents that skip this step and pick a shape from training data routinely write to the wrong files and break the build.

Run a directory listing of the project root (the folder you'll be modifying — the same folder the prompt or task directive points at). Then pick **exactly one** option in priority order based on the files present:

1. `Podfile` AND `project.yml` both exist → **Hybrid (Option A for the SDK + xcodegen for sources)**. `project.yml` owns project structure (sources, schemes, entitlements); CocoaPods supplies third-party modules. For the SmartStore dependency, follow Option A only — **DO NOT** also add the `SmartStore` SPM product to `project.yml` (linking the SDK via both Pods and SPM produces duplicate-symbol errors). After authoring the new resources in Steps 2–4, run `xcodegen generate`, then `pod install`.
2. `Podfile`, no `project.yml` → **Option A — CocoaPods**. Edit only the `Podfile`; don't run xcodegen or text-edit the `.xcodeproj`.
3. `project.yml`, no `Podfile` → **Option B-i — xcodegen + SPM (autonomous)**. The `.xcodeproj` is regenerable output.
4. `.xcodeproj`, no `project.yml`, no `Podfile` → **Option B-ii — Plain SPM (human-instruction)**.

If none match, the project hasn't been initialized with Mobile SDK yet — run [`add-mobile-sdk.md`](add-mobile-sdk.md) first.

**Commit to your choice and state it.** State which option you picked and which file(s) in the listing triggered the choice (e.g. *"Option A — found `Podfile`, no `project.yml`"*). Then read **only that option's section** in Step 1 — reading sections for options you didn't pick will mix workflows and break the build.

## Step 1 — Dependency

### Option A — CocoaPods

> **DO NOT** author a `project.yml` (if one isn't already present). **DO NOT** recreate or overwrite the existing `.xcodeproj/`. **DO NOT** text-edit `project.pbxproj`.
>
> **For pure CocoaPods (Step 0 case 2):** also **DO NOT** run `xcodegen` or `xcodegen generate` — the `.xcodeproj` is hand-maintained.
>
> **For Hybrid (Step 0 case 1, where `project.yml` is also present):** xcodegen owns source-file inclusion. After authoring the new files in Steps 2–4, run `xcodegen generate`, then `pod install`.
>
> Edit only the existing `Podfile` for the dependency change. SmartStore depends on `SalesforceSDKCore` transitively, so swap (don't add) the pod entry.

Replace the `SalesforceSDKCore` pod with `SmartStore`:

```ruby
# was: pod 'SalesforceSDKCore'
pod 'SmartStore'
```

```bash
pod install
```

After this, all `xcodebuild` / open invocations use `<AppName>.xcworkspace` (not `.xcodeproj`).

### Option B-i — xcodegen + SPM (project has `project.yml`)

> `project.yml` is the source of truth. Running `xcodegen generate` is the correct move here — that's how new files and dependencies land in the `.xcodeproj`. **DO NOT** use Xcode's "Add Package Dependencies…" UI; those edits live in `project.pbxproj` and get wiped on the next regen.

This is the autonomous path. The `SalesforceMobileSDK-iOS-SPM` package is already declared in `project.yml`'s `packages:` map (from a prior [`add-mobile-sdk.md`](add-mobile-sdk.md) run). You need to **add** the `SmartStore` product to the app target's `dependencies:` list.

**Step B-i.1: Edit `project.yml`.** On the `<AppName>` target's `dependencies:` list, add a new `product: SmartStore` entry alongside the existing `SalesforceSDKCore`, `SalesforceAnalytics`, and `SalesforceSDKCommon` entries. **Do not remove the existing entries** — unlike the CocoaPod, the SmartStore SPM product does not transitively pull in `SalesforceSDKCore`, and `SceneDelegate.swift` still needs `SalesforceSDKCore` for `AuthHelper`.

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
        product: SmartStore         # new
```

**Verify before regenerating.** Re-read `project.yml` and confirm exactly four `dependencies:` entries: `SalesforceSDKCore`, `SalesforceAnalytics`, `SalesforceSDKCommon`, and the new `SmartStore`. Removing `SalesforceSDKCore` will break the build with `No such module 'SalesforceSDKCore'` from `SceneDelegate.swift`.

**Step B-i.2: Regenerate the project.**

```bash
xcodegen generate
```

This rewrites `<AppName>.xcodeproj`. `project.yml` remains the source of truth.

**Step B-i.3: Resolve packages.**

```bash
xcodebuild -resolvePackageDependencies \
  -project <AppName>.xcodeproj \
  -scheme <AppName>
```

This pre-fetches and pins the SPM packages. Without it, the next build can fail on a clean checkout or after clearing DerivedData.

**Step B-i.4: Continue with Steps 2–5 below.** After authoring `userstore.json` in Step 4, re-run `xcodegen generate` once more so the new file ends up in the regenerated project.

### Option B-ii — Plain SPM (project has only `.xcodeproj`)

> **DO NOT** author a `project.yml`. **DO NOT** run `xcodegen` or `xcodegen generate`. **DO NOT** create a `Podfile` or run `pod install`. **DO NOT** text-edit `project.pbxproj`.

This is the human-instruction path. The project's `.xcodeproj` is hand-managed, so updating the package's product set via the Xcode UI is the only safe option.

**Step B-ii.1: Print the manual-step block and stop.** Emit the following block verbatim (substituting `<AppName>`), then halt — do not proceed to Step 2 of Add SmartStore until the user replies with a confirmation.

> **Manual step required — Xcode UI.** This project is a hand-managed `.xcodeproj` (no `project.yml`). I can't update the Swift package autonomously without risking corrupting your project file. Please do the following in Xcode, then reply with "done" so I can continue.
>
> 1. Open `<AppName>.xcodeproj` in Xcode.
> 2. In the project navigator, select the project, then the `<AppName>` target.
> 3. Open the **General** tab. Under **Frameworks, Libraries, and Embedded Content**, click **+**.
> 4. In the picker, expand **SalesforceMobileSDK-iOS-SPM**, select `SmartStore`, and click **Add**.
> 5. Leave the existing `SalesforceSDKCore`, `SalesforceAnalytics`, and `SalesforceSDKCommon` entries in place — unlike the CocoaPod, the `SmartStore` SPM product does not transitively pull in `SalesforceSDKCore`, which is still required by the auth code in `SceneDelegate.swift`.
> 6. Reply "done" (or "added") when finished.

**Step B-ii.2: Wait for user confirmation.** While waiting, do not edit files, run builds, or invent commands. If the user replies with anything other than a confirmation, re-emit the instructions or answer the user's question — but do not advance to Step 2.

**Step B-ii.3: After confirmation, continue with Steps 2–5 below in place.** Edit existing source files directly. **Do not** run `xcodegen generate` — the project is hand-managed, and any new files you create on disk are not automatically in the Xcode target. After authoring `userstore.json` in Step 4 (and before the Step 5 build), emit one more human instruction:

> **Manual step required — Xcode UI.** I've created `<AppName>/userstore.json`. In Xcode, please drag this file into the `<AppName>` target group and verify it appears in **Build Phases → Copy Bundle Resources**, then reply "done".

Wait again for confirmation before running the Step 5 build.

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

`setupUserStoreFromDefaultConfig()` reads `userstore.json` from the app bundle and creates the configured soups in the encrypted store for the current user. **Step 4 writes that file — do not skip it. If `userstore.json` is missing, this call is a silent no-op: the build succeeds, but no soup is ever created and every subsequent SmartStore read/write fails at runtime.**

## Step 4 — `<AppName>/userstore.json` (required)

> **Do not skip this step.** It's tempting after Steps 1–3 to jump straight to Step 5 — every Swift symbol resolves and the build will compile. But `setupUserStoreFromDefaultConfig()` (Step 3) loads soup definitions from this JSON file at runtime; without it, no soup exists and every SmartStore call silently fails. The build alone will not surface this gap.

**Create a new file at `<AppName>/userstore.json`** (relative to the project root — same folder that holds `AppDelegate.swift`). Steps 1–3 modified existing files; this step creates a new one.

Substitute `<SoupName>` with an appropriate name. If the task explicitly names a soup, use that. Otherwise infer one from the data the app is storing — `Account` for account records, `Contact` for contacts, `Lead` for leads, `Note` for free-form notes, and so on. Soup names are arbitrary strings (the SDK only enforces non-empty), but they're easier to maintain when they match the dominant Salesforce object or data domain:

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

<!-- CANONICAL: copy-bundle-resources mechanism — keep identical across add-smartstore / add-mobilesync except the resource filename (userstore.json vs usersyncs.json) -->
After adding the file, ensure it lands in **Copy Bundle Resources** for the app target. The mechanism depends on the shape you picked in Step 0:

- **Option A (CocoaPods, pure — Step 0 case 2)**: drag the file into the project navigator in Xcode, or write it at the path the existing target already references; verify Build Phases → Copy Bundle Resources lists it.
- **Hybrid (Step 0 case 1)**: write the file at `<AppName>/userstore.json` — the `sources:` glob in `project.yml` covers it. Run `xcodegen generate`, followed by `pod install`. Do **not** also drag the file into Xcode — that would create a duplicate reference after regen.
- **Option B-i (xcodegen + SPM)**: the `<AppName>` target's `sources:` glob in `project.yml` already covers `<AppName>/*.json`. Run `xcodegen generate` to land the new file in the regenerated project.
- **Option B-ii (Plain SPM)**: emit the human-instruction block from Step 1 (Option B-ii) asking the user to drag the file into the target.

## Step 5 — Build

**Preflight — verify before invoking `xcodebuild`.** Re-list the project root and the app target's source folder, and confirm all four deltas are on disk. The build will pass even if some are missing — every item below is either a runtime resource or a config edit that does not break compilation. Do not proceed to `xcodebuild` until each box is ticked; if any are missing, return to that step and finish it.

- [ ] **Step 1 — dependency**: for Option A / Hybrid, `Podfile` declares `pod 'SmartStore'`; for Option B-i / B-ii, `project.yml` (or the Xcode UI) lists `SmartStore` alongside the existing `SalesforceSDKCore` / `SalesforceAnalytics` / `SalesforceSDKCommon` products on the `<AppName>` target.
- [ ] **Step 2 — `<AppName>/AppDelegate.swift`**: contains `import SmartStore` and the `SmartStoreSDKManager.initializeSDK()` call inside the `override init()` block.
- [ ] **Step 3 — `<AppName>/SceneDelegate.swift`**: contains `import SmartStore` and `SmartStoreSDKManager.shared.setupUserStoreFromDefaultConfig()` inside `setupRootViewController()`.
- [ ] **Step 4 — `<AppName>/userstore.json`**: file exists with the `soups` array; for Option B-i / Hybrid, `xcodegen generate` has been re-run after the file was written so it lands in the regenerated project.

Once every item is verified, the build invocation depends on the shape you picked in Step 0:

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

After login, the placeholder view reads "SmartStore ready" and `<SoupName>` is registered.

## Next

- Cloud sync into the same soup: [`add-mobilesync.md`](add-mobilesync.md)
- Symptoms (e.g. `setupUserStoreFromDefaultConfig()` silently does nothing): [`troubleshooting.md`](troubleshooting.md)
