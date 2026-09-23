# Android — Add Dark Mode

Configures dark mode for the SDK-managed UI in an Android Kotlin app that already has Mobile SDK initialized. Android exposes a **single** lever: the `SalesforceSDKManager.theme` property (`Theme.LIGHT`, `Theme.DARK`, `Theme.SYSTEM_DEFAULT`). Setting it drives the color scheme of the SDK's own screens (login host picker, OAuth web login, Switch User, passcode/screen-lock). Your own activities and Composables use standard Android dark-mode handling (a `DayNight` theme and `res/values-night/` resources) — see the Android docs linked at the bottom.

Unlike iOS there is no static-vs-runtime split: the same property covers both the "force at launch" and "user toggle" cases. The only rule to remember is that `theme` is **not persisted by the SDK** across process launches (see the note in Option A), so whatever value you want must be re-applied every launch.

## Preconditions

- `MainApplication.kt` calls one of `SalesforceSDKManager.initNative(...)`, `SmartStoreSDKManager.initNative(...)`, or `MobileSyncSDKManager.initNative(...)`.

If the SDK is not yet wired up, run [`add-mobile-sdk.md`](add-mobile-sdk.md) first.

## Decision — Pick One Option

| Intent | Pick |
|---|---|
| Follow the Android system dark/light setting (no force, no user toggle) | **Neither needed** — the SDK default (`Theme.SYSTEM_DEFAULT`) already follows the system `uiMode`. Skip this scenario. |
| Force light always, OR force dark always, no user toggle | **Option A** (set `theme` at launch) |
| Follow a user preference / app-level toggle that persists across launches | **Option B** (persist a preference and apply it at launch) |

Read **only** the chosen option's section below.

## Option A — Force Light or Dark at Launch

Set `SalesforceSDKManager.theme` in `MainApplication.onCreate()`, immediately **after** the `initNative(...)` call. The manager singleton must exist first.

```kotlin
import android.app.Application
import com.salesforce.androidsdk.app.SalesforceSDKManager
import com.salesforce.androidsdk.app.SalesforceSDKManager.Theme

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        SalesforceSDKManager.initNative(applicationContext, MainActivity::class.java)

        // Force dark for all SDK-managed screens. Use Theme.LIGHT to force light.
        SalesforceSDKManager.getInstance().theme = Theme.DARK
    }
}
```

If the app initializes through `SmartStoreSDKManager` or `MobileSyncSDKManager`, call `initNative(...)` on that manager instead — `getInstance().theme` is the same property on every manager in the hierarchy.

Notes on the API:

- `theme` is a `var` of type `SalesforceSDKManager.Theme` — `LIGHT`, `DARK`, or `SYSTEM_DEFAULT`. Default is `SYSTEM_DEFAULT` (SDK screens follow the OS `uiMode`).
- `isDarkTheme: Boolean` (read-only) resolves the effective state: for `SYSTEM_DEFAULT` it reads the OS `UI_MODE_NIGHT_MASK`; otherwise it is `theme == DARK`.
- **`theme` is not persisted by the SDK across process launches** (its KDoc: *"The value is not persistent across instances of Salesforce SDK Manager"*). Re-apply it every launch from `onCreate()`, as above. This is why a user toggle (Option B) must persist the choice itself.
- Scope: SDK-managed screens only. Your own activities/Composables are not affected — theme those with a `Theme.Material3.DayNight` parent plus `res/values-night/` overrides.

