# iOS — API Reference (Swift ↔ Objective-C Names)

The Salesforce Mobile SDK for iOS is implemented mostly in Objective-C with a smaller Swift surface. Headers expose Swift-facing names via `NS_SWIFT_NAME(...)` annotations on each class. From Swift, use the Swift-visible name.

When the compiler reports `cannot find 'X' in scope` from Swift, the fix is the corresponding Swift-visible name from the table below — not a hunt for a "newer" replacement type.

## Class Name Map

| Use from Swift | Underlying Objective-C class | Module |
|---|---|---|
| `SalesforceManager` | `SalesforceSDKManager` (annotated `NS_SWIFT_NAME(SalesforceManager)`) | `SalesforceSDKCore` |
| `SmartStoreSDKManager` | `SmartStoreSDKManager` (no `SF` prefix; same name in Swift and Obj-C) | `SmartStore` |
| `MobileSyncSDKManager` | `MobileSyncSDKManager` (no `SF` prefix; same name in Swift and Obj-C) | `MobileSync` |
| `UserAccountManager` | `SFUserAccountManager` | `SalesforceSDKCore` |
| `AuthHelper` | `SFSDKAuthHelper` | `SalesforceSDKCore` |
| `BiometricAuthenticationManager` (Swift `protocol`) | `SFBiometricAuthenticationManager` (protocol); concrete singleton is `BiometricAuthenticationManagerInternal` (internal — do not instantiate from app code) | `SalesforceSDKCore` |
| `PushNotificationManager` | `SFPushNotificationManager` | `SalesforceSDKCore` |
| `SyncManager` | `SFMobileSyncSyncManager` | `MobileSync` |
| `SyncOptions` | `SFSyncOptions` | `MobileSync` |
| `SyncState` | `SFSyncState` | `MobileSync` |
| `SoqlSyncDownTarget` | `SFSoqlSyncDownTarget` | `MobileSync` |
| `SoslSyncDownTarget` | `SFSoslSyncDownTarget` | `MobileSync` |
| `MruSyncDownTarget` | `SFMruSyncDownTarget` | `MobileSync` |
| `SyncUpTarget` | `SFSyncUpTarget` | `MobileSync` |

The `SDKManager` chain extends linearly: `SalesforceSDKManager` ← `SmartStoreSDKManager` ← `MobileSyncSDKManager`. The same singleton is reachable through any superclass. The Swift name `SalesforceManager` exists only because the original Obj-C class was named `SalesforceSDKManager` and the Swift alias was added later.

## Method/Property Quirks

- `UserAccountManager.shared` is a **property**, not a method — `UserAccountManager.shared.currentUserAccount`, not `UserAccountManager.shared().currentUser`.
- `SalesforceManager.shared.biometricAuthenticationManager()` is a **method** call (the Obj-C accessor on `SalesforceSDKManager` is `- (id <SFBiometricAuthenticationManager>)biometricAuthenticationManager;` — bridged to Swift as a parenthesized accessor).
- `SyncManager.sharedInstance` is overloaded — three Swift forms exist:
  - `sharedInstance(forUserAccount:)` — for an `SFUserAccount` (the most common direct use).
  - `sharedInstance(named:forUserAccount:)` — for a named store under a user.
  - `sharedInstance(store:)` — for an `SFSmartStore` directly (the pattern the `iOSNativeSwiftTemplate` uses, e.g. `SyncManager.sharedInstance(store: store!)` in `AccountsListModel.swift`).
  Plain `for:` is not a valid label.
- `SoqlSyncDownTarget` has no Swift initializer — construct it via the class method `SoqlSyncDownTarget.newSyncTarget(_:)`.
- `SyncOptions` builders are separate per direction:
  - `SyncOptions.newSyncOptions(forSyncDown:)` — argument is the merge mode.
  - `SyncOptions.newSyncOptions(forSyncUp:)` — argument is the field-list array.
  - `SyncOptions.newSyncOptions(forSyncUp:mergeMode:)` — field list plus merge mode.
- `SyncState.name` is the sync's human name (the `Name` column of `SFSyncState`). It is **not** `syncName` — that is only a JSON-config key (`kSyncsConfigSyncName = @"syncName"`). When logging from inside a `reSync(named:onUpdate:)` closure, use `sync.name`.
- `BiometricAuthenticationManager.locked` reads the SDK's locked state. The protocol has no static `.shared`; obtain the manager via `SalesforceManager.shared.biometricAuthenticationManager().locked`.

## Resolving the Source of Truth

When this table disagrees with reality, the SDK headers/Swift sources win.

- Repo: <https://github.com/forcedotcom/SalesforceMobileSDK-iOS>
- Sample searches: `NS_SWIFT_NAME(SyncManager)`, `NS_SWIFT_NAME(SalesforceManager)`. The header that owns the Swift name also documents the Swift parameter labels for each method.
- Working examples: <https://github.com/forcedotcom/SalesforceMobileSDK-Templates/tree/dev/iOSNativeSwiftTemplate>.
