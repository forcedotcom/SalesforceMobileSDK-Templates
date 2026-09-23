# Android SDK 12 → 13 Upgrade — Troubleshooting

Symptom-first reference for failures that occur when upgrading from Salesforce Mobile SDK 12.x to 13.2.1.

---

## Compile Errors

| Symptom | Cause | Fix |
|---|---|---|
| `Unresolved reference: LoginOptions` | `ClientManager.LoginOptions` is removed in SDK 13. | Remove all `LoginOptions` construction. Update the `ClientManager` constructor call to `ClientManager(context, accountType, isBackground)` — the `loginOptions` parameter no longer exists. See [`upgrade-12-to-13.md`](upgrade-12-to-13.md) Step 4a. |
| `Unresolved reference: OAuthWebviewHelper` (or `OAuthWebviewHelperEvents`) | Both classes are deleted in SDK 13. | Remove the subclass or implementation. Migrate any login customizations to a `LoginViewModel` subclass registered via `SalesforceSDKManager.getInstance().loginViewModelFactory`. See [`upgrade-12-to-13.md`](upgrade-12-to-13.md) Step 4b and Step 5. |
| `Unresolved reference: ServerPickerActivity` | `ServerPickerActivity` is removed in SDK 13. The server picker is now embedded in the Compose login screen. | Remove any explicit `Intent` constructions that target `ServerPickerActivity`. Remove the activity declaration from `AndroidManifest.xml` if present. See [`upgrade-12-to-13.md`](upgrade-12-to-13.md) Step 4f. |
| `'onLogoutComplete' overrides nothing` | `LogoutCompleteReceiver.onLogoutComplete()` now requires an `OAuth2.LogoutReason` parameter. The parameterless override no longer matches any method in the base class. | Add the `reason: OAuth2.LogoutReason` parameter: `override fun onLogoutComplete(reason: OAuth2.LogoutReason)`. See [`upgrade-12-to-13.md`](upgrade-12-to-13.md) Step 4c. |
| `Unresolved reference: qr_code_login_button` or `Unresolved reference: BottomBarButton` in `QrCodeEnabledLoginActivity` | The SDK 12 QR login activity used `R.id.qr_code_login_button` (a layout view ID) to show a button. SDK 13 removed that layout element and replaced it with `LoginViewModel.BottomBarButton` in the Compose login UI. | Migrate `QrCodeEnabledLoginActivity` to the SDK 13 pattern. See [`upgrade-12-to-13.md`](upgrade-12-to-13.md) Step 4j for the full before/after. |

---

## Gradle Sync Errors

| Symptom | Cause | Fix |
|---|---|---|
| `minSdk must be 28 or higher` during Gradle sync or build | SDK 13 declares `minSdk = 28` in its own manifest. The manifest merger rejects a lower `minSdk` in the app module. | Raise `minSdk` to `28` in `app/build.gradle.kts` (or in `gradle.properties` / `libs.versions.toml` if the project uses a catalog for SDK-level settings). Also update `cdvMinSdkVersion=28` in `gradle.properties` if that key is present. Confirm the app's Play Store minimum version policy allows dropping Android 8.x before proceeding. See [`upgrade-12-to-13.md`](upgrade-12-to-13.md) Step 2. |
| Gradle sync fails: `Android Gradle plugin requires ... Gradle 8.7 or higher` (or similar incompatibility error) | AGP 8.12.0 requires Gradle 8.7 or later, but `gradle-wrapper.properties` still points to an older distribution. | Update `gradle/wrapper/gradle-wrapper.properties` to use `gradle-8.14.3-bin.zip`. Save the file, then sync. The Gradle wrapper downloads the new distribution automatically on the next sync. See [`upgrade-12-to-13.md`](upgrade-12-to-13.md) Step 3. |

---

## Runtime / Login Failures

| Symptom | Cause | Fix |
|---|---|---|
| App builds but login screen is blank after upgrade | Jetpack Compose initialization failed silently. Most common cause: the `Activity` does not have a `ComponentActivity`-compatible theme, or Compose dependencies are not resolved. | (1) Ensure `android:theme` on `LoginActivity` (or the `<application>`) is set to `@style/SalesforceSDK` or a theme that extends `Theme.AppCompat`. (2) Run `./gradlew dependencies --configuration releaseRuntimeClasspath` and confirm `androidx.compose.*` appears (it is a transitive dependency of SDK 13). (3) Clean the build: `./gradlew clean assembleDebug`. |
| Unexpected logout on first launch after upgrading from SDK 11/12 | SDK 13 re-encrypts stored OAuth tokens on first launch, migrating from PKCS1v15 to OAEP padding. In rare cases — typically on devices running Android 9 with certain OEM keystore implementations — the re-encryption fails silently and the token is invalidated, forcing a re-login. | No code fix required. The user logs in once after the upgrade and the new token is stored correctly. If re-logins recur beyond the first launch, check logcat for `OAuthHelper` or `KeyStoreWrapper` errors that indicate a persistent keystore issue on the device. |
| Login screen appears but OAuth redirect does not complete (app hangs on the callback) | `LoginActivity` launch mode is `singleTop` instead of `singleTask`. With custom tabs or browser-based OAuth, the redirect intent is delivered to a separate task and `singleTop` does not bring the existing activity to the front. | Set `android:launchMode="singleTask"` on the `LoginActivity` declaration in `AndroidManifest.xml`. See [`upgrade-12-to-13.md`](upgrade-12-to-13.md) Step 7. |

---

## ProGuard / R8 Errors

| Symptom | Cause | Fix |
|---|---|---|
| `ClassNotFoundException` at runtime for an SDK class (e.g. `SalesforceSDKManager`, `SmartStore`, a sync manager) after a release build | App-level `proguard-rules.pro` contains keep rules for SDK classes that were accurate for SDK 12 but conflict with the consumer rules SDK 13 ships. In rare cases conflicting rules cause R8 to rename or remove classes unexpectedly. More commonly, SDK classes that previously needed explicit keep rules are now covered by `consumer-rules.pro` but the app's old rules reference renamed internal classes that no longer exist. | (1) Remove from `proguard-rules.pro` any keep rules that target `com.salesforce.androidsdk.**` — SDK 13's `consumer-rules.pro` covers public SDK classes. (2) Run a release build with `./gradlew assembleRelease` and inspect the R8 mapping file at `app/build/outputs/mapping/release/mapping.txt` to confirm the missing class is not being renamed unexpectedly. (3) If a class the app subclasses is being renamed, add a targeted keep rule for that specific class name. |

---

## Logcat Warnings

| Symptom | Cause | Fix |
|---|---|---|
| `W/SalesforceSDKManager: account_type is not unique — using SDK default` in logcat | The app does not override the `account_type` string resource, so multiple apps on the same device share the same account type. This can cause Account Manager conflicts when more than one SDK-based app is installed. | Add `<string name="account_type">com.example.myapp.login</string>` to `app/src/main/res/values/strings.xml` with a value unique to the app (conventionally the `applicationId` plus `.login`). See [`upgrade-12-to-13.md`](upgrade-12-to-13.md) Step 6. |
