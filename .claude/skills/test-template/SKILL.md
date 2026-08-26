---
name: test-template
description: Test templates with test_template.sh script
type: skill
---

# Test Templates with test_template.sh

This skill documents testing templates in the Templates repository using the `test_template.sh` script.

## Purpose

After modifying templates (adding, removing, or updating), you need to verify that:
1. Template `install.js` runs successfully
2. SDK dependencies are downloaded correctly
3. Projects build successfully with Xcode (iOS) or Gradle (Android)

## Prerequisites

- Templates repo with changes committed locally
- Know which templates to test (or test all)
- Know which SDK branches to test against (if using custom branches)

## Basic Usage

### Test Specific Template

```bash
./test_template.sh --template iOSNativeSwiftTemplate
```

### Test on Specific Platform

```bash
./test_template.sh --template ReactNativeTemplate --platform ios
```

### Test All Templates

```bash
./test_template.sh
```

## Testing with Custom SDK Branches

When testing template changes alongside SDK changes, you can override SDK dependencies:

### iOS SDK Override

```bash
./test_template.sh \
  --msdk-ios-org wmathurin \
  --msdk-ios-branch feature/new-api \
  --template iOSNativeSwiftTemplate --platform ios
```

This modifies `package.json` `sdkDependencies` to use:
```json
{
  "SalesforceMobileSDK-iOS": "https://github.com/wmathurin/SalesforceMobileSDK-iOS.git#feature/new-api"
}
```

### Android SDK Override

```bash
./test_template.sh \
  --msdk-android-org wmathurin \
  --msdk-android-branch feature/new-api \
  --template AndroidNativeKotlinTemplate --platform android
```

### React Native with All Overrides

```bash
./test_template.sh \
  --msdk-ios-branch my-feature \
  --msdk-android-branch my-feature \
  --rn-force-branch my-feature \
  --template ReactNativeTemplate
```

This overrides:
- `SalesforceMobileSDK-iOS` dependency
- `SalesforceMobileSDK-Android` dependency
- `react-native-force` npm dependency

## What Gets Tested

✅ **Tested**:
- `install.js` execution
- SDK dependency download (to `mobile_sdk/` directory)
- CocoaPods installation (iOS)
- Gradle dependency resolution (Android)
- Xcode build (iOS)
- Gradle build (Android)

❌ **NOT Tested**:
- Running the generated app
- Unit tests
- UI tests

## Supported Platforms

| Template Type | Test Support |
|---------------|--------------|
| **Native (iOS)** | ✅ Full support |
| **Native (Android)** | ✅ Full support |
| **React Native** | ✅ Full support (iOS and Android) |
| **Hybrid** | ❌ Not supported |

## Common Testing Scenarios

### After Removing a Template

Test that remaining templates still work:

```bash
./test_template.sh
```

### After Modifying a Template

Test the specific modified template:

```bash
./test_template.sh --template <TemplateName>
```

### Testing Template with SDK Changes

When coordinating template changes with SDK changes:

```bash
./test_template.sh \
  --msdk-ios-branch my-feature \
  --msdk-android-branch my-feature \
  --template ReactNativeTemplate
```

### Testing All iOS Templates with Custom SDK

```bash
# Test each iOS template manually
for template in iOSNativeSwiftTemplate iOSNativeSwiftPackageManagerTemplate iOSIDPTemplate; do
  ./test_template.sh \
    --msdk-ios-branch my-feature \
    --template $template --platform ios
done
```

## Output Interpretation

**Success**:
- Template generates successfully
- Dependencies install without errors
- Build completes without errors

**Failure**:
- Template generation fails
- `install.js` errors
- Dependency installation fails
- Build errors (compilation, linking, etc.)

## Validation Checklist

- [ ] Test script runs without errors
- [ ] All applicable templates tested
- [ ] Build succeeds for all tested templates
- [ ] No dependency resolution errors
- [ ] No compilation errors

## Integration with Other Skills

This skill is used by:
- **remove-template**: After removing a template, test that remaining templates work
- **add-template**: After adding a template, test that it works
- **update-template**: After modifying a template, test that changes work

## Example: Testing After Template Removal

```bash
cd SalesforceMobileSDK-Templates

# After removing a template, test remaining iOS templates
./test_template.sh --template iOSNativeSwiftTemplate --platform ios
./test_template.sh --template iOSIDPTemplate --platform ios
./test_template.sh --template iOSNativeLoginTemplate --platform ios

# Or test all templates
./test_template.sh
```

## Example: Testing with Custom SDK Branch

```bash
cd SalesforceMobileSDK-Templates

# Testing modified template with custom iOS SDK
./test_template.sh \
  --msdk-ios-org wmathurin \
  --msdk-ios-branch fix/template-issue \
  --template iOSNativeSwiftTemplate --platform ios
```

## Notes

- **test_template.sh location**: Located in Templates repo root
- **Output directory**: Creates `test_output/` directory with generated projects
- **Cleanup**: Script cleans up test output after successful builds
- **CI Integration**: Used by GitHub Actions PR and nightly workflows
- **Performance**: Testing all templates can take 30-60 minutes

## Related Documentation

- See `TESTING.md` for comprehensive testing documentation
- See `.github/workflows/pr.yaml` for CI test configuration
- See workspace skill `test-templates.md` for cross-repo testing coordination
