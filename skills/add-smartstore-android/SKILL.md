---
name: add-smartstore-android
description: Add Salesforce SmartStore (encrypted local database) to an existing Android Kotlin app that already has the Mobile SDK integrated.
---

# Add SmartStore to an Android Kotlin App

This skill adds the Salesforce SmartStore encrypted local database to an existing Android Kotlin app that already has the Mobile SDK integrated via the `add-mobile-sdk-android` skill.

## What This Skill Does

1. Upgrades SDK initialization from `MobileSyncSDKManager` to `SmartStoreSDKManager` (no dependency change required — both are in the same artifact)
2. Calls `SmartStoreSDKManager.getInstance().setupUserStoreFromDefaultConfig()` after login
3. Creates `app/src/main/res/raw/userstore.json` with a placeholder soup

## Prerequisites

The app must already have the Mobile SDK wired up. **Check `MainApplication.kt` for `MobileSyncSDKManager.initNative()` or `SmartStoreSDKManager.initNative()`.** If not present, run the `add-mobile-sdk-android` skill first, then return here.

Before starting, confirm:
- **App package name** (e.g. `com.example.myapp`)
- **Soup name** for the initial store table (default: `Item`)

---

## Step 1: No Dependency Change Needed

`SmartStoreSDKManager` is included in the same `com.salesforce.mobilesdk:MobileSync` artifact already present. No `build.gradle.kts` changes are needed.

---

## Step 2: Upgrade SDK Initialization in MainApplication.kt

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

---

## Step 3: Set Up the Store After Login in MainActivity.kt

Call `setupUserStoreFromDefaultConfig()` in `onResume`. Also add a smoke test UI in `onCreate` so you can confirm SmartStore is initializing after login:

**Before:**
```kotlin
override fun onResume(client: RestClient?) {
    // post-login logic
}
```

**After:**
```kotlin
import android.os.Bundle
import android.view.Gravity
import android.widget.TextView
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

After login, you should see **"SmartStore ready"** centered on the screen. This is a smoke test placeholder — replace with your real app UI once verified.

---

## Step 4: Create userstore.json

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

Replace `<SoupName>` with the soup name agreed with the user (default: `Item`).

The SDK reads `userstore.json` automatically from `res/raw/` — no code registration is needed beyond calling `setupUserStoreFromDefaultConfig()`.

---

## Step 5: Build and Verify

```bash
./gradlew assembleDebug
```

Expected: `BUILD SUCCESSFUL`

---

## Checklist

- [ ] `MainApplication.kt` imports `SmartStoreSDKManager` and calls `SmartStoreSDKManager.initNative()`
- [ ] `onCreate()` in `MainActivity.kt` shows the "SmartStore ready" smoke test label
- [ ] `onResume()` in `MainActivity.kt` calls `setupUserStoreFromDefaultConfig()`
- [ ] `app/src/main/res/raw/userstore.json` created with at least one soup
- [ ] Project builds without errors
- [ ] "SmartStore ready" label is shown after login

---

## Troubleshooting

**`setupUserStoreFromDefaultConfig()` silently does nothing**
`userstore.json` must be in `app/src/main/res/raw/` (not `assets/`, not `res/values/`). The SDK resolves it by resource name.

**`Unresolved reference: SmartStoreSDKManager`**
Ensure `com.salesforce.mobilesdk:MobileSync` is in the dependencies and Gradle has synced.
