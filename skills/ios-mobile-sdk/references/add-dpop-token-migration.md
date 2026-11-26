# iOS — Add DPoP Refresh-Token Migration

Migrates users who are signed in with a **Bearer** (non-DPoP) refresh token to a **DPoP-bound** one. Mobile SDK 14 binds only **new** logins to DPoP by default; sessions created by SDK 13 (or with `usesDPoP = false`) stay Bearer until the app migrates them. The SDK ships the whole "when and how" in `DPoPMigrationManager` (SDK **14.0.1+**): it is a no-op when there is no user or the session is already DPoP-bound, runs at most one upgrade at a time, and leaves the session intact on failure. It has no UI, so the app adds a small localized "Securing your session…" screen and calls it at launch.

The result is one SwiftUI view, one strings entry, and a small `SceneDelegate` edit. **Do not write your own migration helper and do not store a "migrated" flag**: the credentials' token type is the source of truth.

## Preconditions

- Mobile SDK **14.0.1 or later** is integrated and the user can log in (`SalesforceManager.initializeSDK()` or a subclass is called in `AppDelegate`). If not, run [`add-mobile-sdk.md`](add-mobile-sdk.md) first. On SDK 13 or older, or on 14.0.0, run [`upgrade-13-to-14.md`](upgrade-13-to-14.md) first and pin the SDK to `14.0.1-rc.1` or later: `DPoPMigrationManager` does not exist before 14.0.1 and the build fails with `cannot find 'DPoPMigrationManager' in scope`.
- The Connected App / External Client App the app logs in with is **DPoP-enabled in the org** (Salesforce Setup, out of scope here). Without it the upgrade fails and the user keeps their existing session.
- The app uses the UIKit `SceneDelegate` launch flow with `AuthHelper.loginIfRequired` (the shape of the Mobile SDK templates, which host SwiftUI views inside UIKit). For a pure SwiftUI `App` lifecycle see [Step 3b](#step-3b--pure-swiftui-app-lifecycle).

## Step 0 — Detect the project shape and the existing localization

```bash
test -f project.yml && echo "xcodegen"            # project.yml at repo root
test -f Podfile && echo "cocoapods"                # Podfile at repo root
grep -l "PBXFileSystemSynchronizedRootGroup" *.xcodeproj/project.pbxproj   # Xcode 16 synchronized folders
find . -name "Localizable.strings" -o -name "Localizable.xcstrings" | grep -v Pods
```

| Shape | How the new files reach the target | After writing the files |
|---|---|---|
| `project.yml` present | `project.yml` `sources:` globs pick them up | Run `xcodegen generate` (hybrid with a Podfile: then `pod install`). |
| Synchronized group (`PBXFileSystemSynchronizedRootGroup`) | Xcode 16 folder sync | Nothing to register. |
| Hand-maintained `.xcodeproj` (CocoaPods or plain SPM; **what the default templates produce**) | **Not automatic** | Emit the manual instruction in [Step 4](#step-4--register-the-files-in-the-target) and wait. **DO NOT** text-edit `project.pbxproj`, **DO NOT** run `xcodegen`. |

If the app already has a `Localizable.strings`, **append the two keys** from Step 2 to it; if it uses a String Catalog (`Localizable.xcstrings`), add the keys there. Do not create a second strings table. In the paths below `<AppName>` is the app target's source folder (the one containing `AppDelegate.swift`).

## Step 1 — Write the progress view

Create `<AppName>/DPoPMigrationView.swift`. Keep user-facing wording free of technical terms (no "DPoP", no "refresh token"); the text comes from `Localizable.strings`.

```swift
import SwiftUI

/// "Please wait" screen shown while `DPoPMigrationManager` upgrades the user's session.
struct DPoPMigrationView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text(String(localized: "dpop_migration_title"))
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text(String(localized: "dpop_migration_message"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    DPoPMigrationView()
}
```

## Step 2 — Localized strings

Create `<AppName>/en.lproj/Localizable.strings` (or append to the existing table, see Step 0):

```
/* Shown while the app silently upgrades the user's sign-in (DPoP migration). */
"dpop_migration_title" = "Securing your session…";
"dpop_migration_message" = "We're upgrading your sign-in to a more secure format. This only takes a moment.";
```

For other languages add `<lang>.lproj/Localizable.strings` with the same keys. Never put the text in code.

## Step 3 — Wire the launch flow

### Step 3a — UIKit `SceneDelegate` (Mobile SDK template shape)

An **additive edit** to the existing `SceneDelegate.swift`; keep every method already there.

1. Make sure the file has `import SwiftUI` (for `UIHostingController`) next to `import SalesforceSDKCore`.
2. Replace `self.setupRootViewController()` with `self.proceedAfterLogin()` in the **two** places that follow a login: the closure passed to `AuthHelper.loginIfRequired` in `sceneWillEnterForeground`, and the closure passed to `AuthHelper.registerBlock(forCurrentUserChangeNotifications:)` in `scene(_:willConnectTo:options:)` (inside `resetViewState { ... }`). Leave `setupRootViewController()` itself untouched.

   ```swift
   // scene(_:willConnectTo:options:)
   AuthHelper.registerBlock(forCurrentUserChangeNotifications: {
       self.resetViewState {
           self.proceedAfterLogin()      // was: self.setupRootViewController()
       }
   })

   // sceneWillEnterForeground(_:)
   self.initializeAppViewState()
   AuthHelper.loginIfRequired {
       self.proceedAfterLogin()          // was: self.setupRootViewController()
   }
   ```

3. Add this property and method next to `setupRootViewController()`:

   ```swift
   private var isMigrating = false

   /// Runs after login (or on a current-user change), before the main UI is built.
   /// Shows the progress screen only if the SDK has a migration to run, then continues.
   func proceedAfterLogin() {
       // The SDK posts current-user-change notifications while it migrates; the completion
       // below builds the UI, so ignore them until the migration finishes.
       if isMigrating { return }

       guard DPoPMigrationManager.shared.isMigrationNeeded else {
           setupRootViewController()
           return
       }
       isMigrating = true
       window?.rootViewController = UIHostingController(rootView: DPoPMigrationView())
       DPoPMigrationManager.shared.migrateIfNeeded { _ in
           // Any outcome (.migrated, .failed, .notNeeded): continue with the session the user has.
           self.isMigrating = false
           self.setupRootViewController()
       }
   }
   ```

Why two call sites and the `isMigrating` guard: `loginIfRequired`'s completion covers launch and foreground return; the current-user-change notification covers a fresh login and user switching. A fresh login with `usesDPoP` on is already DPoP-bound, so `isMigrationNeeded` is `false` and there is no flash.

### Step 3b — Pure SwiftUI `App` lifecycle

Keep `DPoPMigrationView` and the strings; call the same two members where the app currently continues after `AuthHelper.loginIfRequired`:

```swift
AuthHelper.loginIfRequired {
    guard DPoPMigrationManager.shared.isMigrationNeeded else { showMainUI = true; return }
    showMigrationScreen = true            // e.g. an @State/@Published flag that swaps in DPoPMigrationView()
    DPoPMigrationManager.shared.migrateIfNeeded { _ in
        showMigrationScreen = false
        showMainUI = true
    }
}
```

Also ignore user-change callbacks while the migration screen is up, for the reason given in Step 3a. In async code `let outcome = await DPoPMigrationManager.shared.migrateIfNeeded()` is equivalent.

## Step 4 — Register the files in the target

- **`project.yml` present**: run `xcodegen generate` (then `pod install` for a Podfile hybrid). No manual step.
- **Synchronized group**: nothing to do.
- **Hand-maintained `.xcodeproj`**: the new files are on disk but **not** in the target, so the build fails with `cannot find 'DPoPMigrationView' in scope` until they are. Emit this block verbatim (substituting `<AppName>`), then halt until the user confirms:

  > **Manual step required — Xcode UI.** This project is a hand-maintained `.xcodeproj` (no `project.yml`), so I can't add new files to the target without risking corrupting your project file. I've created `<AppName>/DPoPMigrationView.swift` and `<AppName>/en.lproj/Localizable.strings`. In Xcode:
  >
  > 1. Drag those files into the `<AppName>` group in the project navigator (for the `.strings` file drag the `en.lproj` folder contents). Tick the `<AppName>` target in the dialog.
  > 2. Select the `<AppName>` target → **Build Phases** and confirm `DPoPMigrationView.swift` is in **Compile Sources** and `Localizable.strings` is in **Copy Bundle Resources**.
  > 3. Reply "done" when finished.

  If you appended to an existing strings table there is no strings file to drag.

## Step 5 — Build

CocoaPods and hybrid apps build the workspace; for SPM replace the `-workspace` line with `-project <AppName>.xcodeproj \`.

```bash
xcodebuild \
  -workspace <AppName>.xcworkspace \
  -scheme <AppName> \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGN_IDENTITY=- \
  build
```

Never pass `CODE_SIGNING_ALLOWED=NO` (it strips the keychain entitlement and silently breaks login; see [`troubleshooting.md`](troubleshooting.md)). A green build proves the code compiles, not that the migration works; use the next section for that.

## Verify

Needs a user on a Bearer session and an org whose Connected App / External Client App is DPoP-enabled. Use **two builds** of the same app installed one over the other **without clearing app data**, so the login persists:

1. **Build A (before):** the app with `SalesforceManager.shared.usesDPoP = false` right after `SalesforceManager.initializeSDK()` in `AppDelegate`, and **without** the migration wired in. Install it, log in, and confirm a Bearer session (Dev Info screen, or `credentials.tokenType`).
2. **Build B (after):** the migration-enabled app with DPoP default or on (remove the `usesDPoP = false` line). Install it over build A (no reset, no logout) and launch. Expect the "Securing your session…" screen, the SDK's web view, then the app UI.
3. **Watch the log** (the SDK's lines all carry the `DPoPMigration` tag):

   ```bash
   xcrun simctl spawn booted log stream --level debug --predicate 'eventMessage CONTAINS "DPoPMigration"'
   ```

4. **Dev info:** in the simulator press Control+Command+Z (shake gesture). After the migration the User Agent carries the `DP` flag, which build A did not have; the "Use DPoP" row and the current user's token type (Bearer before, DPoP after) are shown there too.

| Case | Expected `DPoPMigration` log lines | UI |
|---|---|---|
| Bearer user | `upgrade started` → `upgrade succeeded` | Screen, the SDK's web view, then the app UI |
| Relaunch after success | `not needed, already DPoP-bound` | No screen |
| No user (fresh install) | `not needed, no current user` | Login, no screen |
| Failure (offline, user cancels the web view, org not DPoP-enabled) | `upgrade failed: ...` or `upgrade cancelled, authentication was stopped` | Screen dismissed, app UI on the existing session; the next launch retries |

To re-run: delete the app (or log out), go back to build A, and log in again.

Do **not** run the migration-wired build while DPoP is still off before the first login: the migration upgrades Bearer sessions regardless of the flag, so the first launch after login would migrate immediately and there would be no Bearer session to observe.

## Failure behavior

On failure `migrateIfNeeded` reports `.failed(error)` and the SDK leaves the existing session intact: nothing is persisted, nobody is logged out, and the next call (the next launch) retries. The `SceneDelegate` above ignores the outcome and continues to the main UI. If every launch logs `upgrade failed` for all users, check the org-side DPoP setting first.

## Calling it from somewhere else

`DPoPMigrationManager.shared.migrateIfNeeded` is idempotent and always completes on the main queue (synchronously with `.notNeeded` when nothing is to do), so it can also be called from a "Secure my session" settings button, after a user switch, or before a long sync; pass `{ _ in }` when there is no UI. Check `isMigrationNeeded` first to show a progress screen only when a migration will run. Only the **current** user is migrated; other users are migrated once they become current.

Out of scope: configuring DPoP on the Connected App, downgrading (`downgradeFromDPoP`), changing consumer key (`migrateRefreshToken`), and Hybrid / React Native apps.

## Symptoms

See [`troubleshooting.md`](troubleshooting.md) → DPoP Migration.

## References

- RFC 9449 — OAuth 2.0 Demonstrating Proof of Possession (DPoP): <https://www.rfc-editor.org/rfc/rfc9449>
