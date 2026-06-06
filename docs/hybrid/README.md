# Hybrid Templates

The Salesforce Mobile SDK provides two hybrid (Cordova) app templates. Both produce apps that run web content inside a native Cordova WebView with access to the Salesforce REST API via `force.js`.

## Templates

| Template | App Type | Description |
|----------|----------|-------------|
| `HybridLocalTemplate` | `hybrid_local` | Local HTML/JS/CSS app running in the Cordova WebView. All app code lives in `www/`. |
| `HybridRemoteTemplate` | `hybrid_remote` | App that loads a Visualforce page or Experience Cloud site as its start page. The `startPage` field in `bootconfig.json` points to the remote URL. |

## How `forcehybrid` Uses These Templates

You never run `install.js` or `template.js` directly — `forcehybrid create` drives the whole sequence:

1. Copies the selected template directory into the new app's `www/`
2. Calls `template.js prepare()` (via `createHelper.js` → `templateHelper.prepareTemplate()`)
3. `template.js prepare()` immediately calls `require('./install')` as its **first step**, running `install.js`
4. The rest of `template.js prepare()` then configures OAuth, moves files, and cleans up

So the effective order is: **`forcehybrid`** → copies template → **`template.js`** → **`install.js`** → back to `template.js` for the rest of setup.

See [Package/docs/hybrid/README.md](../../SalesforceMobileSDK-Package/docs/hybrid/README.md) for the full `forcehybrid create` workflow.

## SDK Dependencies (`package.json`)

Each hybrid template declares its SDK dependencies in `package.json`:

```json
{
  "sdkDependencies": {
    "SalesforceMobileSDK-Shared": "https://github.com/forcedotcom/SalesforceMobileSDK-Shared.git#dev",
    "SalesforceMobileSDK-Android": "https://github.com/forcedotcom/SalesforceMobileSDK-Android.git#dev"
  }
}
```

There is **no iOS SDK dependency** here. The iOS side is handled entirely via CocoaPods through `plugin.xml` in the CordovaPlugin repo. Only Shared (for `force.js`) and Android (for composite build) are cloned.

## `install.js` -- SDK Dependency Cloning

`install.js` reads `sdkDependencies` from `package.json` and for each entry:

1. Parses the `<repoUrl>#<branch>` format
2. Clones to `mobile_sdk/<name>/` using `git clone --branch <branch> --single-branch --depth 1`
3. Runs `npm install` after all clones complete

### Android Tagged-Release Skip

If the dependency is `SalesforceMobileSDK-Android` and the branch matches a semver tag pattern (`v\d+.\d+.\d+`), the clone is skipped entirely. In this case the pre-built `com.salesforce.mobilesdk:SalesforceHybrid` artifact on Maven Central is used instead. This means the Android SDK is only cloned as a source dependency for pre-release development.

```javascript
if (sdkDependency == 'SalesforceMobileSDK-Android' && branch.match(/v\d+\.\d+\.\d+/)) {
    // Skip clone -- use published Maven Central artifacts
    continue;
}
```

## `template.js` -- The Setup Function

`template.js` exports a `prepare(config, replaceInFiles, moveFile, removeFile)` function called by `createHelper.js` with `www/` as the current working directory.

### Steps (in order)

1. **Run `install.js`** -- `require('./install')` clones Shared and Android repos into `mobile_sdk/`.

2. **Replace `startPage`** (HybridRemoteTemplate only) -- Replaces the placeholder `apex/HybridRemotePage` with `config.startpage` in `bootconfig.json`.

3. **Replace consumer key** -- Substitutes `__INSERT_CONSUMER_KEY_HERE__` in `bootconfig.json` with `config.consumerkey` (if provided).

4. **Replace callback URL** -- Substitutes `__INSERT_CALLBACK_URL_HERE__` in `bootconfig.json` with `config.callbackurl` (if provided).

5. **Android login server** -- Replaces `__INSERT_DEFAULT_LOGIN_SERVER__` in `servers.xml` with `config.loginserver` (defaults to `https://login.salesforce.com`).

6. **iOS login server** -- Reads `../platforms/ios/<appname>/<appname>-Info.plist` directly and injects `<key>SFDCOAuthLoginHost</key>` into the plist dict. This cannot use `replaceInFiles` because the plist pattern spans multiple lines.

7. **Move `force.js`** -- Moves `mobile_sdk/SalesforceMobileSDK-Shared/libs/force.js` to `force.js` (in `www/`).

