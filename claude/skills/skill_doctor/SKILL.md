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

**For skill groups (≥ 2 skills targeting the same tool):**

| # | Check | Severity |
|---|-------|----------|
| 10 | Shared context skill exists documenting auth, paths, and conventions for the group | WARN |
| 11 | Service/recipe split: capability skills separate from step-by-step workflow scripts | WARN |
| 12 | Cross-skill dependencies explicitly referenced — no implicit "assumes X is set up" | WARN |

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

## Known baseline (last audited 2026-03-21)

| Skill | desc tokens | trigger | fork | Issues |
|-------|-------------|---------|------|--------|
| `obsidian-new-note` | ❌ ~29 tok | ⚠️ capability | — (agent:) | 2, 3, 5 (no Params for $ARGUMENTS), 8 (verify agent-memory ref) |
| `obsidian-people-note` | ❌ ~27 tok | ⚠️ mixed | — (agent:) | 2, 3, 5 (no Params for $ARGUMENTS), 9 (hardcoded `/Users/maixu/notes/`) |
| `things-daily-review` | ❌ ~22 tok | ⚠️ capability | ✅ | 2, 3, 5 (no Params for $ARGUMENTS date), 8 (verify script refs) |
| `things-read` | ❌ ~22 tok | ⚠️ capability | ⚠️ missing | 2, 3, 5 (--full undocumented), 6, 8 (verify script ref) |
| `claude-project-doctor` | ✅ 7 tok | ⚠️ capability | ✅ | 3 |
| `create-skill` | ⚠️ 13 tok | ✅ trigger | ⚠️ missing | 2, 5 ($ARGUMENTS undocumented), 6 |
| `gws-chat-send` | ✅ 8 tok | ⚠️ capability | — (low bloat) | 3, 7 (write cmd, no disable-model-invocation) |
| `gws-chat` | ✅ 7 tok | ⚠️ capability | — (ref skill) | 3, 4 (spans all Chat resources) |
| `gws-shared` | ⚠️ 11 tok | ⚠️ capability | — (ref skill) | 2, 3 (shared ref — trigger format N/A) |
| `ec2-shared` | ⚠️ 13 tok | ⚠️ capability | — (ref skill) | 2, 3, 9 (hardcoded IP may change on instance restart) |
| `ec2-imessage-bot` | ❌ 16 tok | ⚠️ capability | — (low bloat) | 2, 3, 9 (hardcoded EC2 paths) |

<!-- Last full audit: 2026-03-21. New checks added since prior format: 1 (name field), 5 (Params section with auto-detect). -->
