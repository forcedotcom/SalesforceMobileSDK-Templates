# CLAUDE.md — Salesforce Mobile SDK Templates

---

## About This Project

The Salesforce Mobile SDK Templates repository is the **template library** for creating Salesforce mobile applications. It contains ready-to-use app templates that serve as starting points for iOS, Android, hybrid (Cordova), and React Native mobile applications.

**Key constraint**: These templates are **consumed by CLI tools** (`forceios`, `forcedroid`, `forcehybrid`, `forcereact`) and the SFDX plugin. Changes here affect every new app created with the Mobile SDK.

## Repository Purpose

This repository provides:

1. **Template Library** - Collection of app templates for all supported platforms and app types
2. **Template Metadata** - `templates.json` defining all available templates
3. **Template Scripts** - `install.js` and `template.js` for dependency management and customization
4. **Testing Infrastructure** - `test_template.sh` for validating template structure and buildability

## Repository Structure

```
SalesforceMobileSDK-Templates/
├── templates.json                         # Template registry (defines all templates)
├── test_template.sh                       # Template testing script
├── TESTING.md                             # Testing documentation
├── setversion.sh                          # Version update script
├── .claude/
│   └── skills/                            # Claude Code agent skills (see below)
│       └── README.md                      # Skills documentation
│
├── iOSNativeSwiftTemplate/                # Swift iOS template (most common)
│   ├── package.json                       # SDK dependencies
│   ├── install.js                         # Downloads SDK dependencies
│   ├── template.js                        # Customizes template for user
│   ├── Podfile                            # CocoaPods dependencies
│   └── <template-files>                   # Xcode project and source code
│
├── iOSNativeSwiftPackageManagerTemplate/  # Swift with SPM
├── iOSNativeSwiftEncryptedNotificationTemplate/  # Swift with notifications
├── iOSNativeLoginTemplate/                # Swift native login example
├── iOSIDPTemplate/                        # Swift Identity Provider
├── MobileSyncExplorerSwift/               # Swift MobileSync sample app
│
├── AndroidNativeKotlinTemplate/           # Kotlin Android template (most common)
│   ├── package.json                       # SDK dependencies
│   ├── install.js                         # Downloads SDK dependencies
│   ├── template.js                        # Customizes template for user
│   └── <template-files>                   # Gradle project and source code
│
├── AndroidNativeLoginTemplate/            # Kotlin native login example
├── AndroidIDPTemplate/                    # Kotlin Identity Provider
├── MobileSyncExplorerKotlinTemplate/      # Kotlin MobileSync sample app
│
├── ReactNativeTemplate/                   # React Native JavaScript template
│   ├── package.json                       # SDK and npm dependencies
│   ├── installios.js                      # iOS SDK setup
│   ├── installandroid.js                  # Android SDK setup
│   ├── template.js                        # Customizes for both platforms
│   ├── ios/                               # iOS project structure
│   └── android/                           # Android project structure
│
├── ReactNativeTypeScriptTemplate/         # React Native TypeScript template
├── ReactNativeDeferredTemplate/           # React Native deferred login
├── MobileSyncExplorerReactNative/         # React Native MobileSync sample app
│
├── HybridLocalTemplate/                   # Cordova local hybrid template
│   └── <hybrid-app-files>                 # HTML/JS/CSS app
│
└── HybridRemoteTemplate/                  # Cordova remote hybrid template
    └── <hybrid-app-files>                 # Visualforce/Communities app
```

## Template Registry (templates.json)

The `templates.json` file is the **single source of truth** for all available templates.

### Structure

```json
[
    {
        "path": "iOSNativeSwiftTemplate",
        "description": "Swift application using MobileSync, SwiftUI and Combine",
        "appType": "native_swift",
        "platforms": ["ios"]
    }
]
```

### Fields

- **path**: Directory name (must match actual directory)
- **description**: Human-readable description (shown in `listtemplates` output)
- **appType**: One of: `native`, `native_swift`, `native_kotlin`, `hybrid_local`, `hybrid_remote`, `react_native`
- **platforms**: Array of `"ios"`, `"android"`, or both

