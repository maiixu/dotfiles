---
name: claude-project-doctor
description: Audit current project .claude/ config health.
context: fork
---

Perform a health check on the **current project's** `.claude/` configuration using the six-layer framework. Read each relevant file and report findings with ✅ OK / ⚠️ Warning / ❌ Error. After all checks, call `/global-doctor` and ask whether to run it too.

---

## Layer 1 — Project Context

**Project CLAUDE.md** (look for `CLAUDE.md` in cwd, then parent dirs up to git root):
- Exists?
- Token estimate. Warn if > 2000 tokens. Flag if it reads like a wiki/knowledge base rather than a contract (long prose, API docs, background history).
- Has build / test / lint / run commands? (The single most important thing to put here.)
- Has architecture boundary section (which dirs own what, what must not cross)?
- Has `## NEVER` list?
- Has `## Verification` or definition-of-done section with actual commands?
- Has `## Compact Instructions` that specifies what to preserve on compression? Without this, architecture decisions get silently dropped.
- Any references to paths, tools, or env vars that no longer exist?

**Rules** (`.claude/rules/`):
- Exists? If not: note that path/language-specific rules belong here, not in the root CLAUDE.md.
- If exists: list files. Are they scoped (e.g. `python.md`, `src-api.md`) rather than repeating global constraints? Warn on empty files.

---

## Layer 2 — Project Skills

Check `.claude/skills/`:

For each skill:
- `SKILL.md` exists?
- `description:` token count. Target ≤ 9 tokens. Warn if > 15 — every descriptor loads every session.
- Does the description say "Use when X" (trigger-oriented) rather than "This skill does Y" (capability-oriented)?
- Clear stop condition and output format defined?
- Skills with side effects (writes, deploys, migrations, API calls): has `disable-model-invocation: true`?
- Referenced supporting files actually exist on disk?
- Single-concern? Flag skills that mash together review + deploy + debug + docs.
- Supporting files unreasonably large (> 500 lines)? Those should be further split.

**Skill description budget**: All descriptions share ~4000 tokens in main context. Bodies are lazy-loaded per invocation and slide out on compaction — the constant tax is descriptions only. Warn if total descriptions across all loaded skills > 3K tokens; flag if > 4K.

**Pattern selection — verify each skill group is using the right pattern:**
- **`context: fork`**: Skills that scan files, make batch API calls, or receive large responses should use `context: fork`. Without it, a single high-bloat invocation pollutes main context for the rest of the session.
- **Router-Recipes pattern**: ≥ 3 skills for the same tool AND the tool lacks runtime self-description? Candidate for Pattern 2 — lightweight router + dense `context: fork` recipes skill. The recipes body is a disposable reference library.
- **Skill vs. Subagent**: Agent doing low-context-bloat work (single write, single API call)? Cold start overhead exceeds skill body cost for low-bloat ops. Use a skill.

**For groups of related skills (≥ 2 skills targeting the same tool or service):**
- **Shared context pattern**: Is there a shared agent or shared SKILL.md documenting auth, paths, and global conventions for the group? Without it, each skill repeats setup independently — drift risk. Good example: GWS `gws-shared/SKILL.md` referenced by all 37 service skills. Bad: each skill re-explains auth tokens or base paths differently.
- **Service vs. recipe split**: Are capability skills ("what commands exist") separate from workflow skills ("step-by-step task procedure")? Flag skills that mix API documentation with multi-step task scripts. Recipe skills should explicitly list the service skill prerequisites they depend on.
- **Hardcoded user-specifics**: Scan skill bodies for hardcoded dates (e.g., `2026-03-14`), absolute user paths (`/Users/<name>/...`), or env-specific values. These belong in a shared context file, not hardcoded in each skill.
- **Input validation at write boundaries**: Skills that write files, pass user-provided arguments to shell commands, or call external APIs — is there a note about validating inputs at the boundary? (path traversal, shell injection) Write side effects without validation guidance are a silent risk.
- **Cross-skill dependency links**: When a skill depends on another, is that dependency explicitly referenced? Implicit dependencies ("assumes X is already set up") cause silent failures when skills are used in isolation.

