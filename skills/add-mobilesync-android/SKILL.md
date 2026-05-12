---
name: add-mobilesync-android
description: Add Salesforce MobileSync (cloud data sync) to an existing Android Kotlin app that already has SmartStore integrated.
---

# Add MobileSync to an Android Kotlin App

This skill adds Salesforce MobileSync to an existing Android Kotlin app that already has SmartStore integrated via the `add-smartstore-android` skill.

## What This Skill Does

1. Upgrades SDK initialization back to `MobileSyncSDKManager` (the top of the SDK manager hierarchy)
2. Calls `MobileSyncSDKManager.getInstance().setupUserSyncsFromDefaultConfig()` after login alongside the existing store setup
3. Creates `app/src/main/res/raw/usersyncs.json` with placeholder sync definitions

## Prerequisites

The app must already have SmartStore integrated. **Check `MainApplication.kt` for `SmartStoreSDKManager.initNative()` and `MainActivity.kt` for `setupUserStoreFromDefaultConfig()`.** If not present:

1. If the app has no Mobile SDK at all, run `add-mobile-sdk-android` first.
2. Then run `add-smartstore-android`.
3. Then return here.

Before starting, confirm:
- **Soup name** used in `userstore.json` (the sync will target this soup)
- **Salesforce sObject API name** to sync from (e.g. `Account`, `Contact`) — this is the server-side object, not necessarily the same as the soup name

---

## Step 1: No Dependency Change Needed

`MobileSyncSDKManager` is included in the same `com.salesforce.mobilesdk:MobileSync` artifact already present. No `build.gradle.kts` changes are needed.

---

## Step 2: Upgrade SDK Initialization in MainApplication.kt

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

---

## Step 3: Add Sync Setup in MainActivity.kt

Add `setupUserSyncsFromDefaultConfig()` alongside the existing store setup call in `onResume`. Also update the smoke test label in `onCreate` to reflect MobileSync is now active:

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
import android.os.Bundle
import android.view.Gravity
import android.widget.TextView
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

After login, you should see **"SmartStore + MobileSync ready"** centered on the screen. This is a smoke test placeholder — replace with your real app UI once verified.

---

## Step 4: Create usersyncs.json

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
- `<SalesforceObject>` in the SOQL `FROM` clause with the **Salesforce sObject API name** to sync from (e.g. `Account`, `Contact`) — this query runs on the server

> The soup name and the sObject name are often the same (e.g. soup `Account`, query `FROM Account`) but they don't have to be. The soup is a local storage concept; the SOQL target is a server-side Salesforce object.

The SDK reads `usersyncs.json` automatically from `res/raw/` — no code registration is needed beyond calling `setupUserSyncsFromDefaultConfig()`.

---

## Step 5: Build and Verify

```bash
./gradlew assembleDebug
```

Expected: `BUILD SUCCESSFUL`

---

## Checklist

- [ ] `MainApplication.kt` imports `MobileSyncSDKManager` and calls `MobileSyncSDKManager.initNative()`
- [ ] `onCreate()` in `MainActivity.kt` shows the "SmartStore + MobileSync ready" smoke test label
- [ ] `onResume()` in `MainActivity.kt` calls both `setupUserStoreFromDefaultConfig()` and `setupUserSyncsFromDefaultConfig()`
- [ ] `app/src/main/res/raw/usersyncs.json` created with at least one sync targeting the correct soup
- [ ] SOQL `FROM` clause references a Salesforce sObject, not the local soup name
- [ ] Project builds without errors
- [ ] "SmartStore + MobileSync ready" label is shown after login

---

## Troubleshooting

**`setupUserSyncsFromDefaultConfig()` silently does nothing**
`usersyncs.json` must be in `app/src/main/res/raw/`. The SDK resolves it by resource name.

**Sync fails at runtime with "Soup not found"**
The `soupName` in `usersyncs.json` must exactly match the `soupName` in `userstore.json`.

**`Unresolved reference: MobileSyncSDKManager`**
Ensure `com.salesforce.mobilesdk:MobileSync` is in the dependencies and Gradle has synced.