### App Types

| App Type | Description | Platforms |
|----------|-------------|-----------|
| **native** | Objective-C (iOS) or Java (Android) | Single platform |
| **native_swift** | Swift (iOS) | iOS only |
| **native_kotlin** | Kotlin (Android) | Android only |
| **hybrid_local** | Cordova app with local HTML/JS | iOS and/or Android |
| **hybrid_remote** | Cordova app loading Visualforce/Communities | iOS and/or Android |
| **react_native** | React Native app (JavaScript or TypeScript) | iOS and/or Android |

## Template Anatomy

Each template follows a consistent structure with two key scripts: `install.js` and `template.js`.

### package.json

Defines SDK dependencies in `sdkDependencies` field:

**Native iOS Template:**
```json
{
  "sdkDependencies": {
    "SalesforceMobileSDK-iOS": "https://github.com/forcedotcom/SalesforceMobileSDK-iOS.git#dev"
  }
}
```

**Native Android Template:**
```json
{
  "sdkDependencies": {
    "SalesforceMobileSDK-Android": "https://github.com/forcedotcom/SalesforceMobileSDK-Android.git#dev"
  }
}
```

**React Native Template:**
```json
{
  "sdkDependencies": {
    "SalesforceMobileSDK-iOS": "https://github.com/forcedotcom/SalesforceMobileSDK-iOS.git#dev",
    "SalesforceMobileSDK-Android": "https://github.com/forcedotcom/SalesforceMobileSDK-Android.git#dev"
  },
  "dependencies": {
    "react-native-force": "git+https://github.com/forcedotcom/SalesforceMobileSDK-ReactNative.git#dev"
  }
}
```

### install.js

Downloads SDK dependencies and runs platform-specific setup.

**Purpose:**
- Clone SDK repositories from `package.json` `sdkDependencies`
- Run CocoaPods (`pod update` for iOS)
- Install npm dependencies (for React Native)
- Cleanup unnecessary files

**Workflow:**
1. Read `sdkDependencies` from `package.json`
2. Parse repo URL and branch (`repoUrl#branch`)
3. Clone to `mobile_sdk/<sdk-name>/` directory
4. Run platform-specific dependency managers

**Example (iOS Native):**
```javascript
#!/usr/bin/env node

var packageJson = require('./package.json');
var execSync = require('child_process').execSync;
var path = require('path');
var fs = require('fs');

console.log('Installing sdk dependencies');
for (var sdkDependency in packageJson.sdkDependencies) {
    var repoUrlWithBranch = packageJson.sdkDependencies[sdkDependency];
    var parts = repoUrlWithBranch.split('#');
    var repoUrl = parts[0];
    var branch = parts.length > 1 ? parts[1] : 'master';
    var targetDir = path.join('mobile_sdk', sdkDependency);

    if (fs.existsSync(targetDir)) {
        console.log(targetDir + ' already exists');
    } else {
        execSync('git clone --branch ' + branch + ' --single-branch --depth 1 ' + repoUrl + ' ' + targetDir, {stdio:[0,1,2]});
    }
}

console.log('Installing pod dependencies');
execSync('pod update', {stdio:[0,1,2]});
```

**Android-Specific Logic:**
```javascript
// Skip cloning Android SDK for tagged releases (use Maven Central artifacts instead)
if (sdkDependency == 'SalesforceMobileSDK-Android' && branch.match(/v\d+\.\d+\.\d+/)) {
    console.log('SalesforceMobileSDK-Android is a release version. Using published artifacts.');
    continue;
}
```

**React Native:**
- Has separate `installios.js` and `installandroid.js`
- Runs `yarn install` for npm dependencies
- Creates `.xcode.env` with node binary path (iOS)
- Runs `pod update` in `ios/` directory

### template.js

Customizes the template with user-provided values.

**Purpose:**
- Replace template placeholders with actual values (app name, package name, organization)
- Configure OAuth settings (consumer key, callback URL, login server)
- Rename/move files to match new app name
- Run `install.js` to download SDK dependencies
- Return paths to workspace and bootconfig file

