---
name: create-skill
description: Use when scaffolding a new skill or agent for a tool or workflow.
---

Scaffold a new skill or agent using the three-pattern methodology.

Input: `$ARGUMENTS` — tool name or workflow description. If not provided, ask.

## Step 1 — Apply the decision framework

Ask the user (or infer from context) if not obvious:

1. **Does the tool have runtime self-description?** (e.g., `--help` flag, `schema` command, structured JSON output that Claude can introspect at runtime)
2. **How much context does a single operation produce?** Low = single API call, one file write, brief response. High = scanning many files, batch API calls, large text processing, multi-step reasoning with large intermediate outputs.
3. **Does the workflow span multiple tools with high intermediate bloat?**

Then determine the pattern:

```
Tool has good self-description?
├─ Yes → Pattern 1: flat skills (default)
│         └─ Some ops produce high bloat? → add `context: fork` to those skills
└─ No  → Reference material large (hundreds of commands, complex param matrix)?
          ├─ Yes → Pattern 2: router + context:fork recipes
          └─ No  → Pattern 1, with inline reference in skill body

Cross-tool orchestration + high intermediate bloat? → Pattern 3: custom agent
Low-bloat cross-tool? → Recipe skill (still Pattern 1, runs in main session)
```

Present the recommended pattern with one sentence of reasoning before generating files.

---

## Step 2 — Determine file location

**Pattern 1 (flat skills):**
- Shared context: `~/.claude/skills/{tool}-shared/SKILL.md` — create first if ≥ 2 skills for this tool
- Service skill: `~/.claude/skills/{tool}-{service}/SKILL.md`
- Recipe skill: `~/.claude/skills/{tool}-{workflow}/SKILL.md`
- Global (`~/.claude/skills/`) for personal tools; project (`.claude/skills/`) for repo-specific tools

**Pattern 2 (router + recipes):**
- Router: `~/.claude/skills/{tool}-router/SKILL.md`
- Recipes: `~/.claude/skills/{tool}-recipes/SKILL.md`

**Pattern 3 (custom agent):**
- Agent: `~/.claude/agents/{workflow}.md`
- Any atomic supporting skills → Pattern 1 above

---

## Step 3 — Generate scaffold

### SKILL.md frontmatter reference

| Field | When to use |
|---|---|
| `name` | Always — matches directory name |
| `description` | Always — ≤ 9 tokens, trigger-oriented: "Use when X" |
| `context: fork` | High-bloat skills (batch ops, large responses, file scanning) |
| `agent: {name}` | Skill should run within a specific agent's context |
| `disable-model-invocation: true` | Skill body is pure bash — no LLM reasoning needed |

### Agent frontmatter reference

| Field | When to use |
|---|---|
| `tools` | Always — restrict to minimum required |
| `model` | Always — `claude-haiku-4-5-20251001` for low-stakes; Sonnet for reasoning-heavy |
| `maxTurns` | Always — set a reasonable bound (10–20 typical) |
| `permissionMode` | `acceptEdits` only if agent writes files and you trust its scope |
| `skills` | Avoid unless necessary — listed skills are **fully injected at cold start**, not lazy-loaded |

### Content structure: service skill (Pattern 1)

```markdown
---
name: {tool}-{service}
description: Use when {trigger condition}.
---

> **PREREQUISITE:** Read `{tool}-shared/SKILL.md` for auth, global flags, and conventions.

# {service} — {brief scope note}

## {resource type}

- `{command} {resource} {method}` — brief description
- ...

## Discovery

```bash
{tool} {service} --help
{tool} schema {service}.{resource}.{method}
```
```

### Content structure: recipe skill (Pattern 1)

```markdown
---
name: {tool}-{workflow}
description: Use when {trigger condition}.
---

> **Dependencies:** `{tool}-shared` (auth), `{tool}-{service-a}` (service), `{tool}-{service-b}` (service)

## Step 1 — {action}

```bash
{command with example values, using PLACEHOLDER for user-provided args}
```

## Step 2 — ...
```

### Content structure: router + recipes (Pattern 2)

Router (`context: inherit`, lightweight ~100 lines):
```markdown
---
name: {tool}-router
description: Use when {trigger condition}.
context: inherit
---

Extract intent from the conversation and invoke the appropriate recipe.

Allowed tools: Skill, Read, Bash

...dispatch logic...
```

Recipes (`context: fork`, dense reference):
```markdown
---
name: {tool}-recipes
description: {tool} reference library — invoked by {tool}-router only.
context: fork
---

> This skill is a reference library. It is invoked by {tool}-router with structured parameters and returns a result. The body is disposed after each invocation.

## {category}

...dense reference...
```

---

## Step 4 — Preview and confirm

Show the user:
- Recommended pattern + reasoning (one sentence)
- File path(s) to be created
- Full content of each file

Ask:
> 确认创建？回复 `y` 直接写入，或告诉我需要修改的地方。

Wait for confirmation. Apply edits if requested, then re-show. Repeat until confirmed.

## Step 5 — Write files

Write confirmed files to disk. Then note:
- If a shared skill was created: list existing skills that should add a prerequisite link to it
- If a new agent was created: confirm `tools`, `model`, and `maxTurns` are set
- Run `/claude-global-doctor` if the new skill affects the description budget significantly
