---
name: things-daily-review
description: Daily review of Things 3 inbox and schedule. Triages inbox items into correct projects with proper deadlines, then executes after user confirmation.
disable-model-invocation: true
context: fork
agent: things
---

Do a daily review of Things 3. Today is $ARGUMENTS (if not provided, use today's date).

## Step 1 — Read state

1. Read `~/.claude/agent-memory/things/MEMORY.md` (routing guide, areas, tags)
2. Run `bash ~/code/things-scripts/things-read.sh`

## Step 2 — Triage inbox

**Inbox = only the items listed under `## INBOX` in the reader script output.**

Inbox items are often raw drafts — do NOT rely on existing title format to infer routing. Process each item:

1. **Understand intent**: interpret what the item actually means
2. **Rephrase title**: rewrite into a clear action item with the correct emoji prefix
3. **Decide routing**: project (`list`), deadline, when — per the scheduling philosophy in your system prompt

## Step 3 — User confirmation (batch review)

Present all proposed changes:

```
# Inbox Triage — N items

1. [原标题] → [新标题] | [Project] | when: anytime | due: YYYY-MM-DD (EOW/EOM/EOQ)
2. ...
```

Always show `due:` for every item. Write `due: none` if genuinely not applicable, with a brief reason.

Then ask:

> 回复格式：`1a 2s 3e:新标题` （a=accept, s=skip, e=edit 并跟新标题）
> 不回复的默认 accept。直接回复 `a` 表示全部 accept。

Wait for user reply, parse it, and apply edits.

## Step 4 — Execute confirmed items

```bash
echo '<JSON>' | bash ~/code/things-scripts/things-write.sh
```

Skip items where action == "skip".

## Step 5 — Report

Return summary of what was done. Note any items left in inbox intentionally.
