# iOS SDK 13 → 14: Breaking Changes Reference

Comprehensive reference for API removals, default-value changes, protocol changes, version bumps, and new capabilities introduced between Salesforce Mobile SDK 13.x and 14.0.

---

## Removed APIs

These members no longer compile in SDK 14. Every call site must be updated before the project can build.

| Class / Protocol | Removed Member | Replacement |
|---|---|---|
| `SFInstrumentation` | Entire class | Remove all usages; no replacement |
| `SFMethodInterceptor` | Entire class | Remove all usages; no replacement |
| `SFSDKInstrumentationHelper` | Entire class | Remove all usages; no replacement |
| `SFSDKOAuthSessionManaging` | Entire protocol | Remove conformance; use standard OAuth coordinator APIs |
| `SFSDKWebViewStateManager` | `sharedProcessPool` class property | Create and manage your own `WKProcessPool` if needed |
| `SalesforceSDKManager` | `isQrCodeLoginEnabled` property | Removed; QR code login is always enabled in SDK 14 |
| Podfile hook | `signposts_post_install(installer)` | Removed from mobilesdk_pods.rb; delete the call from `post_install` |

---

## Deprecated APIs

These members still compile in SDK 14 but are marked deprecated (`SFSDK_DEPRECATED(14.0, 15.0, ...)`) and are scheduled for removal in a future release. Migrate when convenient.

| Class / Protocol | Deprecated Member | Replacement |
|---|---|---|
| `SFOAuthSessionRefresher` | Entire class (`initWithCredentials:`, `refreshSessionWithCompletion:error:`) | `UserAccountManager.refresh(credentials:)` (Swift) / `-[SFUserAccountManager refreshCredentials:completion:failure:]` (Obj-C) |

---

## Removed APIs — Before/After Code Examples

### SFInstrumentation, SFMethodInterceptor, SFSDKInstrumentationHelper

These classes are entirely removed. Remove all imports and usages.

```swift
// BEFORE — SDK 13, deprecated
import SalesforceSDKCore  // (if SFInstrumentation was accessed via this)
SFInstrumentation.logEvent("myEvent", data: myData)
let interceptor = SFMethodInterceptor()

// AFTER — SDK 14
// Remove the above lines entirely. No replacement.
```

Search for all usages:

```bash
grep -rn 'SFInstrumentation\|SFMethodInterceptor\|SFSDKInstrumentationHelper' \
  --include='*.swift' --include='*.m' --include='*.h' .
```

---

### SFSDKOAuthSessionManaging

The protocol is removed. Remove conformance declarations and any methods that were implemented solely to satisfy it.

Swift:
```swift
// BEFORE — SDK 13, deprecated
class MyAuthCoordinator: NSObject, SFSDKOAuthSessionManaging {
    func sessionManagerUpdatedCredentials(_ credentials: SFOAuthCredentials) {
        // ...
    }
}

// AFTER — SDK 14
class MyAuthCoordinator: NSObject {
    // Remove the protocol conformance and its required methods
}
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

---

### SFSDKWebViewStateManager.sharedProcessPool

```swift
// BEFORE — SDK 13, deprecated
let pool = SFSDKWebViewStateManager.sharedProcessPool
let config = WKWebViewConfiguration()
config.processPool = pool
let webView = WKWebView(frame: .zero, configuration: config)

// AFTER — SDK 14
let pool = WKProcessPool()  // create your own, or omit if sharing is not required
let config = WKWebViewConfiguration()
config.processPool = pool
let webView = WKWebView(frame: .zero, configuration: config)
```

---

### SFOAuthSessionRefresher (deprecated, not removed)

`SFOAuthSessionRefresher` still compiles in SDK 14 but is deprecated (`SFSDK_DEPRECATED(14.0, 15.0, ...)`). Its message: it bypasses the centralized token-refresh coordinator and will be removed from the public API. Migrate to `UserAccountManager.refresh(credentials:)`.

```swift
// BEFORE — SDK 13 (still compiles in SDK 14, but deprecated)
let refresher = SFOAuthSessionRefresher(credentials: credentials)
refresher.refreshSession { updatedCredentials in
    // use updatedCredentials
} error: { error in
    // handle error
}

// AFTER — SDK 14: UserAccountManager.refresh(credentials:) uses a Result callback and returns Bool
let started = UserAccountManager.shared().refresh(credentials: credentials) { result in
    switch result {
    case .success(let (userAccount, authInfo)):
        // use userAccount / authInfo
        break
    case .failure(let error):
        // handle error
        break
    }
}

