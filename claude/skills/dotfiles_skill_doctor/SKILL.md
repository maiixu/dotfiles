---
name: dotfiles_skill_doctor
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
| 14 | Skill family role is one of: **shared** (pure reference, never directly invoked, description may be non-trigger), **router** (directly invocable + family base, body cross-references sub-skills), **action** (targeted op, references `*_shared` or router via PREREQUISITE) | WARN |

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

## Known baseline (last audited 2026-03-22, updated 2026-03-22)

| Skill | role | desc tokens | trigger | fork | naming | Remaining Issues |
|-------|------|-------------|---------|------|--------|-----------------|
| `things_shared` | shared | ✅ | N/A | N/A | ✅ | — |
| `things_read` | action | ✅ | ✅ | ✅ | ✅ | 8 (verify script ref) |
| `things_daily_review` | action | ✅ | ✅ | ✅ | ✅ | 8 (verify script refs) |
| `obsidian_shared` | shared | ✅ | N/A | N/A | ✅ | — |
| `obsidian_new_note` | action | ✅ | ✅ | ✅ | ✅ | — |
| `obsidian_people_note` | action | ✅ | ✅ | ✅ | ✅ | — |
| `gws_shared` | shared | ✅ | N/A | N/A | ✅ | — |
| `gws_chat` | router | ✅ | ✅ | — (ref skill) | ✅ | — |
| `gws_chat_send` | action | ✅ | ✅ | — (low bloat) | ✅ | 7 (write cmd, intentional) |
| `gws_calendar` | router | ✅ | ✅ | — (ref skill) | ✅ | — |
| `gws_calendar_insert` | action | ✅ | ✅ | — (low bloat) | ✅ | 7 (write cmd, intentional) |
| `gws_calendar_agenda` | action | ✅ | ✅ | — (low bloat) | ✅ | — |
| `gws_docs` | router | ✅ | ✅ | — (ref skill) | ✅ | — |
| `gws_docs_write` | action | ✅ | ✅ | — (low bloat) | ✅ | 7 (write cmd, intentional) |
| `gws_drive` | router | ✅ | ✅ | — (ref skill) | ✅ | — |
| `gws_drive_upload` | action | ✅ | ✅ | — (low bloat) | ✅ | 7 (write cmd, intentional) |
| `gws_gmail` | router | ✅ | ✅ | — (ref skill) | ✅ | — |
| `gws_people` | router | ✅ | ✅ | — (ref skill) | ✅ | — |
| `ec2_shared` | shared | ✅ | N/A | N/A | ✅ | 9 (hardcoded EC2 paths, intentional) |
| `ec2_heartbeat_hourly` | standalone | ✅ | ✅ | — (no model) | ✅ | 9 (hardcoded EC2 paths, intentional) |
| `pua` | router | ✅ | ✅ | — (behavior modifier) | ✅ | — |
| `pua_en` | standalone | ✅ | ✅ | — (behavior modifier) | ✅ | — |
| `pua_loop` | action | ✅ | ✅ | — (behavior modifier) | ✅ | — |
| `pua_p7` | action | ✅ | ✅ | — (behavior modifier) | ✅ | — |
| `pua_p9` | action | ✅ | ✅ | — (behavior modifier) | ✅ | — |
| `pua_p10` | action | ✅ | ✅ | — (behavior modifier) | ✅ | — |
| `pua_pro` | action | ✅ | ✅ | — (behavior modifier) | ✅ | — |
| `pua_yes` | action | ✅ | ✅ | — (behavior modifier) | ✅ | — |
| `gstack_office_hours` | standalone | ✅ | ✅ | ✅ | ✅ | — |
| `gstack_plan_eng_review` | standalone | ✅ | ✅ | ✅ | ✅ | — |
| `gstack_plan_design_review` | standalone | ✅ | ✅ | ✅ | ✅ | — |
| `gstack_skill_creator` | standalone | ✅ | ✅ | ✅ | ✅ | — |
| `dotfiles_skill_doctor` | standalone | ✅ | ✅ | ✅ | ✅ | — |
| `dotfiles_skill_creator` | standalone | ✅ | ✅ | ✅ | ✅ | — |
| `dotfiles_hotkey_doctor` | standalone | ✅ | ✅ | ✅ | ✅ | — |

<!-- Last full audit: 2026-03-22. things agent + agent-memory removed; things_shared + obsidian_shared added; skill renames: dotfiles_*, gstack_*, ec2_heartbeat_hourly; ec2_imessage_bot deleted; Check 14 (skill family roles) added. -->
