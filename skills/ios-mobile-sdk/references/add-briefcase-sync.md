# iOS — Add Briefcase Sync

Makes an iOS Swift app work offline from an **existing Salesforce briefcase**: a MobileSync sync-down that uses `BriefcaseSyncDownTarget` to pull every record the user's briefcase contains (across several object types) into SmartStore soups.

## Preconditions

- MobileSync is already wired up: `AppDelegate.swift` calls `MobileSyncSDKManager.initializeSDK()`, `userstore.json` and `usersyncs.json` exist in the target source folder (and in **Copy Bundle Resources**), and `SceneDelegate.swift` calls `setupUserSyncsFromDefaultConfig()`.

  If not, run [`add-mobilesync.md`](add-mobilesync.md) first (it chains back to `add-smartstore.md` and `add-mobile-sdk.md` as needed).
- **Org side (not something the skill can do):** a briefcase is configured in the org and assigned to the user who logs in. If not, the sync still succeeds and simply returns no records. Tell the user this; do not try to create the briefcase.

## Inputs

Collect these from the request. If an object's field list is not given, ask; do not guess business fields.

| Variable | Example | Notes |
|---|---|---|
| `<SObjectType>` (one per object) | `Account`, `Contact` | Salesforce sObject API name. Only types listed here are synced, even if the briefcase contains more |
| `<SoupName>` (one per object) | `Account`, `Contact` | **Local** soup for that object type. One soup per object type; never share a soup between types |
| `<FieldList>` (one per object) | `["Id", "Name", "Phone"]` | Fields fetched for each record |
| `<IdField>` (optional) | `Id` | Defaults to `Id` |
| `<ModDateField>` (optional) | `LastModifiedDate` | Defaults to `LastModifiedDate` |
| `<SyncName>` | `syncDownBriefcase` | Name used to trigger the sync. Pick a **new** name: on an already-initialized installation the SDK keeps the existing sync of that name, so reusing the old name would not pick up the briefcase definition |
| `<MergeMode>` | `OVERWRITE` | `OVERWRITE` or `LEAVE_IF_CHANGED`. A mode given in the request wins; otherwise reuse the existing sync-down's mode |

## Step 0 — Detect Project Shape

No dependency change is needed: `BriefcaseSyncDownTarget` ships in the `MobileSync` library the app already links. Still, list the project root and note the shape, because it decides how the edited resource files are picked up:

- `Podfile` and/or `project.yml`: the JSON files already exist and are already in the target, so no file-list change is needed. If `project.yml` exists, still run `xcodegen generate` after your edits (it keeps the project in sync). Generation removes the app project's CocoaPods integration, so if a `Podfile` also exists (Hybrid), **always** run `pod install` right after `xcodegen generate`, even when `Pods/` and the `.xcworkspace` already exist; otherwise `MobileSync` and `SalesforceSDKCore` are missing at build time. For a Podfile-only project, run `pod install` only if there is no `Pods/` folder or `.xcworkspace` yet.
- Plain `.xcodeproj`: nothing to do.

State the shape you found. If `MobileSync` is not linked (no `pod 'MobileSync'` / no `MobileSync` product), stop and run [`add-mobilesync.md`](add-mobilesync.md) Step 0–1 first. Do not add a second dependency path. Never mix CocoaPods and SPM linking.

## Step 1 — `userstore.json`: one soup per object type

Open `<AppName>/userstore.json`. For every `<SoupName>` that is not already declared, add a soup. Keep the existing soups untouched. Mirror the existing soup's indexes: `Id`, one display field of your choice (e.g. `LastName` for Contact), and `__local__`, each with the same `type` the existing soup uses. Indexing every synced field is unnecessary.

```json
{
  "soups": [
    {
      "soupName": "Account",
      "indexes": [
        { "path": "Id",        "type": "string" },
        { "path": "Name",      "type": "string" },
        { "path": "__local__", "type": "string" }
      ]
    },
    {
      "soupName": "Contact",
      "indexes": [
        { "path": "Id",        "type": "string" },
        { "path": "LastName",  "type": "string" },
        { "path": "__local__", "type": "string" }
      ]
    }
  ]
}
```

If `<IdField>` is not `Id`, index that path instead of `Id`. Copy index `type` values from the existing soup (`string`, `full_text`, …) rather than inventing new ones.

## Step 2 — `usersyncs.json`: replace the sync-down with a briefcase sync-down

Open `<AppName>/usersyncs.json`. **Replace** the existing `syncType: "syncDown"` entry (typically the `soql` one) with the entry below. Leave every `syncUp` entry as it is. If the user asks to keep the old SOQL sync as well, keep it, but use a different `syncName`.

