# Android — Upgrade Salesforce Mobile SDK 13.x to 14.0

Step-by-step guide for upgrading an existing Android Kotlin app from SDK 13.x to 14.0. Covers the AGP 8→9 migration (plugin removal), minSdk/compileSdk/targetSdk bump, Gradle 9.4.1 upgrade, Kotlin plugin removal, `account_type` enforcement, manifest `LoginActivity` intent-filter, DPoP/AA defaults, the biometric API change, the `logout()` signature, and the `ClientManager` redesign. Does NOT cover React Native, Hybrid/Cordova, or Java apps.

**Still on 12.x?** Run [`upgrade-12-to-13.md`](upgrade-12-to-13.md) first and get a green build, then come back here.

## Preconditions

- App already integrates Salesforce Mobile SDK 13.x
- App is written in Kotlin (not Java)
- Android Studio Meerkat (2024.3) or later (required for AGP 9.1.1 support)
- JDK 17+

## Invariants

These hold regardless of the project shape (version catalog or inline dependencies):

- **Do NOT recreate the Android project from scratch.** Preserve all hand-maintained module configuration, signing config, and build variants.
- **Do NOT rename or move app source files.** Only SDK version identifiers and removed/renamed APIs change.
- **Do NOT change `applicationId`, signing config, or non-SDK build settings** unless the upgrade explicitly requires it.
- **`minSdk` MUST be raised to 31.** SDK 14.0 requires Android 12 (API 31) as the minimum. This drops support for Android 9, 10, and 11 — confirm the app's Play Store minimum version policy before applying.
- **`compileSdk` and `targetSdk` must be at least 36.** The SDK 14.0 library itself targets `compileSdk = 36` (`libs/SalesforceSDK/build.gradle.kts` has an explicit `// TODO: MSDK 14 will remain on 36. The next increment will be in MSDK 15.`), so an app on 36 is fully compatible — this matches the "Create New App" scenario, which generates apps at 36. `37` also builds but is not required; it comes only from sample apps. Do not force a bump to 37.
- **Gradle wrapper MUST be updated to 9.4.1; AGP MUST be updated to 9.1.1.**
- **Reconcile the Kotlin plugin with the `android.builtInKotlin` flag.** Two valid configurations exist: with AGP built-in Kotlin active (`android.builtInKotlin` true/unset) remove `id("org.jetbrains.kotlin.android")` from `plugins { }`, since leaving it in conflicts; or set `android.builtInKotlin=false` in `gradle.properties` and keep the plugin. (The Mobile SDK library itself sets `builtInKotlin=false`, but that is the library's internal build choice and does **not** propagate to consuming apps via Maven — a consuming app on AGP 9 gets built-in Kotlin by default, so prefer Path A and choose Path B only deliberately.) Do not remove the plugin without confirming the flag. See Step 4 below.
- **Build target**: `./gradlew assembleDebug` from the project root unless there is reason to use a different variant.

When the SDK API in this guide disagrees with reality, the upstream Kotlin source in the release wins. Release: <https://github.com/forcedotcom/SalesforceMobileSDK-Android/releases/tag/v14.0.1-rc.1>

## Inputs

| Variable | Example | Notes |
|---|---|---|
| `<AppModule>` | `app` | Gradle module name for the app (usually `app`) |
| `<PackageName>` | `com.example.myapp` | Application package / `applicationId` |
| `<CallbackUrl>` | `myapp://success/done` | OAuth callback URL registered in the Connected App. This is the app's `oauthRedirectURI` — locate it in Step 0 and classify it before Step 8. |

---

## Step 0 — Detect project shape

Before making any changes, determine:

1. **Dependency style** — does the project use a version catalog (`libs.versions.toml`) or inline versions in `app/build.gradle.kts`?
2. **SDK libraries in use** — search for `com.salesforce.mobilesdk:` across all `*.gradle.kts` and `*.toml` files. Note which artifacts appear: `SalesforceSDK`, `SmartStore`, `MobileSync`. Only update artifacts that are already present.
3. **`buildSrc/` directory** — if present, check `buildSrc/build.gradle.kts` for Kotlin plugin or stdlib references that must be removed.
4. **OAuth callback URL (`oauthRedirectURI`)** — SDK 14 moves login to a Chrome Custom Tab, and login only works if the browser can hand the callback URL back to the app. Find every place the value is defined; it is not always in `bootconfig.xml`:

   ```bash
   grep -rn "oauthRedirectURI" --include='*.xml' --include='*.kts' --include='*.gradle' --include='*.properties' .
   ```

   Check `res/raw/bootconfig.xml`, `res/values/*.xml`, and `resValue("string", "oauthRedirectURI", ...)` in `build.gradle(.kts)` — including per-flavor or per-build-type overrides and values injected from `gradle.properties` / CI. Record each value and classify it with the table in Step 8. **Do this before editing anything:** if the callback is an `https` URL on a host the app does not own, browser login cannot work without a Connected App change (Step 8, row C), and the user must decide how to proceed.

---

## Step 1 — Bump SDK dependency versions to 14.0.1-rc.1

### Option A — Version catalog (`gradle/libs.versions.toml`)

```toml
[versions]
salesforceSDK = "14.0.1-rc.1"  # was "13.2.1"

[libraries]
# Only include entries that already exist in the project — do not add new ones
salesforce-sdk = { module = "com.salesforce.mobilesdk:SalesforceSDK", version.ref = "salesforceSDK" }
salesforce-smartstore = { module = "com.salesforce.mobilesdk:SmartStore", version.ref = "salesforceSDK" }
salesforce-mobilesync = { module = "com.salesforce.mobilesdk:MobileSync", version.ref = "salesforceSDK" }
```

The version key name varies by project (e.g. `mobileSdk`, `salesforceSdk`), and some projects use a rich version such as `{ strictly = "13.1.3" }`. Find the key by searching for the current 13.x version string rather than assuming `salesforceSDK`. Keep any `strictly` constraint and change only the version inside it.

Use version `14.0.1-rc.1` for every SDK dependency version.

### Option B — Inline versions in `app/build.gradle.kts`

```kotlin
dependencies {
    implementation("com.salesforce.mobilesdk:SalesforceSDK:14.0.1-rc.1")
    implementation("com.salesforce.mobilesdk:SmartStore:14.0.1-rc.1")      // only if present in project
    implementation("com.salesforce.mobilesdk:MobileSync:14.0.1-rc.1")      // only if present in project
}
```

---

## Step 2 — Raise Android minSdk

Edit `app/build.gradle.kts`:

```kotlin
android {
    defaultConfig {
        minSdk = 31           // raise to 31 (was 28); see note below
    }
}
```

> **NOTE:** Setting `minSdk = 31` drops support for devices running Android 9 (API 28), 10 (API 29), and 11 (API 30). Before applying this change, confirm the app's Play Store minimum version policy allows dropping Android 9–11. If the project declares `minSdk` in `gradle.properties` or `libs.versions.toml`, update it there instead.

---

## Step 3 — Update build toolchain

**`gradle/wrapper/gradle-wrapper.properties`** — update the distribution URL:

```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-9.4.1-bin.zip
```

**Root `build.gradle.kts`** — update the AGP version. Look at the file to determine which style it uses:

**Style 1 — `buildscript {}` block** (used by `forcedroid`-generated apps including all `MobileSyncExplorer*` and `AndroidNativeKotlin*` templates):

```kotlin
buildscript {
    dependencies {
        classpath("com.android.tools.build:gradle:9.1.1")   // update to 9.1.1
    }
}
```

**Style 2 — `plugins {}` block** (newer Gradle project structure):

```kotlin
plugins {
    id("com.android.application") version "9.1.1" apply false
    id("com.android.library") version "9.1.1" apply false
}
```

If the project uses a `libs.versions.toml` plugin catalog, update the AGP entry there:

```toml
[versions]
agp = "9.1.1"
```

**`buildSrc/build.gradle.kts`** — if the project has a `buildSrc/` module:

- Remove `implementation("org.jetbrains.kotlin:kotlin-stdlib:...")` if present.
- Remove `gradlePluginPortal()` from the `repositories {}` block if it was only there for the Kotlin plugin.
- For `kotlin-gradle-plugin`: what to do depends on whether the app uses Compose (see below).

```kotlin
// Remove these lines from buildSrc/build.gradle.kts if NOT a Compose app:
implementation("org.jetbrains.kotlin:kotlin-gradle-plugin:...")   // REMOVE for non-Compose apps
implementation("org.jetbrains.kotlin:kotlin-stdlib:...")          // REMOVE always
```

**If the app uses Jetpack Compose** (`buildFeatures { compose = true }` in `app/build.gradle.kts`): Kotlin 2.0 requires the Compose Compiler plugin to be explicitly applied. The `composeOptions { kotlinCompilerExtensionVersion }` block is no longer the mechanism in Kotlin 2.0+. The `kotlin-gradle-plugin` must be **kept** (not removed) and **bumped to 2.3.20** in both the root buildscript and `buildSrc`.

For **`buildscript {}`-style** projects (forcedroid templates):

1. **Root `build.gradle.kts`** — keep and bump the Kotlin classpath entry:

```kotlin
buildscript {
    dependencies {
        classpath("com.android.tools.build:gradle:9.1.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.3.20")  // KEEP, bump to 2.3.20
    }
}
```

2. **`buildSrc/build.gradle.kts`** — keep and bump (do NOT remove):

```kotlin
dependencies {
    implementation("com.android.tools.build:gradle:9.1.1")
    implementation("org.jetbrains.kotlin:kotlin-gradle-plugin:2.3.20")  // KEEP, bump to 2.3.20
}
```

3. **`app/build.gradle.kts`** — add the Compose Compiler plugin to the plugins block:

```kotlin
plugins {
    android                                                    // existing
    kotlin("plugin.compose") version "2.3.20"                 // ADD for Compose
}
```

4. Remove the `composeOptions { kotlinCompilerExtensionVersion = "..." }` block from `app/build.gradle.kts` — it is no longer used with Kotlin 2.0+.

---

## Step 4 — Decide how Kotlin is applied (`android.builtInKotlin`)

AGP 9.0 can supply Kotlin support natively. Whether you keep or remove the explicit Kotlin Android plugin depends on the `android.builtInKotlin` property in `gradle.properties`. Pick **one** of the two paths below — do not mix them.

The plugin may appear in any of these forms — check for all of them:

```kotlin
id("org.jetbrains.kotlin.android")   // explicit ID form
kotlin("android")                     // Kotlin DSL shorthand
`kotlin-android`                      // backtick alias (used in forcedroid templates)
```

### Path A — AGP built-in Kotlin (`android.builtInKotlin=true`, the AGP 9 default)

When built-in Kotlin is active, AGP applies Kotlin automatically and the explicit plugin conflicts, so remove it.

**`app/build.gradle.kts`:**

```kotlin
// BEFORE — conflicts with built-in Kotlin
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")   // REMOVE — or `kotlin-android` / kotlin("android")
}

// AFTER
plugins {
    id("com.android.application")
}
```

> **Build error if you leave the plugin in while built-in Kotlin is active:** `"The 'org.jetbrains.kotlin.android' plugin is no longer required for Kotlin support since AGP 9.0."`

### Path B — opt out of built-in Kotlin and keep the plugin

Set `android.builtInKotlin=false` in `gradle.properties` and keep the explicit Kotlin plugin. This is what the Mobile SDK's own build does (its `gradle.properties` sets `android.builtInKotlin=false` and every module keeps the `kotlin-android` plugin).

```properties
# gradle.properties
android.builtInKotlin=false
```

```kotlin
// app/build.gradle.kts — plugin is REQUIRED because built-in Kotlin is disabled
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}
```

### Root `build.gradle.kts` classpath

Remove `classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:...")` from the root `dependencies { }` **only if the app does NOT use Compose and you chose Path A**. For Compose apps, the Kotlin plugin classpath is still needed (see Step 3):

```kotlin
// Path A, NON-Compose apps only: remove if present at root level
dependencies {
    classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:...")   // REMOVE only for non-Compose Path A apps
}
```

---

## Step 5 — Remove Kotlin JVM target blocks and add compileOptions

AGP 9 manages Kotlin compilation through standard Java compile options. Remove whichever of these Kotlin JVM target blocks is present:

```kotlin
// BEFORE — block style 1: remove if present
kotlin {
    jvmToolchain(17)
}

// BEFORE — block style 2: remove if present (used in forcedroid MobileSyncExplorer templates)
kotlinOptions {
    jvmTarget = "17"
}
```

After removing, add `compileOptions` inside the `android { }` block if not already present:

```kotlin
// AFTER — add inside android { } block
android {
    // ... existing android config ...

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
```

Also remove the top-level `repositories { google(); mavenCentral() }` block from `app/build.gradle.kts` if present. Repository declarations belong in `settings.gradle.kts`, not module build files:

```kotlin
// Remove from app/build.gradle.kts if present — belongs in settings.gradle.kts
repositories {
    google()
    mavenCentral()
}
```

---

## Step 6 — Fix buildFeatures and sourceSets

**`app/build.gradle.kts`** — inside the `android { }` block, remove legacy feature flags that AGP 9 no longer supports:

```kotlin
// BEFORE — remove these entries from buildFeatures { }
buildFeatures {
    renderScript = true   // REMOVE — RenderScript support removed in AGP 9
    aidl = true           // REMOVE — only remove if the app does not use AIDL directly
    buildConfig = true    // KEEP if present
}

// AFTER — only keep what the app actually uses
buildFeatures {
    buildConfig = true    // keep if the app reads BuildConfig fields
}
```

Also remove the matching `srcDirs` entries from the `sourceSets {}` block if present — AGP 9 removes the `aidl` and `renderscript` accessors, so leaving them causes a build script configuration error:

```kotlin
// BEFORE — remove these lines from sourceSets { getByName("main") { ... } }
aidl.srcDirs(arrayOf("src/main/aidl"))           // REMOVE if aidl was removed from buildFeatures
renderscript.srcDirs(arrayOf("src/main/rs"))      // REMOVE if renderScript was removed from buildFeatures

// KEEP these lines (they are valid in AGP 9)
manifest.srcFile("AndroidManifest.xml")
java.srcDirs(arrayOf("src/main/java"))
res.srcDirs(arrayOf("src/main/res"))
assets.srcDirs(arrayOf("src/main/assets"))
```

---

## Step 7 — CRITICAL: Add mandatory account_type string resource

SDK 14.0 throws `IllegalStateException` at startup if `account_type` is absent. In SDK 13.x this was only a logged warning; in SDK 14.0 it is fatal.

**`app/src/main/res/values/strings.xml`** — add:

```xml
<!-- Required by SDK 14.0 — value must be unique to this app -->
<string name="account_type"><PackageName>.salesforce.account</string>
```

Replace `<PackageName>` with the app's `applicationId`. Example: `com.example.myapp` → `com.example.myapp.salesforce.account`.

If the file already contains an `account_type` entry, verify it uses the app's `applicationId` (not the SDK default) and leave it unchanged.

---

## Step 8 — Make the OAuth callback routable (LoginActivity intent-filter)

SDK 14.0 uses Chrome Custom Tabs for browser-based OAuth. After the user signs in, the browser navigates to the callback URL, and Android must route that URL to the app's `LoginActivity`. In SDK 13 the in-app WebView intercepted the redirect itself, so apps that never needed an `intent-filter` (or a custom-scheme callback) break on upgrade.

Reference: [Android advanced authentication — browser-based app configuration](https://developer.salesforce.com/docs/platform/mobile-sdk/guide/auth-android-advanced.html#browser-based-app-configuration).

### 8a — Classify the callback URL (from Step 0)

| Row | Callback URL shape | Example | Will browser login work? | Action |
|---|---|---|---|---|
| A | Custom scheme | `myapp://success/done`, `testsfdc:///mobilesdk/detect/oauth/done` | Yes, once the `intent-filter` is added | Go to 8b. |
| B | `https` on a domain the app owner controls | `https://auth.example.com/oauth/done` | Only with verified Android App Links | Go to 8b, add `android:autoVerify="true"` to the `<intent-filter>`, and publish `https://<host>/.well-known/assetlinks.json` that lists the app's package name and signing-cert SHA-256. Without verification, Chrome opens the URL itself instead of handing it to the app. |
| C | `https` on a host the app does **not** control | `https://mobileauth.salesforce.com/oauth/done`, `https://login.salesforce.com/services/oauth2/success` | **No.** Android cannot verify App Links for a host you don't control, so the browser shows the page itself. For `mobileauth.salesforce.com` this is a blank page reading "Please contact support if you see this page". | Do **not** add an `intent-filter` for this host — it has no effect. **Stop and ask the user** which row C option to take (below). |

Row C options:

1. **Recommended — add a routable callback to the existing Connected App / External Client App.** Either a custom scheme (e.g. `<applicationId>://oauth/done`) or an `https` URL on a domain the app owner controls (then follow row B). Keep the old callback registered during rollout, so builds that are already shipped keep working. Update every `oauthRedirectURI` found in Step 0 to match the new URL exactly, then do 8b. This is a server-side change and usually needs an org admin. The callback must match a registered Callback URL exactly, or the authorize request fails with `redirect_uri_mismatch`.
2. **Temporary — keep the current callback and opt out of browser login** with `forceAdvancedAuthentication = false` (Step 11). Use this if the Callback URLs can't be changed yet. The opt-out is removed in SDK 15, so record it as debt.

### 8b — Add the intent-filter

Parse the callback URL to derive the three data attributes:

```
Given callback URL: myapp://success/done
  scheme = "myapp"       (everything before "://")
  host   = "success"     (segment after "://" up to the first "/")
  path   = "/done"       (remainder, with leading "/"; omit android:path if no path segment)

Given callback URL with no host: testsfdc:///mobilesdk/detect/oauth/done
  scheme = "testsfdc"
  host   = "*"           (empty host → use "*", per the Mobile SDK developer guide)
  path   = "/mobilesdk/detect/oauth/done"
```

**`AndroidManifest.xml`** — add inside `<application>`:

```xml
<activity
    android:name="com.salesforce.androidsdk.ui.LoginActivity"
    android:theme="@style/SalesforceSDK"
    android:launchMode="singleTask"
    android:exported="true">
    <intent-filter>
        <data android:scheme="<scheme>"
              android:host="<host>"
              android:path="<path>" />
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.BROWSABLE" />
        <category android:name="android.intent.category.DEFAULT" />
    </intent-filter>
</activity>
```

If an `<activity android:name="com.salesforce.androidsdk.ui.LoginActivity" ...>` entry already exists in the manifest, add the `<intent-filter>` block inside it rather than creating a duplicate `<activity>` entry.

If the app has several `oauthRedirectURI` values (flavors, build types, CI overrides), add one `<data>` element per distinct scheme/host/path, or one `<intent-filter>` per value.

> **If the callback URL is not known:** run the Step 0 grep (`bootconfig.xml`, `res/values`, and `resValue` in Gradle files), or look up the Connected App definition in Salesforce Setup.

---

## Step 9 — Fix logout() signature

The `logout(Activity)` overload is removed in SDK 14.0. **This affects all apps generated from `AndroidNativeKotlinTemplate`** — the stock `MainActivity.kt` calls `logout(this)` directly.

Search for all call sites:

```bash
grep -rn '\.logout(' --include='*.kt' --include='*.java' .
```

Update each one:

```kotlin
// BEFORE (SDK 13)
SalesforceSDKManager.getInstance().logout(this)

// AFTER (SDK 14)
import com.salesforce.androidsdk.auth.OAuth2.LogoutReason

SalesforceSDKManager.getInstance().logout(frontActivity = this, reason = LogoutReason.USER_LOGOUT)
```

> **`LogoutReason.USER_LOGOUT`** is in `com.salesforce.androidsdk.auth.OAuth2.LogoutReason`. Add the import; do not use `UserAccountManager.USER_LOGOUT` (that constant does not exist and causes an "Unresolved reference" build error).
>
> The `reason` parameter defaults to `LogoutReason.UNKNOWN` (`logout(..., reason: LogoutReason = UNKNOWN)`). Passing `USER_LOGOUT` explicitly is intentional — it labels a user-initiated logout rather than the default. If you omit `reason`, the logout is recorded as `UNKNOWN`, not `USER_LOGOUT`.

Alternatively, use the `UserAccountManager` API which does not require passing an `Activity` or a reason:

```kotlin
UserAccountManager.getInstance().signoutCurrentUser()
```

---

## Step 10 — Handle DPoP now on by default (ALL apps)

DPoP (Demonstrating Proof of Possession) token binding is enabled by default in SDK 14.0. If the app's Connected App is not configured for DPoP, login will fail with a `400 invalid_grant` error.

**Option A — Temporary opt-out during development (all apps):**

```kotlin
// In Application.onCreate(), after SalesforceSDKManager.initNative(...)
SalesforceSDKManager.getInstance().useDPoP = false
```

**Option B — Migrate existing users to DPoP without requiring re-login:** follow [`add-dpop-token-migration.md`](add-dpop-token-migration.md). It needs SDK 14.0.1 or later and uses the SDK's `DpopMigrationManager` (which wraps `UserAccountManager.upgradeToDPoP`), plus a "Securing your session…" screen at launch and the failure behavior (existing session kept, retried next launch). Do it after this upgrade builds green; it is not required to finish the 13 → 14 upgrade.

> **Required for all apps.** Even apps that did not previously use DPoP must handle this default. Configure the Connected App for DPoP in Salesforce Setup, or explicitly opt out with Option A until ready.

---

## Step 11 — Handle Advanced Authentication now on by default (conditional)

Browser-based login via Chrome Custom Tab is now the default for all hosts in SDK 14.0. In SDK 13 it was opt-in per-host.

Decide from the Step 8a classification:

- **Row A, or row B with verified App Links:** leave the default (`true`). The Step 8b `intent-filter` is all that is needed.
- **Row C, and the Connected App callback can't change yet:** opt out so login returns to the in-app WebView, which intercepts the redirect itself and works with any callback URL:

```kotlin
// In Application.onCreate(), after SalesforceSDKManager.initNative(...)
// The callback (<CallbackUrl>) is an https URL the browser can't route back to this app.
// Remove once the Connected App has a custom-scheme callback (WebView login is removed in SDK 15).
@Suppress("DEPRECATION")
SalesforceSDKManager.getInstance().forceAdvancedAuthentication = false
```

> **Use the `forceAdvancedAuthentication` property, not other login flags.** `isBrowserLoginEnabled` is set from the org's My Domain configuration and its setter is not public API. Don't call `setBrowserLoginEnabled(...)` — in Kotlin it resolves to an `internal` two-argument overload and won't compile. If the org's My Domain enables browser login, the Custom Tab is used regardless of this flag, and only Step 8a row C option 1 fixes login.
>
> **`forceAdvancedAuthentication` is deprecated in 14.0** (`@Deprecated("Will be removed in 15.0 when WebView login is removed entirely.")` on `SalesforceSDKManager.forceAdvancedAuthentication`) and defaults to `true`. Setting it emits a deprecation warning. Treat the opt-out above as a temporary measure — the flag will be removed in 15.0.

---

## Step 12 — Migrate biometric authentication API (only if app uses biometric auth)

`presentOptInDialog(supportFragmentManager)` signature changed to `presentOptInDialog()` in SDK 14.0. Alternatively, replace with `mgr.automaticPresentation = true`.

```kotlin
// BEFORE (SDK 13)
BiometricAuthOptInPrompt(this).presentOptInDialog(supportFragmentManager)

// AFTER (SDK 14) — set automaticPresentation instead
private fun maybePresentBiometricOptIn() {
    val mgr = MobileSyncSDKManager.getInstance().biometricAuthenticationManager ?: return
    val deviceHasBiometrics = BiometricManager.from(this).canAuthenticate(
        BIOMETRIC_STRONG or BIOMETRIC_WEAK
    ) == BiometricManager.BIOMETRIC_SUCCESS
    if (mgr.enabled && deviceHasBiometrics) {
        mgr.automaticPresentation = true
    }
}
```

Call `maybePresentBiometricOptIn()` from `onResume(client: RestClient?)` after the user is bound — not from `onPostResume()`.

---

## Step 13 — Migrate ClientManager (only if app uses it directly)

The old `ClientManager(context, accountType, Boolean)` constructor is removed. `ClientManager` still exists — construct it with the `UserAccount` and call `peekRestClient()`.

```kotlin
// BEFORE (SDK 13)
val clientManager = ClientManager(this, accountType, true)
clientManager.getRestClient { restClient ->
    // use restClient
}

// AFTER (SDK 14) — build ClientManager for the current user and peek
val user = UserAccountManager.getInstance().currentUser
val restClient = user?.let { ClientManager(context, it).peekRestClient() }
// restClient is null if no user is authenticated
```

`peekRestClient()` is non-blocking and does not trigger login. As a convenience, `SalesforceSDKManager` also exposes a `clientManager` property for the current user:

```kotlin
val restClient = SalesforceSDKManager.getInstance().clientManager?.peekRestClient()
```

---

## Step 14 — Clean up gradle.properties

Remove legacy properties if present:

```properties
# Remove these lines from gradle.properties if present:
cdvCompileSdkVersion=...
cdvMinSdkVersion=...
android.useAndroidX=...
android.enableJetifier=...
```

These were generated by older Cordova/forcedroid tooling and have no effect in SDK 14.0 projects.

---

## Step 15 — Build verification

First confirm the Step 3 wrapper edit landed. This must print a match:

```bash
grep 'gradle-9.4.1-bin.zip' gradle/wrapper/gradle-wrapper.properties
```

If it prints nothing, go back to Step 3. Then build:

```bash
./gradlew assembleDebug
```

Expected output: `BUILD SUCCESSFUL`

If there are remaining compilation errors, consult [Breaking Changes](upgrade-13-to-14-breaking-changes.md) for the full list of removed/changed symbols, and [Troubleshooting](upgrade-13-to-14-troubleshooting.md) for common failure patterns.

## Step 16 — Verify login on a device

A green build does not prove login works — the Step 8 redirect and Step 10 DPoP defaults only fail at runtime. Test on a clean install:

```bash
adb uninstall <PackageName>            # `pm clear` is not enough: AccountManager accounts survive it
adb shell am force-stop com.android.chrome   # close any Custom Tab left over from an earlier failed attempt
./gradlew installDebug
```

Sign in, then confirm the app reaches its post-login screen. To see which flow ran, check logcat for the authorize URL. `auth_trigger=force_advanced_auth` and a `com.android.chrome/...CustomTabActivity` start mean browser login. Confirm its `redirect_uri=` matches the Step 8b `intent-filter`.

```bash
adb logcat -d | grep -oE "redirect_uri=[^&]*|auth_trigger=[^&]*|CustomTabActivity" | sort -u
```

If the Custom Tab ends on a blank Salesforce page instead of returning to the app, the callback is not routable. Go back to Step 8a.

---

> **SDK 14.0 defaults:** DPoP and Advanced Authentication (browser-based login) are both enabled by default. The first launch after upgrade will use Chrome Custom Tab for login. Before testing on a device, make sure the callback URL is routable (Step 8a) and the `LoginActivity` `intent-filter` is in place (Step 8b).

---

## Next

- [Breaking Changes](upgrade-13-to-14-breaking-changes.md) — complete list of removed classes, removed methods, and changed signatures
- [Troubleshooting](upgrade-13-to-14-troubleshooting.md) — symptom-first guide for build and runtime errors