8. **Move Android SDK** (Android only) -- If `mobile_sdk/SalesforceMobileSDK-Android/` exists, creates `../platforms/android/mobile_sdk/` and moves the Android SDK there. This is the composite build path that `postinstall-android.js` registers in `settings.gradle`.

9. **Move `servers.xml`** (Android only) -- Moves `servers.xml` to `../platforms/android/app/src/main/res/xml/servers.xml`.

10. **Clean up** -- Removes from `www/`: `node_modules`, `mobile_sdk`, `package.json`, `template.js`, `install.js`, `servers.xml`.

11. **Return metadata** -- Returns an array of `{ workspacePath, bootconfigFile, platform }` per requested platform:
    ```javascript
    { workspacePath: 'platforms/<platform>', bootconfigFile: 'www/bootconfig.json', platform: '<platform>' }
    ```

## `bootconfig.json`

### HybridLocalTemplate

```json
{
    "remoteAccessConsumerKey": "__INSERT_CONSUMER_KEY_HERE__",
    "oauthRedirectURI": "__INSERT_CALLBACK_URL_HERE__",
    "isLocal": true,
    "startPage": "index.html",
    "errorPage": "error.html",
    "shouldAuthenticate": true,
    "attemptOfflineLoad": false
}
```

### HybridRemoteTemplate

```json
{
    "remoteAccessConsumerKey": "__INSERT_CONSUMER_KEY_HERE__",
    "oauthRedirectURI": "__INSERT_CALLBACK_URL_HERE__",
    "isLocal": false,
    "startPage": "apex/HybridRemotePage",
    "errorPage": "error.html",
    "shouldAuthenticate": true,
    "attemptOfflineLoad": false
}
```

### Field Reference

| Field | Description |
|-------|-------------|
| `remoteAccessConsumerKey` | OAuth consumer key from your Salesforce Connected App |
| `oauthRedirectURI` | OAuth callback URL configured in the Connected App |
| `isLocal` | `true` = start page is a file in `www/`; `false` = start page is a remote URL |
| `startPage` | The page loaded at launch. For local: a file path relative to `www/`. For remote: a Salesforce URL path (e.g., `apex/MyPage`). |
| `errorPage` | Page shown when the start page fails to load |
| `shouldAuthenticate` | Whether to require OAuth login before loading the start page |
| `attemptOfflineLoad` | Whether to attempt loading a cached version when offline |

## HybridRemoteTemplate Difference

The HybridRemoteTemplate is identical to HybridLocalTemplate except:

- `bootconfig.json` has `"isLocal": false` and `"startPage": "apex/HybridRemotePage"`
- `template.js` replaces the `startPage` placeholder with `config.startpage` before performing the other substitutions
- The exported `appType` is `'hybrid_remote'` instead of `'hybrid_local'`

## Testing

`test_template.sh` in the Templates repo does **not** support hybrid templates. To test hybrid templates, use `test/test_force.js` in the Package repo:

```bash
cd SalesforceMobileSDK-Package
npm install
node test/test_force.js --hybrid-local   # or --hybrid-remote
```

## Version Management

`setversion.sh` updates the SDK dependency branch in all template `package.json` files:

```bash
# On dev branch:
./setversion.sh -v 14.0.0 -d yes
# On master branch (after merging dev → master at release):
./setversion.sh -v 14.0.0 -d no
```

For hybrid templates specifically, this rewrites the `sdkDependencies` branch in `HybridLocalTemplate/package.json` and `HybridRemoteTemplate/package.json`:
- `-d yes` → `#dev` (e.g., `SalesforceMobileSDK-Shared.git#dev`)
- `-d no` → `#v14.0.0` (e.g., `SalesforceMobileSDK-Shared.git#v14.0.0`)

This controls whether `install.js` clones the dev branch or a specific release tag when generating a new hybrid app.

## Overriding SDK Dependencies

To test with a custom SDK branch or fork, you have two options:

1. **Edit `package.json` directly** before running `install.js`:
   ```json
   "sdkDependencies": {
     "SalesforceMobileSDK-Shared": "https://github.com/myfork/SalesforceMobileSDK-Shared.git#my-branch",
     "SalesforceMobileSDK-Android": "https://github.com/myfork/SalesforceMobileSDK-Android.git#my-branch"
   }
   ```

2. **Use the `--sdkdependencies` flag** with `forcehybrid create` to override at app creation time.
