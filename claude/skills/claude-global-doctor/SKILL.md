---
name: claude-global-doctor
description: Audit global ~/.claude/ config health and context budget.
context: fork
---

Perform a health check on the **global** `~/.claude/` configuration. Read each relevant file and report findings with ✅ OK / ⚠️ Warning / ❌ Error.

---

## Layer 1 — Global Context

**`~/.claude/CLAUDE.md`**:
- Exists?
- Token estimate (rough: characters ÷ 4). Warn if > 1500 tokens — this loads every session for every project. Anthropic's own CLAUDE.md is ~2.5K; aim tighter for personal configs.
- Has `## Compact Instructions` section? Without it, architecture decisions get silently dropped on context compression.
- Is content actionable (commands, routing rules, NEVER lists, incident notes) rather than fluffy prose ("write high quality code")?
- Any outdated references: paths that don't exist, tools not installed, project names that changed?
- Does it contain project-specific details that should live in a project-level CLAUDE.md instead?

**`~/.claude/rules/`**:
- Exists? List files. Are they scoped by language or path? Warn if rules are global catch-alls.
- Warn on empty files.

---

## Layer 2 — Global Skills

Check `~/.claude/skills/`:

For each skill:
- `SKILL.md` exists?
- `description:` token count. Target ≤ 9 tokens. Warn if > 15 — every descriptor is a constant tax on every session.
- Trigger-oriented description ("Use when X") not capability-oriented ("This skill does Y")?
- Single-concern? Flag skills covering multiple unrelated workflows.
- Skills with side effects: `disable-model-invocation: true` present?
- Referenced supporting files exist on disk?
- Skills that haven't been updated in > 90 days but reference active tools/workflows: note for review.

**For groups of related skills (≥ 2 skills targeting the same tool or service):**
- **Shared context pattern**: Is there a shared agent or shared SKILL.md documenting auth, paths, and global conventions for the group? Without it, each skill repeats setup independently — drift and inconsistency risk. Good example: GWS `gws-shared/SKILL.md` is the single auth/flags/security source referenced by all 37 service skills. Bad: each skill re-explains `$THINGS_TOKEN` or vault path differently.
- **Service vs. recipe split**: Are capability skills ("what commands/APIs exist") separate from workflow skills ("step-by-step procedure to accomplish a goal")? Flag skills that mix API enumeration with multi-step task scripts — they should be split. Recipe skills should list their service skill prerequisites explicitly.
- **Hardcoded user-specifics**: Scan skill bodies for hardcoded dates (e.g., `2026-03-14`), absolute user paths (`/Users/<name>/...`), or env-specific values that belong in a shared context file, not hardcoded in each skill.
- **Input validation at write boundaries**: Skills that write files, pass user-provided arguments to shell commands, or call external APIs — is there a note about validating inputs at the boundary? (path traversal, shell injection, untrusted user content) Write side effects without validation guidance are a silent risk.
- **Cross-skill dependency links**: When a skill depends on another skill or shared context, is the dependency explicitly referenced (e.g., relative path link, "requires X to be loaded")? Implicit dependencies cause silent failures when skills are used in isolation.

**Skill description budget**: All descriptions share ~4000 tokens in main context (~2% of 200K window). This is the true constant tax — bodies are lazy-loaded per invocation and slide out on compaction. Calculate: total descriptions across all loaded skills. Warn if > 3K; flag if > 4K. This budget is shared with plugin skills (e.g., ralph-skills).

**Pattern selection — verify each skill group is using the right pattern:**
- **`context: fork`**: Skills that scan many files, make batch API calls, or receive large responses should use `context: fork` in frontmatter. Without it, a single high-bloat invocation pollutes main context for the rest of the session.
- **Router-Recipes pattern**: If ≥ 3 skills target the same tool AND the tool lacks runtime self-description (no `--help`, no schema introspection command), flag as candidate for Pattern 2 — a lightweight router skill + a dense recipes skill with `context: fork`. The recipes body is a disposable reference library that never persists in main context.
- **Skill vs. Subagent**: Is an agent handling low-context-bloat work (send one message, create one task, write one file)? Subagent cold start (load system prompt + receive delegation + optional `skills:` full injection + generate summary) costs more than a skill body temporarily entering main context. Low-bloat operations belong as skills, not agents.

---

## Layer 3 — Global Tools & MCP

Check `~/.claude/settings.json`:

**MCP servers**:
List each enabled MCP server. For each, estimate token overhead:
- Small server (≤ 10 tools): ~2K tokens
- Medium server (10–25 tools): ~4–6K tokens
- Large server (25+ tools): ~6–10K tokens

