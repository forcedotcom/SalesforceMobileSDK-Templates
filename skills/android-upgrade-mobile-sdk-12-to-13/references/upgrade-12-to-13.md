# Android — Upgrade Salesforce Mobile SDK 12.x to 13.2.1

Step-by-step guide for upgrading an existing Android app from SDK 12.x to 13.2.1.

## Preconditions

- App already integrates Salesforce Mobile SDK 12.x
- Android Studio Ladybug (2024.2.1) or later (required for AGP 8.12.0 support)
- JDK 17+

## Inputs

| Variable | Example | Notes |
|---|---|---|
| `<AppModule>` | `app` | Gradle module name for the app (usually `app`) |
| `<PackageName>` | `com.example.myapp` | Application package / `applicationId` |

---

## Step 0 — Detect project shape

Before making any changes, determine:

1. **Dependency style** — does the project use a version catalog (`libs.versions.toml`) or inline versions in `app/build.gradle.kts` / `app/build.gradle`?
2. **SDK libraries in use** — search for `com.salesforce.mobilesdk:` across all `*.gradle.kts` and `*.toml` files. Note which artifacts appear: `SalesforceSDK`, `SmartStore`, `MobileSync`. Only update artifacts that are already present.
3. **Login customization** — search for references to `OAuthWebviewHelper`, `OAuthWebviewHelperEvents`, `LoginOptions`, `LogoutCompleteReceiver`, `SalesforceListActivity`, `ServerPickerActivity`, `SalesforceAnalyticsManager`, and `QrCodeEnabledLoginActivity`. These all require source changes in addition to the version bump.

---

## Step 1 — Bump SDK dependency versions

### Option A — Version catalog (`gradle/libs.versions.toml`)

```toml
[versions]
salesforceSDK = "13.2.1"  # was "12.x.x"

[libraries]
# Only include entries that already exist in the project — do not add new ones
salesforce-sdk = { module = "com.salesforce.mobilesdk:SalesforceSDK", version.ref = "salesforceSDK" }
salesforce-smartstore = { module = "com.salesforce.mobilesdk:SmartStore", version.ref = "salesforceSDK" }
salesforce-mobilesync = { module = "com.salesforce.mobilesdk:MobileSync", version.ref = "salesforceSDK" }
```

### Option B — Inline versions in `app/build.gradle.kts`

```kotlin
dependencies {
    implementation("com.salesforce.mobilesdk:SalesforceSDK:13.2.1")
    implementation("com.salesforce.mobilesdk:SmartStore:13.2.1")      // only if present in project
    implementation("com.salesforce.mobilesdk:MobileSync:13.2.1")      // only if present in project
}
```

### Option C — Groovy DSL `app/build.gradle`

```groovy
dependencies {
    implementation 'com.salesforce.mobilesdk:SalesforceSDK:13.2.1'
    implementation 'com.salesforce.mobilesdk:SmartStore:13.2.1'       // only if present in project
    implementation 'com.salesforce.mobilesdk:MobileSync:13.2.1'       // only if present in project
}
```

---

## Step 2 — Raise Android API levels

Edit `app/build.gradle.kts` (or `app/build.gradle` for Groovy DSL):

```kotlin
android {
    compileSdk = 36          // raise to 36 (was 34 or 35 depending on template vintage)

    defaultConfig {
        minSdk = 28           // raise to 28 (was 26); see note below
        targetSdk = 36        // raise to 36 (was 34 or 35)
    }
}
```

> **NOTE:** Setting `minSdk = 28` drops support for devices running Android 8.0 (Oreo, API 26) and 8.1 (API 27). Before applying this change, confirm the app's Play Store minimum version policy allows dropping Android 8.x. If the project declares `minSdk` in `gradle.properties` or `libs.versions.toml`, update it there instead.

**`gradle.properties`** — if the file contains `cdvMinSdkVersion` (present in forceios/forcedroid generated projects), update it too:

```properties
# Before
cdvMinSdkVersion=24
# After
cdvMinSdkVersion=28
```

---

## Step 3 — Upgrade Gradle wrapper and AGP

**`gradle/wrapper/gradle-wrapper.properties`** — update the distribution URL:

```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.14.3-bin.zip
```

**Root `build.gradle.kts`** — update the AGP version:

