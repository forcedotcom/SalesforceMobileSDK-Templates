# Android SDK 13 → 14: Breaking Changes Reference

Complete reference for classes, methods, and signatures that changed between Salesforce Mobile SDK 13.x and 14.0.

---

## Build System Changes

| Component | SDK 13.x value | SDK 14.0 value |
|---|---|---|
| `minSdk` | 28 (Android 9) | 31 (Android 12) |
| Android Gradle Plugin (AGP) | 8.12.0 | 9.1.1 |
| Gradle wrapper | 8.14.3 | 9.4.1 |
| `id("org.jetbrains.kotlin.android")` | Required | Optional — depends on the `android.builtInKotlin` flag (see below) |
| `kotlin { jvmToolchain(17) }` | Used for JVM target | **Removed — replaced by `compileOptions`** |

---

## Kotlin plugin — governed by the `android.builtInKotlin` flag

AGP 9.0 can supply Kotlin support natively (built-in Kotlin). Whether the explicit `org.jetbrains.kotlin.android` plugin is required depends on the `android.builtInKotlin` property in `gradle.properties`. There are two valid configurations — pick one:

**Path A — use AGP built-in Kotlin (`android.builtInKotlin=true`, the AGP 9 default).** Remove the explicit plugin, because AGP applies Kotlin automatically and the explicit plugin then conflicts:

```kotlin
// gradle.properties: android.builtInKotlin=true (or unset — true is the AGP 9 default)
plugins {
    id("com.android.application")
    // no id("org.jetbrains.kotlin.android") — AGP applies Kotlin automatically
}
```

Build error if you leave the plugin in while built-in Kotlin is active:
`"The 'org.jetbrains.kotlin.android' plugin is no longer required for Kotlin support since AGP 9.0."`

**Path B — opt out of built-in Kotlin (`android.builtInKotlin=false`) and keep the plugin.** The Mobile SDK library itself does this (`gradle.properties` sets `android.builtInKotlin=false`, and every module keeps the `kotlin-android` plugin) — but that is the library's internal build choice and does **not** propagate to consuming apps via Maven. A consuming app on AGP 9 gets built-in Kotlin by default, so prefer Path A; choose Path B only if you deliberately set the flag:

```properties
# gradle.properties
android.builtInKotlin=false
```

```kotlin
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")   // kept — required because built-in Kotlin is disabled
}
```

Choose the path that matches your `gradle.properties`. Do not remove the plugin without confirming `android.builtInKotlin` is `true`/unset, and do not set `android.builtInKotlin=false` while dropping the plugin.

---

## account_type String Resource — Warning → Fatal

| SDK 13.x behavior | SDK 14.0 behavior |
|---|---|
| Logs `W/SalesforceSDKManager: account_type is not unique` | Throws `IllegalStateException` at startup — **app crashes** |

```xml
<!-- Add to app/src/main/res/values/strings.xml — required in SDK 14.0 -->
<string name="account_type">com.example.myapp.salesforce.account</string>
```

---

## Removed Methods

| Class | Removed Method | Replacement |
|---|---|---|
| `SalesforceSDKManager` | `logout(activity: Activity)` | `logout(frontActivity = activity, reason = LogoutReason.USER_LOGOUT  // import com.salesforce.androidsdk.auth.OAuth2.LogoutReason)` |
| `ClientManager` constructor | `ClientManager(context, accountType, Boolean)` | Use `ClientManager(context, user).peekRestClient()` (user is a `UserAccount`) |

## Changed Method Signatures

| Class | Old Signature | New Signature |
|---|---|---|
| `BiometricAuthenticationManager` | `presentOptInDialog(supportFragmentManager)` | `presentOptInDialog()` |

---

## Changed Signatures

| Class | Old Signature | New Signature |
|---|---|---|
| `SalesforceSDKManager` | `logout(this)` | `logout(frontActivity = this, reason = LogoutReason.USER_LOGOUT  // import com.salesforce.androidsdk.auth.OAuth2.LogoutReason)` |

### logout()

```kotlin
// BEFORE (SDK 13)
SalesforceSDKManager.getInstance().logout(this)

// AFTER (SDK 14)
SalesforceSDKManager.getInstance().logout(frontActivity = this, reason = LogoutReason.USER_LOGOUT  // import com.salesforce.androidsdk.auth.OAuth2.LogoutReason)
```

### registerUsedAppFeature() — not a breaking change

The existing single-argument form still exists and compiles unchanged. SDK 14.0 only *adds* an optional overload that associates the feature with a specific user; there is no `version` parameter.