// Or the async form:
// let (userAccount, authInfo) = try await UserAccountManager.shared().refresh(credentials: credentials)
```

Objective-C:
```objc
// BEFORE (still compiles, but deprecated)
SFOAuthSessionRefresher *refresher = [[SFOAuthSessionRefresher alloc] initWithCredentials:credentials];
[refresher refreshSessionWithCompletion:^(SFOAuthCredentials *updated) {
    // ...
} error:^(NSError *error) {
    // ...
}];

// AFTER — success/failure blocks are (SFOAuthInfo *, SFUserAccount *) and (SFOAuthInfo *, NSError *)
[[SFUserAccountManager sharedInstance] refreshCredentials:credentials
    completion:^(SFOAuthInfo *authInfo, SFUserAccount *userAccount) {
        // ...
    }
    failure:^(SFOAuthInfo *authInfo, NSError *error) {
        // ...
    }];
```

---

### signposts_post_install (Podfile hook)

```ruby
# BEFORE — SDK 13
post_install do |installer|
  mobile_sdk_post_install(installer)
  signposts_post_install(installer)    # <-- this helper was removed in SDK 14
end

# AFTER — SDK 14
post_install do |installer|
  mobile_sdk_post_install(installer)
  # signposts_post_install is gone; do not call it
end
```

Calling the removed helper causes `pod install` to fail with `undefined method 'signposts_post_install'`.

---

### SalesforceSDKManager.isQrCodeLoginEnabled

```swift
// BEFORE — SDK 13, deprecated
MobileSyncSDKManager.shared.isQrCodeLoginEnabled = true

// AFTER — SDK 14
// Remove this line entirely. QR code login is always enabled.
```

---

## Default Behavior Changes

### usesDPoP — now defaults to true

In SDK 13 `usesDPoP` defaulted to `false`. In SDK 14 it defaults to `true`.

**Impact:** Apps whose Connected App is not configured for DPoP will fail at token exchange after upgrading. The error appears at runtime, not at build time.

**To opt out (temporary, for development):**

```swift
override init() {
    super.init()
    SalesforceManager.initializeSDK()
    SalesforceManager.shared().usesDPoP = false
}
```

**To upgrade existing users to DPoP (once Connected App is configured):**

```swift
UserAccountManager.shared().upgradeToDPoP(userAccount,
    success: { authInfo, userAccount in /* tokens are now DPoP-bound */ },
    failure: { authInfo, error in /* handle */ }
)
```

---

### forceAdvancedAuthentication — now defaults to true for all hosts

In SDK 13, Advanced Authentication (browser-based login via `SFSafariViewController`) was enabled only for specific hosts. In SDK 14, it is on for **all** login hosts including `login.salesforce.com`.

**Impact:** Users will see a browser-based login prompt instead of an in-app `WKWebView` flow on first login after upgrade.

**To preserve the in-app WKWebView login flow:**

```swift
SalesforceManager.shared().forceAdvancedAuthentication = false
```

---

## New APIs

### upgradeToDPoP(_:success:failure:)

New method on `UserAccountManager` (Obj-C `SFUserAccountManager`) for migrating an existing authenticated user account from non-DPoP tokens to DPoP-bound tokens. The `success` block receives `(AuthInfo, UserAccount)` and the `failure` block receives `(AuthInfo, Error)`.

```swift
UserAccountManager.shared().upgradeToDPoP(
    userAccount,
    success: { authInfo, userAccount in
        // tokens refreshed and bound to a new DPoP key pair
    },
    failure: { authInfo, error in
        // handle: re-authenticate if needed
    }
)
```

Call once per user account. Use a `UserDefaults` flag keyed to the account ID to avoid calling it on subsequent launches.

---

## Version Bumps

| Component | SDK 13.2.1 | SDK 14.0 |
|---|---|---|
| iOS deployment target | 17.0 | **18.0** |
| Xcode requirement | 16 | **16** (unchanged) |
| SQLCipher (SmartStore encryption) | 4.10.0 | **4.17.0** (auto via pod install) |
| Default Salesforce REST API version | v66.0 | Check release notes |

SQLCipher is updated automatically during `pod install`. No manual migration is required for SmartStore databases — the SDK handles key migration on first open.

For SPM builds, SQLCipher is bundled inside the pre-built `SmartStore.xcframework` — no separate action is required.
