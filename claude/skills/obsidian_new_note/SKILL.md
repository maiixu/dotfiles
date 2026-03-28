---
name: obsidian_new_note
description: Use when creating a new Obsidian inbox note from conversation or given content.
---

deps:    obsidian_shared

params:
  title   required   $ARGUMENTS | infer
  body    optional   $ARGUMENTS | infer
  tags    required   $ARGUMENTS | infer

```
parent extracts title + body + tags from conversation
              ↓ $ARGUMENTS (or inferred)
        decide: title, body, tags
              ↓
        preview → confirm
              ↓
        new_note.sh "title" "body" "tags"
              ↓
        new_note.sh git commit + push
```

## Step 1 — Decide content

From `$ARGUMENTS` or conversation context, determine:
- **Title**: short, descriptive
- **Body**: concise standalone note — not a chat transcript. OK to leave empty.
- **Tags**: one or more relevant subject tag (see `obsidian_shared`); `#Meta--元数据/Source--来源/Claude-Code` is added by the script automatically.

## Step 2 — Preview and confirm

Show:
````
**Title:** {title}
**Body:**
{body}
**Tags:** {tags}
````

> 确认保存？回复 `y` 直接保存，或告诉我需要修改的地方。

Wait for confirmation. Apply edits if requested, repeat until confirmed.

## Step 3 — Run script

```bash
~/code/dotfiles/claude/skills/obsidian_new_note/new_note.sh "{title}" "{body}" "{tags}"
```
