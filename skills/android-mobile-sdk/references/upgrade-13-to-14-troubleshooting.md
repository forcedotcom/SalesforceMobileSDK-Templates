# Android SDK 13 → 14 Upgrade — Troubleshooting

Symptom-first reference for failures that occur when upgrading from Salesforce Mobile SDK 13.x to 14.0.

---

## Compile Errors

| Symptom | Cause | Fix |
|---|---|---|
| `"The 'org.jetbrains.kotlin.android' plugin is no longer required for Kotlin support since AGP 9.0."` | `id("org.jetbrains.kotlin.android")` is present in `plugins { }` **while AGP built-in Kotlin is active** (`android.builtInKotlin` is `true`/unset). The explicit plugin then conflicts with AGP's built-in Kotlin. | Either (Path A) remove `id("org.jetbrains.kotlin.android")` from `app/build.gradle.kts` (and `classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:...")` from root `build.gradle.kts` for non-Compose apps), or (Path B) set `android.builtInKotlin=false` in `gradle.properties` and keep the plugin. See [`upgrade-13-to-14.md`](upgrade-13-to-14.md) Step 4. |
| `Unresolved reference: BiometricAuthOptInPrompt` | `BiometricAuthOptInPrompt` is removed in SDK 14.0. | Remove all usage. Replace with `biometricAuthenticationManager.automaticPresentation = true`. See [`upgrade-13-to-14.md`](upgrade-13-to-14.md) Step 12. |
| `None of the following candidates is applicable: logout(Activity)` (or similar overload error on `logout`) | The `logout(activity: Activity)` overload is removed. | Use `logout(frontActivity = this, reason = OAuth2.LogoutReason.USER_LOGOUT)` (import `com.salesforce.androidsdk.auth.OAuth2.LogoutReason`) or `UserAccountManager.getInstance().signoutCurrentUser(frontActivity)`. There is no `UserAccountManager.USER_LOGOUT`. See [`upgrade-13-to-14.md`](upgrade-13-to-14.md) Step 9. |
| `None of the following candidates is applicable` on `ClientManager` constructor | The old `ClientManager(context, accountType, Boolean)` constructor is removed. | Construct `ClientManager(context, user).peekRestClient()` (user is a `UserAccount` from `UserAccountManager.getInstance().currentUser`), or use `SalesforceSDKManager.getInstance().clientManager?.peekRestClient()`. See [`upgrade-13-to-14.md`](upgrade-13-to-14.md) Step 13. |

---

## Gradle Sync Errors

| Symptom | Cause | Fix |
|---|---|---|
| `minSdk must be 31 or higher` during Gradle sync or build | SDK 14.0 declares `minSdk = 31` in its own manifest. The manifest merger rejects a lower `minSdk` in the app module. | Raise `minSdk` to `31` in `app/build.gradle.kts` (or in `gradle.properties` / `libs.versions.toml` if the project uses a catalog). Confirm the app's Play Store minimum version policy allows dropping Android 9–11 before proceeding. See [`upgrade-13-to-14.md`](upgrade-13-to-14.md) Step 2. |
| `Unsupported Gradle version` or `Android Gradle plugin requires Gradle ... or higher` | The Gradle wrapper still points to Gradle 8.x, but AGP 9.1.1 requires Gradle 9.3 or higher. | Update `distributionUrl` in `gradle/wrapper/gradle-wrapper.properties` to `gradle-9.4.1-bin.zip`. Save the file and re-sync. The wrapper downloads the new distribution automatically. See [`upgrade-13-to-14.md`](upgrade-13-to-14.md) Step 3. |
| `Unresolved reference: gradlePluginPortal` or Kotlin plugin not found in `buildSrc` | `buildSrc/build.gradle.kts` still references `org.jetbrains.kotlin:kotlin-gradle-plugin` from `gradlePluginPortal()`. AGP 9 bundles Kotlin, so the plugin is no longer separately resolvable this way. | Remove the `kotlin-gradle-plugin` and `kotlin-stdlib` dependency lines from `buildSrc/build.gradle.kts` and remove `gradlePluginPortal()` from its repositories block if no other plugins depend on it. See [`upgrade-13-to-14.md`](upgrade-13-to-14.md) Step 3. |

