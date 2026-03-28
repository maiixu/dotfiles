---
name: things-daily-review
description: Use when doing a daily Things 3 inbox review.
context: fork
---

Do a daily review of Things 3. Today is $ARGUMENTS (if not provided, use today's date).

## Params

- `$ARGUMENTS` — optional; today's date (YYYY-MM-DD); if not provided, auto-detect via: `date +%Y-%m-%d`

## Step 1 — Read state

```bash
bash ~/code/things-scripts/things-read.sh
```

Refer to `things-shared` for areas, routing guide, emoji conventions, and scheduling philosophy.

## Step 2 — Triage inbox

**Inbox = only items listed under `## INBOX` in the reader output.**

Process each item:
1. **Understand intent** — interpret what the item actually means
2. **Rephrase title** — rewrite into a clear action item with the correct emoji prefix
3. **Decide routing** — project (`list`), deadline, when — per scheduling philosophy in `things-shared`

## Step 3 — User confirmation

Present all proposed changes:

```
# Inbox Triage — N items

1. [原标题] → [新标题] | [Project] | when: anytime | due: YYYY-MM-DD (EOW/EOM/EOQ)
2. ...
```

Always show `due:` for every item. Write `due: none` if genuinely not applicable, with a brief reason.

> 回复格式：`1a 2s 3e:新标题` （a=accept, s=skip, e=edit 并跟新标题）
> 不回复的默认 accept。直接回复 `a` 表示全部 accept。

Wait for user reply, parse it, apply edits.

## Step 4 — Execute

Per writing protocol in `things-shared`. Skip items where action == "skip".

## Step 5 — Report

Summary of what was done. Note any items left in inbox intentionally.
