---
name: things-daily-review
description: Daily review of Things 3 inbox and schedule. Triages inbox items into correct projects with proper deadlines, then executes after user confirmation.
disable-model-invocation: true
context: fork
agent: things
---

Do a daily review of Things 3. Today is $ARGUMENTS (if not provided, use today's date).

## Step 1 — Read state

1. Read `~/.claude/agent-memory/things/MEMORY.md`
2. Run `bash ~/.claude/skills/things/read-things.sh`

## Step 2 — Triage inbox

**Inbox = only the items listed under `## INBOX` in the reader script output.** Do not query the DB directly or treat tasks with no project as inbox items — those are already triaged and live in Anytime/Someday intentionally.

Inbox items are often raw drafts or rough ideas — do NOT rely on the existing title format or prefix to infer routing. Process each item in this order:

1. **Understand intent**: interpret what the item actually means
2. **Rephrase title**: rewrite into a clear action item and add the correct emoji prefix (🔎 research, 💭 writing/ideas, 💰 financial, etc.)
3. **Then decide routing**:
   - **Project** (`list`): use routing guide in memory
   - **Deadline** (`deadline`): EOW = next Friday, EOM = last Friday of month, etc.
   - **When** (`when`): `anytime` for most things; `today` for 2-minute tasks or things pulled into today; a future date only if the task should be hidden until then

Serialize all decisions to `/tmp/step-through-in.json` in the format defined by `~/.claude/skills/step-through/SKILL.md`, then run:

```bash
python3 ~/.claude/skills/step-through/step-through.py \
  --input /tmp/step-through-in.json \
  --output /tmp/step-through-out.json
```

## Step 3 — Execute confirmed items

Read `/tmp/step-through-out.json`. For items where `action == "accept"`, build a single `things:///json` batch update and execute. Skip items where `action == "skip"`.

Use `os.environ['THINGS_TOKEN']` for auth.

## Step 4 — Report

Return summary of what was done. Note any items left in inbox intentionally (e.g. waiting for another agent).
