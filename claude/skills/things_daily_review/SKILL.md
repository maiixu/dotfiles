---
name: things_daily_review
description: Use when doing a daily Things 3 inbox review.
context: fork
---

Do a daily review of Things 3. Today is $ARGUMENTS (if not provided, use today's date).

## Params

- `$ARGUMENTS` — optional; today's date (YYYY-MM-DD); if not provided, auto-detect via: `date +%Y-%m-%d`

## Scheduling Philosophy

**Week structure: Saturday → Friday**
- EOW (end of week) = the coming Friday

**Standard deadline anchors — always use the Friday of that period:**
- End of week → this Friday
- End of month → last Friday of the month
- End of quarter → last Friday of the quarter
- End of year → last Friday of December

Exception: real hard dates (credit card renewal, tax deadlines, event dates) use the actual date, not the Friday.

**Weekend-only tasks:** tasks requiring a large time block (errands, deep-focus) get the **Sunday** of the target week, not Friday.

**`when` vs `deadline` — critical distinction:**
- `when` = when the task *appears* in the timeline (schedule start). Use `anytime` for almost everything.
- `deadline` = completion due date (shown in red). Use for EOW/EOM/EOQ/EOY anchors and hard deadlines.
- **NEVER use `when` for Friday anchors** — always use `deadline` instead.

**Valid `when` values:** `today`, `tomorrow`, `evening`, `anytime`, `someday`, `yyyy-mm-dd`
**Valid `deadline` values:** `yyyy-mm-dd`

**Deadline is required for almost every task.** Default to EOW unless the task clearly has a longer horizon. Only omit if genuinely open-ended with no plausible time horizon.

## Writing to Things

**Auth token** — read from env: `$THINGS_TOKEN` (set in `~/.claude/settings.local.json`)

**Single new task (no auth token needed):**
```bash
python3 -c "
import urllib.parse, subprocess
params = urllib.parse.urlencode({
    'title': 'Task title',
    'notes': 'Optional notes',
    'list': 'Inbox',
    'when': 'anytime',
    'deadline': 'YYYY-MM-DD',
    'tags': 'tag1,tag2',
})
subprocess.run(['open', f'things:///add?{params}'])
"
```

**Update existing tasks (requires auth token):**
```bash
echo '[{"id":"UUID","title":"New title","list":"Project","when":"anytime","deadline":"2026-03-14"}]' \
  | bash ~/code/things-scripts/things-write.sh
```

**`list`:** exact project or area title (copy from reader output), or `Inbox`
**`tags`:** comma-separated, must match exactly (copy from reader output)

## Step 1 — Read state

1. Read `~/.claude/agent-memory/things/MEMORY.md` (routing guide, areas, tags)
2. Run `bash ~/code/things-scripts/things-read.sh`

## Step 2 — Triage inbox

**Inbox = only the items listed under `## INBOX` in the reader script output.**

Inbox items are often raw drafts — do NOT rely on existing title format to infer routing. Process each item:

1. **Understand intent**: interpret what the item actually means
2. **Rephrase title**: rewrite into a clear action item with the correct emoji prefix
3. **Decide routing**: project (`list`), deadline, when — per the scheduling philosophy above

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
