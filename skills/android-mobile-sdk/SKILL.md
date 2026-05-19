---
name: android-mobile-sdk
description: Add Salesforce Mobile SDK capabilities to Android Kotlin applications. Covers creating new apps with the SDK pre-integrated, or adding base SDK, SmartStore (encrypted database), MobileSync (cloud sync), and biometric authentication to existing applications.
---

# Android Salesforce Mobile SDK Integration

This skill helps you integrate the Salesforce Mobile SDK into Android Kotlin applications. It uses progressive disclosure to guide you through the right scenario based on your needs.

## What This Skill Covers

- **Create a new Android app** with Mobile SDK from scratch
- **Add Mobile SDK** authentication to an existing Android app
- **Add SmartStore** (encrypted local database) to an app with Mobile SDK
- **Add MobileSync** (cloud data sync) to an app with SmartStore
- **Add Biometric Authentication** (fingerprint / face / iris) to an app with Mobile SDK

---

## Step 1: Identify Your Scenario

**Which of these describes your situation?**

### Scenario A: Create a New App
You're starting from scratch and want to create a new Android Kotlin app with Mobile SDK already integrated.

→ **Proceed to [Section: Create New App](#create-new-app)**

### Scenario B: Add SDK to Existing App
You have an existing Android Kotlin app and want to add Salesforce authentication.

→ **Proceed to [Section: Add Mobile SDK](#add-mobile-sdk)**

### Scenario C: Add SmartStore
You have an app with Mobile SDK and want to add encrypted local storage (SmartStore).

→ **Proceed to [Section: Add SmartStore](#add-smartstore)**

### Scenario D: Add MobileSync
You have an app with SmartStore and want to add cloud data synchronization.

→ **Proceed to [Section: Add MobileSync](#add-mobilesync)**

### Scenario E: Add Biometric Authentication
You have an app with Mobile SDK and want to add fingerprint / face / iris authentication support.

→ **Proceed to [Section: Add Biometric Auth](#add-biometric-auth)**

---

<a name="create-new-app"></a>
## Create New App

This section creates a new Android Kotlin application from scratch with Gradle, then integrates the Salesforce Mobile SDK.

### Prerequisites

Before starting, gather:
- **App name** (e.g. `MyApp`)
- **Package name** (e.g. `com.mycompany.myapp`)
- **Output directory** (where to create the project, e.g. `~/Projects`)
- **Consumer Key**, **Callback URL**, **Login host** (or leave as placeholders)

Ensure you have:
- Android SDK installed with `ANDROID_HOME` set
- `JAVA_HOME` pointing to a JDK 17

### Step 1: Create the Project Structure

```bash
mkdir -p <OutputDir>/<AppName>
cd <OutputDir>/<AppName>

mkdir -p app/src/main/java/<PackagePath>
mkdir -p app/src/main/res/layout
mkdir -p app/src/main/res/values
mkdir -p app/src/main/res/xml
mkdir -p gradle/wrapper
```

Replace `<PackagePath>` with your package name where dots are replaced by slashes (e.g., `com.mycompany.myapp` → `com/mycompany/myapp`).

### Step 2: Create Gradle Configuration Files

Create `settings.gradle.kts`:

```kotlin
rootProject.name = "<AppName>"
include(":app")
```

Create `build.gradle.kts` (root):

```kotlin
buildscript {
    repositories { google(); mavenCentral() }
    dependencies {
        classpath("com.android.tools.build:gradle:8.12.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.24")
    }
}
allprojects { repositories { google(); mavenCentral() } }
```

Create `gradle.properties`:

```properties
android.useAndroidX=true
org.gradle.jvmargs=-Xmx2g -XX:MaxMetaspaceSize=512m
```

Create `gradle/wrapper/gradle-wrapper.properties`:

```properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.14.3-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
```

Copy Gradle wrapper files from an existing Android project or download from gradle.org.

### Step 3: Create Module build.gradle.kts

Create `app/build.gradle.kts`:

```kotlin
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}
android {
    namespace = "<PackageName>"
    compileSdk = 36
    defaultConfig {
        applicationId = "<PackageName>"
        minSdk = 28; targetSdk = 36; versionCode = 1; versionName = "1.0"
    }
    buildFeatures { aidl = true; renderScript = true; buildConfig = true }
    packaging { resources { excludes += setOf("META-INF/LICENSE","META-INF/LICENSE.txt","META-INF/DEPENDENCIES","META-INF/NOTICE") } }
}
dependencies {
    implementation("com.salesforce.mobilesdk:MobileSync:13.2.0")
}
kotlin { jvmToolchain(17) }
```

Replace `<PackageName>` with your package name (e.g., `com.mycompany.myapp`).

### Step 4: Create Android Source Files

Now proceed to the [Add Mobile SDK](#add-mobile-sdk) section below to create the source files and integrate Salesforce authentication.

---

<a name="add-mobile-sdk"></a>
## Add Mobile SDK

This section integrates the Salesforce Mobile SDK into an **existing** Android Kotlin application, wiring up authentication so users are prompted to log in to Salesforce when the app launches.

> **Important — do not recreate Gradle scaffolding.** The app already has a working Gradle wrapper, `gradle.properties`, `settings.gradle.kts`, and root `build.gradle.kts`. Do **not** overwrite those files. The instructions below only modify `app/build.gradle.kts`, `AndroidManifest.xml`, and `MainActivity.kt`, and create `MainApplication.kt`, `bootconfig.xml`, `servers.xml`, and `strings.xml`. If you find yourself about to write a `gradle-wrapper.properties` or root `build.gradle.kts`, stop — you're confusing this scenario with **Create New App**.

### Prerequisites

Before starting, gather:
- **App package name** (e.g. `com.example.myapp`)
- **Main activity class name** (e.g. `MainActivity`)
- **Consumer Key** (OAuth connected app consumer key, or leave as placeholder)
- **Callback URL** (OAuth redirect URI, or leave as placeholder)
- **Login host** (default: `https://login.salesforce.com`, use `https://test.salesforce.com` for sandboxes)

### Step 1: Add the SDK Dependency

This scenario adds **Salesforce Mobile SDK Core only** — OAuth login and REST. Adding SmartStore (encrypted local database) or MobileSync (cloud data sync) is covered by the dedicated scenarios later in this skill; do not pre-emptively pull them in here.

In `app/build.gradle.kts`, **add** the `SalesforceSDK` artifact (Mobile SDK Core) via Maven Central. Don't remove existing dependencies the app already declares:

```kotlin
dependencies {
    implementation("com.salesforce.mobilesdk:SalesforceSDK:13.2.0")
    // Required: SalesforceActivity (used in Step 7) extends AppCompatActivity.
    // Keep the existing appcompat dependency if your app already has it, or add:
    implementation("androidx.appcompat:appcompat:1.7.0")
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

### Step 2: Create MainApplication.kt

Create `MainApplication.kt` in the app's main package (same directory as `MainActivity.kt`):

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

Replace `<AppPackage>` with your package name. `SalesforceSDKManager.initNative()` must be called before any SDK class is used.

> **Adding SmartStore or MobileSync later?** Those are separate scenarios in this same skill (see _Add SmartStore_ and _Add MobileSync_ below). They swap the dependency artifact and the SDK manager class. Don't pre-emptively pull them in here — start with `SalesforceSDK` and stay on it for the base authentication scenario.

### Step 3: Update AndroidManifest.xml

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

### Step 4: Create bootconfig.xml

Create `app/src/main/res/values/bootconfig.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="remoteAccessConsumerKey">YOUR_CONSUMER_KEY</string>
    <string name="oauthRedirectURI">YOUR_CALLBACK_URL</string>
</resources>
```

Replace `YOUR_CONSUMER_KEY` and `YOUR_CALLBACK_URL` with actual values (or leave as placeholders).

### Step 5: Create servers.xml

Create `app/src/main/res/xml/servers.xml` (create the `xml/` directory if it doesn't exist):

```xml
<?xml version="1.0" encoding="utf-8"?>
<servers>
    <server name="Default" url="https://login.salesforce.com" />
</servers>
```

Use the login host provided by the user, or `https://login.salesforce.com` as the default.

### Step 6: Create strings.xml

Create `app/src/main/res/values/strings.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name"><AppName></string>
</resources>
```

Replace `<AppName>` with your app name.

### Step 7: Update MainActivity.kt

`MainActivity` must extend `SalesforceActivity` so the SDK can manage the OAuth login lifecycle:

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

Replace `<AppPackage>` with your package name. After login, you should see **"Mobile SDK ready"**.

### Step 8: Build and Verify

```bash
./gradlew assembleDebug
```

Expected: `BUILD SUCCESSFUL`

Run on an emulator — the Salesforce login screen should appear on first launch.

---

<a name="add-smartstore"></a>
## Add SmartStore

This section adds the Salesforce SmartStore encrypted local database to an existing Android Kotlin app that already has `MobileSyncSDKManager` integrated.

### Prerequisites

**The app must already have the Mobile SDK wired up.** Check `MainApplication.kt` for `MobileSyncSDKManager.initNative()` and that `bootconfig.xml` exists. If not, complete the [Add Mobile SDK](#add-mobile-sdk) section first.

Before starting, confirm:
- **Soup name** for the initial store table (default: `Item`)

### Step 1: No Dependency Change Needed

`SmartStore` is already included in the `com.salesforce.mobilesdk:MobileSync` artifact. No `build.gradle.kts` changes are needed.

### Step 2: Upgrade SDK Initialization in MainApplication.kt

Replace `MobileSyncSDKManager` with `SmartStoreSDKManager`:

**Before:**
```kotlin
import com.salesforce.androidsdk.mobilesync.app.MobileSyncSDKManager

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        MobileSyncSDKManager.initNative(applicationContext, MainActivity::class.java)
    }
}
```

**After:**
```kotlin
import com.salesforce.androidsdk.smartstore.app.SmartStoreSDKManager

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        SmartStoreSDKManager.initNative(applicationContext, MainActivity::class.java)
    }
}
```

> `SmartStoreSDKManager` is a subclass of `SalesforceSDKManager`. It adds SmartStore support while preserving all OAuth and REST functionality.

### Step 3: Set Up the Store After Login in MainActivity.kt

Add `setupUserStoreFromDefaultConfig()` in `onResume()`:

**Before:**
```kotlin
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
    // post-login logic
}
```

**After:**
```kotlin
import com.salesforce.androidsdk.smartstore.app.SmartStoreSDKManager

override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    val label = TextView(this).apply {
        text = "SmartStore ready"
        gravity = Gravity.CENTER
        textSize = 18f
    }
    setContentView(label)
}

override fun onResume(client: RestClient?) {
    if (client == null) return
    SmartStoreSDKManager.getInstance().setupUserStoreFromDefaultConfig()
    // post-login logic
}
```

After login, you should see **"SmartStore ready"**.

### Step 4: Create userstore.json

Create `app/src/main/res/raw/userstore.json` (create the `raw/` directory if it doesn't exist):

```json
{
  "soups": [
    {
      "soupName": "<SoupName>",
      "indexes": [
        { "path": "Id",        "type": "string" },
        { "path": "Name",      "type": "string" },
        { "path": "__local__", "type": "string" }
      ]
    }
  ]
}
```

Replace `<SoupName>` with the soup name (default: `Item`).

The SDK reads `userstore.json` automatically from `res/raw/` — no code registration is needed beyond calling `setupUserStoreFromDefaultConfig()`.

### Step 5: Build and Verify

Build and run. After login, you should see **"SmartStore ready"**.

---

<a name="add-mobilesync"></a>
## Add MobileSync

This section adds the Salesforce MobileSync cloud data synchronization library to an existing Android Kotlin app that already has `SmartStore` integrated.

### Prerequisites

**The app must already have SmartStore wired up.** Check `MainApplication.kt` for `SmartStoreSDKManager.initNative()` and `MainActivity.kt` for `setupUserStoreFromDefaultConfig()`. If not, complete the [Add SmartStore](#add-smartstore) section first.

Before starting, gather:
- **Soup name** used in `userstore.json` (the sync will target this soup)
- **Salesforce sObject API name** to sync from (e.g. `Account`, `Contact`, `CustomObject__c`)

### Step 1: No Dependency Change Needed

`MobileSyncSDKManager` is included in the same `com.salesforce.mobilesdk:MobileSync` artifact already present. No `build.gradle.kts` changes are needed.

### Step 2: Upgrade SDK Initialization in MainApplication.kt

Replace `SmartStoreSDKManager` with `MobileSyncSDKManager`:

**Before:**
```kotlin
import com.salesforce.androidsdk.smartstore.app.SmartStoreSDKManager

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        SmartStoreSDKManager.initNative(applicationContext, MainActivity::class.java)
    }
}
```

**After:**
```kotlin
import com.salesforce.androidsdk.mobilesync.app.MobileSyncSDKManager

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        MobileSyncSDKManager.initNative(applicationContext, MainActivity::class.java)
    }
}
```

> `MobileSyncSDKManager` is a subclass of `SmartStoreSDKManager`. It adds MobileSync support while preserving all SmartStore, OAuth and REST functionality.

### Step 3: Add Sync Setup in MainActivity.kt

Add `setupUserSyncsFromDefaultConfig()` alongside the existing store setup call in `onResume`:

**Before:**
```kotlin
import com.salesforce.androidsdk.smartstore.app.SmartStoreSDKManager

override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    val label = TextView(this).apply {
        text = "SmartStore ready"
        gravity = Gravity.CENTER
        textSize = 18f
    }
    setContentView(label)
}

override fun onResume(client: RestClient?) {
    if (client == null) return
    SmartStoreSDKManager.getInstance().setupUserStoreFromDefaultConfig()
    // post-login logic
}
```

**After:**
```kotlin
import com.salesforce.androidsdk.mobilesync.app.MobileSyncSDKManager

override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    val label = TextView(this).apply {
        text = "SmartStore + MobileSync ready"
        gravity = Gravity.CENTER
        textSize = 18f
    }
    setContentView(label)
}

override fun onResume(client: RestClient?) {
    if (client == null) return
    MobileSyncSDKManager.getInstance().setupUserStoreFromDefaultConfig()
    MobileSyncSDKManager.getInstance().setupUserSyncsFromDefaultConfig()
    // post-login logic
}
```

After login, you should see **"SmartStore + MobileSync ready"**.

### Step 4: Create usersyncs.json

Create `app/src/main/res/raw/usersyncs.json` (next to `userstore.json`):

```json
{
  "syncs": [
    {
      "syncName": "syncDown<SoupName>",
      "syncType": "syncDown",
      "soupName": "<SoupName>",
      "target": {
        "type": "soql",
        "query": "SELECT Id, Name FROM <SalesforceObject> LIMIT 100"
      },
      "options": {
        "mergeMode": "LEAVE_IF_CHANGED"
      }
    }
  ]
}
```

Replace:
- `<SoupName>` with the soup name used in `userstore.json` — this is the **local** SmartStore table name
- `<SalesforceObject>` in the SOQL `FROM` clause with the **Salesforce sObject API name** to sync from (e.g. `Account`, `Contact`)

> The soup name and the sObject name are often the same but they don't have to be. The soup is a local storage concept; the SOQL target is a server-side Salesforce object.

The SDK reads `usersyncs.json` automatically from `res/raw/` — no code registration is needed beyond calling `setupUserSyncsFromDefaultConfig()`.

### Step 5: Build and Verify

Build and run. After login, you should see **"SmartStore + MobileSync ready"** and data should begin syncing from Salesforce.

---

<a name="add-biometric-auth"></a>
## Add Biometric Authentication

This section adds fingerprint / face / iris biometric authentication to an existing Android Kotlin app that already has Mobile SDK integrated.

### Prerequisites

**The app must already have the Mobile SDK integrated.** Check `MainApplication.kt` for `MobileSyncSDKManager.initNative()` (or `SmartStoreSDKManager`) and that `bootconfig.xml` exists. If not, complete the [Add Mobile SDK](#add-mobile-sdk) section first.

The SDK handles all locking, unlocking, and the native biometric prompt automatically once the user opts in.

### Step 1: Add the androidx.biometric Dependency

In `app/build.gradle.kts`, add the AndroidX Biometric library:

```kotlin
dependencies {
    implementation("com.salesforce.mobilesdk:MobileSync:13.2.0")
    implementation("androidx.biometric:biometric:1.1.0")
}
```

Sync Gradle after editing.

### Step 2: Update MainActivity.kt

Add `onPostResume()` to check device biometric capability and present the SDK opt-in dialog if needed.

**Add these imports** (at the top of `MainActivity.kt`):

```kotlin
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricManager.Authenticators.BIOMETRIC_STRONG
import androidx.biometric.BiometricManager.Authenticators.BIOMETRIC_WEAK
import com.salesforce.androidsdk.mobilesync.app.MobileSyncSDKManager
```

**Add `onPostResume()`** (after `onResume(client: RestClient?)`):

```kotlin
override fun onPostResume() {
    super.onPostResume()

    val deviceHasBiometrics = BiometricManager.from(this).canAuthenticate(
        BIOMETRIC_STRONG or BIOMETRIC_WEAK
    ) == BiometricManager.BIOMETRIC_SUCCESS

    MobileSyncSDKManager.getInstance().biometricAuthenticationManager?.run {
        if (enabled && deviceHasBiometrics && !hasBiometricOptedIn()) {
            presentOptInDialog(supportFragmentManager)
        }
    }
}
```

> **`onPostResume()`** fires after `onResume()` and after the activity window is fully visible — the correct lifecycle point to present a dialog.

> **`biometricAuthenticationManager`** is a nullable property on `SalesforceSDKManager`. The `?.run { }` block safely no-ops when no user is logged in.

### Step 3: Build and Verify

```bash
./gradlew assembleDebug
```

Expected: `BUILD SUCCESSFUL`

### Runtime verification (emulator or device)

1. Launch the app — Salesforce login screen appears.
2. Log in — the SDK opt-in dialog appears: **"Use biometrics to unlock?"**
3. Tap **Enable** — biometric authentication is now active.
4. Background the app, then foreground — the OS biometric prompt appears.
5. Authenticate successfully — the app unlocks without re-entering credentials.

> **Emulator note:** Fingerprint can be enrolled in the emulator via **Extended controls → Fingerprint**. Use `adb -e emu finger touch 1` to simulate a fingerprint scan.

---

## Troubleshooting

### Build Errors

**`Unresolved reference: MobileSyncSDKManager` (or `SmartStoreSDKManager`)**
The `MobileSync` dependency is not added or Gradle sync didn't complete. Add the dependency and sync.

**Build error: `aidl` or `renderScript` feature not found**
These features require `buildFeatures { aidl = true; renderScript = true }` in the `android` block.

### Login Issues

**Login screen does not appear**
Verify `android:name=".MainApplication"` is set in the `<application>` tag and `MobileSyncSDKManager.initNative()` is called in `onCreate()`.

**`Cannot find symbol SalesforceActivity`**
The `MobileSync` artifact wasn't synced. Run `./gradlew assembleDebug` to force dependency resolution.

### SmartStore Issues

**`setupUserStoreFromDefaultConfig()` silently does nothing**
`userstore.json` must be in `app/src/main/res/raw/`. The SDK resolves it by resource name.

### MobileSync Issues

**Sync fails at runtime with "Soup not found"**
The `soupName` in `usersyncs.json` must exactly match the `soupName` in `userstore.json`.

**`setupUserSyncsFromDefaultConfig()` silently does nothing**
`usersyncs.json` must be in `app/src/main/res/raw/`.

### Biometric Issues

**Opt-in dialog never appears**
`enabled` is `false` — the connected app in your org does not have `ENABLE_BIOMETRIC_AUTHENTICATION` set. The dialog correctly does not appear.

**`IllegalStateException`: Can not perform this action after onSaveInstanceState**
The dialog is being presented too early in the lifecycle. Ensure you are calling `presentOptInDialog` from `onPostResume()`, not `onResume()`.

**`Unresolved reference: BiometricManager`**
The `androidx.biometric:biometric` dependency is missing or Gradle sync didn't complete.

**`biometricAuthenticationManager` is null**
No user is currently authenticated. This is expected before login. The `?.run { }` safe-call handles this correctly.

---

## Next Steps

Once you've completed the integration:
- Replace placeholder OAuth values in `bootconfig.xml` with real Connected App credentials
- Replace smoke test UI with your actual app screens
- Implement data sync logic for your specific use case
- Test on physical devices for biometric authentication
