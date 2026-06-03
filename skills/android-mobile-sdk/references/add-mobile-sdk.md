# Android — Add Mobile SDK Authentication

Wires the Salesforce Mobile SDK into an existing Android Kotlin app so the OAuth login screen appears on first launch and the SDK manages token persistence.

## Inputs

| Variable | Example | Notes |
|---|---|---|
| `<AppName>` | `MyApp` | Display name |
| `<PackageName>` | `com.mycompany.myapp` | `applicationId` / `namespace` |
| `<PackagePath>` | `com/mycompany/myapp` | `<PackageName>` with `.` → `/` |
| `<ConsumerKey>` | `3MVG9...` | Connected App consumer key, or leave as the placeholder |
| `<CallbackURL>` | `myapp://oauth/callback` | OAuth redirect URI, or leave as the placeholder |
| `<LoginHost>` | `https://login.salesforce.com` | `https://test.salesforce.com` for sandboxes |

## Step 1 — `app/build.gradle.kts` dependency

The single artifact `com.salesforce.mobilesdk:MobileSync` pulls in `SmartStore` and `SalesforceSDKCore` transitively. Pin to a published version:

```kotlin
plugins {
    id("com.android.application")
}

android {
    namespace = "<PackageName>"
    compileSdk = 37

    defaultConfig {
        applicationId = "<PackageName>"
        minSdk = 28
        targetSdk = 37
    }

    buildFeatures {
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

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    implementation("com.salesforce.mobilesdk:MobileSync:13.2.1")
}

kotlin {
    jvmToolchain(17)
}
```

The `META-INF/*` excludes prevent `Duplicate file` packaging errors that arise when multiple SDK transitive dependencies ship the same legal-notice files.

## Step 2 — `app/src/main/java/<PackagePath>/MainApplication.kt`

```kotlin
package <PackageName>

import android.app.Application
import com.salesforce.androidsdk.mobilesync.app.MobileSyncSDKManager

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        MobileSyncSDKManager.initNative(applicationContext, MainActivity::class.java)
    }
}
```

`initNative(...)` must run before any other SDK class is referenced. The second argument is the activity the SDK lands the user on after a successful login.

## Step 3 — `app/src/main/AndroidManifest.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    android:installLocation="internalOnly"
    android:versionCode="1"
    android:versionName="1.0">

    <application
        android:name=".MainApplication"
        android:icon="@drawable/sf__icon"
        android:label="@string/app_name"
        android:manageSpaceActivity="com.salesforce.androidsdk.ui.ManageSpaceActivity">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:theme="@style/SalesforceSDK">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

`@drawable/sf__icon` and `@style/SalesforceSDK` ship with the SDK — they resolve out of the `MobileSync` AAR with no additional resources required.

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
    <string name="account_type"><PackageName>.login</string>
</resources>
```

The `account_type` string is required — it is the Android `AccountManager` account-type label that the SDK's authenticator registers against.

## Step 7 — `app/src/main/java/<PackagePath>/MainActivity.kt`

`MainActivity` extends `SalesforceActivity`. The base class drives the OAuth flow and supplies the `RestClient` to `onResume(client: RestClient?)` once login completes.

```kotlin
package <PackageName>

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

Do **not** override `onResume()` (the no-arg form) without delegating to `super.onResume()` — `SalesforceActivity.onResume()` is what kicks off the OAuth bridge.

## Step 8 — Build

```bash
./gradlew assembleDebug
```

Expected: `BUILD SUCCESSFUL`. Install the resulting `app/build/outputs/apk/debug/app-debug.apk` on an emulator or device. On first launch, the Salesforce login screen appears; after a successful login, the placeholder "Mobile SDK ready" view installs.

## Next

- Encrypted local DB: [`add-smartstore.md`](add-smartstore.md)
- Cloud sync: [`add-mobilesync.md`](add-mobilesync.md)
- Biometric session locking: [`add-biometric-auth.md`](add-biometric-auth.md)
- Symptoms after build: [`troubleshooting.md`](troubleshooting.md)
