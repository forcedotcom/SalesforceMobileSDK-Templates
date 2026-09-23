# iOS SDK 12 → 13 Upgrade — Troubleshooting

Symptom-first reference for failures that arise when upgrading from Salesforce Mobile SDK 12.x to 13.2.1.

---

## Build / Linking

### 1. "No such module 'SalesforceSDKCore'" after pod install

**Symptom:** `xcodebuild` or Xcode reports `No such module 'SalesforceSDKCore'` even though `pod install` completed without errors.

**Cause (most common):** The project is being built against `<ProjectName>.xcodeproj` instead of `<ProjectName>.xcworkspace`. After any `pod install`, the build entry point is the workspace, not the project.

**Fix:**
1. Confirm the build command uses `-workspace <ProjectName>.xcworkspace`, not `-project <ProjectName>.xcodeproj`.
2. If you opened the project by double-clicking the `.xcodeproj`, close it and open the `.xcworkspace` instead.
3. If the error persists, delete `Pods/`, `Podfile.lock`, and the `.xcworkspace`, then re-run `pod install --repo-update`.

**Cause (secondary):** The Salesforce specs source is missing from the Podfile, so `pod install` resolved zero SDK pods silently.

**Fix:** Ensure both sources are present:
```ruby
source 'https://cdn.cocoapods.org/'
source 'https://github.com/forcedotcom/SalesforceMobileSDK-iOS-Specs'
```

---

### 2. `'encryptUsingRSAforData:withKeyRef:' has been renamed` compiler error

**Symptom:** Compiler error: `'encryptUsingRSAforData:withKeyRef:' has been renamed` or `No known class method for selector 'encryptUsingRSAforData:withKeyRef:'`.

**Cause:** `SFSDKCryptoUtils.encryptUsingRSAforData:withKeyRef:` and its decrypt counterpart were removed in SDK 13.