```json
{
  "syncName": "<SyncName>",
  "syncType": "syncDown",
  "soupName": "<SoupName of the first object>",
  "target": {
    "type": "briefcase",
    "infos": [
      {
        "sobjectType": "Account",
        "soupName": "Account",
        "fieldlist": ["Id", "Name", "Phone"]
      },
      {
        "sobjectType": "Contact",
        "soupName": "Contact",
        "fieldlist": ["Id", "FirstName", "LastName"]
      }
    ]
  },
  "options": {
    "mergeMode": "<MergeMode>"
  }
}
```

Rules for this entry:

- `target.type` is `"briefcase"`. The other keys are `infos` (required) and `countIdsPerRetrieve` (optional; the default and maximum is 200, so omit it unless asked).
- Each `infos` entry needs `sobjectType`, `soupName` and `fieldlist`. `idFieldName` and `modificationDateFieldName` are optional and default to `Id` and `LastModifiedDate`; add them only for custom id / timestamp fields.
- Every `infos[].soupName` must match a soup declared in `userstore.json` (Step 1).
- The top-level `soupName` is required by the config parser but is **not used** for briefcase targets (each `infos` entry carries its own soup). Set it to the first object's soup.
- `syncName` must be unique in the file.

## Step 3 — `SceneDelegate.swift`: trigger the sync and reload every soup

The existing code already calls `reSync(named:)` for the old sync-down name inside `setupRootViewController()`. Change the name to `<SyncName>`, and make the `.done` branch refresh **every** soup the sync fills, not just one. Keep the structure from `add-mobilesync.md` Step 3 (the `onUpdate` block fires asynchronously; reload inside it).

```swift
if let user = UserAccountManager.shared.currentUserAccount {
    let syncManager = SyncManager.sharedInstance(forUserAccount: user)
    try? syncManager.reSync(named: "<SyncName>") { sync in
        if sync.status == .done {
            DispatchQueue.main.async {
                listVC.reloadFromStore()   // re-query the Account soup and the Contact soup
            }
        } else if sync.status == .failed {
            NSLog("Sync \(sync.name ?? "<unnamed>") failed")
        }
    }
}
```

If the stand-in `MyAccountsViewController` is still the stub from `add-mobilesync.md`, leave it (and keep `reloadFromStore()` empty if the user asked for a stub); optionally update its comment to mention every soup. If the user asked for a different UI, keep that request and only change what the sync needs.

No new Swift imports are needed (`MobileSync`, `SalesforceSDKCore`).

## Behavior to know (and to tell the user)

- **IDs first, records second.** The target asks the priming-records API (`/connect/briefcase/priming-records`) for the record IDs, then fetches the fields with Collection Retrieve in slices of up to 200 IDs, one call per object type.
- **Types not in `infos` are skipped.** If the briefcase has `Opportunity` records but no `infos` entry for `Opportunity`, they are not synced.
- **Re-sync is incremental** (it only asks for IDs changed since the last sync); **ghost cleanup** removes local, non-dirty records that are no longer in the briefcase, across all the sync's soups.
- **Dirty records are protected.** Locally modified records are not overwritten by `LEAVE_IF_CHANGED`.
- **Large briefcases.** The SDK reports an approximate total size; do not build a progress bar that assumes an exact total.
- The SDK registers the `BC` app-feature marker by itself; no extra code.

## Step 4 — Build

CocoaPods or Hybrid (workspace):

```bash
xcodebuild -workspace <AppName>.xcworkspace -scheme <AppName> -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

xcodegen + SPM or plain SPM (project):

```bash
xcodebuild -project <AppName>.xcodeproj -scheme <AppName> -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Do **not** pass `CODE_SIGNING_ALLOWED=NO`. Also validate both JSON files parse:

```bash
python3 -m json.tool < <AppName>/userstore.json > /dev/null
python3 -m json.tool < <AppName>/usersyncs.json > /dev/null
```

Checklist before finishing:

- [ ] Every `infos[].soupName` exists in `userstore.json`
- [ ] The briefcase sync-down replaced the old sync-down; the `syncUp` entries are unchanged
- [ ] `reSync(named:)` uses `<SyncName>`; the `.done` branch covers every soup
- [ ] No dependency changes were made
- [ ] The user was told the briefcase must exist in the org and be assigned to the user

## Next

- Symptoms: [`troubleshooting.md`](troubleshooting.md) (MobileSync → briefcase rows)
- API name resolution: [`api-reference.md`](api-reference.md)
- Biometric session locking: [`add-biometric-auth.md`](add-biometric-auth.md)
