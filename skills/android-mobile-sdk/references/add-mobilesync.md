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

Swap the Maven artifact from `SmartStore` to `MobileSync`. `MobileSync` transitively pulls `SmartStore` in.

```kotlin
dependencies {
    implementation("com.salesforce.mobilesdk:MobileSync:13.2.0")  // was: SmartStore
}
```

If the app already declared `com.salesforce.mobilesdk:MobileSync` (e.g. via `create-new-app.md`), no `build.gradle.kts` changes are needed.

## Step 2 — `MainApplication.kt`

Swap the manager. `MobileSyncSDKManager` extends `SmartStoreSDKManager` and adds sync orchestration while preserving every existing behavior.

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

## Step 3 — `MainActivity.kt`

Add `setupUserSyncsFromDefaultConfig()` next to the existing store-setup call. `setupUserSyncsFromDefaultConfig()` registers the syncs declared in `usersyncs.json` with the user's `SyncManager`. It does **not** run them (see Step 5).

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

## Step 4 — `app/src/main/res/raw/usersyncs.json`

Create at `app/src/main/res/raw/usersyncs.json` (next to `userstore.json`). The Android template uses the plural filename `usersyncs.json` — the SDK resolves it by raw-resource name.

```json
{
  "syncs": [
    {
      "syncName": "syncDown<SoupName>",
      "syncType": "syncDown",
      "soupName": "<SoupName>",
      "target": {
        "type": "soql",
        "query": "SELECT Id, Name FROM <SObjectType> LIMIT 100"
      },
      "options": {
        "mergeMode": "LEAVE_IF_CHANGED"
      }
    },
    {
      "syncName": "syncUp<SoupName>",
      "syncType": "syncUp",
      "soupName": "<SoupName>",
      "target": {
        "createFieldlist": ["Name"],
        "updateFieldlist": ["Name"]
      },
      "options": {
        "mergeMode": "LEAVE_IF_CHANGED"
      }
    }
  ]
}
```

Replace:

- `<SoupName>` with the soup name used in `userstore.json` — this is the **local** SmartStore table name.
- `<SObjectType>` in the SOQL `FROM` clause with the **Salesforce sObject API name** to sync from (e.g. `Account`, `Contact`).
- Tailor `createFieldlist` and `updateFieldlist` to the fields you want to push. Omitting `target.type` is intentional — the SDK defaults to `CollectionSyncUpTarget`, the standard sync-up target.

> The soup name and the sObject name are often the same but they don't have to be. The soup is a local storage concept; the SOQL target is a server-side Salesforce object.

The SDK reads `usersyncs.json` automatically from `res/raw/` when `setupUserSyncsFromDefaultConfig()` is called. That call **registers** each named sync as a `SyncState` record in SmartStore — it does **not** run any of them. To pull data from Salesforce, invoke a sync explicitly (Step 5).

Constraints:

- `syncType` is `"syncDown"` or `"syncUp"`.
- `soupName` must match a `soupName` declared in `userstore.json`.
- `target.type` for sync-down is one of `"soql"`, `"sosl"`, `"mru"`, `"refresh"`, `"parent_children"`, `"layout"`, `"metadata"`, `"briefcase"`, `"custom"`.
- `options.mergeMode` is `"OVERWRITE"` or `"LEAVE_IF_CHANGED"`.

## Step 5 — Trigger the Sync to Pull Data

After `setupUserSyncsFromDefaultConfig()` has registered the syncs, call `reSync` to run one.

> **`onUpdate` fires asynchronously** as the sync transitions through `RUNNING` → `DONE` / `FAILED`. Re-query the soup and update your UI **inside** the `onUpdate` block when status reaches `DONE` — your view will stay empty if you query before that.

> **Always pass the current user account** to `SyncManager.getInstance(userAccount)`. The no-arg overload uses the default org and will fail for sandbox or multi-org setups.

```kotlin
import com.salesforce.androidsdk.accounts.UserAccount
import com.salesforce.androidsdk.mobilesync.manager.SyncManager
import com.salesforce.androidsdk.mobilesync.util.SyncState

override fun onResume(client: RestClient?) {
    if (client == null) return
    MobileSyncSDKManager.getInstance().setupUserStoreFromDefaultConfig()
    MobileSyncSDKManager.getInstance().setupUserSyncsFromDefaultConfig()

    val user: UserAccount = MobileSyncSDKManager.getInstance().userAccountManager.currentUser
    SyncManager.getInstance(user).reSync("syncDown<SoupName>", object : SyncManager.SyncUpdateCallback {
        override fun onUpdate(sync: SyncState) {
            if (sync.status == SyncState.Status.DONE) {
                // Re-query the soup and update your UI here.
            } else if (sync.status == SyncState.Status.FAILED) {
                Log.e(TAG, "Sync failed: ${sync.error}")
            }
        }
    })
}
```

> **`SyncUpdateCallback` is a regular `interface` (not `fun interface`).** SAM-conversion lambdas don't compile — use the `object :` expression shown above.

## Step 6 — Creating Local Records for Sync-Up

When the user creates a record before it has been pushed to Salesforce, flag it as locally created so sync-up will push it. The server `Id` is filled in on the next sync-up.

```kotlin
import org.json.JSONObject

fun createLocalRecord(name: String) {
    val user = MobileSyncSDKManager.getInstance().userAccountManager.currentUser
    val store = MobileSyncSDKManager.getInstance().getSmartStore(user)

    val entry = JSONObject().apply {
        put("attributes", JSONObject().put("type", "<SalesforceObject>"))  // e.g. "Account"
        put("Name", name)
        put("__local__", true)           // boolean true, not integer 1
        put("__locally_created__", true)
        put("__locally_updated__", false)
        put("__locally_deleted__", false)
    }
    store.upsert("<SoupName>", entry)    // do NOT pre-set _soupEntryId
}
```

> **`__local__` must be a JSON boolean `true`, not `1`.** The SDK's dirty-record query hardcodes `WHERE {soup:__local__} = 'true'` (string comparison). SmartStore serialises a JSON boolean as the string `"true"` when the index type is `"string"` (set in `userstore.json`). An integer `1` never matches.

> **Do not pre-set `_soupEntryId`** before calling `upsert`. SmartStore treats a record that already carries `_soupEntryId` as an update request; if that ID doesn't exist the call is a silent no-op.

## Step 7 — Build

```bash
./gradlew assembleDebug
```

Expected: `BUILD SUCCESSFUL`. After login, you should see **"SmartStore + MobileSync ready"**, and `reSync` will fetch records from Salesforce into the local `<SoupName>` soup. Verify by querying the soup with `SmartStoreInspectorActivity` or your own SmartSQL `SELECT {<SoupName>:_soup} FROM {<SoupName>}` query.

## Next

- Biometric session locking: [`add-biometric-auth.md`](add-biometric-auth.md)
- API class map: [`api-reference.md`](api-reference.md)
- Symptoms: [`troubleshooting.md`](troubleshooting.md)
