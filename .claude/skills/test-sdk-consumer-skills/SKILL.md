---
name: test-sdk-consumer-skills
description: End-to-end test harness for all SDK consumer skills. Creates 8 apps (4 iOS, 4 Android) in parallel, one per consumer skill, builds each, and reports results.
---

# Test SDK Consumer Skills

End-to-end test harness that exercises every consumer skill by creating a fresh app for each one, applying the skill, building the result, and reporting a pass/fail summary alongside the paths so the user can do further manual testing.

## Apps Created

| # | Name | Platform | Skills Applied |
|---|------|----------|----------------|
| 1 | `SkillTest_iOS_Full` | iOS (CocoaPods) | `create-ios-app-with-mobile-sdk` |
| 2 | `SkillTest_iOS_SDK` | iOS (CocoaPods) | `add-mobile-sdk-ios` |
| 3 | `SkillTest_iOS_SmartStore` | iOS (CocoaPods) | `add-mobile-sdk-ios` + `add-smartstore-ios` |
| 4 | `SkillTest_iOS_MobileSync` | iOS (CocoaPods) | `add-mobile-sdk-ios` + `add-smartstore-ios` + `add-mobilesync-ios` |
| 5 | `SkillTest_Android_Full` | Android (Gradle) | `create-android-app-with-mobile-sdk` |
| 6 | `SkillTest_Android_SDK` | Android (Gradle) | `add-mobile-sdk-android` |
| 7 | `SkillTest_Android_SmartStore` | Android (Gradle) | `add-mobile-sdk-android` + `add-smartstore-android` |
| 8 | `SkillTest_Android_MobileSync` | Android (Gradle) | `add-mobile-sdk-android` + `add-smartstore-android` + `add-mobilesync-android` |

## Prerequisites

- `xcodegen` installed (`brew install xcodegen`)
- `cocoapods` installed (`brew install cocoapods`)
- Android SDK installed with `ANDROID_HOME` set
- `JAVA_HOME` pointing to a JDK 17

Verify:

```bash
which xcodegen && which pod && echo $ANDROID_HOME && java -version
```

## Step 1: Choose an Output Directory

All 8 apps are created under a single parent directory. Default: `/tmp/SdkSkillsTest_<timestamp>`.

```bash
BASE=/tmp/SdkSkillsTest_$(date +%Y%m%d_%H%M%S)
mkdir -p "$BASE"
echo "Output: $BASE"
```

## Step 2: Create the 8 App Skeletons in Parallel

Launch all 8 app skeletons simultaneously. Each group below can be started without waiting for the others.

### iOS apps — shared scaffold helper

All 4 iOS apps use the same xcodegen scaffold. For apps 2–4 (where `create-ios-app-with-mobile-sdk` is NOT applied), use the minimal scaffold produced by steps 1–3 of that skill (project.yml + xcodegen + bare Swift files). For app 1, `create-ios-app-with-mobile-sdk` handles scaffolding internally.

Create the following reusable function (or repeat the steps inline for each app):

```bash
# Usage: scaffold_ios <AppName> <BundleID> <OutputDir>
scaffold_ios() {
  local NAME=$1 BUNDLE=$2 DIR=$3
  mkdir -p "$DIR/$NAME/$NAME"

  cat > "$DIR/$NAME/$NAME/AppDelegate.swift" <<'SWIFT'
import UIKit
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    override init() { super.init() }
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool { true }
}
SWIFT

  cat > "$DIR/$NAME/$NAME/SceneDelegate.swift" <<'SWIFT'
import UIKit
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window?.windowScene = windowScene
        window?.rootViewController = UIViewController()
        window?.makeKeyAndVisible()
    }
    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}
SWIFT

  cat > "$DIR/$NAME/project.yml" <<YAML
name: $NAME
options:
  bundleIdPrefix: $(echo $BUNDLE | rev | cut -d. -f2- | rev)
  deploymentTarget:
    iOS: "18.0"
settings:
  PRODUCT_BUNDLE_IDENTIFIER: $BUNDLE
targets:
  $NAME:
    type: application
    platform: iOS
    sources:
      - $NAME
    info:
      path: $NAME/Info.plist
      properties:
        UILaunchStoryboardName: LaunchScreen
        UIApplicationSceneManifest:
          UIApplicationSupportsMultipleScenes: false
          UISceneConfigurations:
            UIWindowSceneSessionRoleApplication:
              - UISceneConfigurationName: Default Configuration
                UISceneDelegateClassName: \$(PRODUCT_MODULE_NAME).SceneDelegate
YAML

  (cd "$DIR/$NAME" && xcodegen generate)
}
```