```kotlin
plugins {
    id("com.android.application") version "8.12.0" apply false
    id("com.android.library") version "8.12.0" apply false
}
```

If the project uses a `libs.versions.toml` plugin catalog, update the AGP entry there:

```toml
[versions]
agp = "8.12.0"
```

**`buildSrc/build.gradle.kts`** — if the project has a `buildSrc/` module that declares AGP, update it:

```kotlin
// buildSrc/build.gradle.kts — update if present
implementation("com.android.tools.build:gradle:8.12.0")          // was 8.6.1
```

> **Kotlin stays on 1.9.24 for SDK 13.2.1** — do not bump your app's Kotlin version as part of this upgrade. Kotlin 2.0 only becomes a requirement in SDK 14.0; defer that bump until you upgrade to 14.0.

> **AGP 8.12.0 requires Gradle 8.7 or higher.** Gradle 8.14.3 satisfies this. If you see a Gradle sync error about incompatible versions, verify `gradle-wrapper.properties` was saved correctly and re-sync.

---

## Step 4 — Fix compilation errors from removed APIs

Sync Gradle after Steps 1–3. If there are compilation errors, apply the fixes below for each error that appears. Not all fixes will apply to every project — only fix what the compiler flags.

> **Note for Java projects:** All code samples below are Kotlin. For Java apps, apply the equivalent Java syntax: use `new ClassName(...)` constructors, `@Override` annotations instead of `override`, and Java type signatures (e.g. `OAuth2.LogoutReason` as a Java enum parameter type).

### 4a. Remove `ClientManager.LoginOptions` usage

`LoginOptions` is removed. The SDK now reads OAuth configuration directly from `bootconfig.xml` resources.

```kotlin
// BEFORE (SDK 12) — no longer compiles
val loginOptions = ClientManager.LoginOptions(
    loginUrl, oauthCallbackUrl, oauthClientId, oauthScopes
)
val clientManager = ClientManager(this, accountType, loginOptions, true)

// AFTER (SDK 13) — loginOptions parameter removed
val clientManager = ClientManager(this, accountType, true)
```

Also remove any references to:

```kotlin
SalesforceSDKManager.getInstance().loginOptions       // property removed
SalesforceSDKManager.getInstance().getLoginOptions()  // method removed
```

### 4b. Remove `OAuthWebviewHelper` and `OAuthWebviewHelperEvents`

Both classes are deleted in SDK 13. If the app subclassed `OAuthWebviewHelper` or implemented `OAuthWebviewHelperEvents`, replace with the `LoginViewModel` approach (see Step 5).

Remove any overrides of these `LoginActivity` methods — they no longer exist:

```kotlin
// Remove these overrides:
override fun getOAuthWebviewHelper(...): OAuthWebviewHelper { ... }
override fun onPickServerClick(v: View?) { ... }
override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) { ... }
```

### 4c. Fix `LogoutCompleteReceiver` method signature

The `onLogoutComplete()` override now requires a `reason` parameter.

```kotlin
// BEFORE (SDK 12) — missing parameter
class MyLogoutReceiver : LogoutCompleteReceiver() {
    override fun onLogoutComplete() {
        // cleanup
    }
}

// AFTER (SDK 13) — reason parameter required
class MyLogoutReceiver : LogoutCompleteReceiver() {
    override fun onLogoutComplete(reason: OAuth2.LogoutReason) {
        // cleanup
    }
}
```

### 4d. Remove `SalesforceListActivity` subclass

`SalesforceListActivity` is removed. Migrate to `SalesforceActivity` with a `RecyclerView` or `ListFragment` in the layout.

```kotlin
// BEFORE — remove or reparent
class MyListActivity : SalesforceListActivity() { ... }

// AFTER — extend SalesforceActivity; manage list UI in the layout
class MyListActivity : SalesforceActivity() { ... }
```

### 4e. Fix `SalesforceAnalyticsManager` renamed methods

```kotlin
// BEFORE (SDK 12)
SalesforceAnalyticsManager.getInstance(account).setPublishFrequencyInHours(24)
val freq = SalesforceAnalyticsManager.getInstance(account).publishFrequencyInHours

// AFTER (SDK 13)
SalesforceAnalyticsManager.getInstance(account).setPublishPeriodicallyFrequencyHours(24)
val freq = SalesforceAnalyticsManager.getInstance(account).publishPeriodicallyFrequencyHours
```

