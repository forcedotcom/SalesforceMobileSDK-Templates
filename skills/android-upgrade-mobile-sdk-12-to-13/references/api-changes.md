# Android SDK 12 → 13: API Changes Reference

Complete reference for classes, methods, and signatures that changed between Salesforce Mobile SDK 12.x and 13.2.1.

---

## Removed Classes

| Class | Notes |
|---|---|
| `ClientManager.LoginOptions` | OAuth config is now read directly from `bootconfig.xml` resources. Remove all construction and usage. |
| `OAuthWebviewHelper` | WebView-based login helper replaced by Jetpack Compose `LoginViewModel`. Migrate customizations to `LoginViewModel` subclass. |
| `OAuthWebviewHelperEvents` | Interface removed with `OAuthWebviewHelper`. Remove implementations. |
| `SalesforceListActivity` | Removed. Migrate to `SalesforceActivity` with a `RecyclerView` or `ListFragment`. |
| `ServerPickerActivity` | Server picker is now built into the Compose login UI. Remove explicit `Intent` launches and any `AndroidManifest.xml` declarations. |

---

## Removed Methods

| Class | Removed Method | Replacement |
|---|---|---|
| `SalesforceSDKManager` | `getLoginOptions()` | None — `LoginOptions` concept removed; SDK reads from `bootconfig.xml`. |
| `SalesforceSDKManager` | `loginOptions` (property) | None — remove all reads/writes. |
| `LoginActivity` | `getOAuthWebviewHelper(...)` | Override `val webViewClient` / `val webChromeClient` in `LoginActivity` subclass, or use `loginViewModelFactory`. |
| `LoginActivity` | `onPickServerClick(v: View?)` | Server picker is built into the Compose login screen; no replacement needed. |
| `LoginActivity` | `onActivityResult(requestCode, resultCode, data)` | Remove override; the Compose login flow does not use `startActivityForResult`. |
| `OAuth2` | `getFrontdoorUrl(url, accessToken, instanceURL, additionalParams)` | Removed without direct replacement. Construct the frontdoor URL manually if needed. |
| `OAuth2` | `revokeRefreshToken(httpAccessor, loginServer, refreshToken)` | Use `OAuth2.revokeToken(...)` variants that remain in the API. |
| `HttpAccess` | `getOkHttpClientBuilder()` / `okHttpClientBuilder` (getter) | Set a custom builder via `SalesforceSDKManager.getInstance().okHttpClientBuilder = builder`. |
| `UserAccountManager` | `switchToNewUser(jwt: String, url: String)` | Use `switchToNewUser()` (no parameters). |
| `SalesforceSDKManager` | `setBrowserLoginEnabled(...)` | No longer public — the method is now `internal`. Remove any app-level calls; browser login is configured by the SDK. |

---

## Changed Signatures

| Class | Old Signature | New Signature |
|---|---|---|
| `ClientManager` constructor | `ClientManager(context, accountType, loginOptions, isBackground)` | `ClientManager(context, accountType, isBackground)` — `loginOptions` parameter removed |
| `LogoutCompleteReceiver` | `onLogoutComplete()` | `onLogoutComplete(reason: OAuth2.LogoutReason)` — `reason` parameter required |
| `SalesforceAnalyticsManager` | `setPublishFrequencyInHours(hours: Int)` | `setPublishPeriodicallyFrequencyHours(hours: Int)` |
| `SalesforceAnalyticsManager` | `publishFrequencyInHours: Int` (property) | `publishPeriodicallyFrequencyHours: Int` |

---

## Removed Manifest Entries

| Entry | Notes |
|---|---|
| `<activity android:name="com.salesforce.androidsdk.ui.ServerPickerActivity" />` | Remove from `AndroidManifest.xml` — the activity no longer exists in the SDK. |
| `<uses-permission android:name="android.permission.USE_FINGERPRINT" />` | Removed in SDK 13. The SDK now declares `USE_BIOMETRIC` in its own manifest. Remove any app-level `USE_FINGERPRINT` declarations. |