**Inputs (from CLI):**
```javascript
config = {
    appname: 'MyApp',
    packagename: 'com.mycompany.myapp',
    organization: 'My Company',
    consumerkey: '<oauth-consumer-key>',      // Optional
    callbackurl: '<oauth-callback-url>',      // Optional
    loginserver: 'https://login.salesforce.com' // Optional
}
```

**Workflow:**
1. **Replace in files**: Use `replaceInFiles()` to substitute template values
2. **Rename/move files**: Use `moveFile()` to rename project-specific files
3. **Remove files**: Use `removeFile()` for platform-specific cleanup
4. **Run install.js**: Execute `require('./install')` to download SDK dependencies
5. **Return metadata**: Provide workspace path and bootconfig file location

**Example (iOS Native):**
```javascript
function prepare(config, replaceInFiles, moveFile, removeFile) {
    var path = require('path');

    // Template values
    var templateAppName = 'iOSNativeSwiftTemplate';
    var templatePackageName = 'com.salesforce.iosnativeswifttemplate';
    var templateOrganization = 'iOSNativeSwiftTemplateOrganizationName';

    // Replace in files
    replaceInFiles(templateAppName, config.appname, [
        'Podfile',
        'package.json',
        templateAppName + '.xcodeproj/project.pbxproj'
    ]);

    replaceInFiles(templatePackageName, config.packagename, [
        templateAppName + '.xcodeproj/project.pbxproj'
    ]);

    // OAuth configuration
    if (config.consumerkey && config.consumerkey !== '') {
        replaceInFiles('__INSERT_CONSUMER_KEY_HERE__', config.consumerkey, [
            path.join(templateAppName, 'bootconfig.plist')
        ]);
    }

    // Rename/move files
    moveFile(
        path.join(templateAppName + '.xcodeproj'),
        path.join(config.appname + '.xcodeproj')
    );
    moveFile(templateAppName, config.appname);

    // Run install.js
    require('./install');

    // Return paths
    return {
        workspacePath: config.appname + '.xcworkspace',
        bootconfigFile: path.join(config.appname, 'bootconfig.plist')
    };
}

module.exports = {
    appType: 'native_swift',
    prepare: prepare
};
```

**React Native Multi-Platform:**
```javascript
function prepare(config, replaceInFiles, moveFile, removeFile) {
    var platforms = config.platform.split(',');
    var result = [];

    if (platforms.indexOf('ios') >= 0) {
        // iOS customization
        // ...
        require('./installios');
        result.push({
            workspacePath: path.join('ios', config.appname + '.xcworkspace'),
            bootconfigFile: path.join('ios', config.appname, 'bootconfig.plist'),
            platform: 'ios'
        });
    } else {
        removeFile('ios');
        removeFile('installios.js');
    }

    if (platforms.indexOf('android') >= 0) {
        // Android customization
        // ...
        require('./installandroid');
        result.push({
            workspacePath: 'android',
            bootconfigFile: path.join('android', 'app', 'src', 'main', 'res', 'values', 'bootconfig.xml'),
            platform: 'android'
        });
    } else {
        removeFile('android');
        removeFile('installandroid.js');
    }

    return result;
}
```

## Template Placeholders

Templates use placeholder strings that get replaced during customization:

| Placeholder | Replaced With | Files |
|-------------|---------------|-------|
| `iOSNativeSwiftTemplate` | `config.appname` | Project files, schemes |
| `com.salesforce.iosnativeswifttemplate` | `config.packagename` | Bundle ID, manifests |
| `iOSNativeSwiftTemplateOrganizationName` | `config.organization` | Xcode project |
| `__INSERT_CONSUMER_KEY_HERE__` | `config.consumerkey` | bootconfig.plist/bootconfig.xml |
| `__INSERT_CALLBACK_URL_HERE__` | `config.callbackurl` | bootconfig.plist/bootconfig.xml |
| `__INSERT_DEFAULT_LOGIN_SERVER__` | `config.loginserver` | Info.plist/servers.xml |

## Template Creation Workflow

When a user runs a CLI command, the following happens:

