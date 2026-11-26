# Mobile SDK Consumer Skills

Agent skills for autonomous coding agents that build apps with the Salesforce Mobile SDK. The skills synced to <https://github.com/forcedotcom/SalesforceMobileSDK-Templates> live here; from the public repo they are installable via:

```bash
npx skills add forcedotcom/SalesforceMobileSDK-Templates
```

## Available Skills

| Skill | Description |
|---|---|
| [`ios-mobile-sdk/`](./ios-mobile-sdk/) | Integrate the Mobile SDK into iOS Swift apps: create a new app, add SDK auth, SmartStore, MobileSync, biometric auth (Face ID / Touch ID), DPoP refresh-token migration. Upgrade an existing app 12.x → 13.2.1 → 14.0. |
| [`android-mobile-sdk/`](./android-mobile-sdk/) | Integrate the Mobile SDK into Android Kotlin apps: create a new app, add SDK auth, SmartStore, MobileSync, biometric auth (fingerprint / face / iris), DPoP refresh-token migration for existing users. Upgrade an existing app 12.x → 13.2.1 → 14.0. |

## Skill Layout

Each skill follows the same shape:

```
<skill-name>/
├── SKILL.md                       # Thin router: scenarios, detection rules, invariants
└── references/
    ├── create-new-app.md          # Bootstrap a project from scratch
    ├── add-mobile-sdk.md          # Wire OAuth login into an existing project
    ├── add-biometric-auth.md      # Add biometric session locking
    ├── add-smartstore.md          # Add encrypted local DB
    ├── add-mobilesync.md          # Add cloud sync on top of SmartStore
    ├── api-reference.md           # Class/symbol map
    ├── troubleshooting.md         # Symptom → cause → fix table
    ├── upgrade-<from>-to-<to>.md  # Upgrade an existing app one major SDK version
    └── upgrade-<from>-to-<to>-*.md  # Per-upgrade API changes + troubleshooting
```

`SKILL.md` is the entry point an agent loads. Each scenario file is self-contained — the agent reads exactly one reference per task.

## Testing a Consumer Skill

Skills must build a working app end-to-end before merging. The eval suite under [`../eval/`](../eval/README.md) exercises the agent path that consumes these skills and asserts the generated project builds: run `scripts/eval.sh mobile-sdk-ios` or `scripts/eval.sh mobile-sdk-android` locally (the app build only runs locally; CI scores with the judge alone).

Per-domain evals follow the same pattern; see [`../eval/README.md`](../eval/README.md) for setup, env config, and how to add new domains.