---

## Runtime / Login Failures

| Symptom | Cause | Fix |
|---|---|---|
| `IllegalStateException: account_type not set` (or similar crash) at startup | `account_type` string resource is absent. In SDK 13.x this was a logged warning; SDK 14.0 throws a fatal exception. | Add `<string name="account_type"><PackageName>.salesforce.account</string>` to `app/src/main/res/values/strings.xml`, replacing `<PackageName>` with the app's `applicationId`. See [`upgrade-13-to-14.md`](upgrade-13-to-14.md) Step 7. |
| OAuth redirect never returns to the app after browser-based login | The `LoginActivity` `intent-filter` for the callback URL scheme is absent from `AndroidManifest.xml`. Chrome Custom Tab delivers the redirect as an `ACTION_VIEW` intent; without the filter the OS has no target and the app hangs on the login screen. | Add the `intent-filter` block to the `LoginActivity` declaration in `AndroidManifest.xml` with the correct `scheme`, `host`, and `path` derived from the callback URL. See [`upgrade-13-to-14.md`](upgrade-13-to-14.md) Step 8. |
| After entering username/password, the Custom Tab shows a blank page reading "Please contact support if you see this page" (URL bar on `mobileauth.salesforce.com` or another Salesforce host) and never returns to the app | The callback (`oauthRedirectURI`) is an `https` URL on a host the app doesn't control, e.g. `https://mobileauth.salesforce.com/oauth/done`. In SDK 13 the in-app WebView intercepted it. In SDK 14 Chrome loads it, because Android can't verify App Links for that host. Adding an `intent-filter` for the host has **no effect**. | Register a custom-scheme callback on the Connected App and update every `oauthRedirectURI` to match, then add the Step 8b `intent-filter`. If the Connected App can't change yet, set `forceAdvancedAuthentication = false` temporarily. See [`upgrade-13-to-14.md`](upgrade-13-to-14.md) Step 8a row C and Step 11. |
| Browser login fails immediately with `redirect_uri_mismatch` (or `invalid redirect_uri`) | The `oauthRedirectURI` was changed in the app (e.g. to a custom scheme) but that exact URL isn't registered in the Connected App's Callback URLs. Or one build flavor still uses an old value. | Add the exact URL to the Connected App / External Client App Callback URLs, and re-run the Step 0 grep to catch flavor/CI overrides. |
| A failed-login Custom Tab is still on screen after reinstalling or relaunching the app | The Custom Tab lives in the app's task, and `am force-stop <app>` doesn't close Chrome's activity. | `adb shell am force-stop com.android.chrome`, then relaunch the app. |
| Login fails with HTTP `400 invalid_grant` or `DPoP proof verification failed` | DPoP is enabled by default in SDK 14.0 but the Connected App is not configured for DPoP. | Either (a) configure the Connected App in Salesforce Setup to require DPoP, or (b) opt out temporarily: `SalesforceSDKManager.getInstance().useDPoP = false` in `Application.onCreate()` after `initNative(...)`. See [`upgrade-13-to-14.md`](upgrade-13-to-14.md) Step 10. |
| Login screen does not appear; app immediately returns to previous screen or crashes | `forceAdvancedAuthentication = true` by default means Chrome Custom Tab is used, but the `LoginActivity` `intent-filter` is missing. The Custom Tab redirect cannot return and the activity lifecycle fails. | Add the `LoginActivity` `intent-filter` (Step 8 in [`upgrade-13-to-14.md`](upgrade-13-to-14.md)). If the app is not ready for browser-based login, set `forceAdvancedAuthentication = false` as a temporary workaround. |
