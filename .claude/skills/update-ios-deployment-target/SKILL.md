---
name: update-ios-deployment-target
description: Update the minimum iOS deployment target across all iOS and React Native templates
---

# Update iOS Minimum Deployment Target

This skill updates the minimum iOS deployment target across all Salesforce Mobile SDK Templates that support iOS.

## When to Use
- After the iOS SDK repo has bumped its minimum iOS version
- When creating a new SDK release that requires a higher iOS version
- Templates should always match or exceed the iOS SDK minimum deployment target

## What This Skill Does

Updates the iOS deployment target in all iOS templates:

1. **Podfiles** - Updates platform declaration in all template Podfiles
2. **Xcode Project Files** - Updates IPHONEOS_DEPLOYMENT_TARGET in all .pbxproj files

## Usage

When invoked, ask the user for:
- **Current minimum iOS version** (e.g., "16.0")
- **New minimum iOS version** (e.g., "17.0")

## Affected Templates

### Native iOS Templates (7 templates)
- iOSIDPTemplate
- iOSNativeLoginTemplate
- iOSNativeSwiftEncryptedNotificationTemplate
- iOSNativeSwiftTemplate
- iOSNativeTemplate
- iOSNativeSwiftPackageManagerTemplate (no Podfile, only .pbxproj)
- MobileSyncExplorerSwift

### React Native Templates (4 templates)
React Native templates have iOS projects in `ios/` subdirectory:
- MobileSyncExplorerReactNative
- ReactNativeDeferredTemplate
- ReactNativeTemplate
- ReactNativeTypeScriptTemplate

## Step-by-Step Process

### 1. Update Native iOS Template Podfiles

Update `platform :ios, "X.0"` in:
- iOSIDPTemplate/Podfile
- iOSNativeLoginTemplate/Podfile
- iOSNativeSwiftEncryptedNotificationTemplate/Podfile
- iOSNativeSwiftTemplate/Podfile
- iOSNativeTemplate/Podfile
- MobileSyncExplorerSwift/Podfile

Note: iOSNativeSwiftPackageManagerTemplate does NOT have a Podfile (uses SPM instead)

### 2. Update React Native Template Podfiles

Update `platform :ios, "X.0"` in:
- MobileSyncExplorerReactNative/ios/Podfile
- ReactNativeDeferredTemplate/ios/Podfile
- ReactNativeTemplate/ios/Podfile
- ReactNativeTypeScriptTemplate/ios/Podfile

### 3. Update Native iOS Xcode Project Files

Update `IPHONEOS_DEPLOYMENT_TARGET = X.0;` in all .pbxproj files:
- iOSIDPTemplate/Authenticator.xcodeproj/project.pbxproj
- iOSNativeLoginTemplate/iOSNativeLoginTemplate.xcodeproj/project.pbxproj
- iOSNativeSwiftEncryptedNotificationTemplate/EncryptedNotificationTemplate.xcodeproj/project.pbxproj
- iOSNativeSwiftTemplate/iOSNativeSwiftTemplate.xcodeproj/project.pbxproj
- iOSNativeTemplate/iOSNativeTemplate.xcodeproj/project.pbxproj
- iOSNativeSwiftPackageManagerTemplate/iOSNativeSwiftPackageManagerTemplate.xcodeproj/project.pbxproj
- MobileSyncExplorerSwift/MobileSyncExplorerSwift.xcodeproj/project.pbxproj

### 4. Update React Native Xcode Project Files

Update `IPHONEOS_DEPLOYMENT_TARGET = X.0;` in all .pbxproj files:
- MobileSyncExplorerReactNative/ios/MobileSyncExplorerReactNative.xcodeproj/project.pbxproj
- ReactNativeDeferredTemplate/ios/ReactNativeDeferredTemplate.xcodeproj/project.pbxproj
- ReactNativeTemplate/ios/ReactNativeTemplate.xcodeproj/project.pbxproj
- ReactNativeTypeScriptTemplate/ios/ReactNativeTypeScriptTemplate.xcodeproj/project.pbxproj

## Post-Update Tasks

1. **Test templates**: Use `test_template.sh` to verify all iOS templates build successfully
   ```bash
   # Test all iOS templates
   ./test_template.sh --platform ios
   
   # Test specific template
   ./test_template.sh --template iOSNativeSwiftTemplate --platform ios
   ```

2. **Test React Native templates**: Test both iOS and Android platforms
   ```bash
   ./test_template.sh --template ReactNativeTemplate --platform ios
   ```

3. **Coordinate with iOS SDK**: Ensure this change is made AFTER the iOS SDK has bumped its deployment target

## Important Notes

- **STOP and FLAG for human review**: This is a breaking change that affects all iOS app developers using the SDK
- **Release timing**: Only bump deployment target at major releases, never patches
- **Breaking change**: Document this in migration guide and release notes
- **iOS SDK dependency**: The iOS SDK (SalesforceMobileSDK-iOS) must be updated FIRST before updating templates
- **Xcode version requirements**: Higher iOS deployment targets may require newer Xcode versions - ensure documentation reflects this

## Historical References
- PR #439: iOS 16.0 → iOS 17.0 bump (January 2025)

## Checklist

Before marking complete:
- [ ] All 6 native iOS template Podfiles updated (iOSNativeSwiftPackageManagerTemplate has no Podfile)
- [ ] All 4 React Native template Podfiles (in ios/ subdirs) updated
- [ ] All 7 native iOS template .pbxproj files updated
- [ ] All 4 React Native template .pbxproj files (in ios/ subdirs) updated
- [ ] Templates build successfully with `test_template.sh`
- [ ] iOS SDK has already been updated to the new deployment target
- [ ] Breaking change documented for release notes

## Finding Files Programmatically

Use these commands to find all affected files:

```bash
# Find all Podfiles (should find 10)
find . -name "Podfile" -not -path "*/mobile_sdk/*" | sort

# Find all .pbxproj files (should find 11)
find . -name "project.pbxproj" -not -path "*/mobile_sdk/*" | sort

# Verify current iOS version in Podfiles
grep -r "platform :ios" --include="Podfile"

# Verify current iOS version in .pbxproj files
grep -r "IPHONEOS_DEPLOYMENT_TARGET" --include="project.pbxproj" | grep -v "mobile_sdk"
```

## Related Skills

See `SalesforceMobileSDK-iOS/.claude/skills/update-ios-deployment-target/SKILL.md` for the iOS SDK version of this skill, which handles:
- CocoaPods specifications (podspec files)
- Build configuration files
- Installation scripts
- Documentation
- GitHub Actions workflows
- Code cleanup (removing obsolete version checks)
