# Template Testing Guide

## What Testing Covers

**Important**: Testing verifies that templates can be **installed and built successfully**. It does not run the generated applications or execute unit/integration tests. The test validates template structure, dependency resolution, and basic compilation.

## Test Script Usage

The `test_template.sh` script allows you to test templates locally or in CI/CD, with support for overriding SDK dependencies.

### Prerequisites

- **For iOS**: macOS with Xcode installed
- **For Android**: Java 17+ and Gradle
- **For all**: Node.js 20+ and `jq` command-line JSON processor

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
