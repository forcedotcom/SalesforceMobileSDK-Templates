# Android — Add Briefcase Sync

Makes an Android Kotlin app work offline from an **existing Salesforce briefcase**: a MobileSync sync-down that uses `BriefcaseSyncDownTarget` to pull every record the user's briefcase contains (across several object types) into SmartStore soups.

## Preconditions

- MobileSync is already wired up: `MainApplication.kt` calls `MobileSyncSDKManager.initNative(...)`, `app/src/main/res/raw/userstore.json` and `app/src/main/res/raw/usersyncs.json` exist, and `MainActivity.kt` calls `setupUserSyncsFromDefaultConfig()`.

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

## Step 1 — `userstore.json`: one soup per object type

Open `app/src/main/res/raw/userstore.json`. For every `<SoupName>` that is not already declared, add a soup. Keep the existing soups untouched. Mirror the existing soup's indexes: `Id`, one display field of your choice (e.g. `LastName` for Contact), and `__local__`, each with the same `type` the existing soup uses. Indexing every synced field is unnecessary.

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

If `<IdField>` is not `Id`, index that path instead of `Id`. The soup's id path must match the id field the sync uses.

## Step 2 — `usersyncs.json`: replace the sync-down with a briefcase sync-down

Open `app/src/main/res/raw/usersyncs.json`. **Replace** the existing `syncType: "syncDown"` entry (typically the `soql` one) with the entry below. Leave every `syncUp` entry as it is. If the user asks to keep the old SOQL sync as well, keep it, but use a different `syncName`.

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

## Step 3 — Trigger the sync and reload every soup

In `MainActivity.kt`, the existing code already calls `reSync` for the old sync-down name inside `onResume(client)`. Change the name to `<SyncName>`, and make the `DONE` branch refresh **every** soup the sync fills, not just one.

```kotlin
val user: UserAccount = MobileSyncSDKManager.getInstance().userAccountManager.currentUser
SyncManager.getInstance(user).reSync("<SyncName>", object : SyncManager.SyncUpdateCallback {
    override fun onUpdate(sync: SyncState) {
        if (sync.status == SyncState.Status.DONE) {
            // Re-query the Account soup and the Contact soup and update your UI here.
        } else if (sync.status == SyncState.Status.FAILED) {
            Log.e(TAG, "Sync failed: ${sync.error}")
        }
    }
})
```

The same rules as `add-mobilesync.md` Step 5 apply: pass the current user to `SyncManager.getInstance(user)`, use the `object :` form (`SyncUpdateCallback` is not a `fun interface`), and reload inside the callback on `DONE`. Keep any stub the user asked for.

"After login" means inside `onResume(client: RestClient)`, as in `add-mobilesync.md`. If there is no `reSync` call yet (the app only registers syncs), add the block above after `setupUserSyncsFromDefaultConfig()` there.

If the request names a login host, check `app/src/main/res/xml/servers.xml` already has it; edit only if it does not.

### Optional — build the target in code instead of `usersyncs.json`

Only if the user explicitly asks for a programmatic sync. The `BriefcaseObjectInfo` constructor takes **`soupName` first**, then `sobjectType`:

```kotlin
import com.salesforce.androidsdk.mobilesync.target.BriefcaseSyncDownTarget
import com.salesforce.androidsdk.mobilesync.util.BriefcaseObjectInfo
import com.salesforce.androidsdk.mobilesync.util.SyncOptions
import com.salesforce.androidsdk.mobilesync.util.SyncState

val target = BriefcaseSyncDownTarget(
    listOf(
        BriefcaseObjectInfo("Account", "Account", listOf("Id", "Name", "Phone")),
        BriefcaseObjectInfo("Contact", "Contact", listOf("Id", "FirstName", "LastName"))
    )
)
val options = SyncOptions.optionsForSyncDown(SyncState.MergeMode.OVERWRITE)
SyncManager.getInstance(user).syncDown(target, options, "Account", "<SyncName>", callback)
```

## Behavior to know (and to tell the user)

- **IDs first, records second.** The target asks the priming-records API (`/connect/briefcase/priming-records`) for the record IDs, then fetches the fields with Collection Retrieve in slices of up to 200 IDs, one call per object type.
- **Types not in `infos` are skipped.** If the briefcase has `Opportunity` records but no `infos` entry for `Opportunity`, they are not synced.
- **Re-sync is incremental** (it only asks for IDs changed since the last sync); **ghost cleanup** (`cleanResyncGhosts`) removes local, non-dirty records that are no longer in the briefcase, across all the sync's soups.
- **Dirty records are protected.** Locally modified records in any of the sync's soups are not overwritten by `LEAVE_IF_CHANGED`.
- **Large briefcases.** The SDK reports an approximate total size; do not build a progress bar that assumes an exact total.
- The SDK registers the `BC` app-feature marker by itself; no extra code.

## Step 4 — Build

```bash
./gradlew assembleDebug
```

Expected: `BUILD SUCCESSFUL`. Also validate both JSON files parse:

```bash
python3 -m json.tool < app/src/main/res/raw/userstore.json > /dev/null
python3 -m json.tool < app/src/main/res/raw/usersyncs.json > /dev/null
```

Checklist before finishing:

- [ ] Every `infos[].soupName` exists in `userstore.json`
- [ ] The briefcase sync-down replaced the old sync-down; the `syncUp` entries are unchanged
- [ ] `reSync` uses `<SyncName>`; the `DONE` branch covers every soup
- [ ] The user was told the briefcase must exist in the org and be assigned to the user

## Next

- Symptoms: [`troubleshooting.md`](troubleshooting.md) (MobileSync → briefcase rows)
- API class map: [`api-reference.md`](api-reference.md)
- Biometric session locking: [`add-biometric-auth.md`](add-biometric-auth.md)
