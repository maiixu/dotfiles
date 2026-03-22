---
name: obsidian_new_note
description: Use when saving a note to Obsidian inbox.
context: fork
---

Create a new Obsidian note in the inbox. Refer to `obsidian_shared` for vault paths, note format, tag system, and write helper.

## Params

- `$ARGUMENTS` — optional; note title; if not provided, infer from conversation context

## Step 1 — Get timestamp

```bash
date +"%Y%m%d%H%M"
```

## Step 2 — Determine title and content

- Title: use `$ARGUMENTS` if provided, otherwise infer from conversation
- Body: write a concise, standalone note — not a chat summary. OK to leave empty if no clear content yet.

## Step 3 — Choose tags

Always include `#Meta--元数据/Source--来源/Claude-Code` as the last tag. Add one relevant subject tag above it (see `obsidian_shared` for examples).

## Step 4 — Preview and confirm

Show:
````
**Filename:** {ID} {Title}.md

```
{full note content}
```
````

> 确认保存？回复 `y` 直接保存，或告诉我需要修改的地方。

Wait for confirmation. Apply edits if requested, repeat until confirmed.

## Step 5 — Save and push

Write to inbox using the write helper in `obsidian_shared`, then commit and push.
