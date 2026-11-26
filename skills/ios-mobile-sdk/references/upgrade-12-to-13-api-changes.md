# iOS SDK 12 → 13: API Changes Reference

Comprehensive reference for API removals, protocol changes, deprecations, version bumps, and new capabilities introduced between Salesforce Mobile SDK 12.x and 13.2.1.

---

## Removed APIs

These members no longer compile in SDK 13. Every call site must be updated before the project can build.

| Class / Protocol | Removed Member | Replacement |
|---|---|---|
| `SFSDKCryptoUtils` | `+encryptUsingRSAforData:withKeyRef:` | `SecKeyCreateEncryptedData(keyRef, kSecKeyAlgorithmRSAEncryptionOAEPSHA1, data, NULL)` from `Security.framework` |
| `SFSDKCryptoUtils` | `+decryptUsingRSAforData:withKeyRef:` | `SecKeyCreateDecryptedData(keyRef, kSecKeyAlgorithmRSAEncryptionOAEPSHA1, data, NULL)` from `Security.framework` |
| `SFApplicationHelper` | `+openURL:` (single-arg) | `+openURL:options:completionHandler:` — pass `@{}` and `nil` for the extra parameters |
| `SFCrypto` | `+baseAppIdentifier` | Removed; the identifier is now internal to the SDK and not part of the public API |
| `SFCrypto` | `+baseAppIdentifierIsConfigured` | Removed |
| `SFCrypto` | `+baseAppIdentifierConfiguredThisLaunch` | Removed |
| `SFSDKAppDelegate` | Entire protocol | Remove conformance from `AppDelegate`; the SDK no longer requires it |
| `SFSDKNewLoginHostViewController` | Entire class | The SDK now manages the login host UI internally; do not instantiate directly |
| `SalesforceSDKManager` | `isQrCodeLoginEnabled` property | Removed; QR code login is always enabled in SDK 13 |
| `SFPushNotificationManager` | `registerForSalesforceNotifications` legacy form | Still present and source-compatible in SDK 13.2.1. Preferred API is `registerSalesforceNotifications(completionBlock:failBlock:)` — see Step 4f |
| `SFSmartStore` | `fixFor530Bug` | Removed; the 5.3.0 migration auto-heal is no longer applied |
| Header `SFSDKWebViewStateManager.h` | Direct `#import` | No header needed; use `SFSDKWebViewStateManager` as a Swift class directly |
| Header `SFSDKDevInfoViewController.h` | Direct `#import` | Removed; `SFSDKDevInfoViewController` is no longer public API |

---

## Protocol Changes

### `SFSDKOAuthProtocol`

`revokeRefreshToken:reason:` was `@optional` in SDK 12. In SDK 13 it is **required**.

Any class that declares conformance to `SFSDKOAuthProtocol` must implement this method or the project will not compile:

```objc
// Objective-C — add to every SFSDKOAuthProtocol conforming class
- (void)revokeRefreshToken:(SFOAuthCredentials *)credentials reason:(SFLogoutReason)reason;
```

```swift
// Swift
func revokeRefreshToken(_ credentials: SFOAuthCredentials, reason: SFLogoutReason)
```

---

## Deprecated APIs (will be removed in SDK 14.0)

These compile in SDK 13 but produce deprecation warnings. Fix them before upgrading to SDK 14.

| Class / Protocol | Deprecated Member | Replacement |
|---|---|---|
| `SFInstrumentation` | Entire class | Remove usages; a new diagnostic framework is being introduced in a future SDK version |
| `SFMethodInterceptor` | Entire class | Remove usages |
| `SFSDKInstrumentationHelper` | Entire class | Remove usages |
| `SFSDKOAuthSessionManaging` | Entire protocol | Remove conformance; use the standard OAuth coordinator APIs |
| `SFSDKWebViewStateManager` | `sharedProcessPool` class property | Manage your own `WKProcessPool`, or let the SDK manage its internal pool |
| `SFRestAPI` / `RestClient` | All completion-block `send(request:completionBlock:)` overloads | `try await restClient.send(request:)` — available from iOS 15; no guard needed at the new deployment target of iOS 17 |
| `SalesforceSDKManager` | `bootConfigRuntimeSelector` (SDK 13.0 / 13.1) | `appConfigForLoginHost` closure property (SDK 13.2+) |

---

## Version Bumps

| Component | SDK 12 | SDK 13.2.1 |
|---|---|---|
| iOS deployment target | 16.0 | **17.0** |
| Xcode requirement | 15 | **16** |
| SQLCipher (SmartStore encryption) | 4.6.1 | **4.10.0** (bundled) |
| Default Salesforce REST API version | v60.0 | **v66.0** |

The REST API version change affects network requests only if your code hard-codes the version string. The SDK's `SFRestAPI.apiVersion` property is authoritative at runtime; prefer it over string literals.

---

## New APIs Worth Knowing

### Async/await REST client

`RestClient` (Swift name for `SFRestAPI`) gained a full async/await surface in SDK 13:

```swift
// No @escaping closure needed
let response = try await restClient.send(request: myRequest)
let records = response.asJsonDictionary()
```

### WebSocket support

SDK 13 introduces `SFSDKWebSocketClient` for long-lived Salesforce Streaming API and Platform Events connections over WebSocket. This replaces manual CometD client usage:

```swift
let wsClient = SFSDKWebSocketClient(target: streamingChannel)
wsClient.connect { event in
    // handle platform events
}
```

### `URLRequest`-based REST

`SFRestRequest` can now be converted to a standard `URLRequest` for use with any `URLSession`-based networking layer:

```swift
let urlRequest = sfRestRequest.asURLRequest()
```

### Token migration helper

If your app stores tokens outside the SDK's keychain (e.g. for custom SSO flows), `SFOAuthCredentials.migrate(from:)` provides a supported path to import them into the SDK-managed keychain store in SDK 13.

### `SFLogoutReason` new cases

SDK 13 adds `SFLogoutReason.backgroundRefreshFailed` to distinguish token refresh failures that occur while the app is backgrounded from interactive logouts. Update any exhaustive `switch` statements on `SFLogoutReason`.
