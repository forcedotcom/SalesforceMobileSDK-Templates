# Android — Add Mobile SDK Authentication

Wires the Salesforce Mobile SDK into an **existing** Android Kotlin app so the OAuth login screen appears on first launch and the SDK manages token persistence. This scenario adds **Salesforce Mobile SDK Core only** — OAuth login and REST. Adding SmartStore (encrypted local database) or MobileSync (cloud data sync) is covered by the dedicated scenarios; do not pre-emptively pull them in here.

> **Important — do not recreate Gradle scaffolding.** The app already has a working Gradle wrapper, `gradle.properties`, `settings.gradle.kts`, and root `build.gradle.kts`. Do **not** overwrite those files. The instructions below only modify `app/build.gradle.kts`, `AndroidManifest.xml`, and `MainActivity.kt`, and create `MainApplication.kt`, `bootconfig.xml`, `servers.xml`, and `strings.xml`. If you find yourself about to write a `gradle-wrapper.properties` or root `build.gradle.kts`, stop — you're confusing this scenario with [`create-new-app.md`](create-new-app.md).

## Inputs

| Variable | Example | Notes |
|---|---|---|
| `<AppName>` | `MyApp` | Display name |
| `<AppPackage>` | `com.example.myapp` | `applicationId` / `namespace` |
| `<PackagePath>` | `com/example/myapp` | `<AppPackage>` with `.` → `/` |
| `<ConsumerKey>` | `3MVG9...` | Connected App consumer key, or leave as the placeholder |
| `<CallbackURL>` | `myapp://oauth/callback` | OAuth redirect URI, or leave as the placeholder |
| `<LoginHost>` | `https://login.salesforce.com` | `https://test.salesforce.com` for sandboxes |

## Step 0 — Gather credentials

Before writing any files, ask the user for these three values. Without real values the app builds but the login screen cannot connect.

| Value | Where to find it |
|---|---|
| **Consumer key** | Salesforce Setup → App Manager → [Connected App] → View → Consumer Key |
| **Callback URL** | Same Connected App → Callback URLs (the URI you registered, e.g. `myapp://success/done`) |
| **Login server** | Your Salesforce org URL — `login.salesforce.com`, `test.salesforce.com`, or a My Domain URL (e.g. `myorg.my.salesforce.com`) |

Substitute the real values throughout Steps 4–6 in place of `<ConsumerKey>`, `<CallbackURL>`, and `<LoginHost>`. If any value is unavailable, leave the placeholder — the app will build but the login screen will not function.

## Step 1 — Edit `app/build.gradle.kts`

Open `app/build.gradle.kts` and edit it in place — do not delete or rewrite the file.

**Keep the existing `plugins { }` block as-is.** It applies the Android Gradle Plugin; in AGP 9.0+ Kotlin support is built in and `id("org.jetbrains.kotlin.android")` must NOT be present (applying it alongside AGP 9 throws a fatal error). Don't switch the block to a different syntax form (e.g. from `id("com.android.application")` to `alias(libs.plugins.android.application)`) — version-catalog aliases require a `libs.versions.toml` the project may not have.

Merge the additions below into the existing blocks rather than replacing them.

In `dependencies { }`, **add** the `SalesforceSDK` artifact (Mobile SDK Core) via Maven Central. Don't remove existing dependencies the app already declares:

```kotlin
dependencies {
    implementation("com.salesforce.mobilesdk:SalesforceSDK:14.0.0-rc.2")
    // Required: SalesforceActivity (used in Step 7) extends AppCompatActivity.
    // Keep the existing appcompat dependency if your app already has it, or add:
    implementation("androidx.appcompat:appcompat:1.7.0")
}
```