---

## Layer 3 — Project Tools & MCP

Check `.claude/settings.json` if present:

- List MCP servers enabled at project level. For each: estimate token overhead (20–30 tools × ~200 tokens ≈ 4–6K per server). Show running total.
- `allowedTools` configured? Check for dangerous patterns: `rm -rf`, `sudo`, `chmod 777`, `dd`, `mkfs`, `:(){:|:&};:`. Flag any. Note: `skipDangerousModePermissionPrompt: true` without strong hook guards is a risk.
- Any MCP servers that duplicate global ones? Flag redundancy.

---

## Layer 4 — Project Hooks

Check `hooks` in `.claude/settings.json`:

- List hook points (PreToolUse, PostToolUse, SessionStart, etc.).
- For each hook command: does the script/binary actually exist?
- Output truncated (e.g. `| head -30`)? Warn if unbounded — hook output pollutes context.
- Hook doing simple deterministic work (format, lint, block)? Flag if it seems to be doing reasoning — that belongs in a Skill.
- No `PostToolUse` on Edit that runs lint/typecheck? Note as missed opportunity for fast feedback loop.

---

## Layer 5 — Verification

- CLAUDE.md has explicit verification commands with pass/fail criteria?
- Any Skill has a Verification section with runnable commands?
- Are contract tests, smoke tests, or screenshot checks referenced?

Flag if: tasks are described without any verifiable completion criterion. ("Claude thinks it's done" is not a verifier.)

---

## Layer 6 — Subagents & Isolation

Check `.claude/agents/`:

- List agents. For each:
  - Explicit `tools` or `disallowedTools`? Flag full-access inheritance.
  - `model` specified? (Exploration → Haiku/Sonnet; critical review → Opus.)
  - `maxTurns` set? Unbounded agents can drift.
  - `isolation: worktree` used for file-modifying agents?
  - `skills:` field present? Skills listed here are **fully injected** at cold start (not lazy-loaded). Sum body sizes — flag if > 5K tokens total.
  - Is the agent justified by context bloat? Low-bloat ops (one write, one API call) belong as skills — cold start overhead exceeds the body cost.

---

## Anti-Pattern Checklist

Check for these eight anti-patterns from the six-layer framework:

| Anti-pattern | How to detect |
|---|---|
| CLAUDE.md as wiki | > 2000 tokens OR contains long prose / API docs |
| Skill 大杂烩 | Skill covers > 2 unrelated workflows, or description is vague |
| Tool namespace pollution | MCP tools without clear `resource_action` naming |
| No verification loop | CLAUDE.md has no verifier / definition-of-done |
| Over-autonomous agents | Agents with full tool access and no maxTurns |
| No context segmentation | All research/impl/review expected in one session with no Subagent guidance |
| Allowed commands too broad | Dangerous patterns in allowedTools (see Layer 3) |
| Static rules never reviewed | CLAUDE.md last-modified date > 90 days with active project activity |
| No shared context for tooling groups | ≥ 2 skills for same tool each document auth/paths independently — drift risk |
| Hardcoded user-specifics in skills | Dates, absolute user paths, or env-specific values in SKILL.md body |
| Service/recipe conflation | Same skill enumerates API surface AND contains step-by-step workflow scripts |
| Subagent for low-bloat ops | Agent handles single-output operations — cold start exceeds skill body cost; use skill instead |
| Missing `context: fork` | Skill does batch/scan/large-response work without `context: fork` — pollutes main context |
| Agent `skills:` body bloat | Agent lists many skills in `skills:` field — fully injected at cold start, not lazy-loaded |

---

## Summary

### Context cost snapshot (project-level additions)
Show: MCP overhead + skill descriptor overhead + rules size = estimated constant tokens added by this project.

### Overall health: [Healthy / Needs attention / Critical issues]

### Fix now
Numbered list of ❌ errors only.

### Fix soon
Numbered list of ⚠️ warnings, ordered by impact.

### Working well
2–3 ✅ highlights.

### Suggested next step
If significant global config issues are likely, suggest running `/claude-global-doctor`.
