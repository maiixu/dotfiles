---
name: obsidian_new_note
description: Use when saving a note to Obsidian inbox.
context: fork
---

Create a new Obsidian note for the inbox.

## Vault

- Path: `~/notes/`
- Inbox: `~/notes/收件箱 Inbox/`

## Writing Files

Use Python to write files safely (handles Unicode filenames and content):

```bash
python3 << 'PYEOF'
import pathlib
path = pathlib.Path("{FULL_PATH}")
path.write_text("""{CONTENT}""", encoding="utf-8")
print(f"Saved: {path.name}")
PYEOF
```

## Params

- `$ARGUMENTS` — optional; note title; if not provided, inferred from conversation context

## Step 1 — Get current timestamp

```bash
date +"%Y%m%d%H%M"
```

Use the output as the note ID. Never use a hardcoded or assumed timestamp.

## Step 2 — Determine title and content

- If `$ARGUMENTS` is provided, use it as the note title
- Otherwise infer the title from the current conversation context (concise, descriptive)

Draft the note body based on the current conversation. For technical notes, write a concise, standalone explanation of the key concept — not a chat summary, but a real note worth keeping. It's fine to leave the body empty if there's no clear content to capture yet.

## Step 3 — Choose tags

Always include `#Meta--元数据/Source--来源/Claude-Code` as the last tag.

Add one relevant subject tag above it based on the note's topic. Examples:
- `#Productivity--效率/Claude-Code`
- `#Productivity--效率/PKM--Personal-Knowledge-Management--个人知识管理`
- `#Tech--技术/Obsidian`

Read `~/.claude/agent-memory/obsidian/MEMORY.md` for the full tag taxonomy if needed.

## Step 4 — Compose the note

Format:

```
## {ID} {Title}

{body content}

---
{ID}

{subject tag}
#Meta--元数据/Source--来源/Claude-Code

```

Note: the file ends with a space on the last line (after the final tag).

Filename: `{ID} {Title}.md`

## Step 5 — Preview and confirm

Show the user:

````
**Filename:** {ID} {Title}.md

```
{full note content}
```
````

Then ask:

> 确认保存？回复 `y` 直接保存，或告诉我需要修改的地方（标题、内容、标签等）。

Wait for user reply. If they request edits, update and re-show the preview. Repeat until confirmed.

## Step 6 — Save

Write the finalized file to the inbox. Then commit and push:

```bash
cd ~/notes && git add -A && git commit -m "note: {Title}" && git push
```