---

## New Login Architecture

SDK 13 replaces the WebView-based login screen with a Jetpack Compose UI. The key architectural change:

- **Before (SDK 12):** `LoginActivity` hosted a `WebView` managed by `OAuthWebviewHelper`. Customization meant subclassing `OAuthWebviewHelper` or `LoginActivity` and overriding WebView-related methods.
- **After (SDK 13):** `LoginActivity` hosts a Compose UI driven by `LoginViewModel`. Customization is done by:
  1. Subclassing `LoginViewModel` and overriding the methods listed below.
  2. Registering a `LoginViewModel.Factory` via `SalesforceSDKManager.getInstance().loginViewModelFactory`.

**`LoginViewModel` extension points:**

| Method / Property | Purpose |
|---|---|
| `buildAccountName(username, instanceServer)` | Customize how the account name is displayed and stored |
| `clearCookies()` | Custom cookie clearing logic before/after login |
| `var clientId: String` | Override the OAuth client ID per-session |
| `var titleText: String` | Set the title shown in the login screen top bar |
| `var topBarColor: Color` | Set the background color of the login screen top bar |

**`LoginActivity` extension points (post-login):**

| Method / Property | Purpose |
|---|---|
| `val webViewClient: WebViewClient` | Custom `WebViewClient` for the login WebView |
| `val webChromeClient: WebChromeClient` | Custom `WebChromeClient` for the login WebView |
| `val webView: WebView` | Return a custom-configured `WebView` instance |
| `onAuthFlowSuccess(userAccount: UserAccount)` | Called when OAuth completes successfully |

---

## New APIs Worth Knowing

| API | Notes |
|---|---|
| `SalesforceSDKManager.getInstance().loginViewModelFactory` | Register a `LoginViewModel.Factory` to inject a custom `LoginViewModel` subclass into the login screen. |
| `SalesforceSDKManager.getInstance().okHttpClientBuilder` (setter) | Provide a custom `OkHttpClient.Builder` to configure the SDK's HTTP client (replaces the removed `HttpAccess.okHttpClientBuilder` getter). |
| `OAuth2.LogoutReason` | Enum passed to `LogoutCompleteReceiver.onLogoutComplete(reason)`. Values indicate the cause: `USER_LOGOUT`, `TOKEN_REFRESH_FAILURE`, `BIOMETRIC_OPT_OUT`, `INACTIVITY`, etc. |
| `clearCookiesAfterLogin` | `SalesforceSDKManager.getInstance().clearCookiesAfterLogin = true` clears WebView cookies after a successful login to prevent session leakage in multi-user scenarios. Disabled by default. |
| Biometric authentication | `BiometricAuthenticationManager` (available in SDK 12+) continues in SDK 13 with the same interface. No changes required for existing biometric integrations. |
| WebSocket support | SDK 13 adds `SalesforceWebSocketClient` for streaming API connections. Not a replacement for any removed API — purely additive. |
| Token migration (OAEP) | On first launch after upgrading from SDK 11 or SDK 12, stored OAuth tokens are automatically re-encrypted using OAEP padding if they were stored with PKCS1v15. This is transparent and requires no code changes, but may cause a brief delay on first post-upgrade launch. |

---

## Version Bumps

| Component | SDK 12.x value | SDK 13.2.1 value |
|---|---|---|
| `minSdk` | 26 (Android 8.0) | 28 (Android 9) |
| `compileSdk` | 34 | 36 |
| `targetSdk` | 34 | 36 |
| Android Gradle Plugin (AGP) | 8.6.1 | 8.12.0 |
| Gradle wrapper | 8.7 | 8.14.3 |
| Default REST API version | `v60.0` | `v66.0` |
| Kotlin | 1.9.24 | 1.9.24 (unchanged through 13.2.1; Kotlin 2.0 becomes required in SDK 14.0) |