1. **CLI invokes Package repo** (`forceios create ...`)
2. **Package repo clones Templates repo** (from `templatesRepoUri` in `constants.js`)
3. **Package repo copies template** to user's project directory
4. **Package repo calls `template.js`** with user config
5. **`template.js` customizes template**:
   - Replaces placeholders
   - Renames files
   - Calls `install.js`
6. **`install.js` downloads SDK dependencies**:
   - Clones SDK repos to `mobile_sdk/`
   - Runs CocoaPods/Gradle/npm
7. **Package repo prints next steps** (how to open in IDE)

See `SalesforceMobileSDK-Package/shared/createHelper.js` for the orchestration logic.

## Testing Templates

### test_template.sh

Comprehensive testing script that validates template structure and buildability.

**What It Tests:**
- ✅ `install.js` runs successfully
- ✅ SDK dependencies are downloaded
- ✅ Project builds with Xcode (iOS) or Gradle (Android)
- ❌ Does NOT run the app or execute unit tests

**Usage:**
```bash
# Test a specific template
./test_template.sh --template iOSNativeSwiftTemplate

# Test on specific platform
./test_template.sh --template ReactNativeTemplate --platform ios

# Test all templates
./test_template.sh

# Test with custom SDK branch
./test_template.sh \
  --msdk-ios-branch my-feature \
  --template iOSNativeSwiftTemplate
```

### SDK Dependency Overrides

Override SDK dependencies for testing with custom branches:

```bash
# iOS SDK override
./test_template.sh \
  --msdk-ios-org wmathurin \
  --msdk-ios-branch feature/new-api \
  --template iOSNativeSwiftTemplate --platform ios

# Android SDK override
./test_template.sh \
  --msdk-android-org wmathurin \
  --msdk-android-branch feature/new-api \
  --template AndroidNativeKotlinTemplate --platform android

# React Native with all overrides
./test_template.sh \
  --msdk-ios-branch my-feature \
  --msdk-android-branch my-feature \
  --rn-force-branch my-feature \
  --template ReactNativeTemplate
```

The script modifies `package.json` `sdkDependencies` before running `install.js`.

### Supported Platforms

| Template Type | Test Support |
|---------------|--------------|
| **Native (iOS)** | ✅ Full support |
| **Native (Android)** | ✅ Full support |
| **React Native** | ✅ Full support (iOS and Android) |
| **Hybrid** | ❌ Not supported |

### GitHub Actions

- **PR Workflow**: Tests only changed templates
- **Nightly Workflow**: Tests all templates on all platforms

See `.github/workflows/` and `TESTING.md` for details.

## Available Templates

### Native iOS Templates

| Template | Description | Key Features |
|----------|-------------|--------------|
| **iOSNativeSwiftTemplate** | Basic Swift template (most common) | MobileSync, SwiftUI, Combine |
| **iOSNativeSwiftPackageManagerTemplate** | Swift with SPM | Uses Swift Package Manager instead of CocoaPods |
| **iOSNativeSwiftEncryptedNotificationTemplate** | Swift with notifications | Notification service extension |
| **iOSNativeLoginTemplate** | Native login UI example | SwiftUI native login screen |
| **iOSIDPTemplate** | Identity Provider sample | OAuth IDP implementation |
| **MobileSyncExplorerSwift** | Full MobileSync sample | Complete CRUD, sync, conflict resolution |

### Native Android Templates

| Template | Description | Key Features |
|----------|-------------|--------------|
| **AndroidNativeKotlinTemplate** | Basic Kotlin template (most common) | Modern Kotlin, Jetpack Compose |
| **AndroidNativeLoginTemplate** | Native login UI example | Jetpack Compose native login screen |
| **AndroidIDPTemplate** | Identity Provider sample | OAuth IDP implementation |
| **MobileSyncExplorerKotlinTemplate** | Full MobileSync sample | Complete CRUD, sync, conflict resolution |

### React Native Templates

