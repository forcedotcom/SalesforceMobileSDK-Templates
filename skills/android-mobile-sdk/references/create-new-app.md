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
- Gradle wrapper (created in Step 2) — host Gradle is not required.

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
        classpath("com.android.tools.build:gradle:9.1.1")
    }
}
allprojects { repositories { google(); mavenCentral() } }
```

AGP 9.x ships built-in Kotlin support and registers the `kotlin` extension on `com.android.application` modules itself. Applying `com.android.application` alone is sufficient — do **not** also apply `id("org.jetbrains.kotlin.android")` and do not add the `kotlin-gradle-plugin` classpath. With both applied, Gradle fails with `Cannot add extension with name 'kotlin', as there is an extension already registered with that name`.

`gradle.properties`:

```properties
org.gradle.jvmargs=-XX:MaxMetaspaceSize=512m
android.nonTransitiveRClass=false
```

(AGP 8+ enforces AndroidX by default — `android.useAndroidX=true` is unnecessary and removed in AGP 9. `android.nonTransitiveRClass=false` matches the SDK consumers' expectation that `R` class fields from libraries leak into the app's `R`.)

`gradle/wrapper/gradle-wrapper.properties`:

```properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-9.4.1-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
```

The Gradle wrapper jar (`gradle/wrapper/gradle-wrapper.jar`) and `gradlew` / `gradlew.bat` scripts must exist alongside this file. Three ways to get them:

1. Copy them from any existing Android project on the same machine.
2. If a host `gradle` is installed: `gradle wrapper --gradle-version 9.4.1`.
3. As a last resort, copy them from <https://github.com/forcedotcom/SalesforceMobileSDK-Templates/tree/dev/AndroidNativeKotlinTemplate> (`gradlew`, `gradlew.bat`, and `gradle/wrapper/gradle-wrapper.jar`).

AGP 9.1.1 requires Gradle 9.3.1 or newer — pairing it with Gradle 8.x will fail the version compatibility check at sync time.

## Step 3 — Module `app/build.gradle.kts`

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
        versionCode = 1
        versionName = "1.0"
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

`MobileSync:13.2.1` is the latest published Maven Central release at the time of writing — verify the current `<latest>` at <https://repo1.maven.org/maven2/com/salesforce/mobilesdk/MobileSync/maven-metadata.xml> when integrating. The canonical `AndroidNativeKotlinTemplate` on the `dev` branch pins a higher in-development version (matching the upcoming MSDK release); consumers building outside this repo should use the latest **published** version.

## Step 4 — Add Mobile SDK

Continue at [`add-mobile-sdk.md`](add-mobile-sdk.md). It creates the `Application` subclass, the `MainActivity`, the manifest, and the resource files.
