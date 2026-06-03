# Android — Add SmartStore

Adds the encrypted local database `SmartStore` to an Android Kotlin app that already has the Mobile SDK wired up.

## Preconditions

- `MainApplication.kt` calls one of `MobileSyncSDKManager.initNative(...)`, `SmartStoreSDKManager.initNative(...)`, or `SalesforceSDKManager.initNative(...)`.
- `bootconfig.xml`, `servers.xml`, and `strings.xml` are populated.
- `MainActivity` extends `SalesforceActivity`.

If not, run [`add-mobile-sdk.md`](add-mobile-sdk.md) first.

## Inputs

| Variable | Example | Notes |
|---|---|---|
| `<SoupName>` | `Account` | The local SmartStore table name |

## Step 1 — Dependency

`SmartStore` is included transitively by `com.salesforce.mobilesdk:MobileSync`. No `build.gradle.kts` changes are needed.

## Step 2 — `MainApplication.kt`

If the app was created from [`add-mobile-sdk.md`](add-mobile-sdk.md) (or from the canonical `AndroidNativeKotlinTemplate`), `MainApplication.kt` already calls `MobileSyncSDKManager.initNative(...)`. **Leave it unchanged** — `MobileSyncSDKManager` extends `SmartStoreSDKManager`, so all SmartStore APIs are reachable through `MobileSyncSDKManager.getInstance()`.

Only swap to `SmartStoreSDKManager.initNative(...)` if the app explicitly does **not** want MobileSync (cloud sync). In that less common case:

```kotlin
package <PackageName>

import android.app.Application
import com.salesforce.androidsdk.smartstore.app.SmartStoreSDKManager   // was: com.salesforce.androidsdk.app.SalesforceSDKManager

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        SmartStoreSDKManager.initNative(applicationContext, MainActivity::class.java)
    }
}
```

## Step 3 — `MainActivity.kt`

Register the soup after login by calling `setupUserStoreFromDefaultConfig()` from the existing `onResume(client: RestClient?)`. Guard on a non-null client so the call is skipped during the pre-login phase.

This is an **additive** edit — preserve the existing `setContentView(R.layout.main)`, `findViewById(...)` calls, and any other body the activity already has. Add the import and the new line inside `onResume(client:)`:

```kotlin
import com.salesforce.androidsdk.mobilesync.app.MobileSyncSDKManager

override fun onResume(client: RestClient?) {
    if (client == null) return
    MobileSyncSDKManager.getInstance().setupUserStoreFromDefaultConfig()
    // … existing onResume(client:) body …
}
```

When the app does not initialize MobileSync (the swap path in Step 2), substitute `SmartStoreSDKManager.getInstance()` for `MobileSyncSDKManager.getInstance()` — both expose `setupUserStoreFromDefaultConfig()` and resolve to the same singleton when the manager hierarchy is in place.

`setupUserStoreFromDefaultConfig()` reads `userstore.json` from `res/raw/` and creates the configured soups in the encrypted store for the current user. The call is safe to make even before any soups are declared — `StoreConfig.hasSoups()` returns `false` when no soups are configured and no soups are created. Once `app/src/main/res/raw/userstore.json` is added with at least one soup definition, the same call registers those soups.

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

The Android resource system resolves `userstore.json` by raw-resource name only (no nesting). The file must be at `app/src/main/res/raw/userstore.json` exactly.

## Step 5 — Build

```bash
./gradlew assembleDebug
```

Expected: `BUILD SUCCESSFUL`. After login, the placeholder view reads "SmartStore ready" and `<SoupName>` is registered.

## Next

- Cloud sync into the same soup: [`add-mobilesync.md`](add-mobilesync.md)
- Symptoms (e.g. `setupUserStoreFromDefaultConfig()` silently does nothing): [`troubleshooting.md`](troubleshooting.md)