### Android apps — shared scaffold helper

```bash
# Usage: scaffold_android <AppName> <PackageName> <OutputDir>
scaffold_android() {
  local NAME=$1 PKG=$2 DIR=$3
  local PKG_PATH=$(echo $PKG | tr '.' '/')
  local APP_DIR="$DIR/$NAME"

  mkdir -p "$APP_DIR/app/src/main/java/$PKG_PATH"
  mkdir -p "$APP_DIR/app/src/main/res/layout"
  mkdir -p "$APP_DIR/app/src/main/res/values"
  mkdir -p "$APP_DIR/app/src/main/res/xml"
  mkdir -p "$APP_DIR/gradle/wrapper"

  # Copy wrapper from the Templates repo.
  # If running from inside the SalesforceMobileSDK-Workspace, use:
  #   local TMPL="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)/AndroidNativeKotlinTemplate"
  # Otherwise set the full path explicitly:
  local TMPL=/path/to/SalesforceMobileSDK-Templates/AndroidNativeKotlinTemplate
  cp "$TMPL/gradlew" "$APP_DIR/gradlew"
  cp "$TMPL/gradlew.bat" "$APP_DIR/gradlew.bat"
  cp "$TMPL/gradle/wrapper/gradle-wrapper.jar" "$APP_DIR/gradle/wrapper/gradle-wrapper.jar"
  chmod +x "$APP_DIR/gradlew"

  cat > "$APP_DIR/gradle/wrapper/gradle-wrapper.properties" <<'PROPS'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.14.3-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
PROPS

  cat > "$APP_DIR/gradle.properties" <<'PROPS'
android.useAndroidX=true
org.gradle.jvmargs=-Xmx2g -XX:MaxMetaspaceSize=512m
PROPS

  cat > "$APP_DIR/settings.gradle.kts" <<KTS
rootProject.name = "$NAME"
include(":app")
KTS

  cat > "$APP_DIR/build.gradle.kts" <<'KTS'
buildscript {
    repositories { google(); mavenCentral() }
    dependencies {
        classpath("com.android.tools.build:gradle:8.12.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.24")
    }
}
allprojects { repositories { google(); mavenCentral() } }
KTS

  cat > "$APP_DIR/app/build.gradle.kts" <<KTS
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}
android {
    namespace = "$PKG"
    compileSdk = 36
    defaultConfig {
        applicationId = "$PKG"
        minSdk = 28; targetSdk = 36; versionCode = 1; versionName = "1.0"
    }
    buildFeatures { aidl = true; renderScript = true; buildConfig = true }
    packaging { resources { excludes += setOf("META-INF/LICENSE","META-INF/LICENSE.txt","META-INF/DEPENDENCIES","META-INF/NOTICE") } }
}
dependencies { implementation("com.salesforce.mobilesdk:MobileSync:13.2.0") }
kotlin { jvmToolchain(17) }
KTS

  cat > "$APP_DIR/app/src/main/AndroidManifest.xml" <<XML
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android" android:installLocation="internalOnly">
    <application android:name=".MainApplication" android:icon="@drawable/sf__icon" android:label="@string/app_name" android:theme="@style/SalesforceSDK">
        <activity android:name=".MainActivity" android:exported="true" android:theme="@style/SalesforceSDK">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
XML

  cat > "$APP_DIR/app/src/main/res/values/strings.xml" <<XML
<?xml version="1.0" encoding="utf-8"?>
<resources><string name="app_name">$NAME</string></resources>
XML

  cat > "$APP_DIR/app/src/main/res/values/bootconfig.xml" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="remoteAccessConsumerKey">YOUR_CONSUMER_KEY</string>
    <string name="oauthRedirectURI">YOUR_CALLBACK_URL</string>
</resources>
XML

  cat > "$APP_DIR/app/src/main/res/xml/servers.xml" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<servers><server name="Default" url="https://login.salesforce.com"/></servers>
XML

  cat > "$APP_DIR/app/src/main/java/$PKG_PATH/MainApplication.kt" <<KT
package $PKG
import android.app.Application
import com.salesforce.androidsdk.mobilesync.app.MobileSyncSDKManager
class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        MobileSyncSDKManager.initNative(applicationContext, MainActivity::class.java)
    }
}
KT

  cat > "$APP_DIR/app/src/main/java/$PKG_PATH/MainActivity.kt" <<KT
package $PKG
import android.os.Bundle
import android.view.Gravity
import android.widget.TextView
import com.salesforce.androidsdk.rest.RestClient
import com.salesforce.androidsdk.ui.SalesforceActivity
class MainActivity : SalesforceActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(TextView(this).apply { text = "Mobile SDK ready"; gravity = Gravity.CENTER; textSize = 18f })
    }
    override fun onResume(client: RestClient?) {}
}
KT
}
```

