# Android — Create a New Kotlin App

Generates a bare Android Kotlin Gradle project, then chains into [`add-mobile-sdk.md`](add-mobile-sdk.md) to wire up Salesforce authentication.

## Inputs

| Variable | Example | Notes |
|---|---|---|
| `<AppName>` | `MyApp` | Project / Gradle name |
| `<PackageName>` | `com.mycompany.myapp` | `applicationId` and `namespace` |
| `<PackagePath>` | `com/mycompany/myapp` | `<PackageName>` with `.` → `/` |
| `<OutputDir>` | `~/Projects` | Parent directory |

## Tooling

- Android SDK with `ANDROID_HOME` set.
- JDK 17 with `JAVA_HOME` pointing at it.
- `gradle` on PATH to generate the wrapper (macOS: `brew install gradle`). Host Gradle is only needed once for Step 3; it is not required after that.

## Step 1 — Project tree

```bash
mkdir -p <OutputDir>/<AppName>
cd <OutputDir>/<AppName>

mkdir -p app/src/main/java/<PackagePath>
mkdir -p app/src/main/res/layout
mkdir -p app/src/main/res/values
mkdir -p app/src/main/res/xml
mkdir -p gradle/wrapper
```

## Step 2 — Gradle configuration

`settings.gradle.kts`:

```kotlin
rootProject.name = "<AppName>"
include(":app")
```

`build.gradle.kts` (root):

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

`gradle.properties`:

```properties
android.useAndroidX=true
org.gradle.jvmargs=-Xmx2g -XX:MaxMetaspaceSize=512m
```

`gradle/wrapper/gradle-wrapper.properties`:

```properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.14.3-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
```

## Step 3 — Generate the Gradle wrapper

**Required.** From the project root, run:

```bash
gradle wrapper --gradle-version 8.14.3
```

This produces `gradlew`, `gradlew.bat`, and `gradle/wrapper/gradle-wrapper.jar` alongside the `gradle-wrapper.properties` you wrote above. The build will fail without these — do not skip this step, and do not fabricate `gradle-wrapper.jar` by hand (it is a binary).

## Step 4 — Module `app/build.gradle.kts`

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
dependencies {
    implementation("com.salesforce.mobilesdk:SalesforceSDK:13.2.0")
}
kotlin {
    jvmToolchain(17)
}
```

Use `SalesforceSDK` (Mobile SDK Core) here — not `MobileSync`. Add `SmartStore` or `MobileSync` later only if those capabilities are needed (see [`add-smartstore.md`](add-smartstore.md) / [`add-mobilesync.md`](add-mobilesync.md)).

## Step 5 — Add Mobile SDK

Continue at [`add-mobile-sdk.md`](add-mobile-sdk.md). It creates the `Application` subclass, the `MainActivity`, the manifest, and the resource files.
