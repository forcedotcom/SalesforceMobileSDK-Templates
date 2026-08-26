![Build Status](https://forcedotcom.github.io/SalesforceMobileSDK-TestResults/Templates-results/dev/latest/buildstatus.svg)

# Salesforce Mobile SDK Templates

The **template library** for creating Salesforce mobile applications. This repository contains ready-to-use app templates for iOS, Android, hybrid (Cordova), and React Native platforms.

## Overview

These templates are consumed by the Mobile SDK CLI tools and SFDX plugin to generate new mobile applications:

- **forceios** - Creates iOS native apps (Swift or Objective-C)
- **forcedroid** - Creates Android native apps (Kotlin or Java)
- **forcehybrid** - Creates hybrid apps using Cordova
- **forcereact** - Creates React Native apps (JavaScript or TypeScript)
- **sf mobilesdk** - SFDX plugin providing all above functionality

## Available Templates

### Native iOS

| Template | Description |
|----------|-------------|
| **iOSNativeSwiftTemplate** | Basic Swift template with MobileSync, SwiftUI, and Combine *(most common)* |
| **iOSNativeSwiftPackageManagerTemplate** | Swift template using Swift Package Manager instead of CocoaPods |
| **iOSNativeSwiftEncryptedNotificationTemplate** | Swift template with notification service extension |
| **iOSNativeLoginTemplate** | SwiftUI native login screen example |
| **iOSIDPTemplate** | Identity Provider implementation sample |
| **MobileSyncExplorerSwift** | Full-featured sample app demonstrating MobileSync CRUD and sync |

### Native Android

| Template | Description |
|----------|-------------|
| **AndroidNativeKotlinTemplate** | Basic Kotlin template with Jetpack Compose *(most common)* |
| **AndroidNativeLoginTemplate** | Jetpack Compose native login screen example |
| **AndroidIDPTemplate** | Identity Provider implementation sample |
| **MobileSyncExplorerKotlinTemplate** | Full-featured sample app demonstrating MobileSync CRUD and sync |

### React Native

| Template | Description |
|----------|-------------|
| **ReactNativeTemplate** | Basic JavaScript template |
| **ReactNativeTypeScriptTemplate** | Basic TypeScript template |
| **ReactNativeDeferredTemplate** | Deferred login (guest mode) example |
| **MobileSyncExplorerReactNative** | Full-featured sample app demonstrating MobileSync CRUD and sync |

### Hybrid (Cordova)

| Template | Description |
|----------|-------------|
| **HybridLocalTemplate** | Local HTML/JS/CSS app |
| **HybridRemoteTemplate** | Remote Visualforce/Communities app |

## Using Templates

### With CLI Tools

```bash
# Create app with default template
forceios create --appname MyApp --packagename com.mycompany.myapp --organization "My Company"

# List available templates
forceios listtemplates

# Create app from specific template
forceios createwithtemplate \
  --templaterepouri iOSNativeSwiftTemplate \
  --appname MyApp \
  --packagename com.mycompany.myapp \
  --organization "My Company"

# Create from custom template repository
forceios createwithtemplate \
  --templatesource https://github.com/myorg/my-templates#main \
  --template MyCustomTemplate \
  --appname MyApp \
  --packagename com.mycompany.myapp \
  --organization "My Company"
```

### With SFDX Plugin

```bash
# Install plugin
sf plugins install sfdx-mobilesdk-plugin

# Create app
sf mobilesdk ios create \
  --appname MyApp \
  --packagename com.mycompany.myapp \
  --organization "My Company"

# List templates
sf mobilesdk ios listtemplates
```

## How Templates Work

Each template contains two key scripts that orchestrate app creation:

### 1. install.js

Downloads SDK dependencies and sets up the development environment.

**What it does:**
- Clones SDK repositories from `package.json` `sdkDependencies`
- Runs CocoaPods (`pod update` for iOS)
- Installs npm dependencies (for React Native)
- Cleans up unnecessary files

**Example:**
```javascript
var packageJson = require('./package.json');
var execSync = require('child_process').execSync;

for (var sdkDependency in packageJson.sdkDependencies) {
    var repoUrlWithBranch = packageJson.sdkDependencies[sdkDependency];
    var [repoUrl, branch] = repoUrlWithBranch.split('#');
    var targetDir = 'mobile_sdk/' + sdkDependency;

    execSync(`git clone --branch ${branch} --single-branch --depth 1 ${repoUrl} ${targetDir}`);
}

execSync('pod update'); // iOS only
```

### 2. template.js

Customizes the template with user-provided values.

**What it does:**
- Replaces placeholders (app name, package name, organization)
- Configures OAuth settings (consumer key, callback URL)
- Renames/moves files to match new app name
- Calls `install.js` to download dependencies
- Returns workspace and bootconfig file paths

**Example:**
```javascript
function prepare(config, replaceInFiles, moveFile, removeFile) {
    // Replace template values with user values
    replaceInFiles('iOSNativeSwiftTemplate', config.appname, [
        'Podfile',
        'iOSNativeSwiftTemplate.xcodeproj/project.pbxproj'
    ]);

    // Rename project files
    moveFile('iOSNativeSwiftTemplate.xcodeproj', config.appname + '.xcodeproj');
    moveFile('iOSNativeSwiftTemplate', config.appname);

    // Download SDK dependencies
    require('./install');

    return {
        workspacePath: config.appname + '.xcworkspace',
        bootconfigFile: config.appname + '/bootconfig.plist'
    };
}

module.exports = {
    appType: 'native_swift',
    prepare: prepare
};
```

## Template Structure

Each template follows this structure:

```
TemplateDirectory/
├── package.json              # SDK dependencies
├── install.js                # Downloads SDK dependencies
├── template.js               # Customizes template
├── <project-files>           # Platform-specific project files
└── <source-code>             # Template source code
```

**React Native templates** have additional files:
```
ReactNativeTemplate/
├── package.json              # SDK and npm dependencies
├── installios.js             # iOS setup
├── installandroid.js         # Android setup
├── template.js               # Multi-platform customization
├── ios/                      # iOS project
└── android/                  # Android project
```

## Testing Templates

Use `test_template.sh` to verify templates build successfully:

```bash
# Test a specific template
./test_template.sh --template iOSNativeSwiftTemplate

# Test on specific platform
./test_template.sh --template ReactNativeTemplate --platform ios

# Test all templates
./test_template.sh
```

### Testing with Custom SDK Branches

Override SDK dependencies for testing with in-development changes:

```bash
# Test with custom iOS SDK branch
./test_template.sh \
  --msdk-ios-branch my-feature \
  --template iOSNativeSwiftTemplate

# Test with custom Android SDK branch
./test_template.sh \
  --msdk-android-branch my-feature \
  --template AndroidNativeKotlinTemplate

# Test React Native with all custom branches
./test_template.sh \
  --msdk-ios-branch my-feature \
  --msdk-android-branch my-feature \
  --rn-force-branch my-feature \
  --template ReactNativeTemplate
```

For detailed testing documentation, see [TESTING.md](TESTING.md).

## Creating a Custom Template

### Basic Steps

1. **Copy an existing template** as a starting point
2. **Modify the code** to implement your desired functionality
3. **Update placeholders** to match your template name
4. **Create/update scripts**:
   - `package.json` with `sdkDependencies`
   - `install.js` for SDK dependency management
   - `template.js` for customization logic
5. **Add to `templates.json`**:
   ```json
   {
       "path": "MyCustomTemplate",
       "description": "My custom iOS template",
       "appType": "native_swift",
       "platforms": ["ios"]
   }
   ```
6. **Test with `test_template.sh`**

### Template Placeholders

Templates use placeholder strings that get replaced during customization:

| Placeholder | Replaced With | Where |
|-------------|---------------|-------|
| Template app name (e.g., `iOSNativeSwiftTemplate`) | User's app name | Project files, schemes |
| Template package name (e.g., `com.salesforce.iosnativeswifttemplate`) | User's package name | Bundle ID, manifests |
| Template organization (e.g., `iOSNativeSwiftTemplateOrganizationName`) | User's organization | Xcode project |
| `__INSERT_CONSUMER_KEY_HERE__` | OAuth consumer key | bootconfig files |
| `__INSERT_CALLBACK_URL_HERE__` | OAuth callback URL | bootconfig files |
| `__INSERT_DEFAULT_LOGIN_SERVER__` | Login server URL | Info.plist/servers.xml |

### App Types

When adding a template to `templates.json`, specify the `appType`:

- **native** - Objective-C (iOS) or Java (Android)
- **native_swift** - Swift (iOS only)
- **native_kotlin** - Kotlin (Android only)
- **hybrid_local** - Cordova with local HTML/JS
- **hybrid_remote** - Cordova with Visualforce/Communities
- **react_native** - React Native (JavaScript or TypeScript)

### Example: Simple iOS Template

**MyCustomTemplate/package.json:**
```json
{
  "name": "MyCustomTemplate",
  "sdkDependencies": {
    "SalesforceMobileSDK-iOS": "https://github.com/forcedotcom/SalesforceMobileSDK-iOS.git#dev"
  }
}
```

**MyCustomTemplate/install.js:** *(copy from existing iOS template)*

**MyCustomTemplate/template.js:**
```javascript
function prepare(config, replaceInFiles, moveFile, removeFile) {
    var path = require('path');
    var templateAppName = 'MyCustomTemplate';

    replaceInFiles(templateAppName, config.appname, ['Podfile', 'package.json']);
    moveFile(templateAppName + '.xcodeproj', config.appname + '.xcodeproj');
    moveFile(templateAppName, config.appname);

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

**templates.json** (add entry):
```json
{
    "path": "MyCustomTemplate",
    "description": "My custom iOS template",
    "appType": "native_swift",
    "platforms": ["ios"]
}
```

## Version Management

Update SDK dependencies across all templates:

```bash
./setversion.sh <version>
```

This updates `sdkDependencies` in all `package.json` files to reference the specified SDK version.

## Documentation

- **CLAUDE.md**: Comprehensive development guide for AI-assisted development
- **TESTING.md**: Detailed testing guide with SDK override examples
- **[Mobile SDK Developer Guide](https://developer.salesforce.com/docs/platform/mobile-sdk/guide)**: Official documentation
- **[SalesforceMobileSDK-Package](https://github.com/forcedotcom/SalesforceMobileSDK-Package)**: CLI tools that consume these templates

## Related Repositories

- **[SalesforceMobileSDK-iOS](https://github.com/forcedotcom/SalesforceMobileSDK-iOS)** - iOS native SDK
- **[SalesforceMobileSDK-Android](https://github.com/forcedotcom/SalesforceMobileSDK-Android)** - Android native SDK
- **[SalesforceMobileSDK-ReactNative](https://github.com/forcedotcom/SalesforceMobileSDK-ReactNative)** - React Native SDK
- **[SalesforceMobileSDK-Package](https://github.com/forcedotcom/SalesforceMobileSDK-Package)** - CLI tools and SFDX plugin
- **[SalesforceMobileSDK-Shared](https://github.com/forcedotcom/SalesforceMobileSDK-Shared)** - Hybrid JavaScript libraries
- **[SalesforceMobileSDK-CordovaPlugin](https://github.com/forcedotcom/SalesforceMobileSDK-CordovaPlugin)** - Cordova plugin

## Contributing

Contributions are welcome! When adding or modifying templates:

1. Follow existing template patterns
2. Test with `test_template.sh`
3. Update `templates.json`
4. Verify CLI tools can use the template
5. Document any special requirements

## License

Salesforce Mobile SDK License. See [LICENSE](LICENSE) for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/forcedotcom/SalesforceMobileSDK-Templates/issues)
- **Questions**: [Salesforce Developer Community](https://developer.salesforce.com/forums)
- **Stack Overflow**: Tag questions with `salesforce-mobile-sdk`