### 4f. Remove `ServerPickerActivity` explicit launches

`ServerPickerActivity` is removed. The server picker is built into the login Compose UI and no longer needs to be launched explicitly.

```kotlin
// BEFORE — remove these lines
val intent = Intent(this, ServerPickerActivity::class.java)
startActivity(intent)
```

Also remove `ServerPickerActivity` from `AndroidManifest.xml` if it appears there:

```xml
<!-- Remove this entry if present -->
<activity android:name="com.salesforce.androidsdk.ui.ServerPickerActivity" ... />
```

### 4g. Remove `OAuth2` deleted methods (advanced / hybrid cases)

```kotlin
// Remove any calls to these — they no longer exist:
OAuth2.getFrontdoorUrl(url, accessToken, instanceURL, additionalParams)
OAuth2.revokeRefreshToken(httpAccessor, loginServer, refreshToken)
```

### 4h. Remove `HttpAccess.getOkHttpClientBuilder()`

```kotlin
// BEFORE — remove
val builder = HttpAccess.DEFAULT.okHttpClientBuilder

// AFTER — use the new setter on SalesforceSDKManager if OkHttp customization is needed
SalesforceSDKManager.getInstance().okHttpClientBuilder = myCustomBuilder
```

### 4i. Fix `UserAccountManager.switchToNewUser(jwt, url)` (if used)

```kotlin
// BEFORE (SDK 12)
userAccountManager.switchToNewUser(jwt, url)

// AFTER (SDK 13) — jwt and url parameters removed
userAccountManager.switchToNewUser()
```

### 4j. Migrate `QrCodeEnabledLoginActivity` (if present)

If the app includes a `QrCodeEnabledLoginActivity` subclass (generated by `forcedroid create` and kept for QR code login), the SDK 12 pattern used `findViewById<Button>` to show a button from a layout XML and passed a `View?` parameter to the tap handler. SDK 13 replaces this with `LoginViewModel.BottomBarButton` — the button is added programmatically via the Compose login UI.

**Add Compose runtime dependency to `app/build.gradle.kts`:**

`LoginViewModel.BottomBarButton` uses `androidx.compose.runtime.MutableState` internally. Apps generated from SDK 12 do not include the Compose runtime as a direct dependency. Add it explicitly:

```kotlin
dependencies {
    // ... existing deps ...
    implementation("androidx.compose.runtime:runtime-android:1.8.2")
}
```

**Imports to remove:**
```kotlin
// Remove these SDK-12-era imports:
import android.net.Uri.parse
import android.view.View
import android.view.View.VISIBLE
import android.widget.Button
import com.salesforce.<apppackage>.R.id.qr_code_login_button
```

**Imports to add:**
```kotlin
import androidx.core.net.toUri
import com.salesforce.androidsdk.ui.LoginViewModel.BottomBarButton
import com.salesforce.<apppackage>.R.string.login_with_qr_code  // adjust package to match app
```

**`onCreate` — replace the `findViewById` call with `BottomBarButton`:**

```kotlin
// BEFORE (SDK 12) — inside onCreate, after super.onCreate(savedInstanceState)
findViewById<Button>(qr_code_login_button).visibility = VISIBLE

// AFTER (SDK 13) — replace with:
viewModel.customBottomBarButton.value = BottomBarButton(getString(login_with_qr_code)) {
    onLoginWithQrCodeTapped()
}
```

**Tap handler — change from public `View?` param to private no-arg:**

```kotlin
// BEFORE (SDK 12)
fun onLoginWithQrCodeTapped(
    @Suppress("UNUSED_PARAMETER") view: View?
) = loginWithQrCodeActivityResultLauncher.launch(...)

// AFTER (SDK 13)
private fun onLoginWithQrCodeTapped() = loginWithQrCodeActivityResultLauncher.launch(...)
```

**URI construction — replace `Uri.parse()` with `.toUri()` extension:**

```kotlin
// BEFORE (SDK 12)
data = parse(qrCodeLoginUrl)

// AFTER (SDK 13)
data = qrCodeLoginUrl.toUri()
```

---

## Step 5 — Login customization migration

Skip this step if the app does not customize the login screen.

