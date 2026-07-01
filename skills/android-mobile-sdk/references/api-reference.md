# Android — API Reference

The Android SDK uses a linear class hierarchy; each scenario in this skill swaps the active manager class for one farther down the chain without changing other code paths.

## Manager Hierarchy

```
SalesforceSDKManager
        ▲
SmartStoreSDKManager        ← adds setupUserStoreFromDefaultConfig() and soup APIs
        ▲
MobileSyncSDKManager        ← adds setupUserSyncsFromDefaultConfig() and SyncManager
```

The same singleton instance is reachable through any superclass via `getInstance()`. When the manifest registers an `Application` subclass that calls `MobileSyncSDKManager.initNative(...)`, calls to `SalesforceSDKManager.getInstance()` return the same singleton — there is no separate manager per module.

## Maven Artifacts

Each artifact transitively pulls the lower one:

| Artifact | Pulls | When to use |
|---|---|---|
| `com.salesforce.mobilesdk:SalesforceSDK` | — | Base auth + REST only |
| `com.salesforce.mobilesdk:SmartStore` | `SalesforceSDK` | Encrypted local DB |
| `com.salesforce.mobilesdk:MobileSync` | `SmartStore` (and `SalesforceSDK`) | Cloud sync |

Pin a single version per app (e.g. `13.2.0`).

## Key Types

| Class | Package | Used For |
|---|---|---|
| `SalesforceSDKManager` | `com.salesforce.androidsdk.app` | Base init, `logout(activity)`, dark-theme detection, `biometricAuthenticationManager` |
| `SmartStoreSDKManager` | `com.salesforce.androidsdk.smartstore.app` | Soup management, `setupUserStoreFromDefaultConfig()` |
| `MobileSyncSDKManager` | `com.salesforce.androidsdk.mobilesync.app` | Sync orchestration, `setupUserSyncsFromDefaultConfig()` |
| `SalesforceActivity` | `com.salesforce.androidsdk.ui` | Base activity that drives OAuth and supplies `RestClient` to `onResume(RestClient?)` |
| `LoginActivity` | `com.salesforce.androidsdk.ui` | OAuth login activity (registered automatically; subclass for QR-code login flows) |
| `RestClient` | `com.salesforce.androidsdk.rest` | Authenticated REST/SOQL client; non-null after login |
| `RestRequest` | `com.salesforce.androidsdk.rest` | Builder for REST/SOQL requests (e.g. `RestRequest.getRequestForQuery(...)`) |
| `ApiVersionStrings` | `com.salesforce.androidsdk.rest` | Looks up the API version string for the host context |
| `SyncManager` | `com.salesforce.androidsdk.mobilesync.manager` | Per-user sync coordinator; runs/registers syncs declared in `usersyncs.json` |
| `SyncManager.SyncUpdateCallback` | `com.salesforce.androidsdk.mobilesync.manager` | `interface` (not `fun interface`) — must be implemented with `object :`, not a lambda |
| `SyncOptions` | `com.salesforce.androidsdk.mobilesync.util` | Sync-up / sync-down options builder |
| `SyncState` | `com.salesforce.androidsdk.mobilesync.util` | Sync result/state object; `SyncState.Status.{NEW,RUNNING,DONE,FAILED}` |
| `SoqlSyncDownTarget` | `com.salesforce.androidsdk.mobilesync.target` | SOQL-based sync-down target |
| `BiometricAuthenticationManager` | `com.salesforce.androidsdk.security` | Reachable as `SalesforceSDKManager.getInstance().biometricAuthenticationManager` |
| `PushService` | `com.salesforce.androidsdk.push` | Push registration entry point — subclass to handle Salesforce push registration |
| `PushMessaging` | `com.salesforce.androidsdk.push` | Static helper for triggering push registration / unregistration |

## Common Method Signatures

- `SalesforceSDKManager.getInstance().logout(this)` — terminates the session and returns the user to the login screen.
- `MobileSyncSDKManager.initNative(applicationContext, MainActivity::class.java)` — registered in `Application.onCreate()`.
- `SmartStoreSDKManager.getInstance().setupUserStoreFromDefaultConfig()` — reads `res/raw/userstore.json`.
- `MobileSyncSDKManager.getInstance().setupUserSyncsFromDefaultConfig()` — reads `res/raw/usersyncs.json`; registers but does not run syncs.
- `SyncManager.getInstance(currentUser).reSync(syncName, callback)` — runs a registered sync; callback fires on `RUNNING`/`DONE`/`FAILED` transitions.
- `RestRequest.getRequestForQuery(ApiVersionStrings.getVersionNumber(this), soql)` — builds a SOQL query request.
- `client.sendAsync(restRequest, AsyncRequestCallback { … })` — runs a REST request on the SDK's worker pool.
- `BiometricManager.from(this).canAuthenticate(BIOMETRIC_STRONG or BIOMETRIC_WEAK)` — Android-side capability check before presenting the SDK opt-in dialog.

## Source of Truth

When this map disagrees with reality, the SDK source wins.

- Repo: <https://github.com/forcedotcom/SalesforceMobileSDK-Android>
