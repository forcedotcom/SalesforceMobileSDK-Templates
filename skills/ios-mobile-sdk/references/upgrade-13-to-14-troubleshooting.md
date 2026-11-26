# iOS SDK 13 → 14 Upgrade — Troubleshooting

Symptom-first reference for failures that arise when upgrading from Salesforce Mobile SDK 13.x to 14.0.

---

## Build / Linking

### 1. `pod install` fails: "Could not find compatible versions for pod 'SQLCipher'"

**Symptom:** `pod install` exits with:

```
[!] CocoaPods could not find compatible versions for pod "SQLCipher":
  In Podfile:
    SmartStore (14.0.1-rc.1) was resolved to 14.0.1-rc.1, which depends on
      SQLCipher (~> 4.17.0)

  In snapshot (Podfile.lock):
    SQLCipher (= 4.10.x)
```

**Cause:** The existing `Podfile.lock` pins SQLCipher at the SDK 13 version (`4.10.x`). SDK 14.0's SmartStore requires `~> 4.17.0`. The two constraints are irreconcilable while the lock file is present.

Additionally, the Salesforce iOS-Specs source must be declared in the Podfile for CocoaPods to locate SQLCipher 4.17.0.

**Fix (step 1):** Verify both sources are declared in the Podfile:

```ruby
source 'https://cdn.cocoapods.org/'
source 'https://github.com/forcedotcom/SalesforceMobileSDK-iOS-Specs'
```

**Fix (step 2):** Delete the lock file and cached pods, then re-run install:

```bash
rm -f Podfile.lock
rm -rf Pods/
pod install
```

CocoaPods regenerates `Podfile.lock` with the correct `4.17.x` constraint. Both files are derived artifacts; removing them is safe.

---

### 2. Build error: "No such module 'SFInstrumentation'"

**Symptom:** Compiler error: `No such module 'SFInstrumentation'` or `Cannot find type 'SFInstrumentation' in scope`.

**Cause:** `SFInstrumentation`, `SFMethodInterceptor`, and `SFSDKInstrumentationHelper` were removed in SDK 14. Any import or usage of these classes will fail to compile.

**Fix:** Search for all references:

```bash
grep -rn 'SFInstrumentation\|SFMethodInterceptor\|SFSDKInstrumentationHelper' \
  --include='*.swift' --include='*.m' --include='*.h' .
```

Remove every import and call site. There is no replacement API — the instrumentation infrastructure was removed entirely.

---

### 3. Build error: "'SFSDKOAuthSessionManaging' does not exist" or "cannot find type"

**Symptom:** Compiler error: `'SFSDKOAuthSessionManaging' does not exist`, `Cannot find type 'SFSDKOAuthSessionManaging' in scope`, or `Type 'MyClass' does not conform to protocol 'SFSDKOAuthSessionManaging'`.

**Cause:** The `SFSDKOAuthSessionManaging` protocol was deprecated in SDK 13 and removed in SDK 14.

**Fix:** Remove the protocol conformance from every class that declares it:

Swift:
```swift
// BEFORE
class MyAuthCoordinator: NSObject, SFSDKOAuthSessionManaging { ... }

// AFTER
class MyAuthCoordinator: NSObject { ... }
```

Objective-C:
```objc
// BEFORE
@interface MyAuthCoordinator () <SFSDKOAuthSessionManaging>
@end

// AFTER
@interface MyAuthCoordinator ()
@end
```

Also remove any methods that were added solely to satisfy this protocol's requirements.

---

### 4. Runtime: login fails with "invalid_grant" or DPoP token exchange error

**Symptom:** After upgrading, login fails at the token exchange step. The error message contains `invalid_grant`, `use_dpop_nonce`, or a reference to DPoP key binding.

**Cause:** `usesDPoP` now defaults to `true` in SDK 14. If the Connected App in Salesforce Setup is not configured for DPoP, the authorization server rejects the DPoP-bound token request.

**Fix (Option A — disable DPoP for development/testing):**

Add to `AppDelegate.init()` immediately after `SalesforceManager.initializeSDK()`:

```swift
override init() {
    super.init()
    SalesforceManager.initializeSDK()
    SalesforceManager.shared.usesDPoP = false
}
```

Remove this line before shipping to production.

**Fix (Option B — configure Connected App for DPoP):**

1. In Salesforce Setup, open the Connected App and enable DPoP under OAuth Settings.
2. Migrate existing users with [`add-dpop-token-migration.md`](add-dpop-token-migration.md). If the migration itself fails at runtime, see [`troubleshooting.md`](troubleshooting.md) → DPoP Migration.

---

### 5. Runtime: unexpected browser-based login sheet (ASWebAuthenticationSession)

**Symptom:** After upgrading, users see a browser login sheet ("<App> Wants to Use salesforce.com to Sign In") where previously they saw an in-app `WKWebView` login screen.

**Cause:** `forceAdvancedAuthentication` now defaults to `true` for all login hosts in SDK 14. In SDK 13 it was enabled only for specific hosts. `login.salesforce.com` now triggers browser-based login by default.

**Fix:** This is expected. Make sure the callback can be routed back to the app: a custom scheme, or `https` with Universal Links on a domain the app owns (see 5a and [`upgrade-13-to-14.md`](upgrade-13-to-14.md) Step 9). To keep WKWebView login temporarily, add this after `SalesforceManager.initializeSDK()`:

