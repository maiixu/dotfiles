---
name: dotfiles_claude_doctor
description: Use when auditing Claude Code config, hooks, and Claude.md files, or when user wants to understand their Claude setup e2e.
context: fork
---

Full audit of the user's Claude Code setup: hooks, CLAUDE.md files, skills inventory, and an ASCII end-to-end flow diagram.

## Steps

### 1. Read settings.json

Read `~/.claude/settings.json` and report:

| Field | Value |
|-------|-------|
| model | |
| language | |
| hooks defined | (list hook event types) |

### 2. Audit hooks

For each hook in `settings.json` under `hooks.*`, report:

```
Hook type     | Matcher | Script                                      | Exists | Executable
--------------|---------|---------------------------------------------|--------|------------
SessionStart  | —       | (inline shell)                              | N/A    | N/A
PreToolUse    | Bash    | ~/.claude/hooks/block-dangerous-commands.sh | ✅     | ✅
Stop          | —       | ~/.claude/hooks/check-language.sh           | ✅     | ✅
```

For each script-based hook: `test -f <path>` and `test -x <path>` to verify existence and executability.

### 3. Audit CLAUDE.md files

Locate all CLAUDE.md files:
- `~/.claude/CLAUDE.md` (global)
- `~/code/dotfiles/claude/rules/*.md` (global rules)
- Any project-level `CLAUDE.md` files in `~/code/` (max depth 3)

For each: path, line count, one-sentence summary of what it configures.

### 4. List all skills

```bash
ls ~/.claude/skills/
```

Report: total count, all skill names, flag any that lack a `SKILL.md`.

### 5. Draw ASCII e2e diagram

Render this diagram with actual values substituted from settings.json:

```
User types message
    │
    ▼
┌──────────────────────────────────────────────────┐
│  SessionStart hooks                              │
│  • git pull dotfiles + notes (async)             │
└──────────────────────────────────────────────────┘
    │
    ▼
┌──────────────────────────────────────────────────┐
│  CLAUDE.md context injected                      │
│  • ~/.claude/CLAUDE.md          (global rules)   │
│  • ~/code/dotfiles/claude/rules/*.md             │
│  • <project>/CLAUDE.md          (project rules)  │
│  • ~/.claude/projects/*/memory/MEMORY.md         │
└──────────────────────────────────────────────────┘
    │
    ▼
┌──────────────────────────────────────────────────┐
│  Claude processes request                        │
│  model: <model>   language: <language>           │
│  Skills lazy-loaded via /skill-name              │
└──────────────────────────────────────────────────┘
    │
    ▼  ← Claude decides to call a tool
┌──────────────────────────────────────────────────┐
│  PreToolUse hooks                                │
│  • Bash matcher → block-dangerous-commands.sh    │
│    exit 2 = block + stderr fed back to Claude    │
└──────────────────────────────────────────────────┘
    │
    ▼
┌──────────────────────────────────────────────────┐
│  Tool executes                                   │
│  Bash / Read / Edit / Write / Glob / Grep / ...  │
└──────────────────────────────────────────────────┘
    │
    ▼
┌──────────────────────────────────────────────────┐
│  PostToolUse hooks                               │
│  • (none configured)                             │
└──────────────────────────────────────────────────┘
    │
    ▼
┌──────────────────────────────────────────────────┐
│  Claude formulates reply                         │
└──────────────────────────────────────────────────┘
    │
    ▼
┌──────────────────────────────────────────────────┐
│  Stop hooks                                      │
│  • check-language.sh                             │
│    detects Korean/Japanese → exit 2 →            │
│    Claude re-answers in Chinese immediately      │
└──────────────────────────────────────────────────┘
    │
    ▼
Output displayed to user
```

### 6. Summary

Print:
- Hooks: N total (N script-based, N inline)
- Missing/non-executable scripts: list or "none"
- CLAUDE.md files: N found
- Skills: N total
- Overall health: **HEALTHY** / **WARN** (list issues if any)