Then build and verify against the [Verify](#verify-applies-to-both-options) section below.

## Option B — User Toggle Persisted Across Launches

To let the user choose appearance from your settings UI and keep the choice across launches, persist the selection (here with `SharedPreferences`) and apply it to `SalesforceSDKManager.theme` on every launch.

### Step 1 — A persisted preference

```kotlin
import android.content.Context
import com.salesforce.androidsdk.app.SalesforceSDKManager
import com.salesforce.androidsdk.app.SalesforceSDKManager.Theme

enum class AppearancePreference {
    SYSTEM, LIGHT, DARK;

    val sdkTheme: Theme
        get() = when (this) {
            SYSTEM -> Theme.SYSTEM_DEFAULT
            LIGHT  -> Theme.LIGHT
            DARK   -> Theme.DARK
        }
}

private const val PREFS = "appearance"
private const val KEY_PREF = "appearance.preference"

fun readAppearance(context: Context): AppearancePreference {
    val name = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        .getString(KEY_PREF, AppearancePreference.SYSTEM.name)
    return runCatching { AppearancePreference.valueOf(name!!) }
        .getOrDefault(AppearancePreference.SYSTEM)
}

// Call from your settings UI. Persists the choice AND applies it to the SDK.
fun setAppearance(context: Context, pref: AppearancePreference) {
    context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        .edit().putString(KEY_PREF, pref.name).apply()
    SalesforceSDKManager.getInstance().theme = pref.sdkTheme
}
```

### Step 2 — Apply the persisted choice at launch

```kotlin
class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        SalesforceSDKManager.initNative(applicationContext, MainActivity::class.java)

        // Restore the user's saved appearance for SDK-managed screens.
        SalesforceSDKManager.getInstance().theme = readAppearance(applicationContext).sdkTheme
    }
}
```

Notes:

- Applying a new value takes effect for **subsequently presented** SDK screens (each SDK screen reads `colorScheme()` when it is composed). SDK-managed screens (login, host picker, Switch User, screen lock) are launched by the SDK and aren't on-screen when the user toggles from your settings UI, so the next one presented picks up the new value automatically — no refresh call is needed for the SDK scope.
- The activity **on-screen at the toggle moment is your own app-owned UI** (for example, your settings screen), and it won't repaint from the `theme` change alone. To update it immediately, call `recreate()` on that activity (or recompose it from your own state). This applies only to the app-owned activity the user is standing on — not to SDK screens.
- To match your app-owned UI to the same appearance, apply the standard Android lever yourself — the SDK does **not** touch it, so `theme` alone won't change your own screens. Which lever depends on how your UI is built: **View / AppCompat** UI (activities, fragments) → `AppCompatDelegate.setDefaultNightMode(...)`; **Jetpack Compose** UI → drive it from `isSystemInDarkTheme()` or your own app state. `SalesforceSDKManager.theme` governs only the SDK's own screens.

Then build and verify against the [Verify](#verify-applies-to-both-options) section below.

## (Optional) Custom Color Schemes

Beyond light/dark selection, you can replace the SDK's default Compose color schemes. `SalesforceSDKManager` exposes `setLightColorScheme(ColorScheme)` and `setDarkColorScheme(ColorScheme)` (defaults are `sfLightColors()` / `sfDarkColors()`). Set these in `onCreate()` after `initNative(...)` if you need brand colors on the SDK screens. This is independent of the light/dark **selection** above.

## Verify (applies to both Options)

Build first:

```bash
./gradlew assembleDebug
```

Expected: `BUILD SUCCESSFUL`. Then exercise each SDK-managed screen and confirm it renders in the configured appearance:

- **Login host picker** — the screen offering Production / Sandbox / custom hosts.
- **OAuth web login** — the web view that hosts the Salesforce login page.
- **Switch User** — the account-switching list reachable from the SDK's account UI.
- **Passcode / screen lock** — the screen-lock unlock screen shown after the policy's idle timeout (or on `lock()`).

App-owned UI (your own activities/Composables) is **not** governed by `SalesforceSDKManager.theme` — theme it with the standard Android lever for how it's built: **View / AppCompat** → `AppCompatDelegate.setDefaultNightMode(...)` (with a `Theme.Material3.DayNight` parent and `res/values-night/` overrides); **Jetpack Compose** → `isSystemInDarkTheme()` or your own app state. See the Android docs in the [References](#references) section.

> **Emulator note:** toggle the device dark setting via **Settings → Display → Dark theme**, or `adb shell "cmd uimode night yes"` / `adb shell "cmd uimode night no"`, to confirm `Theme.SYSTEM_DEFAULT` follows the system.

## Symptoms

See [`troubleshooting.md`](troubleshooting.md).

## References

- Mobile SDK — Set Dark Mode in Android Apps: <https://developer.salesforce.com/docs/platform/mobile-sdk/guide/ui-dark-settings.html>
- Android — Support dark theme (DayNight, `values-night`): <https://developer.android.com/develop/ui/views/theming/darktheme>