```swift
SalesforceManager.shared.forceAdvancedAuthentication = false
```

The flag is deprecated and removed in 15.0, so treat this as temporary.

---

### 5a. Runtime: login sheet shows "Please contact support if you see this page", or never returns to the app

**Symptom:** After the user enters username/password in the browser sheet, it lands on a blank page reading "Please contact support if you see this page" (often on `mobileauth.salesforce.com`). Or the sheet just never dismisses. The app stays signed out.

**Cause:** `oauthRedirectURI` (in `bootconfig.plist`) is an `https` URL that isn't set up as a Universal Link for the app. In SDK 13 the in-app WKWebView intercepted the redirect, which is why it used to work. In SDK 14 the browser sheet hands an `https` callback back to the app only through Universal Links. If the callback host is one the app doesn't control (e.g. `https://mobileauth.salesforce.com/oauth/done`), Universal Links can't be set up there.

**Fix:** Either:

- **Callback on a domain the app owns:** set up Universal Links for it (Associated Domains `applinks:<host>` entitlement plus an `apple-app-site-association` file on the host). See Step 9 row B.
- **Callback on a host the app doesn't control (recommended):** add a custom-scheme Callback URL (e.g. `com.example.myapp://oauth/done`) to the existing Connected App, set `oauthRedirectURI` to it, and register the scheme under `CFBundleURLTypes` in `Info.plist`. See Step 9 row C.
- **Temporary:** set `SalesforceManager.shared.forceAdvancedAuthentication = false`.

See [`upgrade-13-to-14.md`](upgrade-13-to-14.md) Step 9.

---

### 5b. Runtime: browser login fails immediately with `redirect_uri_mismatch`

**Symptom:** The login sheet shows `error=redirect_uri_mismatch` (or "invalid redirect_uri") before or right after credentials are entered.

**Cause:** The app's `oauthRedirectURI` was changed (e.g. to a custom scheme), but that exact URL isn't in the Connected App / External Client App's Callback URLs. Or another bootconfig / build configuration still uses the old value.

**Fix:** Add the exact URL to the Connected App's Callback URLs. Changes can take a few minutes to propagate. Then re-run the Step 0 `oauthRedirectURI` grep to catch per-target or per-configuration overrides.

---

### 6. FMDB duplicate class warning on SPM builds

**Symptom:** The build log contains warnings like:

```
objc[]: Class FMDatabase is implemented in both
  .../SmartStore.framework/SmartStore (0x...) and
  .../debug.dylib (0x...).
One of the two will be used. Which one is undefined.
```

**Cause:** This warning is cosmetic. When SPM links `SmartStore.xcframework`, the FMDB (SQLite wrapper) symbols are compiled into the static framework. The dynamic linker notices that these symbols also appear in a debug library and logs the conflict. At runtime, the correct framework copy is used.

**This warning does not cause incorrect behavior and does not affect the production build.** It appears only in debug configurations.

**No action required.** If the warning is distracting, confirm the release build (Archive) is clean — the warning does not appear in release builds.

---

### 7. "Package.resolved is out of date" after version bump

**Symptom:** After updating the version pin in `project.pbxproj` (hand-managed SPM), Xcode reports:

```
The package graph is out of date. Update the package graph to fix this issue.
```

Or `xcodebuild` fails with:

```
error: package at '.../SalesforceMobileSDK-iOS-SPM' @ 14.0.1-rc.1 does not match resolved version 13.2.1
```

**Cause:** For hand-managed SPM projects (version pinned in `project.pbxproj` only), Xcode caches the resolved package state. After bumping the version number in `project.pbxproj`, the cache must be explicitly cleared.

**Fix:**

```bash
xcodebuild -resolvePackageDependencies \
  -project <ProjectName>.xcodeproj \
  -scheme <TargetName>
```

Or in Xcode: **File → Packages → Resolve Package Versions**.

If the error persists, delete the derived data for the project:

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/<ProjectName>-*
```

Then re-run `-resolvePackageDependencies`.

---

### 8. `pod install` fails: "undefined method 'signposts_post_install'"

**Symptom:** `pod install` exits with:

```
[!] An error occurred while loading the post_install hook of the Podfile.
NoMethodError - undefined method `signposts_post_install' for main:Object
```

**Cause:** The `signposts_post_install` helper was removed from `mobilesdk_pods.rb` in SDK 14. The call in the `post_install` block refers to a method that no longer exists.

If the error names `mobile_sdk_post_install` instead (or `signposts_post_install` in a Podfile that pins explicit pod versions), the Podfile doesn't load `mobilesdk_pods.rb` at all, so none of its helpers exist. Remove every `*_post_install(installer)` helper call from the `post_install` block. See [`upgrade-13-to-14.md`](upgrade-13-to-14.md) Step 2, Case A.

**Fix (Podfile that loads `mobilesdk_pods.rb`):** Remove the `signposts_post_install(installer)` line from the `post_install` block in the Podfile:

```ruby
# BEFORE
post_install do |installer|
  mobile_sdk_post_install(installer)
  signposts_post_install(installer)    # remove this line
end

# AFTER
post_install do |installer|
  mobile_sdk_post_install(installer)
end
```

