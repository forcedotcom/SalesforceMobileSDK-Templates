---
name: create-android-app-with-mobile-sdk
description: Create a new Android Kotlin application from scratch using the Android Gradle build system, then integrate Salesforce Mobile SDK authentication into it.
---

# Create an Android App with Salesforce Mobile SDK

This skill creates a new Android Kotlin application from scratch, then integrates the Salesforce Mobile SDK by invoking the `add-mobile-sdk-android` skill.

## Prerequisites

Ensure the Android SDK is installed (via Android Studio or `sdkmanager`) and that `ANDROID_HOME` is set:

```bash
echo $ANDROID_HOME   # should print the SDK root, e.g. /Users/you/Library/Android/sdk
```

Before starting, ask the user for:
- **App name** (e.g. `MyApp`) — used as the project directory name and `app_name` string
- **Package name** (e.g. `com.mycompany.myapp`) — Android application ID
- **Output directory** (where to create the project, e.g. `/tmp`)
- **Consumer Key**, **Callback URL**, **Login host** — passed through to the `add-mobile-sdk-android` skill

---

## Step 1: Create the Project Directory Structure

```bash
APP_DIR=<OutputDir>/<AppName>
mkdir -p "$APP_DIR/app/src/main/java/<PackagePath>"
mkdir -p "$APP_DIR/app/src/main/res/layout"
mkdir -p "$APP_DIR/app/src/main/res/values"
mkdir -p "$APP_DIR/app/src/main/res/xml"
mkdir -p "$APP_DIR/gradle/wrapper"
```

Where `<PackagePath>` is the package name with dots replaced by slashes (e.g. `com/mycompany/myapp`).

---

## Step 2: Create the Gradle Wrapper Files

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

Copy the Gradle wrapper scripts from an existing Android project, or download them:

```bash
# If another Android project is available locally (e.g. an SDK template):
cp <existing-project>/gradlew "$APP_DIR/gradlew"
cp <existing-project>/gradlew.bat "$APP_DIR/gradlew.bat"
cp <existing-project>/gradle/wrapper/gradle-wrapper.jar "$APP_DIR/gradle/wrapper/gradle-wrapper.jar"
chmod +x "$APP_DIR/gradlew"
```

> **Tip:** The Gradle wrapper JAR and scripts are identical across all Android projects. Copy them from any nearby Android project rather than downloading them fresh.

---

## Step 3: Create gradle.properties

Create `gradle.properties` in the project root:

```properties
android.useAndroidX=true
org.gradle.jvmargs=-Xmx2g -XX:MaxMetaspaceSize=512m
```

`android.useAndroidX=true` is required because the SDK pulls in AndroidX dependencies. The JVM heap setting prevents out-of-memory failures during dex merging with the large dependency graph the SDK brings in.

---

## Step 5: Create Top-Level Build Files

Create `settings.gradle.kts` in the project root:

```kotlin
rootProject.name = "<AppName>"

include(":app")
```

Create `build.gradle.kts` in the project root:

```kotlin
buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.12.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.24")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
```

---

## Step 4: Create the App Module Build File

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
        minSdk = 28
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
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

> **Note:** The SDK dependency, `MainApplication`, and updated `AndroidManifest` are added by the `add-mobile-sdk-android` skill in the next step. Do not add them here.

---

## Step 6: Create AndroidManifest.xml

Create `app/src/main/AndroidManifest.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <application
        android:label="@string/app_name"
        android:theme="@style/Theme.AppCompat">

        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

    </application>

</manifest>
```

---

## Step 7: Create MainActivity.kt

Create `app/src/main/java/<PackagePath>/MainActivity.kt`:

```kotlin
package <PackageName>

import android.os.Bundle
import android.view.Gravity
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val label = TextView(this).apply {
            text = "Hello, Android!"
            gravity = Gravity.CENTER
            textSize = 18f
        }
        setContentView(label)
    }
}
```

---

## Step 8: Create strings.xml

Create `app/src/main/res/values/strings.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name"><AppName></string>
</resources>
```

---

## Step 9: Add Salesforce Mobile SDK

Invoke the `add-mobile-sdk-android` skill now, passing the values collected in the prerequisites.

The skill will:
- Add the `MobileSync` dependency to `app/build.gradle.kts`
- Add SDK-required `android` configuration blocks to `app/build.gradle.kts`
- Create `MainApplication.kt` that calls `MobileSyncSDKManager.initNative()`
- Update `AndroidManifest.xml` with `android:name=".MainApplication"` and the SDK login theme
- Create `bootconfig.xml` with consumer key and callback URL
- Create `servers.xml` with the login host
- Update `MainActivity.kt` to extend `SalesforceActivity`

---

## Step 10: Build and Verify

```bash
cd <OutputDir>/<AppName>
./gradlew assembleDebug
```

Expected: `BUILD SUCCESSFUL`

Run on an emulator — the Salesforce login screen should appear on first launch.

---

## Checklist

- [ ] Project directory structure created with `app/src/main/java/<PackagePath>/`
- [ ] Gradle wrapper files in place (`gradlew`, `gradlew.bat`, `gradle/wrapper/`)
- [ ] `gradle.properties` created with `android.useAndroidX=true` and JVM heap settings
- [ ] `settings.gradle.kts` created with correct app name and `:app` include
- [ ] Root `build.gradle.kts` created with AGP and Kotlin classpath dependencies
- [ ] `app/build.gradle.kts` created with namespace and compileSdk
- [ ] `AndroidManifest.xml` created with `MainActivity` as launcher
- [ ] `MainActivity.kt` created
- [ ] `strings.xml` created with `app_name`
- [ ] `add-mobile-sdk-android` skill applied
- [ ] `./gradlew assembleDebug` succeeds
- [ ] Salesforce login screen appears on first launch

---

## Troubleshooting

**`./gradlew: Permission denied`**
Run `chmod +x gradlew` in the project root.

**`gradle-wrapper.jar` missing**
Copy `gradle/wrapper/gradle-wrapper.jar` from any existing Android project. It is a binary launcher that bootstraps the Gradle distribution — it cannot be created manually.

**`Unresolved reference: MobileSyncSDKManager`**
The `add-mobile-sdk-android` skill step was not applied or Gradle sync didn't complete. Apply the skill and run `./gradlew assembleDebug` again.

**`Namespace not specified`**
Ensure `namespace = "<PackageName>"` is set in the `android { }` block of `app/build.gradle.kts`.

**`android.useAndroidX` property is not enabled`**
Create `gradle.properties` at the project root with `android.useAndroidX=true`.

**`OutOfMemoryError: Java heap space` during dex merging**
Add `org.gradle.jvmargs=-Xmx2g -XX:MaxMetaspaceSize=512m` to `gradle.properties`.

For all other issues, refer to the troubleshooting section of the `add-mobile-sdk-android` skill.
