# Mobile SDK Consumer Skills

Agent skills for autonomous coding agents that build apps with the Salesforce Mobile SDK. The skills synced to <https://github.com/forcedotcom/SalesforceMobileSDK-Templates> live here; from the public repo they are installable via:

```bash
npx skills add forcedotcom/SalesforceMobileSDK-Templates
```

## Available Skills

| Skill | Description |
|---|---|
| [`ios-mobile-sdk/`](./ios-mobile-sdk/) | Integrate the Mobile SDK into iOS Swift apps: create a new app, add SDK auth, SmartStore, MobileSync, biometric auth (Face ID / Touch ID). |
| [`android-mobile-sdk/`](./android-mobile-sdk/) | Integrate the Mobile SDK into Android Kotlin apps: create a new app, add SDK auth, SmartStore, MobileSync, biometric auth (fingerprint / face / iris). |

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
    └── troubleshooting.md         # Symptom → cause → fix table
```

`SKILL.md` is the entry point an agent loads. Each scenario file is self-contained — the agent reads exactly one reference per task.

## Testing a Consumer Skill

Skills must build a working app end-to-end before merging. The eval suite under [`../skills-eval/`](../skills-eval/README.md) is the merge gate: `npm run eval:ios:skill` and `npm run eval:android:skill` exercise the agent path that consumes these skills and asserts the generated project builds.

Per-domain evals follow the same pattern; see [`../skills-eval/README.md`](../skills-eval/README.md) for setup, env config, and how to add new domains.
