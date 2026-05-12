---
name: add-mobile-sdk-android
description: Add Salesforce Mobile SDK to an existing Android Kotlin application. Handles Gradle dependency, SDK initialization in Application class, OAuth login flow via SalesforceActivity, bootconfig.xml, and servers.xml configuration.
---

# Add Salesforce Mobile SDK to an Android Kotlin App

This skill integrates the Salesforce Mobile SDK into an existing Android Kotlin application, wiring up authentication so users are prompted to log in to Salesforce when the app launches.

## What This Skill Does

1. Adds the `MobileSyncSDKManager` dependency to `app/build.gradle.kts`
2. Creates `MainApplication.kt` — initializes the SDK on startup
3. Updates `AndroidManifest.xml` to declare `MainApplication` and use the SDK login theme
4. Creates `bootconfig.xml` with OAuth configuration
5. Creates `servers.xml` with the login host
6. Updates `MainActivity.kt` to extend `SalesforceActivity`

## Prerequisites

Before starting, ask the user for:
- **App package name** (e.g. `com.example.myapp`)
- **Main activity class name** (e.g. `MainActivity`)
- **Consumer Key** (OAuth connected app consumer key, or leave as placeholder)
- **Callback URL** (OAuth redirect URI, or leave as placeholder)
- **Login host** (default: `https://login.salesforce.com`, use `https://test.salesforce.com` for sandboxes)

---

## Step 1: Add the SDK Dependency

In `app/build.gradle.kts`, add `MobileSyncSDKManager` via Maven Central. Using `MobileSync` as the single dependency pulls in `SmartStore` and `SalesforceSDKCore` transitively.

```kotlin
dependencies {
    implementation("com.salesforce.mobilesdk:MobileSync:13.2.0")
}
```

Also ensure the Android build block is configured for SDK compatibility:

```kotlin
android {
    compileSdk = 36

    defaultConfig {
        minSdk = 28
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

kotlin {
    jvmToolchain(17)
}
```

Sync Gradle after editing.

> **Adding SmartStore or MobileSync later?** The `MobileSync` artifact already includes both. There is no separate `SalesforceSDKCore`-only artifact needed for the basic SDK — start with `MobileSync` and stay on it.

---

## Step 2: Create MainApplication.kt

Create `MainApplication.kt` in the app's main package (same directory as `MainActivity.kt`):

```kotlin
package <AppPackage>

import android.app.Application
import com.salesforce.androidsdk.mobilesync.app.MobileSyncSDKManager

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        MobileSyncSDKManager.initNative(applicationContext, MainActivity::class.java)
    }
}
```

`MobileSyncSDKManager.initNative()` must be called before any SDK class is used. It registers the SDK with the Android system and wires up the OAuth login flow, directing the user to `MainActivity` after successful authentication.

---

## Step 3: Update AndroidManifest.xml

Register `MainApplication` and apply the SDK login theme to `MainActivity`:

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

    </application>

</manifest>
```

---

## Step 4: Create bootconfig.xml

Create `app/src/main/res/values/bootconfig.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="remoteAccessConsumerKey">YOUR_CONSUMER_KEY</string>
    <string name="oauthRedirectURI">YOUR_CALLBACK_URL</string>
</resources>
```

Replace `YOUR_CONSUMER_KEY` and `YOUR_CALLBACK_URL` with the values from your Salesforce Connected App. If the user provided them in the prerequisites, substitute them now.

---

## Step 5: Create servers.xml

Create `app/src/main/res/xml/servers.xml` (create the `xml/` directory if it doesn't exist):

```xml
<?xml version="1.0" encoding="utf-8"?>
<servers>
    <server name="Default" url="https://login.salesforce.com" />
</servers>
```

Use the login host provided by the user, or `https://login.salesforce.com` as the default.

---

## Step 6: Update MainActivity.kt

`MainActivity` must extend `SalesforceActivity` so the SDK can manage the OAuth login lifecycle. Add a smoke test UI in `onCreate` to confirm the SDK is working after login:

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
        val label = TextView(this).apply {
            text = "Mobile SDK ready"
            gravity = Gravity.CENTER
            textSize = 18f
        }
        setContentView(label)
    }

    override fun onResume(client: RestClient?) {
        // Called after successful login. client is non-null when logged in.
        // Replace this with your app's post-login logic.
    }
}
```

After login, you should see **"Mobile SDK ready"** centered on the screen. This is a smoke test placeholder — replace with your real app UI once verified.

> **`onResume(client: RestClient?)`** is called every time the activity resumes with a valid session. It is the correct place to start loading data. `client` is `null` if the user is not authenticated.

---

## Step 7: Build and Verify

```bash
./gradlew assembleDebug
```

Expected: `BUILD SUCCESSFUL`

Run on an emulator — the Salesforce login screen should appear on first launch.

---

## Checklist

- [ ] `MobileSync` dependency added to `app/build.gradle.kts`
- [ ] `MainApplication.kt` created and calls `MobileSyncSDKManager.initNative()`
- [ ] `android:name=".MainApplication"` set in `AndroidManifest.xml`
- [ ] `MainActivity` extends `SalesforceActivity`
- [ ] `bootconfig.xml` created with consumer key and callback URL
- [ ] `servers.xml` created with login host
- [ ] Project builds without errors
- [ ] Salesforce login screen appears on first launch
- [ ] "Mobile SDK ready" label is shown after login

---

## Troubleshooting

**Build error: `Unresolved reference: MobileSyncSDKManager`**
The `MobileSync` dependency is not added or Gradle sync didn't complete. Add the dependency and sync.

**Login screen does not appear**
Verify `android:name=".MainApplication"` is set in the `<application>` tag and `MobileSyncSDKManager.initNative()` is called in `onCreate()`.

**`Cannot find symbol SalesforceActivity`**
The `MobileSync` artifact wasn't synced. Run `./gradlew assembleDebug` to force dependency resolution.

**Build error: `aidl` or `renderScript` feature not found**
These features require `buildFeatures { aidl = true; renderScript = true }` in the `android` block.
