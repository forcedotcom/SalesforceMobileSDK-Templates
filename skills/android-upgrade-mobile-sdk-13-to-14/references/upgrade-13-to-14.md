# Android — Upgrade Salesforce Mobile SDK 13.x to 14.0

Step-by-step guide for upgrading an existing Android Kotlin app from SDK 13.x to 14.0.

## Preconditions

- App already integrates Salesforce Mobile SDK 13.x
- App is written in Kotlin (not Java)
- Android Studio Meerkat (2024.3) or later (required for AGP 9.1.1 support)
- JDK 17+

## Inputs

| Variable | Example | Notes |
|---|---|---|
| `<AppModule>` | `app` | Gradle module name for the app (usually `app`) |
| `<PackageName>` | `com.example.myapp` | Application package / `applicationId` |
| `<CallbackUrl>` | `myapp://success/done` | OAuth callback URL registered in the Connected App |

---

## Step 0 — Detect project shape

Before making any changes, determine:

1. **Dependency style** — does the project use a version catalog (`libs.versions.toml`) or inline versions in `app/build.gradle.kts`?
2. **SDK libraries in use** — search for `com.salesforce.mobilesdk:` across all `*.gradle.kts` and `*.toml` files. Note which artifacts appear: `SalesforceSDK`, `SmartStore`, `MobileSync`. Only update artifacts that are already present.
3. **`buildSrc/` directory** — if present, check `buildSrc/build.gradle.kts` for Kotlin plugin or stdlib references that must be removed.

---

## Step 1 — Bump SDK dependency versions to 14.0.0-rc.1

### Option A — Version catalog (`gradle/libs.versions.toml`)

```toml
[versions]
salesforceSDK = "14.0.0-rc.1"  # was "13.2.1" — use 14.0.0-rc.1 until GA is published

[libraries]
# Only include entries that already exist in the project — do not add new ones
salesforce-sdk = { module = "com.salesforce.mobilesdk:SalesforceSDK", version.ref = "salesforceSDK" }
salesforce-smartstore = { module = "com.salesforce.mobilesdk:SmartStore", version.ref = "salesforceSDK" }
salesforce-mobilesync = { module = "com.salesforce.mobilesdk:MobileSync", version.ref = "salesforceSDK" }
```

### Option B — Inline versions in `app/build.gradle.kts`

> **Release candidate note:** The current published 14.0 artifact is the release candidate `14.0.0-rc.1`, not `14.0.0`. Use `14.0.0-rc.1` until the GA release is published; plain `14.0.0` returns a 404 from Maven Central.

```kotlin
dependencies {
    implementation("com.salesforce.mobilesdk:SalesforceSDK:14.0.0-rc.1")
    implementation("com.salesforce.mobilesdk:SmartStore:14.0.0-rc.1")      // only if present in project
    implementation("com.salesforce.mobilesdk:MobileSync:14.0.0-rc.1")      // only if present in project
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

## Step 8 — Add LoginActivity intent-filter to AndroidManifest.xml

SDK 14.0 uses Chrome Custom Tabs for browser-based OAuth. Without the `intent-filter`, the OAuth redirect after login never returns to the app.

Parse the app's callback URL to derive the three data attributes:

```
Given callback URL: myapp://success/done
  scheme = "myapp"       (everything before "://")
  host   = "success"     (segment after "://" up to the first "/")
  path   = "/done"       (remainder, with leading "/"; omit android:path if no path segment)
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

> **If the callback URL is not known:** check `bootconfig.xml` (usually at `app/src/main/res/raw/bootconfig.xml`) for the `oauthRedirectURI` field, or look up the Connected App definition in Salesforce Setup.

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

**Option B — Migrate existing users to DPoP without requiring re-login:**

```kotlin
// upgradeToDPoP is an extension on UserAccountManager.
// onSuccess receives the upgraded UserAccount; onFailure receives (error, errorDesc, throwable).
UserAccountManager.getInstance().upgradeToDPoP(
    userAccount,
    onSuccess = { account -> /* handle success */ },
    onFailure = { error, errorDesc, e -> /* handle failure */ }
)
```

> **Required for all apps.** Even apps that did not previously use DPoP must handle this default. Configure the Connected App for DPoP in Salesforce Setup, or explicitly opt out with Option A until ready.

---

## Step 11 — Handle Advanced Authentication now on by default (conditional)

Browser-based login via Chrome Custom Tab is now the default for all hosts in SDK 14.0. In SDK 13 it was opt-in per-host.

If the app relies on in-app WebView login and is not ready for browser-based OAuth:

```kotlin
// In Application.onCreate(), after SalesforceSDKManager.initNative(...)
SalesforceSDKManager.getInstance().forceAdvancedAuthentication = false
```

> **Most apps should leave this at the default (`true`)** and instead ensure the `LoginActivity` `intent-filter` (Step 8) is configured correctly.
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

```bash
./gradlew assembleDebug
```

Expected output: `BUILD SUCCESSFUL`

If there are remaining compilation errors, consult [Breaking Changes](breaking-changes.md) for the full list of removed/changed symbols, and [Troubleshooting](troubleshooting.md) for common failure patterns.

---

> **SDK 14.0 defaults:** DPoP and Advanced Authentication (browser-based login) are both enabled by default. The first launch after upgrade will use Chrome Custom Tab for login. Ensure the app's Connected App is configured for browser-based OAuth and that the `LoginActivity` `intent-filter` is in place before testing on a device.

---

## Next

- [Breaking Changes](breaking-changes.md) — complete list of removed classes, removed methods, and changed signatures
- [Troubleshooting](troubleshooting.md) — symptom-first guide for build and runtime errors
