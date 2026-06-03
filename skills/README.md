# Mobile SDK Consumer Skills

Agent skills for autonomous coding agents that build apps with the Salesforce Mobile SDK. Installable via the [skills CLI](https://github.com/vercel-labs/skills):

```bash
npx skills add forcedotcom/SalesforceMobileSDK-Templates
```

The CLI scans this directory for subdirectories that contain a `SKILL.md`.

## Available Skills

| Skill | Description |
|---|---|
| [`ios-mobile-sdk/`](./ios-mobile-sdk/) | Integrate the Mobile SDK into iOS Swift apps: create a new app, add SDK auth, SmartStore, MobileSync, biometric auth (Face ID / Touch ID). |
| [`android-mobile-sdk/`](./android-mobile-sdk/) | Integrate the Mobile SDK into Android Kotlin apps: create a new app, add SDK auth, SmartStore, MobileSync, biometric auth (fingerprint / face / iris). |

> SDK-developer skills (for contributors working on the Mobile SDK itself) live in [`../.claude/skills/`](../.claude/skills/) and are not published through this CLI.

## Skill Layout

Each skill follows the same shape:

```
<skill-name>/
├── SKILL.md                       # Thin router: scenarios, detection rules, invariants
└── references/
    ├── create-new-app.md          # Bootstrap a project from scratch
    ├── add-mobile-sdk.md          # Wire OAuth login into an existing project
    ├── add-smartstore.md          # Add encrypted local DB
    ├── add-mobilesync.md          # Add cloud sync on top of SmartStore
    ├── add-biometric-auth.md      # Add biometric session locking
    ├── api-reference.md           # Class/symbol map
    └── troubleshooting.md         # Symptom → cause → fix table
```

`SKILL.md` is the entry point an agent loads. Each scenario file is self-contained — the agent reads exactly one reference per task.

## Adding a New Consumer Skill

1. Create `skills/<skill-name>/SKILL.md` with the standard frontmatter:
   ```markdown
   ---
   name: <skill-name>
   description: When to use this skill, in one sentence.
   ---
   ```
2. Split the body into `references/*.md` — one file per scenario, plus an `api-reference.md` and `troubleshooting.md` if applicable.
3. Add a row to the table above.
4. Verify against the live SDK source (<https://github.com/forcedotcom/SalesforceMobileSDK-iOS>, <https://github.com/forcedotcom/SalesforceMobileSDK-Android>) and against the corresponding template under this repo's root before merging.