In `android { }`, ensure the following are configured (merge with the existing block — don't replace it):

```kotlin
android {
    compileSdk = 36

    defaultConfig {
        minSdk = 31
        targetSdk = 36
    }

    buildFeatures {
        aidl = true
        renderScript = true
        buildConfig = true
    }

    packaging {
        resources {
            excludes += setOf(
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/DEPENDENCIES",
                "META-INF/NOTICE"
            )
        }
    }
}
```

At the top level, add (or keep) the Kotlin toolchain block:

```kotlin
kotlin {
    jvmToolchain(17)
}
```

The `META-INF/*` excludes prevent `Duplicate file` packaging errors that arise when multiple SDK transitive dependencies ship the same legal-notice files.

Sync Gradle after editing.

## Step 2 — `app/src/main/java/<PackagePath>/MainApplication.kt`

```kotlin
package <AppPackage>

import android.app.Application
import com.salesforce.androidsdk.app.SalesforceSDKManager

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        SalesforceSDKManager.initNative(applicationContext, MainActivity::class.java)
    }
}
```

`initNative(...)` must run before any other SDK class is referenced. The second argument is the activity the SDK lands the user on after a successful login.

> **Adding SmartStore or MobileSync later?** Those are separate scenarios in this same skill (see [`add-smartstore.md`](add-smartstore.md) and [`add-mobilesync.md`](add-mobilesync.md)). They swap the dependency artifact and the SDK manager class. Don't pre-emptively pull them in here — start with `SalesforceSDK` and stay on it for the base authentication scenario.

## Step 3 — `app/src/main/AndroidManifest.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <application
        android:name=".MainApplication"
        android:icon="@drawable/sf__icon"
        android:label="@string/app_name"
        android:theme="@style/SalesforceSDK">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:theme="@style/SalesforceSDK">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <!-- Required: handles the OAuth redirect back from the browser after login.
             Derive the three data attributes by parsing <CallbackURL>:
               scheme = everything before "://"
               host   = segment between "://" and the first "/"
               path   = the remainder including the leading "/" (omit android:path if there is no path segment)
             Example: "myapp://success/done" → scheme="myapp" host="success" path="/done"
             Without this, the OAuth flow completes in the browser but the redirect never returns to the app. -->
        <activity
            android:name="com.salesforce.androidsdk.ui.LoginActivity"
            android:theme="@style/SalesforceSDK"
            android:launchMode="singleTask"
            android:exported="true">
            <intent-filter>
                <data android:scheme="<CallbackScheme>"
                      android:host="<CallbackHost>"
                      android:path="<CallbackPath>" />
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.BROWSABLE" />
                <category android:name="android.intent.category.DEFAULT" />
            </intent-filter>
        </activity>

    </application>

</manifest>
```

`@drawable/sf__icon` and `@style/SalesforceSDK` ship with the SDK — they resolve out of the SDK AAR with no additional resources required.

## Step 4 — `app/src/main/res/values/bootconfig.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="remoteAccessConsumerKey"><ConsumerKey></string>
    <string name="oauthRedirectURI"><CallbackURL></string>
</resources>
```

The SDK reads these resource strings during `initNative(...)`. Both keys must be present even when using placeholder values.

## Step 5 — `app/src/main/res/xml/servers.xml`

Create the `xml/` directory if it does not exist.

```xml
<?xml version="1.0" encoding="utf-8"?>
<servers>
    <server name="Default" url="<LoginHost>" />
</servers>
```

Multiple `<server>` entries are allowed — the SDK presents them as login-host choices.

## Step 6 — `app/src/main/res/values/strings.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name"><AppName></string>
    <string name="account_type"><AppPackage>.salesforce.account</string>
</resources>
```

> **`account_type` is required in SDK 14.0.** The SDK uses this string to register an Android Account Manager account type. If it is absent or left at the SDK default, the app crashes at startup with `IllegalStateException`. The value must be unique to your app — using `<AppPackage>.salesforce.account` is the recommended pattern.

## Step 7 — `app/src/main/java/<PackagePath>/MainActivity.kt`

`MainActivity` extends `SalesforceActivity`. The base class drives the OAuth flow and supplies the `RestClient` to `onResume(client: RestClient?)` once login completes.

```kotlin
package <AppPackage>

import android.os.Bundle
import android.view.Gravity
import android.widget.TextView
import com.salesforce.androidsdk.rest.RestClient
import com.salesforce.androidsdk.ui.SalesforceActivity

class MainActivity : SalesforceActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Smoke test view — replace with the real layout after login works.
        val label = TextView(this).apply {
            text = "Mobile SDK ready"
            gravity = Gravity.CENTER
            textSize = 18f
        }
        setContentView(label)
    }

    override fun onResume(client: RestClient?) {
        // Called after a successful login. `client` is non-null when authenticated.
        // Replace this with the real post-login logic.
    }
}
```

## Step 8 — Build

```bash
./gradlew assembleDebug
```

Expected: `BUILD SUCCESSFUL`. Install the resulting `app/build/outputs/apk/debug/app-debug.apk` on an emulator or device. On first launch, the Salesforce login screen appears; after a successful login, the placeholder "Mobile SDK ready" view installs.

> **SDK 14.0 defaults:** DPoP token binding and Advanced Authentication (Chrome Custom Tab for all login servers, including `login.salesforce.com`) are both **enabled by default**. No code changes are needed to get DPoP or browser-based login — they work out of the box. To temporarily opt out during development:
> ```kotlin
> SalesforceSDKManager.getInstance().useDPoP = false                   // opt out of DPoP
> SalesforceSDKManager.getInstance().forceAdvancedAuthentication = false // opt out of browser login
> ```
> Both opt-outs are deprecated and will be removed in SDK 15.0.

## Next

- Encrypted local DB: [`add-smartstore.md`](add-smartstore.md)
- Cloud sync: [`add-mobilesync.md`](add-mobilesync.md)
- Biometric session locking: [`add-biometric-auth.md`](add-biometric-auth.md)
- Symptoms after build: [`troubleshooting.md`](troubleshooting.md)
