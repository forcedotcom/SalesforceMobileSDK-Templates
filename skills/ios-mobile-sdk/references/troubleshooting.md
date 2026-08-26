# iOS — Troubleshooting

Symptom-first reference for iOS Mobile SDK integration failures.

## Build / Linking

| Symptom | Cause | Fix |
|---|---|---|
| `Cannot find type 'SalesforceManager'` (or `SmartStoreSDKManager` / `MobileSyncSDKManager`) | Module not imported, or framework not linked. | Add `import SalesforceSDKCore` (or `SmartStore` / `MobileSync`) to the file. For CocoaPods, ensure `pod install` completed and the build uses `<AppName>.xcworkspace`. For SPM, ensure the corresponding product is in the target's **Frameworks, Libraries, and Embedded Content**. |
| `pod install` fails: `Unable to find a specification for 'SalesforceSDKCore'` | The Salesforce specs source is missing from the `Podfile`. | Add `source 'https://github.com/forcedotcom/SalesforceMobileSDK-iOS-Specs'` and `source 'https://cdn.cocoapods.org/'` at the top of the `Podfile`, then re-run. |
| `xcodebuild` fails with `Found no destinations for the scheme` | Either `supportedDestinations` is missing on the target (Xcode 16+ excludes the simulator unless declared) or the scheme is not shared. | For xcodegen-managed projects (see [`create-new-app.md`](create-new-app.md)): set `supportedDestinations: [iOS, iPadOS, iOSSimulator]` on the target and add a top-level `schemes:` block in `project.yml`, then `xcodegen generate`. For hand-maintained `.xcodeproj`: confirm a shared scheme exists at `<AppName>.xcodeproj/xcshareddata/xcschemes/<AppName>.xcscheme`, and pass `-destination 'platform=iOS Simulator,name=iPhone 17 Pro'` (or `'generic/platform=iOS Simulator'`) to `xcodebuild`. |
| New file added on disk does not appear in the build | The file was created on disk but not added to the Xcode target. | For xcodegen projects: re-run `xcodegen generate` (then `pod install` if using CocoaPods, since `xcodegen generate` rewrites `.xcodeproj`). For hand-maintained `.xcodeproj`: drag the file into the project navigator and tick the app target's Target Membership. For resources, confirm the file is in Build Phases → Copy Bundle Resources. |

## Login

| Symptom | Cause | Fix |
|---|---|---|
| Login screen does not appear at launch | `bootconfig.plist` not in **Copy Bundle Resources**, or `SFDCOAuthLoginHost` missing from `Info.plist`. | Verify both. The OAuth bridge cannot start without the consumer key + redirect URI from `bootconfig.plist`, and `AuthHelper` reads `SFDCOAuthLoginHost` from `Info.plist`. |
| Login screen renders with black bars above and below content | `LaunchScreen.storyboard` is missing or `UILaunchStoryboardName` is not set in `Info.plist`. | Add `LaunchScreen.storyboard` to the target and set `UILaunchStoryboardName=LaunchScreen` in `Info.plist`. |
| User enters credentials, login UI dismisses, app never advances to the post-login UI | Keychain entitlement missing or stripped. The SDK writes OAuth tokens to the keychain — without `keychain-access-groups` it cannot persist them and silently fails. Device log shows `errSecMissingEntitlement` / OSStatus `-34018` plus `Authentication failed: ... access token`. | (1) Verify `<AppName>.entitlements` contains `keychain-access-groups` with `$(AppIdentifierPrefix)<BundleID>`. (2) Build Settings → **Code Signing Entitlements** points at it. (3) The build is **not** using `CODE_SIGNING_ALLOWED=NO` (which strips entitlements). Ad-hoc signing (`CODE_SIGN_IDENTITY=-`) is sufficient on the simulator. |

## SmartStore

| Symptom | Cause | Fix |
|---|---|---|
| `setupUserStoreFromDefaultConfig()` returns without error and no soup is created | `userstore.json` not in **Copy Bundle Resources**. | Confirm Build Phases → Copy Bundle Resources includes `userstore.json`. For xcodegen projects, re-run `xcodegen generate` (then `pod install` if using CocoaPods); for hand-maintained `.xcodeproj`, drag the file into the project navigator and tick the app target's membership. |
| App crashes on first store access with "soup ... does not exist" | Code reads/writes a soup name that isn't declared in `userstore.json`, or the file failed to parse (silent). | Check the JSON parses (`python3 -m json.tool < userstore.json`). Confirm the `soupName` referenced in code matches a declared soup. |

## MobileSync

| Symptom | Cause | Fix |
|---|---|---|
| `setupUserSyncsFromDefaultConfig()` runs but no sync executes | `setupUserSyncsFromDefaultConfig()` only **registers** syncs; it does not run them. | Trigger by name with `syncManager.reSync(named: <SyncName>)`, or run a one-off sync with `syncDown(target:options:soupName:onUpdate:)`. |
| Sync fails: `Soup not found` | `soupName` in `usersyncs.json` does not match a declared soup in `userstore.json`. | Align names between the two files. |
| `usersyncs.json` is ignored | File missing from the bundle, or named wrong. The SDK looks for the literal filename `usersyncs.json` (plural). | Add the file at `<AppName>/usersyncs.json` (sibling to `userstore.json`), then confirm it appears in Build Phases → Copy Bundle Resources for the app target. For xcodegen projects, re-run `xcodegen generate`; for hand-maintained `.xcodeproj`, drag into the project navigator and tick target membership. |
| UI stays empty after sync completes | Reload was issued before `onUpdate` fired with `.done`. `reSync(named:onUpdate:)` returns immediately while the sync runs asynchronously. | Move the data-source reload **inside** the `onUpdate` block, gated on `sync.status == .done`. See [`add-mobilesync.md`](add-mobilesync.md) Step 3. |

## Biometric

| Symptom | Cause | Fix |
|---|---|---|
| Biometric prompt does not appear | `NSFaceIDUsageDescription` missing in `Info.plist`, OR the Connected App's biometric policy isn't in force for this user — so `SalesforceManager.shared.biometricAuthenticationManager().enabled` returns `false` at runtime. | Add `NSFaceIDUsageDescription` to `Info.plist`. If `enabled` is `false`, talk to your Salesforce admin — the policy is server-driven, not a client-side switch. |
| Opt-in dialog appears every launch even after the user opted in | The opt-in is being presented while the SDK has the session locked (post-relaunch, pre-unlock), or while the user has already opted in. | Guard with `enabled`, `!locked`, and `!hasBiometricOptedIn()` before calling `presentOptInDialog(viewController:)`. |
| Compile error: `BiometricAuthenticationManager` has no member `shared` | `BiometricAuthenticationManager` is a Swift `protocol`. Use the concrete singleton `SalesforceManager.shared.biometricAuthenticationManager()`. | Replace `BiometricAuthenticationManager.shared` with `SalesforceManager.shared.biometricAuthenticationManager()`. The full public surface is in [`add-biometric-auth.md`](add-biometric-auth.md). |

## Code Signing

| Symptom | Cause | Fix |
|---|---|---|
| Login completes in UI but tokens vanish on relaunch (or never set) | `CODE_SIGNING_ALLOWED=NO` was passed to `xcodebuild`, stripping entitlements. | Drop the flag. Use ad-hoc signing — `CODE_SIGN_IDENTITY=-` is sufficient for simulator builds. |
