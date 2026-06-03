# Android — Add MobileSync

Adds the `MobileSync` library — sObject ⇄ soup sync down/up — on top of an Android Kotlin app that already has SmartStore.

## Preconditions

- `MainApplication.kt` calls `SmartStoreSDKManager.initNative(...)` (or `MobileSyncSDKManager.initNative(...)`).
- `app/src/main/res/raw/userstore.json` exists and declares the target soup.
- `MainActivity.kt` calls `setupUserStoreFromDefaultConfig()` after login.

If not, run [`add-smartstore.md`](add-smartstore.md) first.

## Inputs

| Variable | Example | Notes |
|---|---|---|
| `<SoupName>` | `Account` | Must match a soup in `userstore.json` (local table name) |
| `<SObjectType>` | `Account` | Salesforce sObject API name (server-side) |
| `<SyncName>` | `syncDownAccounts` | The `syncName` declared in `usersyncs.json` |

The soup name and sObject name are independent — they often match for convenience but do not have to.

## Step 1 — Dependency

`MobileSync` is included transitively by `com.salesforce.mobilesdk:MobileSync`. No `build.gradle.kts` changes are needed.

## Step 2 — `MainApplication.kt`

Swap the manager. `MobileSyncSDKManager` extends `SmartStoreSDKManager` and adds sync orchestration while preserving every existing behavior.

```kotlin
package <PackageName>

import android.app.Application
import com.salesforce.androidsdk.mobilesync.app.MobileSyncSDKManager   // was: com.salesforce.androidsdk.smartstore.app.SmartStoreSDKManager

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        MobileSyncSDKManager.initNative(applicationContext, MainActivity::class.java)
    }
}
```

## Step 3 — `MainActivity.kt`

Add `setupUserSyncsFromDefaultConfig()` next to the existing store-setup call. `setupUserSyncsFromDefaultConfig()` registers the syncs declared in `usersyncs.json` with the user's `SyncManager`. To execute one, call `SyncManager.runSync(...)`/`reSync(...)` by name; the `setup*` calls do not auto-run syncs.

This is an **additive** edit — preserve the existing `setContentView(R.layout.main)`, `findViewById(...)` calls, and the existing `onResume(client: RestClient?)` body. Add the new line inside `onResume(client:)` alongside the SmartStore call:

```kotlin
import com.salesforce.androidsdk.mobilesync.app.MobileSyncSDKManager

override fun onResume(client: RestClient?) {
    if (client == null) return
    MobileSyncSDKManager.getInstance().setupUserStoreFromDefaultConfig()
    MobileSyncSDKManager.getInstance().setupUserSyncsFromDefaultConfig()
    // … existing onResume(client:) body …
}
```

## Step 4 — `app/src/main/res/raw/usersyncs.json`

Create at `app/src/main/res/raw/usersyncs.json` (next to `userstore.json`). The Android template uses the plural filename `usersyncs.json` — the SDK resolves it by raw-resource name.

```json
{
  "syncs": [
    {
      "syncName": "<SyncName>",
      "syncType": "syncDown",
      "soupName": "<SoupName>",
      "target": {
        "type": "soql",
        "query": "SELECT Id, Name FROM <SObjectType> LIMIT 100"
      },
      "options": {
        "fieldlist": ["Id", "Name", "LastModifiedDate"],
        "mergeMode": "LEAVE_IF_CHANGED"
      }
    }
  ]
}
```

Constraints:

- `syncType` is `"syncDown"` or `"syncUp"`.
- `soupName` must match a `soupName` declared in `userstore.json`.
- `target.type` for sync-down is one of `"soql"`, `"sosl"`, `"mru"`, `"refresh"`, `"parent_children"`, `"layout"`, `"metadata"`, `"briefcase"`, `"custom"`. SOQL is the default for record-set syncs.
- `options.mergeMode` is `"OVERWRITE"` or `"LEAVE_IF_CHANGED"`.

## Step 5 — Build

```bash
./gradlew assembleDebug
```

Expected: `BUILD SUCCESSFUL`. After login the placeholder view reads "SmartStore + MobileSync ready" and the configured syncs are registered.

## Next

- Biometric session locking: [`add-biometric-auth.md`](add-biometric-auth.md)
- API class map: [`api-reference.md`](api-reference.md)
- Symptoms: [`troubleshooting.md`](troubleshooting.md)