```kotlin
// Still valid — registerUsedAppFeature(appFeatureCode: String?)
SalesforceSDKManager.getInstance().registerUsedAppFeature("MY_FEATURE")

// New optional overload — registerUsedAppFeature(appFeatureCode: String, user: UserAccount?)
SalesforceSDKManager.getInstance().registerUsedAppFeature("MY_FEATURE", user)
```

### getUserAgent() — not a breaking change

`getUserAgent()` was not removed. The `userAgent` property (accessed as `getUserAgent()` from Java) still works. SDK 14.0 only *adds* optional overloads; the string parameter is a user-agent `qualifier`, not an app name.

```kotlin
// Still valid — the userAgent property
val ua = SalesforceSDKManager.getInstance().userAgent

// New optional overloads — getUserAgent(qualifier) and getUserAgent(qualifier, user)
val ua2 = SalesforceSDKManager.getInstance().getUserAgent("MyQualifier")
```

---

## Changed Defaults

| Setting | SDK 13.x default | SDK 14.0 default | Impact |
|---|---|---|---|
| `SalesforceSDKManager.useDPoP` | `false` | **`true`** | Login fails if Connected App is not configured for DPoP |
| `SalesforceSDKManager.forceAdvancedAuthentication` | `false` (opt-in per host) | **`true`** (all hosts) | All login flows use Chrome Custom Tab |

### Opting out of DPoP

```kotlin
// In Application.onCreate(), after SalesforceSDKManager.initNative(...)
SalesforceSDKManager.getInstance().useDPoP = false
```

### Opting out of Advanced Authentication

```kotlin
// In Application.onCreate(), after SalesforceSDKManager.initNative(...)
SalesforceSDKManager.getInstance().forceAdvancedAuthentication = false
```

---

## Biometric Authentication API Change

`presentOptInDialog(supportFragmentManager)` signature changed to `presentOptInDialog()`. Alternatively, use `automaticPresentation = true` on the `BiometricAuthenticationManager`.

```kotlin
// BEFORE (SDK 13)
BiometricAuthOptInPrompt(this).presentOptInDialog(supportFragmentManager)

// AFTER (SDK 14)
private fun maybePresentBiometricOptIn() {
    val mgr = MobileSyncSDKManager.getInstance().biometricAuthenticationManager ?: return
    val deviceHasBiometrics = BiometricManager.from(this).canAuthenticate(
        BIOMETRIC_STRONG or BIOMETRIC_WEAK
    ) == BiometricManager.BIOMETRIC_SUCCESS
    if (mgr.enabled && deviceHasBiometrics) {
        mgr.automaticPresentation = true
    }
}
```

---

## ClientManager Redesign

The old `ClientManager(context, accountType, Boolean)` constructor is removed. `ClientManager` itself remains — construct it with the `UserAccount` and call `peekRestClient()`.

```kotlin
// BEFORE (SDK 13)
val clientManager = ClientManager(this, accountType, true)
clientManager.getRestClient { restClient ->
    // use restClient
}

// AFTER (SDK 14) — build ClientManager for the user and peek (returns null if not authenticated)
val user = UserAccountManager.getInstance().currentUser
val restClient = user?.let { ClientManager(context, it).peekRestClient() }

// Convenience: SalesforceSDKManager exposes a `clientManager` property for the current user
val restClient2 = SalesforceSDKManager.getInstance().clientManager?.peekRestClient()
```

---

## New API

| API | Notes |
|---|---|
| `UserAccountManager.upgradeToDPoP(userAccount, onSuccess, onFailure)` | Extension on `UserAccountManager`. Migrates an existing non-DPoP account to DPoP without requiring re-login. |
| `SalesforceSDKManager.clientManager` | `ClientManager?` property for the current user (null when no account is current). Call `peekRestClient()` on it. |
| `ClientManager.peekRestClient()` | Non-blocking REST client accessor. Does not trigger login. Returns `null` if no user is authenticated. |

### upgradeToDPoP()

`upgradeToDPoP` is an extension function on `UserAccountManager`. `onSuccess` receives the upgraded `UserAccount`; `onFailure` receives `(error: String, errorDesc: String?, e: Throwable?)`.

```kotlin
UserAccountManager.getInstance().upgradeToDPoP(
    userAccount,
    onSuccess = { account -> /* DPoP migration succeeded */ },
    onFailure = { error, errorDesc, e -> /* handle error */ }
)
```

---

## Removed Gradle Properties

The following `gradle.properties` keys are no longer used and should be removed:

| Key | Notes |
|---|---|
| `cdvCompileSdkVersion` | Cordova legacy — no effect in SDK 14.0 |
| `cdvMinSdkVersion` | Cordova legacy — no effect in SDK 14.0 |
| `android.useAndroidX` | AndroidX migration flag — unnecessary since AndroidX is mandatory |
| `android.enableJetifier` | Jetifier flag — unnecessary in SDK 14.0 |
