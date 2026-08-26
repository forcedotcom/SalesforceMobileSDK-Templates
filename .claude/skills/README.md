# Mobile SDK Developer Skills (Internal)

Agent skills for **developers working on the Mobile SDK itself** (contributors, maintainers).

These are auto-loaded by Claude Code when this repo is open locally. They are **not** published through the `npx skills add` CLI — that scans [`/skills/`](../../skills/) at the repo root for consumer-facing skills only.

| Skill | Description |
|---|---|
| `remove-template/` | Remove a template from this repository |
| `test-template/` | Test templates with `test_template.sh` |
| `test-sdk-consumer-skills/` | End-to-end test harness for all SDK consumer skills |
| `update-ios-deployment-target/` | Bump the minimum iOS deployment target across all templates |

## Adding a New Internal Skill

Create a subdirectory with a `SKILL.md`:

```markdown
---
name: my-skill
description: What this skill does and when to use it
---

# My Skill
...
```

No `metadata.internal` flag is needed — placement under `.claude/skills/` is itself the signal that this skill is for SDK maintainers, not consumers.
