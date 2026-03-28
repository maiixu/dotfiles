---
name: obsidian_new
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
   obvious? → preview → y/n confirm
   ambiguous? → numbered options → wait → preview → confirm
              ↓
        new.sh "title" "body" "tags"
              ↓
        git commit + push
```

## Step 1 — Decide content

From `$ARGUMENTS` or conversation context, determine:
- **Title**: short, descriptive
- **Body**: concise standalone note — not a chat transcript. OK to leave empty.
- **Tags**: one or more relevant subject tag (see `obsidian_shared`); `#Meta--元数据/Source--来源/Claude-Code` is added by the script automatically.

If any of these are ambiguous, ask via AskUserQuestion with numbered options before proceeding. One question at a time.

Example (ambiguous title):
> 标题不确定，选一个：
> 1. Claude Code Skill 设计规范
> 2. Obsidian Skill 写法约定
> 3. 自定义 →

## Step 2 — Preview and confirm

Show via AskUserQuestion:
````
**Title:** {title}
**Body:**
{body}
**Tags:** {tags}
````

> 确认保存？`y` 直接保存，或告诉我需要修改的地方。

Wait for confirmation. Apply edits if requested, repeat until confirmed.

## Step 3 — Run script

```bash
~/code/dotfiles/claude/skills/obsidian_new/new.sh "{title}" "{body}" "{tags}"
```
