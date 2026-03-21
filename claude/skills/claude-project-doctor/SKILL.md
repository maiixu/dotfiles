---
name: claude-project-doctor
description: Use when auditing the current project's .claude/ config.
context: fork
---

Checks the current project's `.claude/` configuration across six layers. Report findings with ✅ OK / ⚠️ Warning / ❌ Error.

## Checks

### Layer 1 — CLAUDE.md

| # | Check | Severity |
|---|-------|----------|
| 1 | `CLAUDE.md` exists at project root or git root | FAIL |
| 2 | Token estimate ≤ 2000 tokens (characters ÷ 4); warn if reads like a wiki rather than a contract | WARN |
| 3 | Has build / test / lint / run commands — the single most important thing to put here | WARN |
| 4 | Has architecture boundary section (which dirs own what, what must not cross) | WARN |
| 5 | Has `## NEVER` list | WARN |
| 6 | Has `## Verification` or definition-of-done section with runnable commands | WARN |
| 7 | Has `## Compact Instructions` specifying what to preserve on compression — without this, architecture decisions get silently dropped | WARN |
| 8 | No outdated references: paths that don't exist, tools not installed, env vars that changed | WARN |

### Layer 2 — Rules

| # | Check | Severity |
|---|-------|----------|
| 9 | `.claude/rules/` exists; if not, note that path/language-specific rules belong here, not in root CLAUDE.md | WARN |
| 10 | Rules are scoped by language or path (e.g. `python.md`, `src-api.md`) — not global catch-alls repeating constraints already in CLAUDE.md | WARN |

### Layer 3 — Skills

| # | Check | Severity |
|---|-------|----------|
| 11 | Each skill has `SKILL.md` with both `name:` and `description:` fields | FAIL |
| 12 | `description:` ≤ 9 tokens (target); warn if > 15 — constant tax on every session | WARN |
| 13 | Trigger-oriented description ("Use when X"), not capability-oriented | WARN |
| 14 | Single-concern skill — not mixing review + deploy + debug + docs | WARN |
| 15 | Skills with side effects where no LLM reasoning needed — `disable-model-invocation: true` present | WARN |
| 16 | Referenced supporting files exist on disk | FAIL |
| 17 | High-bloat skills (file scans, large API responses) — `context: fork` in frontmatter | WARN |
| 18 | Skill groups (≥ 2 for same tool): shared context skill exists for auth, paths, conventions | WARN |
| 19 | Service/recipe split: capability skills separate from step-by-step workflow scripts | WARN |
| 20 | No hardcoded dates, absolute user paths (`/Users/<name>/...`), or env-specific values in body | WARN |
| 21 | Cross-skill dependencies explicitly referenced — no implicit "assumes X is set up" | WARN |

### Layer 4 — Tools & MCP

| # | Check | Severity |
|---|-------|----------|
| 22 | No dangerous patterns in `allowedTools`: `rm -rf`, `sudo`, `chmod 777`, `dd`, `mkfs`, `:(){ :|:& };:` | FAIL |
| 23 | No MCP servers that duplicate global ones — flag redundancy | WARN |
| 24 | `skipDangerousModePermissionPrompt: true` only if strong PreToolUse hook guards are in place | WARN |

### Layer 5 — Hooks

| # | Check | Severity |
|---|-------|----------|
| 25 | Each hook script/binary exists on disk | FAIL |
| 26 | Hook output is truncated (e.g. `| head -30`) — unbounded output pollutes context | WARN |
| 27 | No reasoning in hooks — complex logic belongs in a skill, not a hook | WARN |
| 28 | `PostToolUse` on Edit that runs lint/typecheck? If absent, note as missed fast-feedback opportunity | WARN |

### Layer 6 — Agents

| # | Check | Severity |
|---|-------|----------|
| 29 | Each agent has explicit `tools` or `disallowedTools` — full-access inheritance defeats isolation | WARN |
| 30 | `model` specified: Haiku/Sonnet for exploration, Opus for critical review | WARN |
| 31 | `maxTurns` set — unbounded agents can drift | WARN |
| 32 | `skills:` field: sum body sizes of all listed skills — fully injected at cold start, not lazy-loaded; flag if total > 5K tokens | WARN |
| 33 | Agent justified by context bloat — low-bloat ops (one write, one API call) belong as skills; cold start overhead exceeds skill body cost | WARN |

## Run

```bash
ls .claude/ 2>/dev/null || echo "No .claude/ found at $(pwd)"
find . -name "CLAUDE.md" -maxdepth 3 2>/dev/null
```

Read each relevant file. Apply all checks. Output a report table:

```
Layer  | # | Status | Detail
-------|---|--------|-------
1      | 3 |  WARN  | No build/test commands found
1      | 6 |  FAIL  | No Verification section
3      | 17|  WARN  | scan-logs skill reads 50+ files, missing context:fork
...
```

After the table, list all WARN/FAIL items grouped by layer with proposed fix diffs. Apply fixes upon user confirmation (or immediately if invoked with `--fix`).

## Params

- `--fix` — optional; apply all proposed fixes immediately without user confirmation

## Anti-pattern checklist

| Anti-pattern | Signal |
|---|---|
| CLAUDE.md as wiki | > 2000 tokens or contains long prose / API docs / background history |
| No verification loop | No runnable pass/fail commands in CLAUDE.md or any skill |
| Skill 大杂烩 | Skill covers > 2 unrelated workflows or has a vague description |
| Over-autonomous agents | Agent with full tool access and no `maxTurns` |
| Missing `context: fork` | Skill does batch/scan/large-response work without forking |
| Agent `skills:` bloat | Agent lists many skills — all fully injected at cold start |
| Hooks doing reasoning | Hook command invokes LLM or contains multi-step logic |
| No shared context for tool groups | ≥ 2 skills for same tool each document auth/paths independently |
| Hardcoded user-specifics | Dates, absolute paths, or env values baked into SKILL.md body |
| Static rules never reviewed | CLAUDE.md last-modified > 90 days with active project commits |

## Summary format

```
### Context cost snapshot
MCP overhead: ~XK + skill descriptors: ~XK + rules: ~XK = ~XK constant tokens added by this project

### Overall health: [Healthy / Needs attention / Critical]

### Fix now
❌ errors only, numbered.

### Fix soon
⚠️ warnings, ordered by impact.

### Working well
2–3 ✅ highlights.
```