SDK 13 replaces the WebView-based login screen with a Jetpack Compose UI driven by `LoginViewModel`. If the app previously customized login by subclassing or overriding `OAuthWebviewHelper`, migrate each customization to the corresponding `LoginViewModel` override.

| Old approach (SDK 12) | New approach (SDK 13) |
|---|---|
| `OAuthWebviewHelper.buildAccountName(...)` | Override `buildAccountName(...)` in `LoginViewModel` subclass |
| `OAuthWebviewHelper.clearCookies()` | Override `clearCookies()` in `LoginViewModel` subclass |
| `OAuthWebviewHelper.val oAuthClientId` | Set `var clientId` in `LoginViewModel` subclass |
| `OAuthWebviewHelper.makeWebChromeClient()` | Override `val webChromeClient` in `LoginActivity` subclass |
| `OAuthWebviewHelper.makeWebViewClient()` | Override `val webViewClient` in `LoginActivity` subclass |
| `OAuthWebviewHelper.onAuthFlowComplete(...)` | Override `onAuthFlowSuccess(userAccount)` in `LoginActivity` subclass |
| `LoginActivity` action bar title / color | Set `var titleText` / `var topBarColor` in `LoginViewModel` subclass |
| `LoginActivity.findViewById<WebView>(...)` | Override `val webView: WebView` in `LoginActivity` subclass |

Register the custom `LoginViewModel` factory early in `Application.onCreate()` after `initNative(...)`:

```kotlin
// In MainApplication.onCreate(), after SalesforceSDKManager.initNative(...)
SalesforceSDKManager.getInstance().loginViewModelFactory = LoginViewModel.Factory {
    MyCustomLoginViewModel(/* dependencies */)
}
```

---

## Step 6 — Verify `account_type` string resource

The SDK logs a warning if `account_type` is not overridden with a value unique to the app. Confirm `app/src/main/res/values/strings.xml` (or equivalent) contains a unique entry:

```xml
<!-- Must be unique to this app — do not use the SDK default -->
<string name="account_type">com.example.myapp.login</string>
```

---

## Step 7 — Manifest changes

If the app uses custom-tab / browser-based authentication, update `LoginActivity`'s launch mode to `singleTask`:

```xml
<activity
    android:name="com.salesforce.androidsdk.ui.LoginActivity"
    android:launchMode="singleTask"
    android:exported="true" />
```

Remove the `USE_FINGERPRINT` permission if present — it is removed in SDK 13 in favor of the `USE_BIOMETRIC` permission, which is declared by the SDK's own manifest:

```xml
<!-- Remove if present — SDK 13 drops USE_FINGERPRINT -->
<uses-permission android:name="android.permission.USE_FINGERPRINT" />
```

---

## Step 8 — ProGuard / R8 cleanup (if minification is enabled)

SDK 13.2.0+ ships `consumer-rules.pro` files for `SalesforceSDK`, `SmartStore`, and `MobileSync`. These are automatically applied when the SDK AARs are consumed.

Review the app's ProGuard file — this is typically `app/proguard-rules.pro` but may be named `app/proguard.cfg` in older-style generated projects:

- Remove any keep rules that were written as workarounds for SDK classes — they are now covered by consumer rules.
- Keep any rules that apply to the app's own code.

Test a release build to confirm no runtime `ClassNotFoundException`:

```bash
./gradlew assembleRelease
```

---

## Step 9 — Build verification

```bash
./gradlew assembleDebug
```

Expected output: `BUILD SUCCESSFUL`

If there are remaining compilation errors, consult [API Changes Reference](api-changes.md) for the full list of removed/changed symbols, and [Troubleshooting](troubleshooting.md) for common failure patterns.

---

## Step 10 — Runtime smoke test

1. Launch the app on a device or emulator running API 28 or higher (Android 9+).
2. Verify the Salesforce login screen appears (it is Compose-based in SDK 13 — the UI looks different from SDK 12's WebView login).
3. Complete the OAuth login flow.
4. Verify the main app screen loads and core functionality works.
5. If the app uses SmartStore or MobileSync, verify that existing data is accessible after upgrade (token migration is automatic; soup schema is preserved).

---

## Next

- [API Changes Reference](api-changes.md) — complete list of removed classes, removed methods, and changed signatures
- [Troubleshooting](troubleshooting.md) — symptom-first guide for build and runtime errors
