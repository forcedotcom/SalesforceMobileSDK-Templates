# Android — Add SmartStore

Adds the encrypted local database `SmartStore` to an Android Kotlin app that already has the Mobile SDK wired up.

## Preconditions

- `MainApplication.kt` calls one of `SalesforceSDKManager.initNative(...)`, `SmartStoreSDKManager.initNative(...)`, or `MobileSyncSDKManager.initNative(...)`.
- `bootconfig.xml`, `servers.xml`, and `strings.xml` are populated.
- `MainActivity` extends `SalesforceActivity`.

If not, run [`add-mobile-sdk.md`](add-mobile-sdk.md) first.

## Inputs

| Variable | Example | Notes |
|---|---|---|
| `<SoupName>` | `Account` | The local SmartStore table name |

## Step 1 — Dependency

Swap the Maven artifact from `SalesforceSDK` to `SmartStore`. `SmartStore` transitively pulls `SalesforceSDK` in.

```kotlin
dependencies {
    implementation("com.salesforce.mobilesdk:SmartStore:13.2.0")  // was: SalesforceSDK
}
```

If the app already declared `com.salesforce.mobilesdk:MobileSync` (e.g. via `create-new-app.md`), no `build.gradle.kts` changes are needed — SmartStore is already on the classpath.

## Step 2 — `MainApplication.kt`

Swap the manager. `SmartStoreSDKManager` extends `SalesforceSDKManager` and adds soup management while preserving every OAuth and REST behavior.

**Before:**
```kotlin
import com.salesforce.androidsdk.app.SalesforceSDKManager

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        SalesforceSDKManager.initNative(applicationContext, MainActivity::class.java)
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

If the app already used `MobileSyncSDKManager.initNative(...)`, leave it — `MobileSyncSDKManager` extends `SmartStoreSDKManager`, so all SmartStore APIs are reachable through `MobileSyncSDKManager.getInstance()`.

## Step 3 — `MainActivity.kt`

Add `setupUserStoreFromDefaultConfig()` in `onResume(client: RestClient?)`:

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

## Step 4 — `app/src/main/res/raw/userstore.json`

Create the `raw/` directory if it does not exist.

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

Constraints:

- `soupName` must be a non-empty string.
- Each index entry needs `path` and `type`. Supported `type` values: `string`, `integer`, `floating`, `full_text`, `json1`.
- `__local__` is reserved for marking dirty rows that need to be uploaded by MobileSync.

The Android resource system resolves `userstore.json` by raw-resource name only (no nesting). The file must be at `app/src/main/res/raw/userstore.json` exactly. The SDK reads it automatically when `setupUserStoreFromDefaultConfig()` is called — no code registration is needed beyond that call.

## Step 5 — Build

```bash
./gradlew assembleDebug
```

Expected: `BUILD SUCCESSFUL`. After login, the placeholder view reads "SmartStore ready" and `<SoupName>` is registered.

## Next

- Cloud sync into the same soup: [`add-mobilesync.md`](add-mobilesync.md)
- Symptoms (e.g. `setupUserStoreFromDefaultConfig()` silently does nothing): [`troubleshooting.md`](troubleshooting.md)
