# Android — Add DPoP Refresh-Token Migration

Moves users who are already logged in with a **Bearer** refresh token (SDK 13.x, or SDK 14 with DPoP off) onto a **DPoP-bound** one, without making them log in again. SDK 14.0 turns DPoP on by default, but only for **new** logins: existing sessions keep their Bearer token until the app upgrades them.

Since SDK **14.0.1** the SDK does the work: `DpopMigrationManager` (`com.salesforce.androidsdk.auth.dpop`) decides whether a migration is needed, runs it once per user, and reports `NotNeeded`, `Migrated` or `Failed`. It has no UI. This reference adds only what the app owns: a small localized "Securing your session…" screen and the call in `MainActivity`.

What the app does after this change:

- At launch, if the logged-in user's session is **not** DPoP-bound, the screen is shown while the SDK upgrades it, then the app continues (success **or** failure).
- No user, or an already-DPoP user: nothing is shown. The app proceeds as before.
- On failure the user keeps the existing session (nobody is logged out) and the migration is retried on the next launch.

## Preconditions

- Mobile SDK **14.0.1 or later** is integrated (`SalesforceSDKManager` / `SmartStoreSDKManager` / `MobileSyncSDKManager.initNative(...)` in `Application.onCreate()`) and the user can log in. If not, run [`add-mobile-sdk.md`](add-mobile-sdk.md) first. On 13.x or 14.0.0, run [`upgrade-13-to-14.md`](upgrade-13-to-14.md) first and set every SDK dependency to `14.0.1-rc.1` (or the latest 14.0.1+ release): `DpopMigrationManager` does not exist before 14.0.1 (`Unresolved reference: DpopMigrationManager`).
- `MainActivity` (the launcher activity) extends `SalesforceActivity` and overrides `onResume(client: RestClient?)`. If not, see [Other activity shapes](#other-activity-shapes).
- The Connected App / External Client App the app logs in with is **DPoP-enabled in the org** (Salesforce Setup, out of scope here). Otherwise the upgrade fails and the user just keeps the existing session.

## Files Added / Changed

| File | Change |
|---|---|
| `app/src/main/res/values/strings.xml` | Add three strings (Step 1). |
| `app/src/main/res/layout/dpop_migration_overlay.xml` | New full-screen overlay (Step 2). |
| `app/src/main/java/<AppPackage path>/MainActivity.kt` | Add the overlay and call `DpopMigrationManager` (Step 3). |

No helper class is generated and nothing is persisted: the account's token type is the source of truth.

## Step 1 — Strings

Add to `app/src/main/res/values/strings.xml` (inside `<resources>`; keep the existing entries):

```xml
<!-- Shown while the user's sign-in is upgraded to the more secure DPoP format -->
<string name="dpop_migration_title">Securing your session…</string>
<string name="dpop_migration_message">We’re upgrading your sign-in to a more secure format. This only takes a moment.</string>
<!-- Shown briefly (toast) if the upgrade could not be completed; the user keeps their current session -->
<string name="dpop_migration_failed">We couldn’t finish securing your session. We’ll try again later.</string>
```

Keep user-facing wording free of technical terms (no "DPoP", no "refresh token"). Add translations under `res/values-<lang>/strings.xml` if the app is localized.

## Step 2 — Overlay layout

Create `app/src/main/res/layout/dpop_migration_overlay.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<!--
  Full-screen "Securing your session" screen, added on top of the activity content by
  MainActivity and shown only while a DPoP migration is running. Opaque so the app UI is hidden.
-->
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:id="@+id/dpop_migration_overlay"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="?android:colorBackground"
    android:clickable="true"
    android:focusable="true"
    android:gravity="center"
    android:orientation="vertical"
    android:padding="32dp"
    android:visibility="gone">

    <ProgressBar
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginBottom="24dp"
        android:indeterminate="true" />

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginBottom="8dp"
        android:text="@string/dpop_migration_title"
        android:textAppearance="?android:attr/textAppearanceLarge"
        android:textColor="?android:textColor" />

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:gravity="center"
        android:text="@string/dpop_migration_message"
        android:textColor="?android:textColor" />
</LinearLayout>
```

## Step 3 — Wire it into `MainActivity`

The hook is `onResume(client: RestClient?)`: the SDK calls it once a user session exists. Make these edits and keep everything else.

**Imports** (merge with the existing ones):

```kotlin
import android.view.View
import android.view.ViewGroup
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import android.widget.Toast
import com.salesforce.androidsdk.accounts.UserAccountManager
import com.salesforce.androidsdk.auth.dpop.DpopMigrationManager
```

**Field**:

```kotlin
/** The "Securing your session..." screen. Added on top of the content, hidden by default. */
private var migrationOverlay: View? = null

/** An upgrade is running. */
private var migrationRunning = false

/** Accounts ("orgId:userId") an upgrade was started for by this activity instance. Prevents a retry loop after a failure. */
private val migrationAttempted = mutableSetOf<String>()
```

**`onCreate`**: at the end, after `setContentView(...)`. `addContentView` puts the overlay **on top of** whatever the activity shows (the SDK template hides its root view until login, so a view inside it would be hidden too):

```kotlin
migrationOverlay = layoutInflater.inflate(R.layout.dpop_migration_overlay, null).also {
    addContentView(it, ViewGroup.LayoutParams(MATCH_PARENT, MATCH_PARENT))
}
```

**`onResume(client)`**: move the existing body into a new `continueIntoApp()` and make `onResume(client)` call it after the migration:

```kotlin
override fun onResume(client: RestClient?) {
    // Resumes while the upgrade runs, or after an attempt this launch (the SDK's migration
    // screen finishing triggers one): never start a second upgrade. The callback below
    // continues into the app.
    if (migrationRunning) return
    val user = UserAccountManager.getInstance().currentUser
    val accountKey = user?.let { "${it.orgId}:${it.userId}" }
    if (accountKey == null || accountKey in migrationAttempted || !DpopMigrationManager.isMigrationNeeded(user)) {
        continueIntoApp()
        return
    }

    migrationAttempted += accountKey
    migrationRunning = true
    migrationOverlay?.visibility = View.VISIBLE

    // The callback is called once, on the main thread, whatever the outcome. On Failed the existing
    // session still works and the next launch retries.
    DpopMigrationManager.migrateIfNeeded(user) { outcome ->
        migrationRunning = false
        migrationOverlay?.visibility = View.GONE
        if (outcome is DpopMigrationManager.Outcome.Failed) {
            Toast.makeText(this, R.string.dpop_migration_failed, Toast.LENGTH_LONG).show()
        }
        continueIntoApp()
    }
}

/**
 * The original body of onResume(client): whatever the app did once logged in
 * (for the SDK template: `findViewById<ViewGroup>(root).visibility = View.VISIBLE`, keeping the
 * `this.client = client` assignment in onResume itself).
 * Must be idempotent: it can run more than once per launch.
 */
private fun continueIntoApp() {
    // Post-login app logic goes here.
}
```

Notes:

- `onResume(client)` fires **again** when the SDK's `TokenMigrationActivity` (its web-based approve screen) finishes. The two flags handle it: while the upgrade runs, `migrationRunning` makes the extra resume a no-op (the overlay stays up and the callback continues into the app). After it ends, `migrationAttempted` (keyed by account, so switching to another Bearer account still migrates that account) makes the resume for the same account just call `continueIntoApp()`. This matters on **failure**: the SDK reports the failure before its screen finishes, so without `migrationAttempted` the returning resume would start another upgrade and could reopen the SDK screen in a loop. A failed upgrade is retried on the next launch (a new activity instance). `continueIntoApp()` must be idempotent because it can run twice.
- If the existing `onResume(client)` does more than show the UI (loads data, starts a sync, presents biometric opt-in…), move **all** of it into `continueIntoApp()` so it runs after the migration completes. Keep any early `if (client == null) return` guard at the top of `onResume(client)`, and keep any `this.client = client` assignment there so the latest client (with the new tokens) is used.
- If the SDK never calls back (for example the user presses Back in `TokenMigrationActivity`), the manager reports `Failed("timed out")` after 90 s by default; pass `timeoutMs` to `migrateIfNeeded` to tune it.

### Other activity shapes

- **Launcher extends another SDK base activity** (`SalesforceListActivity`, …): the same `onResume(client)` code applies.
- **Launcher is not an SDK activity** (e.g. a splash that starts `MainActivity`): wire the first `SalesforceActivity` shown after login. With no user the manager returns `NotNeeded`.
- **Compose host** (`setContent { }`): keep the same calls, but drive a `mutableStateOf(false)` such as `showMigrationScreen` instead of the overlay `View`, and render a full-screen `Box` with a `CircularProgressIndicator` and the two strings (`stringResource(...)`) above the normal content while it is `true`.
- **Other call sites** (a settings "Secure my session" button, after an account switch, before a long sync): call `DpopMigrationManager.migrateIfNeeded { outcome -> … }` (or the `suspend` overload from a coroutine). It is idempotent and only ever migrates the **current** user by default; pass `user = account` for another one. The SDK always shows its `TokenMigrationActivity` during an upgrade, whatever UI you add.

## Step 4 — Build

```bash
./gradlew assembleDebug
```

Expected: `BUILD SUCCESSFUL`. A green build does **not** prove the runtime behavior; verify as below.

## Verify (emulator or device)

Test with a session that is **Bearer**: log in with an app built with `SalesforceSDKManager.getInstance().useDPoP = false` in `Application.onCreate()` (after `initNative(...)`) and no migration wired, then install the migration-enabled app over it **without logging out**. Watch the SDK's log lines (stable tag `DPoPMigration`):

```bash
adb logcat -s DPoPMigration
```

| Case | Setup | Expected logcat | Expected UI |
|---|---|---|---|
| Migrates | Logged-in Bearer user | `upgrade needed, starting` → `success`. Exactly **one** `upgrade needed, starting` even though `onResume(client)` runs twice; the second resume does not call the SDK. | "Securing your session…" screen; the SDK's own web view (`TokenMigrationActivity`) flashes and closes; the screen disappears; the app UI shows. REST calls still work. |
| Already DPoP | Relaunch after "Migrates" | `skipped: already DPoP` | No screen, no network call. |
| No user | Fresh install / logged out | nothing at launch (the login screen shows first) | Login as usual. |
| Failure continues | Make the upgrade fail (airplane mode before launching, or a Connected App without DPoP enabled) | `upgrade needed, starting` → `failed, existing session kept`, with **no** second `upgrade needed, starting` when the SDK screen closes | Screen dismissed, failure toast, app UI on the existing session. The next launch logs `upgrade needed, starting` again. |
| Timeout fallback | Press Back in `TokenMigrationActivity` before approving (or temporarily pass `timeoutMs = 5_000`) | `upgrade needed, starting` → (silence for the timeout) → `timed out after <N>ms, existing session kept` | After the timeout (90 s by default) the screen is dismissed, failure toast, app UI on the existing session. A late success afterwards logs `late success after timeout`. |

If a case does not behave as listed, see [`troubleshooting.md`](troubleshooting.md) → "DPoP Migration".

### Testing an upgrade end to end

Use **two builds** of the same app (same `applicationId`), installed one over the other without clearing app data, so the login persists:

1. **Build A (before):** `SalesforceSDKManager.getInstance().useDPoP = false` in the `Application` class, **without** the migration wired in. Install, log in, and confirm the session is Bearer: open the developer support menu (`adb shell input keyevent KEYCODE_MENU`) → Dev Info. The "OAuth Token Type" row in the Current User section reads Bearer, and the User Agent row has no `DP` flag.
2. **Build B (after):** the migration-enabled app, DPoP on (the default). Install it over build A (no `pm clear`, no logout) and launch. Expect the "Securing your session…" screen, the SDK's migration web view, then the app UI, with the `Migrates` log sequence above.
3. **Verify via Dev Info:** the User Agent row now carries the `DP` flag and the token type is a DPoP type.
4. **Other scenarios:** relaunch again (`skipped: already DPoP`); fresh install with no user (no screen); failure / timeout as in the table.
5. **To re-run:** `adb shell pm clear <package>` (or log out), go back to build A, and log in again.

Do **not** run the migration-wired build while DPoP is still off before the first login: `upgradeToDPoP` upgrades regardless of the flag, so the first launch after login would migrate immediately and there would be no Bearer session left to observe.

Use an org and Connected App / External Client App with DPoP enabled.

## Failure Behavior

- The SDK leaves the existing session intact when the upgrade fails, so `migrateIfNeeded` reports `Failed(reason)` and the app **continues on the existing session**. Nobody is logged out and there is no retry loop in the same launch.
- Nothing is persisted on failure, so the next launch (or the next call) tries again.
- The most common cause is a Connected App / External Client App that is not DPoP-enabled in the org (`invalid_grant`-style reason in the `Failed` outcome and the `failed, existing session kept` log line).

## Symptoms

See [`troubleshooting.md`](troubleshooting.md) → "DPoP Migration" for: `Unresolved reference: DpopMigrationManager`, screen dismisses only after the timeout, migrates on every launch, and `invalid_grant` failures.