Show **context budget breakdown**:
```
System prompt:        ~2K  (fixed)
Tool definitions:     ~2K  (built-ins)
Global CLAUDE.md:     ~XK
Global skills descs:  ~XK
MCP servers total:    ~XK  ← often the biggest surprise
Rules:                ~XK
─────────────────────────
Constant overhead:    ~XK / 200K = X%
Available for work:   ~XK
```
Warn if constant overhead > 15% (30K tokens). Flag if > 25% (50K tokens) — critical.

**`allowedTools` / `disallowedTools`**:
- Configured? Restricting scope is good practice.
- Scan for dangerous patterns in any `allowedTools` list: `rm -rf`, `sudo rm`, `chmod 777`, `dd if=`, `mkfs`, `:(){ :|:& };:`, `truncate`. Flag any.

**`skipDangerousModePermissionPrompt: true`**:
- Present? Warn that this should only be set if strong PreToolUse hook guards are in place. Check hooks layer for coverage.

---

## Layer 4 — Global Hooks

Check `hooks` in `~/.claude/settings.json`:

- List all hook points and their commands.
- For each: does the script/binary exist on disk?
- Output truncated (`| head -N`)? Unbounded hook output pollutes context.
- `SessionStart` hook injecting dynamic context (git branch, env info)? Good practice — note it. Verify it doesn't inject timestamps into the system prompt position (breaks prompt caching).
- `PreToolUse` on `Bash` blocking dangerous commands? Verify the block list is comprehensive.
- Hook doing complex reasoning? That belongs in a Skill, not a hook.

**Prompt caching health**:
- Does any hook or CLAUDE.md inject `{{timestamp}}`, current date, or random IDs into system-prompt-position content? This invalidates the cache on every request — expensive.
- Are tool definitions stable (not reordered dynamically)? Dynamic ordering destroys cache prefix.

---

## Layer 5 — Global Agents

Check `~/.claude/agents/`:

For each agent:
- Explicit `tools` or `disallowedTools`? Full-access inheritance defeats isolation.
- `model` specified? Exploration agents should use Haiku/Sonnet to save cost.
- `maxTurns` set? Unbounded background agents can spiral.
- Is the agent's trigger description specific enough to avoid false invocations?
- `skills:` field in frontmatter? Unlike main-session skills (lazy-loaded on invocation), skills listed in an agent's `skills:` field are **fully injected** into the agent's context at cold start — not lazy-loaded. Sum the body sizes of all listed skills; that's fixed overhead on every agent invocation. Flag if total body > 5K tokens.
- Is the agent justified by context bloat? Agents are the right pattern when operations produce large intermediate context (scanning many files, batch API calls, multi-step reasoning with large outputs). For low-bloat operations (one write, one API call, one file), a skill in main context is cheaper — cold start overhead exceeds the skill body cost.

---

## Layer 6 — Settings Safety

Check `~/.claude/settings.json` holistically:

- `skipDangerousModePermissionPrompt: true` without a comprehensive PreToolUse block hook? ❌ High risk.
- `voiceEnabled` or experimental flags enabled? Note for awareness.
- Any enabled plugins? List them and note their token/permission footprint.
- Global `env` injecting secrets into every session? Warn — prefer `.env.local` at project level.

---

## Anti-Pattern Checklist (global scope)

| Anti-pattern | Signal |
|---|---|
| Global CLAUDE.md as project notebook | Contains project-specific paths, team notes, or task lists |
| Skill descriptor bloat | Total skill descriptor overhead > 5K tokens |
| MCP overload | > 3 MCP servers enabled globally; > 15% context overhead |
| Cache-busting dynamic content | Timestamps/random values in system-prompt-position hooks |
| Hooks without guards | `skipDangerousModePermissionPrompt` but no PreToolUse block hook |
| Stale skills | Skills referencing removed tools or outdated workflows |
| Global rules that duplicate project rules | Same constraint appears in both ~/.claude/rules/ and project .claude/rules/ |
| No shared context for tooling groups | ≥ 2 skills for same tool each document auth/paths independently — drift risk |
| Hardcoded user-specifics in skills | Dates, absolute user paths, or env-specific values in SKILL.md body instead of shared context |
| Service/recipe conflation | Same skill enumerates API surface AND contains step-by-step workflow scripts |
| Subagent for low-bloat ops | Agent handles single-output operations — cold start overhead exceeds skill body cost; use skill instead |
| Missing `context: fork` | Skill does batch/scan/large-response work without `context: fork` — pollutes main context for the session |
| Agent `skills:` body bloat | Agent lists many skills in `skills:` field — fully injected at cold start, not lazy-loaded like main-session skills |

---

## Summary

### Context budget: [X tokens constant / Y% of 200K used before any work starts]

### Overall health: [Healthy / Needs attention / Critical issues]

### Fix now
Numbered list of ❌ errors only.

### Fix soon
Numbered list of ⚠️ warnings, ordered by impact.

### Working well
2–3 ✅ highlights.

### Suggested next step
Run `/claude-project-doctor` to check the current project's `.claude/` configuration.
