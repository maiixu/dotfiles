---
name: skill_doctor
description: Use when auditing ~/.claude/skills/ for health and compliance.
context: fork
---

Checks every `~/.claude/skills/*/SKILL.md` against home skill conventions. Reports issues and proposes fixes.

## Checks

For each skill file, apply all checks below. Mark each: **PASS** / **WARN** / **FAIL**.

| # | Check | Severity |
|---|-------|----------|
| 1 | Frontmatter has both `name:` and `description:` fields | FAIL |
| 2 | `description:` ≤ 9 tokens (target); warn if > 15 — constant tax on every session | WARN |
| 3 | Trigger-oriented description ("Use when X"), not capability-oriented ("This skill does Y") | WARN |
| 4 | Single-concern skill — not covering multiple unrelated workflows | WARN |
| 5 | If skill accepts inputs, body has `## Params` section with auto-detect fallback for each required param | WARN |
| 6 | High-bloat operations (batch file scans, large responses, multi-step reasoning) — `context: fork` in frontmatter | WARN |
| 7 | Write/side-effect skills where no LLM reasoning is needed — `disable-model-invocation: true` present | WARN |
| 8 | All referenced supporting files exist on disk | FAIL |
| 9 | No hardcoded dates, absolute user paths (`/Users/<name>/...`), or env-specific values in body | WARN |
| 10 | Skill directory name uses underscore_case (e.g. `skill_doctor`), not kebab-case or camelCase | WARN |

**For skill groups (≥ 2 skills targeting the same tool):**

| # | Check | Severity |
|---|-------|----------|
| 11 | Shared context skill exists documenting auth, paths, and conventions for the group | WARN |
| 12 | Service/recipe split: capability skills separate from step-by-step workflow scripts | WARN |
| 13 | Cross-skill dependencies explicitly referenced — no implicit "assumes X is set up" | WARN |

## Params

- `--fix` — optional; apply all proposed fixes immediately without user confirmation

## Run

```bash
ls ~/.claude/skills/*/SKILL.md
```

Read each file. Apply all checks. Output a report table:

```
Skill                  | Check | Status | Detail
-----------------------|-------|--------|-------
obsidian-new-note      |   2   |  FAIL  | ~29 tokens
obsidian-new-note      |   3   |  WARN  | "Create a new Obsidian note..." — capability-oriented
...
```

After the table, list all WARN/FAIL items grouped by skill with proposed fix diffs. Apply fixes upon user confirmation (or immediately if invoked with `--fix`).

## Known baseline (last audited 2026-03-21, updated 2026-03-21)

| Skill | desc tokens | trigger | fork | naming | Remaining Issues |
|-------|-------------|---------|------|--------|-----------------|
| `obsidian_new_note` | ✅ | ✅ | ✅ | ✅ | — |
| `obsidian_people_note` | ✅ | ✅ | ✅ | ✅ | — |
| `things_daily_review` | ✅ | ✅ | ✅ | ✅ | 8 (verify script refs) |
| `things_read` | ✅ | ✅ | ✅ | ✅ | 8 (verify script ref) |
| `skill_creator` | ✅ | ✅ | ✅ | ✅ | — |
| `gws_chat_send` | ✅ | ✅ | — (low bloat) | ✅ | 7 (write cmd, disable-model-invocation intentionally absent) |
| `gws_chat` | ✅ | ✅ | — (ref skill) | ✅ | — |
| `gws_shared` | ✅ | — (ref skill) | — (ref skill) | ✅ | — |
| `ec2_shared` | ✅ | — (ref skill) | — (ref skill) | ✅ | 9 (hardcoded IP, low risk) |
| `ec2_imessage_bot` | ✅ | ✅ | — (low bloat) | ✅ | 9 (hardcoded EC2 paths, intentional) |
| `hotkey_doctor` | ✅ | ✅ | ✅ | ✅ | — |
| `skill_doctor` | ✅ | ✅ | ✅ | ✅ | — |

<!-- Last full audit: 2026-03-21. claude-project-doctor deleted; agents/obsidian.md + agents/things.md deleted; all skills renamed to underscore_case; agent info merged into obsidian/things skills. -->