| Template | Description | Key Features |
|----------|-------------|--------------|
| **ReactNativeTemplate** | Basic JavaScript template | React Native, JavaScript |
| **ReactNativeTypeScriptTemplate** | Basic TypeScript template | React Native, TypeScript |
| **ReactNativeDeferredTemplate** | Deferred login example | Login on demand, guest mode |
| **MobileSyncExplorerReactNative** | Full MobileSync sample | Complete CRUD, sync, conflict resolution |

### Hybrid Templates

| Template | Description | Key Features |
|----------|-------------|--------------|
| **HybridLocalTemplate** | Local HTML/JS app | Cordova, local web app |
| **HybridRemoteTemplate** | Visualforce/Communities app | Cordova, remote Salesforce UI |

## Creating a New Template

### Steps

1. **Choose base template** to copy from (e.g., `iOSNativeSwiftTemplate`)
2. **Create directory** matching template name
3. **Copy template files** and modify as needed
4. **Update placeholders** in code to use template-specific values
5. **Create `package.json`** with `sdkDependencies`
6. **Create `install.js`** (usually copy from similar template)
7. **Create `template.js`**:
   - Define `appType`
   - Implement `prepare()` function
   - Handle all placeholders
   - Return workspace and bootconfig paths
8. **Add to `templates.json`**
9. **Test with `test_template.sh`**

### Example: Simple iOS Template

**Directory:** `MyCustomTemplate/`

**package.json:**
```json
{
  "name": "MyCustomTemplate",
  "sdkDependencies": {
    "SalesforceMobileSDK-iOS": "https://github.com/forcedotcom/SalesforceMobileSDK-iOS.git#dev"
  }
}
```

**install.js:** (copy from `iOSNativeSwiftTemplate/install.js`)

**template.js:**
```javascript
function prepare(config, replaceInFiles, moveFile, removeFile) {
    var path = require('path');
    var templateAppName = 'MyCustomTemplate';

    // Customize files
    replaceInFiles(templateAppName, config.appname, ['Podfile', 'package.json']);

    // Rename project
    moveFile(templateAppName + '.xcodeproj', config.appname + '.xcodeproj');
    moveFile(templateAppName, config.appname);

    // Run install
    require('./install');

    return {
        workspacePath: config.appname + '.xcworkspace',
        bootconfigFile: path.join(config.appname, 'bootconfig.plist')
    };
}

module.exports = {
    appType: 'native_swift',
    prepare: prepare
};
```

**templates.json:**
```json
{
    "path": "MyCustomTemplate",
    "description": "My custom iOS template",
    "appType": "native_swift",
    "platforms": ["ios"]
}
```

## Version Management

### setversion.sh

Updates SDK dependency versions across all templates:

```bash
./setversion.sh <version>
```

Updates `sdkDependencies` in all `package.json` files to reference the specified version tag.

## Agent Behavior Guidelines

### Do

- Test templates with `test_template.sh` after making changes
- Update `templates.json` when adding/removing templates
- Maintain consistent placeholder patterns across similar templates
- Test both standalone template use and CLI-generated apps
- Verify OAuth placeholders are properly replaced
- Check that `mobile_sdk/` directory is created correctly
- Test with SDK overrides to ensure install scripts handle custom branches

### Don't

- Don't modify template structure without testing app generation flow
- Don't change placeholder strings without updating `template.js`
- Don't add dependencies without updating `install.js`
- Don't break backward compatibility with CLI tools
- Don't add templates without adding to `templates.json`
- Don't modify `install.js` without considering SDK override scenarios

### Escalation — Stop and Flag for Human Review

- Any change to the template creation workflow (affects `template.js` contract)
- Changes to placeholder patterns used across multiple templates
- New template types (e.g., new `appType` value)
- Changes to `install.js` logic that affect SDK dependency resolution
- Modifications to `templates.json` structure
- Changes that break `test_template.sh` or CI workflows

## Key Domain Concepts

