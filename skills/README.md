# Mobile SDK Consumer Skills

Agent skills for **developers building apps with Mobile SDK**. Installable via the [vercel-labs/skills](https://github.com/vercel-labs/skills) CLI:

```bash
npx skills add forcedotcom/SalesforceMobileSDK-Templates
```

The `npx skills` CLI scans this `./skills/` directory for subdirectories containing a `SKILL.md`.

| Skill | Description |
|---|---|
| `create-ios-app-with-mobile-sdk/` | Create a new iOS Swift app from scratch with Mobile SDK already integrated |
| `create-android-app-with-mobile-sdk/` | Create a new Android Kotlin app from scratch with Mobile SDK already integrated |
| `add-mobile-sdk-ios/` | Add Mobile SDK authentication to an existing iOS Swift app |
| `add-smartstore-ios/` | Add SmartStore (encrypted local database) to an iOS Swift app that already has Mobile SDK |
| `add-mobilesync-ios/` | Add MobileSync (cloud data sync) to an iOS Swift app that already has SmartStore |
| `add-mobile-sdk-android/` | Add Mobile SDK authentication to an existing Android Kotlin app |
| `add-smartstore-android/` | Add SmartStore (encrypted local database) to an Android Kotlin app that already has Mobile SDK |
| `add-mobilesync-android/` | Add MobileSync (cloud data sync) to an Android Kotlin app that already has SmartStore |

> SDK-developer skills (for contributors working on the Mobile SDK itself) live in [`.claude/skills/`](../.claude/skills/) and are not published through this CLI.

## Adding a New Consumer Skill

Create a subdirectory with a `SKILL.md`:

```markdown
---
name: my-skill
description: What this skill does and when to use it
---

# My Skill
...
```

## Testing a Consumer Skill

Before shipping a new consumer skill, exercise it against a real blank app to verify it produces a working result end-to-end.

### Process

1. **Create a blank app** using `xcodegen` (or Xcode's new project wizard) in a temp directory
2. **Apply the skill** — run Claude Code in that directory and invoke the skill
3. **Build** — `xcodebuild` against a simulator to confirm no compile errors
4. **Run on simulator** — verify the skill's core behaviour (e.g. login screen appears, SDK initializes)
5. **Clean up** — delete the temp directory after validation

### Example: testing `add-mobile-sdk-ios`

```bash
mkdir /tmp/SkillTest && cd /tmp/SkillTest
# ... write project.yml, generate with xcodegen ...

# Apply the skill (Claude Code invokes it), then build:
xcodebuild -workspace SkillTest.xcworkspace \
  -scheme SkillTest \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

Expected: `** BUILD SUCCEEDED **` and Salesforce login screen on first run.

### What to check

- [ ] Project builds without errors
- [ ] Login screen appears on first launch
- [ ] Post-login screen is reachable
- [ ] No crash on cold start
