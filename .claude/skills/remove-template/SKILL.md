---
name: remove-template
description: Remove a template from the Templates repository
type: skill
---

# Remove Template from Templates Repository

This skill removes a template from the SalesforceMobileSDK-Templates repository.

## Prerequisites

- Template name to remove (e.g., `iOSNativeSwiftTemplate`)
- Template's `appType` from `templates.json` (e.g., `native_swift`, `hybrid_local`)
- Know if this is the **last template** with that `appType`

## Steps

### 1. Remove Template Directory

```bash
cd SalesforceMobileSDK-Templates
git rm -r <TemplateName>
```

### 2. Update templates.json

**File**: `templates.json`

Remove the template entry completely:
```json
{
    "path": "TemplateName",
    "description": "...",
    "appType": "...",
    "platforms": ["..."]
}
```

### 3. Update setversion.sh

**File**: `setversion.sh`

Remove references in **two sections**:

**Section 1: build.gradle.kts (Android templates only)**
```bash
# Remove line like:
update_build_gradle_dependencies "./TemplateName/app/build.gradle.kts"  "${OPT_VERSION}"
```

**Section 2: package.json (all templates)**
```bash
# Remove line like:
update_package_json "./TemplateName/package.json"  "${SDK_TAG}"
# or for SPM templates:
update_package_json "./TemplateName/package.json"  "${SDK_TAG_SPM}"
```

### 4. Check test_template.sh

**File**: `test_template.sh`

**Usually no changes needed** - script reads `templates.json` dynamically.

**Check for**: Special handling or explicit exclusions of this template.

### 5. Update TESTING.md

**File**: `TESTING.md`

**Search for**: Template name in examples.

**Remove**: Any documentation specifically mentioning this template.

### 6. Update CLAUDE.md

**File**: `CLAUDE.md`

Remove template from:
- **Available Templates** section
- Template tables (Native iOS, Native Android, React Native, Hybrid)
- Any examples referencing this template

### 7. Update README.md

**File**: `README.md`

Remove template from:
- **Available Templates** section  
- Template tables organized by platform
- Usage examples featuring this template

### 8. Verify No References Remain

```bash
grep -r "TemplateName" --exclude-dir=node_modules .
```

## Validation

### Checklist

- [ ] Template directory removed with `git rm -r`
- [ ] templates.json updated
- [ ] setversion.sh updated (both sections if applicable)
- [ ] test_template.sh checked (updated if needed)
- [ ] TESTING.md checked (updated if needed)
- [ ] CLAUDE.md updated
- [ ] README.md updated
- [ ] No references remain: `grep -r "TemplateName" --exclude-dir=node_modules .`

### Test Remaining Templates

Run the test script to ensure remaining templates still work:

```bash
./test_template.sh
```

Or test specific templates:
```bash
./test_template.sh --template <OtherTemplateName>
```

## Commit and Push

```bash
git add -A
git commit -m "Remove <TemplateName> template

Removed template directory and all references from:
- templates.json
- setversion.sh
- TESTING.md
- CLAUDE.md
- README.md"

git push origin <branch-name>
```

## Next Steps

After pushing to a branch, proceed to the Package repository to update references there.

See: `SalesforceMobileSDK-Package/.claude/skills/remove-template.md`
