---
name: dotfiles_skill_creator
description: Use when creating a skill or agent.
context: fork
---

Guide for creating a new skill or agent under `~/.claude/skills/` or `~/.claude/agents/`. Run `/skill_doctor` after creation to validate.

## Params

- `$ARGUMENTS` — optional; description of the skill/agent to create; if not provided, ask the user what they want to build

## Skill vs Agent

| | Skill | Agent |
|--|-------|-------|
| Context | Runs in main session | Runs in isolated sub-context |
| Use when | Low–medium context bloat | High bloat: batch scans, large API responses, multi-step reasoning |
| Cold start | None | ~500–1K token overhead per invocation |
| Example | `gws_chat_send`, `skill_creator` | external API orchestrator with large intermediate state |

Use a skill unless the operation produces enough intermediate context to pollute the main session.

## Patterns

| Pattern | When | Structure |
|---------|------|-----------|
| 1 — Flat skills | Tool has runtime self-description (`--help`, schema), or reference material is small | One `SKILL.md` per capability; add `context: fork` for high-bloat ops |
| 2 — Router + recipes | Tool lacks self-description AND reference material is large | Lightweight router skill + dense `context: fork` recipes skill |
| 3 — Custom agent | Cross-tool orchestration with high intermediate bloat | Agent in `~/.claude/agents/`; supporting atomics as Pattern 1 skills |

Low-bloat cross-tool orchestration stays as a recipe skill (Pattern 1) — don't create an agent just because multiple tools are involved.

## File layout

```
~/.claude/skills/<name>/
  SKILL.md        ← required
  scripts/        ← optional: shell scripts, Python helpers

~/.claude/agents/<name>.md   ← Pattern 3 only
```

Naming: underscore_case. Group shared context as `<tool>_shared/`.

## Frontmatter template

```yaml
---
name: <name>           # matches directory name
description: Use when <trigger condition>.   # ≤ 9 tokens
context: fork          # add if high-bloat
agent: <name>          # add if skill routes to a specific agent
disable-model-invocation: true   # add if pure shell, no LLM needed
---
```

**Description rules:**
- ≤ 9 tokens — loaded into every session's skill list, constant context tax
- States *when to use* the skill, not *what params it takes*
- Params live in the body (only loaded on invocation)

## Body template

```markdown
<One sentence expanding on what this skill does.>

## Params

- `param_a` — required; if not provided, auto-detect via: `<command>`
- `param_b` — default: <value>; use <other value> for <condition>

## Steps

1. ...
2. ...
```

**Param rules:**
- Document every input the skill accepts
- For each required param, specify the auto-detect fallback for manual invocation
- Default values must cover the common manual invocation case

## Shared context pattern

For ≥ 2 skills targeting the same tool: create `<tool>_shared/SKILL.md` first. It owns auth, global flags, paths, and security rules. Service skills reference it with:

```markdown
> **PREREQUISITE:** Read `../<tool>_shared/SKILL.md` for auth, global flags, and security rules.
```

## Agent frontmatter reference

| Field | When to use |
|-------|-------------|
| `tools` | Always — restrict to minimum required |
| `model` | Always — Haiku for low-stakes; Sonnet for reasoning-heavy |
| `maxTurns` | Always — set a reasonable bound (10–20 typical) |
| `permissionMode` | `acceptEdits` only if agent writes files and scope is trusted |
| `skills` | Avoid unless necessary — listed skills are **fully injected at cold start**, not lazy-loaded |

## Preview and confirm

Before writing files, show the user:
- Recommended pattern + one sentence of reasoning
- File path(s) to be created
- Full content of each file

Ask:
> 确认创建？回复 `y` 直接写入，或告诉我需要修改的地方。

Wait for confirmation. Apply edits if requested, re-show, repeat until confirmed.

## After creation

1. Run `/skill_doctor` to validate against all checks
2. Update `skill_doctor/SKILL.md` baseline table with the new skill
3. If a shared skill was created: list existing skills that should add a prerequisite link to it
4. If a new agent was created: confirm `tools`, `model`, and `maxTurns` are set