**Fix:** Replace with the Security framework equivalents. See [upgrade-12-to-13.md § 4a](upgrade-12-to-13.md#4a-removed-crypto-methods) for the exact before/after code. Add `#import <Security/Security.h>` (Obj-C) or `import Security` (Swift) at the top of the file.

---

### 3. `'openURL:' has been renamed` or "missing argument" error

**Symptom:** Compiler error: `'openURL:' has been renamed` or `missing argument for parameter 'options' in call`.

**Cause:** `SFApplicationHelper.openURL:` (single-argument form) was removed. The SDK now requires the `options:completionHandler:` arguments.

**Fix:**

Objective-C:
```objc
// Replace
[SFApplicationHelper openURL:url];
// With
[SFApplicationHelper openURL:url options:@{} completionHandler:nil];
```

Swift:
```swift
// Replace
SFApplicationHelper.open(url)
// With
SFApplicationHelper.open(url, options: [:], completionHandler: nil)
```

---

### 4. Protocol conformance error for `revokeRefreshToken:reason:`

**Symptom:** Compiler error: `Type '<YourClass>' does not conform to protocol 'SFSDKOAuthProtocol'` with a note about `revokeRefreshToken:reason:`.

**Cause:** `revokeRefreshToken:reason:` was `@optional` in SDK 12 and is `@required` in SDK 13. Classes that omitted it now fail to compile.

**Fix:** Add the method to every class that declares `SFSDKOAuthProtocol` conformance. See [upgrade-12-to-13.md § 4c](upgrade-12-to-13.md#4c-sfsdkoauthprotocolrevokerefreshtoken) for the implementation pattern.

If the class holds an `SFOAuthCoordinator`, forward to it:
```objc
- (void)revokeRefreshToken:(SFOAuthCredentials *)credentials reason:(SFLogoutReason)reason {
    [self.coordinator revokeRefreshToken:credentials reason:reason];
}
```

---

### 5. `pod install` error: platform not compatible with iOS 17.0

**Symptom:** `pod install` (or `pod install --repo-update`) exits with:

```
[!] The platform of the target `<TargetName>` (iOS 16.0) is not compatible with
`SalesforceSDKCore (13.2.1)`, which has a minimum requirement of iOS 17.0.
```

**Cause:** The Podfile's `platform :ios` declaration was not updated to `'17.0'`.

**Fix:**

1. Open the Podfile.
2. Change `platform :ios, '16.0'` to `platform :ios, '17.0'`.
3. Add or update the `post_install` block to also set `IPHONEOS_DEPLOYMENT_TARGET` to `17.0` on each pod target (prevents secondary platform mismatch warnings):
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
    end
  end
end
```
4. Also raise `IPHONEOS_DEPLOYMENT_TARGET` in the Xcode project (Build Settings for each target) to match.
5. Re-run `pod install --repo-update`.

---

### 6. `SFSmartStore openSmartStore` returns nil after upgrade

**Symptom:** A call to `SFSmartStore.sharedStore(withName:user:)` (or the global store variant) returns `nil` after upgrading to SDK 13. Previously it returned a store.

**Cause (most likely):** The SmartStore database from SDK 12 is encrypted with SQLCipher 4.6.1. SDK 13.2.1 bundles SQLCipher 4.10.0. On initial access, the store attempts an encryption key migration. If the app's keychain access group is not configured correctly or the entitlement is missing, the migration fails and the store returns `nil`.

**Fix:**
1. Verify the `keychain-access-groups` entitlement is present in `<TargetName>.entitlements` and that Build Settings → **Code Signing Entitlements** points at it.
2. Verify the build is NOT using `CODE_SIGNING_ALLOWED=NO` — this strips entitlements.
3. Delete the app from the simulator (to clear the database and keychain state), re-install, and verify the store opens on a fresh install.
4. If the problem only occurs for existing users (not fresh installs), the SQLCipher migration is failing silently. Enable verbose SDK logging and look for `SFSmartStore` errors in the device log.

**Cause (secondary):** The `userstore.json` is missing from the app bundle (not in Copy Bundle Resources). This returns `nil` from `setupUserStoreFromDefaultConfig()`.

**Fix:** Confirm Build Phases → Copy Bundle Resources includes `userstore.json`.

---

### 7. `SFLogoutReason` values don't match expected behavior

**Symptom:** After upgrade, logout-reason logic behaves incorrectly — for example, the app treats a token-expiry logout as a manual user logout, or shows the wrong message.

**Cause:** The app is reading a persisted `SFLogoutReason.rawValue` integer (e.g. from `UserDefaults` or a database) that was written by SDK 12. The integer backing values of the `SFLogoutReason` enum changed between SDK 12 and SDK 13. The stored integer now maps to a different case.

**Fix:**
1. On first launch after upgrade (detect this via a version migration flag), clear all stored `SFLogoutReason` raw integers.
2. Never compare `reason.rawValue` against a literal integer. Always use the enum constant:
```swift
// Correct
if reason == .tokenExpired { ... }

// Broken across SDK versions
if reason.rawValue == 1 { ... }
```
3. If you must serialize the reason, store the enum's `string` representation or map it to your own domain enum rather than the SDK's raw value.

---

### 8. xcodebuild fails with "Undefined symbol: `_OBJC_CLASS_$_SFCrypto`"

**Symptom:** Linker error: `Undefined symbol: _OBJC_CLASS_$_SFCrypto` (or similar for `SFCrypto` members).

**Cause:** `SFCrypto` was removed in SDK 13. The app still has source files that reference it.

**Fix:**

Search for all references:
```bash
grep -rn 'SFCrypto' --include='*.swift' --include='*.m' --include='*.h' .
```

Remove every usage. The three class methods that were most commonly used — `baseAppIdentifier`, `baseAppIdentifierIsConfigured`, and `baseAppIdentifierConfiguredThisLaunch` — have no public replacement in SDK 13; remove the call sites and any branching logic that depended on them.

---

### 9. Xcode reports "SFSDKWebViewStateManager.h file not found"

**Symptom:** Compiler error: `'SalesforceSDKCore/SFSDKWebViewStateManager.h' file not found`.

**Cause:** The header was removed from the public SDK 13 headers. The class itself still exists and is callable from Swift, but it no longer has a public Obj-C header.

**Fix:**

Remove the import line:
```objc
// Remove this:
#import <SalesforceSDKCore/SFSDKWebViewStateManager.h>
```

If you were calling `SFSDKWebViewStateManager` from Objective-C, create a Swift wrapper file that calls it and exposes the wrapper to Obj-C, or migrate the call site to Swift.

If you were only calling it from Swift (e.g. `SFSDKWebViewStateManager.removeSession()`), no header import was needed in the first place — just remove the `#import` and the Swift call continues to work.

---

### 10. App crashes on first launch after upgrade with "unexpectedly found nil while unwrapping"

**Symptom:** The app crashes immediately on launch (or at the first SDK call) with a Swift fatal error: `Fatal error: Unexpectedly found nil while unwrapping an Optional value`.

**Cause (most common):** `SalesforceSDKManager.initializeSDK()` was not called before the first SDK API call. In SDK 13 more internal state is guarded by a precondition that the SDK is initialized.

**Fix:** Verify that `SalesforceManager.initializeSDK()` (or `SmartStoreSDKManager.initializeSDK()` / `MobileSyncSDKManager.initializeSDK()` for apps using those layers) is called in `AppDelegate.init()` before any SDK reference:

```swift
override init() {
    super.init()
    SalesforceManager.initializeSDK()
}
```

`init()` must be used, not `application(_:didFinishLaunchingWithOptions:)`. The SceneDelegate and other SDK-managed windows can initialize before `didFinishLaunchingWithOptions` fires.

**Cause (secondary):** The `bootconfig.plist` is missing from the app bundle (not in Copy Bundle Resources). The SDK will crash trying to read the consumer key if the file is absent.

**Fix:** Confirm Build Phases → Copy Bundle Resources includes `bootconfig.plist`.

**Cause (tertiary):** An API that returned a non-optional in SDK 12 now returns an optional in SDK 13 (see [api-changes.md](api-changes.md)). The force-unwrap at the call site was safe before and is now nil.

**Fix:** Audit the crash stack trace to identify the exact call site, then add proper optional handling (guard/if-let) instead of force-unwrapping.

---

### 11. `pod install` fails: "CocoaPods could not find compatible versions for pod 'SQLCipher'"

**Symptom:** `pod install --repo-update` exits with:

```
[!] CocoaPods could not find compatible versions for pod "SQLCipher":
  In snapshot (Podfile.lock):
    SQLCipher (= 4.6.1, ~> 4.6, ~> 4.6.1)

  In Podfile:
    SmartStore (from `./mobile_sdk/SalesforceMobileSDK-iOS`) was resolved to 13.2.1, which depends on
      SmartStore/SmartStore (= 13.2.1) was resolved to 13.2.1, which depends on
        SQLCipher (~> 4.10.0)
```

**Cause:** The existing `Podfile.lock` was generated with SDK 12.x and pins SQLCipher at `4.6.1`. SDK 13.2.1's SmartStore requires `~> 4.10.0`. When using a local-path (`use_mobile_sdk!`) Podfile, CocoaPods enforces the lock file's SQLCipher constraint against the new local pod, producing an irreconcilable conflict.

**Fix:** Delete `Podfile.lock` before running `pod install`:

```bash
rm Podfile.lock
pod install --repo-update
```

CocoaPods regenerates the lock file with the correct SQLCipher `4.10.x` version. This is safe — the lock file is a derived artifact and will be recreated with the correct constraints.
