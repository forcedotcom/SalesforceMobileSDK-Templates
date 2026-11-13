# Template Testing Guide

## What Testing Covers

**Important**: Testing verifies that templates can be **installed and built successfully**. It does not run the generated applications or execute unit/integration tests. The test validates template structure, dependency resolution, and basic compilation.

The separate React Native JavaScript and TypeScript workflow runs Jest for all
four React Native templates and checks templates containing TypeScript with
`tsc --noEmit`. It includes the TypeScript sample's logout regression tests.
It runs on pull requests without secrets or native SDK setup. The bridge is
packed from the target branch, so companion upgrades must land bridge-first;
manual dispatch can select a reviewed bridge repository and exact commit.

Run the same checks locally with Node 22.18+ and Yarn Classic installed:

```bash
export MSDK_REACT_NATIVE_FORCE_PACKAGE=file:/path/to/react-native-force.tgz
node scripts/check-react-native-template.ts ReactNativeTypeScriptTemplate /tmp/new-template-check
```

The output directory must be new. It retains dependency provenance, TypeScript
results in `checks.json`, and Jest results in `jest-results.json`. These checks
complement native builds and authenticated runtime testing.

## Test Script Usage

### Generated React Native consumer acceptance

React Native 0.87 templates pair Gesture Handler 2.33.1 with Screens 4.27.0.
Earlier pins fail against removed React headers and nullable Android bitmap
APIs. [Screens 4.27](https://github.com/software-mansion/react-native-screens/releases/tag/4.27.0)
adds RN 0.87 support, including an iOS runtime crash fix. Native consumer builds
must cover these dependencies as well as the Salesforce bridge.

Template copies and Metro bundles do not exercise CLI substitution, native
autolinking or SDK initialization. For a companion upgrade, generate both the
JavaScript and TypeScript apps with `forcereact createwithtemplate`, selecting
the reviewed template directory and bridge package explicitly:

```bash
export MSDK_REACT_NATIVE_FORCE_PACKAGE=file:/absolute/path/react-native-force.tgz
forcereact createwithtemplate --platform=ios,android \
  --templaterepouri=/absolute/path/Templates/ReactNativeTemplate \
  --appname=UpgradeJSConsumer --packagename=com.example.upgrade.jsconsumer \
  --organization=Example --outputdir=/absolute/path/new-js-consumer \
  --consumerkey= --callbackurl= --loginserver=https://login.salesforce.com
```

Repeat with `ReactNativeTypeScriptTemplate`, a different app name/package, and
a new output directory. Retain each generated app's
`node_modules/.msdk-source.json`, lockfiles, native SDK commit IDs and the bridge
archive's SHA-256. Confirm the installed bridge's native and distribution sources
match the intended artifact. Preserve the installer patches when recording SDK
provenance; a native SDK commit ID alone does not describe a patched checkout.

Build Debug and Release for both platforms from each generated app. For local
compilation, use an explicit Android ABI and an explicit iOS simulator
destination; an unsigned simulator build proves compilation, not device signing
or App Store readiness. Keep build logs and exact toolchain versions with the
source receipts. Run the TypeScript app's `tsc --noEmit` and Jest checks after CLI
generation as well.

Complete this runtime matrix on dedicated test resources, using protected local
OAuth/test configuration and an approved test account:

| Scenario | JavaScript app | TypeScript app | Platforms/modes |
|----------|----------------|----------------|-----------------|
| Cold start, Hermes and native module loading | Required | Required | iOS/Android, Debug/Release |
| Login, cancellation/failure and recovery | Required | Required | iOS/Android |
| Contact REST query, logout and re-login | Required | Required | iOS/Android |
| SmartStore local CRUD and cleanup | Required | Required | iOS/Android |
| Representative MobileSync down/up and cleanup | Required | Required | iOS/Android |
| Guest start and deferred login | Deferred template | Not applicable | iOS/Android |

Use explicit simulator IDs and Android serials. Run selected bridge test cases
against the same reviewed bridge/native SDK sources; use sharded CI for the full
Android suite. Record an unavailable account, device or test environment as
missing coverage. Neither successful compilation nor an unconfigured login page
establishes authenticated runtime acceptance. Keep credentials and raw
authenticated responses out of commits and shared logs.

### Supported JavaScript engine

Mobile SDK's React Native templates use Hermes on Android and iOS, following
React Native's [bundled Hermes configuration](https://reactnative.dev/docs/0.87/hermes).
Keep `hermesEnabled=true` on Android. Disabling it fails configuration before
an app can be built without its required runtime. The iOS Podfiles explicitly
enable Hermes. JavaScriptCore support requires separate community runtime
integration and is outside the supported template verification matrix.

### React Native bridge source selection

React Native installers verify the installed bridge's React Native and React
peer requirements and write a source receipt in
`node_modules/.msdk-source.json`. A version upgrade must not test an older bridge
from the release branch and interpret that result as coverage of the proposed
bridge changes.

For local companion verification, select the reviewed package before installing:

```bash
export MSDK_REACT_NATIVE_FORCE_PACKAGE=file:/path/to/react-native-force.tgz
./test_template.sh --template ReactNativeTypeScriptTemplate --platform android
```

An approved Git URL with an exact commit can be used instead of a local tarball.
CI using the default release-branch dependency requires the matching bridge
upgrade to land first. Keep the bridge receipt with the test results, and verify
the resolved source against the intended checkout/artifact before acceptance.

The `test_template.sh` script allows you to test templates locally or in CI/CD, with support for overriding SDK dependencies.

### Prerequisites

- **For iOS**: macOS with Xcode 16.1+ for React Native templates
- **For Android**: Java 17+ and Gradle
- **For all**: Node.js 22+ and `jq` command-line JSON processor

React Native 0.87 templates require Node `^22.13.0 || ^24.3.0 || >=26.0.0`.
The TypeScript check helper above requires Node 22.18+ for native type stripping.
Android keeps `android.builtInKotlin=false` and `android.newDsl=false` with AGP 9
to retain the Kotlin plugin and Android DSL expected by React Native's Gradle
integration. The Jest preset now comes from `@react-native/jest-preset`.
These settings match the [React Native 0.87 template](https://github.com/react-native-community/template/tree/0.87-stable/template).
Mobile SDK's minimum deployment versions remain iOS 18 and Android API 31.

### Basic Usage

```bash
# Test a specific template on all supported platforms
./test_template.sh --template <template-name>

# Test a specific template on a specific platform
./test_template.sh --template <template-name> --platform <platform>

# Test all templates on all platforms
./test_template.sh

# Get help
./test_template.sh --help
```

## SDK Dependency Overrides

You can override the SDK dependencies to test against custom branches or forks. This is useful for testing templates with in-development SDK changes.

### Quick Start

```bash
# Test with custom iOS SDK branch
./test_template.sh --msdk-ios-branch my-feature --template iOSNativeSwiftTemplate --platform ios

# Test with custom Android SDK branch
./test_template.sh --msdk-android-branch my-feature --template AndroidNativeKotlinTemplate --platform android

# Test React Native with all custom branches
./test_template.sh \
  --msdk-ios-branch my-feature \
  --msdk-android-branch my-feature \
  --rn-force-branch my-feature \
  --template ReactNativeTemplate
```

### Parameter Reference

| Parameter | Description | Default | Example |
|-----------|-------------|---------|---------|
| `--msdk-ios-org` | iOS SDK GitHub org | `forcedotcom` | `wmathurin` |
| `--msdk-ios-branch` | iOS SDK branch | `dev` | `feature/my-work` |
| `--msdk-android-org` | Android SDK GitHub org | `forcedotcom` | `wmathurin` |
| `--msdk-android-branch` | Android SDK branch | `dev` | `v13.0` |
| `--rn-force-org` | React Native SDK GitHub org | `forcedotcom` | `myteam` |
| `--rn-force-branch` | React Native SDK branch | `dev` | `feature/new-api` |

### Override Notes

- **Partial Override**: Only specify the parameters you want to change
- **Defaults**: Omitted org defaults to `forcedotcom`, omitted branch defaults to `dev`
- **Order**: SDK override parameters must come before `--template` and `--platform`
- **Scope**: Overrides only modify dependencies that exist in the template's `package.json`

### Supported Template Types

- **Native Templates**: `native`, `native_swift`, `native_kotlin`
  - iOS: Runs `install.js` → `xcodebuild`
  - Android: Runs `install.js` → `gradle assembleDebug`

- **React Native Templates**: `react_native`
  - iOS: Runs `installios.js` → `xcodebuild` in `ios/` directory
  - Android: Runs `installandroid.js` → `gradle assembleDebug` in `android/` directory
  - **Note (SDK 14.0+)**: `--rn-force-branch` controls both the JS API and the Android bridge code (both live in the ReactNative repo). `--msdk-android-branch` only affects core SDK libraries (MobileSync, SmartStore, SalesforceSDK).

- **Hybrid Templates**: Not supported

## Common Use Cases

### Testing Feature Branch
```bash
# Test all SDKs with same feature branch
./test_template.sh \
  --msdk-ios-branch feature/my-work \
  --msdk-android-branch feature/my-work \
  --rn-force-branch feature/my-work

# Test only iOS changes
./test_template.sh --msdk-ios-branch my-ios-feature
```

### Testing from a Fork
```bash
./test_template.sh \
  --msdk-ios-org myusername \
  --msdk-ios-branch my-feature \
  --template iOSNativeSwiftTemplate
```

## GitHub Actions Workflows

### PR Workflow
- Automatically detects changed templates and tests only those
- Tests ALL templates if `test_template.sh` or `templates.json` changes
- Runs on macOS-15 (iOS) and Ubuntu (Android)

### Nightly Workflow
- Automatically discovers and tests ALL templates for each platform from `templates.json`
- No hardcoded template lists to maintain
- Runs daily at 2 AM PST (10 AM UTC)