> **Note on the wrapper path**: Replace `/path/to/SalesforceMobileSDK-Templates/AndroidNativeKotlinTemplate` with the actual path to the Templates repo on your machine (e.g. the workspace clone). The Gradle wrapper JAR and scripts are binary files that cannot be created manually.

## Step 3: Apply Consumer Skills to Each App

Once scaffolded, apply the consumer skills. iOS apps 2–4 need `pod install` after CocoaPods wiring; iOS app 1 does this internally via `create-ios-app-with-mobile-sdk`.

### App 1 — iOS Full (create-ios-app-with-mobile-sdk)

The `create-ios-app-with-mobile-sdk` skill handles scaffolding + SDK wiring in one pass. Invoke it with:
- App name: `SkillTest_iOS_Full`
- Bundle ID: `com.skilltest.ios.full`
- Output directory: `$BASE`
- Dependency manager: CocoaPods
- Consumer key / callback URL / login host: leave as placeholders

### App 2 — iOS SDK only (add-mobile-sdk-ios)

1. Run `scaffold_ios SkillTest_iOS_SDK com.skilltest.ios.sdk $BASE`
2. Apply `add-mobile-sdk-ios` to `$BASE/SkillTest_iOS_SDK` (CocoaPods path, placeholders for OAuth)
3. `pod install` in `$BASE/SkillTest_iOS_SDK`

### App 3 — iOS SmartStore (add-mobile-sdk-ios → add-smartstore-ios)

1. Run `scaffold_ios SkillTest_iOS_SmartStore com.skilltest.ios.smartstore $BASE`
2. Apply `add-mobile-sdk-ios`
3. Apply `add-smartstore-ios` (soup name: `Item`)
4. `pod install`

### App 4 — iOS MobileSync (add-mobile-sdk-ios → add-smartstore-ios → add-mobilesync-ios)

1. Run `scaffold_ios SkillTest_iOS_MobileSync com.skilltest.ios.mobilesync $BASE`
2. Apply `add-mobile-sdk-ios`
3. Apply `add-smartstore-ios` (soup name: `Item`)
4. Apply `add-mobilesync-ios` (soup: `Item`, sObject: `Contact`)
5. `pod install`

### App 5 — Android Full (create-android-app-with-mobile-sdk)

The `create-android-app-with-mobile-sdk` skill handles scaffolding + SDK wiring. Invoke it with:
- App name: `SkillTest_Android_Full`
- Package name: `com.skilltest.android.full`
- Output directory: `$BASE`
- Consumer key / callback URL / login host: leave as placeholders

### App 6 — Android SDK only (add-mobile-sdk-android)

1. Run `scaffold_android SkillTest_Android_SDK com.skilltest.android.sdk $BASE`
2. App is fully wired by the scaffold (the scaffold already includes the SDK wiring from `add-mobile-sdk-android`)

### App 7 — Android SmartStore (add-mobile-sdk-android → add-smartstore-android)

1. Run `scaffold_android SkillTest_Android_SmartStore com.skilltest.android.smartstore $BASE`
2. Apply `add-smartstore-android` (soup name: `Item`)

### App 8 — Android MobileSync (add-mobile-sdk-android → add-smartstore-android → add-mobilesync-android)

1. Run `scaffold_android SkillTest_Android_MobileSync com.skilltest.android.mobilesync $BASE`
2. Apply `add-smartstore-android` (soup name: `Item`)
3. Apply `add-mobilesync-android` (soup: `Item`, sObject: `Contact`)

## Step 4: Build All Apps

### iOS builds (run in parallel using background processes or separate terminals)