- **Template**: Directory containing app boilerplate code, `install.js`, and `template.js`
- **App Type**: Category of app (native, hybrid, React Native) with platform constraints
- **SDK Dependencies**: Git repositories cloned during `install.js` execution
- **Placeholders**: Template-specific strings replaced during customization
- **Bootconfig File**: Platform-specific OAuth configuration file (plist or XML)
- **Workspace Path**: Path to open in IDE (`.xcworkspace` for iOS, project dir for Android)
- **Template Registry**: `templates.json` file defining all available templates
- **Install Script**: `install.js` downloads SDK dependencies and runs platform setup
- **Template Script**: `template.js` customizes template with user inputs

## Claude Code Skills

This repository provides [Claude Code agent skills](https://code.claude.com/docs/en/skills) for two audiences:

### Consumer Skills

Skills for **developers building apps with Mobile SDK** (SDK consumers) live in [`./skills/`](./skills/) at the repo root, matching the convention used by `anthropics/skills`, `obra/superpowers`, and other top repos on skills.sh. They are publicly installable:

```bash
npx skills add forcedotcom/SalesforceMobileSDK-Templates
```

The `npx skills` CLI scans the root `./skills/` directory for subdirectories containing a `SKILL.md`.

Available consumer skills:
- `create-ios-app-with-mobile-sdk` - Create a new iOS Swift app from scratch with Mobile SDK
- `create-android-app-with-mobile-sdk` - Create a new Android Kotlin app from scratch with Mobile SDK
- `add-mobile-sdk-ios` - Add Mobile SDK to an existing iOS Swift app
- `add-mobile-sdk-android` - Add Mobile SDK to an existing Android Kotlin app
- `add-smartstore-ios` - Add SmartStore (encrypted local database) to an iOS app
- `add-smartstore-android` - Add SmartStore to an Android app
- `add-mobilesync-ios` - Add MobileSync (cloud data sync) to an iOS app
- `add-mobilesync-android` - Add MobileSync to an Android app
- `add-biometric-auth-ios` - Add biometric authentication (Face ID / Touch ID) to an iOS app
- `add-biometric-auth-android` - Add biometric authentication (fingerprint / face / iris) to an Android app

### SDK Developer Skills (Internal)

Skills for **developers working on Mobile SDK itself** (contributors, maintainers) live in [`./.claude/skills/`](./.claude/skills/). They are auto-loaded by Claude Code when this repo is open locally, but ignored by `npx skills add` (which only scans the root `./skills/` directory):

- `remove-template` - Remove a template from this repository
- `test-template` - Test templates with `test_template.sh`
- `test-sdk-consumer-skills` - End-to-end test harness for all SDK consumer skills
- `update-ios-deployment-target` - Bump the minimum iOS deployment target across all templates

### Maintaining Skills

**IMPORTANT**: Two skill directories, two READMEs:
- Consumer skills live in `./skills/` — keep `./skills/README.md` in sync
- SDK-developer skills live in `./.claude/skills/` — keep `./.claude/skills/README.md` in sync

When adding a new skill:
1. Decide audience: consumer (root `./skills/`) or SDK-maintainer (`./.claude/skills/`)
2. Create the skill directory and `SKILL.md` file in the right location
3. Add an entry to the appropriate README table
4. If it's a consumer skill, test it end-to-end before shipping (see testing section in `./skills/README.md`)

When removing a skill:
1. Delete the skill directory
2. Remove the entry from the appropriate README

When modifying a skill:
1. Update the `SKILL.md` file
2. If the description changes, update the corresponding table entry in the appropriate README

## Related Documentation

- **TESTING.md**: Comprehensive testing guide with `test_template.sh` usage
- **.claude/skills/README.md**: Complete skills documentation and testing guide
- **Package Repo**: See `SalesforceMobileSDK-Package/CLAUDE.md` for CLI tools that consume templates
- **Package createHelper**: See `SalesforceMobileSDK-Package/shared/createHelper.js` for orchestration logic
- **Mobile SDK Development Guide**: https://developer.salesforce.com/docs/platform/mobile-sdk/guide
- **iOS SDK**: See `SalesforceMobileSDK-iOS/CLAUDE.md`
- **Android SDK**: See `SalesforceMobileSDK-Android/CLAUDE.md`
- **React Native SDK**: See `SalesforceMobileSDK-ReactNative/CLAUDE.md`