First find a simulator UDID to avoid destination-name ambiguity (multiple OS versions with the same device name cause `xcodebuild` to error):

```bash
# Pick an iPhone 16 Pro on iOS 18.x
SIM_ID=$(xcrun simctl list devices available | grep "iPhone 16 Pro " | grep "18\." | head -1 | sed 's/.*(\([A-F0-9-]*\)).*/\1/')
echo "Using simulator: $SIM_ID"
```

Then build:

```bash
for APP in SkillTest_iOS_Full SkillTest_iOS_SDK SkillTest_iOS_SmartStore SkillTest_iOS_MobileSync; do
  (
    cd "$BASE/$APP"
    xcodebuild \
      -workspace "${APP}.xcworkspace" \
      -scheme "$APP" \
      -sdk iphonesimulator \
      -destination "platform=iOS Simulator,id=$SIM_ID" \
      build \
      > "$BASE/${APP}_build.log" 2>&1 \
      && echo "PASS: $APP" \
      || echo "FAIL: $APP (see $BASE/${APP}_build.log)"
  ) &
done
wait
```

### Android builds (run in parallel)

```bash
for APP in SkillTest_Android_Full SkillTest_Android_SDK SkillTest_Android_SmartStore SkillTest_Android_MobileSync; do
  (
    cd "$BASE/$APP"
    ./gradlew assembleDebug \
      > "$BASE/${APP}_build.log" 2>&1 \
      && echo "PASS: $APP" \
      || echo "FAIL: $APP (see $BASE/${APP}_build.log)"
  ) &
done
wait
```

## Step 5: Report Results

Print a summary and the locations of all 8 apps:

```bash
echo ""
echo "=== SDK Consumer Skills Test Results ==="
echo ""
echo "iOS apps (open .xcworkspace in Xcode to run on simulator):"
for APP in SkillTest_iOS_Full SkillTest_iOS_SDK SkillTest_iOS_SmartStore SkillTest_iOS_MobileSync; do
  echo "  $BASE/$APP/${APP}.xcworkspace"
done
echo ""
echo "Android apps (open directory in Android Studio to run on emulator):"
for APP in SkillTest_Android_Full SkillTest_Android_SDK SkillTest_Android_SmartStore SkillTest_Android_MobileSync; do
  echo "  $BASE/$APP"
done
echo ""
echo "Build logs: $BASE/*_build.log"
```

## Manual Testing Checklist

For each app, open it in Xcode / Android Studio and run it on a simulator/emulator:

| App | Expected behaviour |
|-----|--------------------|
| `SkillTest_iOS_Full` | Salesforce login screen on first launch; "Mobile SDK ready" after login |
| `SkillTest_iOS_SDK` | Same as above |
| `SkillTest_iOS_SmartStore` | Salesforce login screen; "SmartStore ready" after login |
| `SkillTest_iOS_MobileSync` | Salesforce login screen; "SmartStore + MobileSync ready" after login |
| `SkillTest_Android_Full` | Salesforce login screen on first launch; "Mobile SDK ready" after login |
| `SkillTest_Android_SDK` | Same as above |
| `SkillTest_Android_SmartStore` | Salesforce login screen; "SmartStore ready" after login |
| `SkillTest_Android_MobileSync` | Salesforce login screen; "SmartStore + MobileSync ready" after login |

## Troubleshooting

**`xcodegen: command not found`** — `brew install xcodegen`

**`pod: command not found`** — `brew install cocoapods`

**iOS build fails with "No such file or directory: .xcworkspace"** — `pod install` was not run, or ran before `xcodegen generate`. Run them in order: `xcodegen generate` → apply consumer skills → `pod install`.

**Android build fails with `OutOfMemoryError`** — Ensure `org.gradle.jvmargs=-Xmx2g` is in `gradle.properties`.

**Android build fails with `android.useAndroidX` error** — Ensure `android.useAndroidX=true` is in `gradle.properties`.

**`gradle-wrapper.jar` missing** — Copy it from any local Android project (e.g. `AndroidNativeKotlinTemplate/gradle/wrapper/gradle-wrapper.jar`).

**iOS build fails with "Unable to find a device matching the provided destination specifier"** — Multiple simulator OS versions have the same device name. Use `xcrun simctl list devices available` to find a UDID for a specific iOS 18.x simulator and pass `-destination "platform=iOS Simulator,id=<UDID>"` instead of using the device name.
