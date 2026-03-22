---
name: obsidian_people_note
description: Use when recording a memory about a person.
context: fork
---

Record a memory about a person into Obsidian.

## Vault

- Path: `~/notes/`
- People notes: `~/notes/板块 Areas/人际 Friends/`
- People MOC: `~/notes/板块 Areas/人际 Friends/人际 Friends.md`

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

- `$ARGUMENTS` — required; person name and what to remember (e.g. "诗钰 养了一只猫叫 Nami"); if not provided, ask the user

Examples:
- "诗钰 养了一只猫叫 Nami"
- "Shelley 不吃蒜"
- "Henry 换工作去了 Google"

## Step 1 — Find existing note

Search for the person in `板块 Areas/人际 Friends/`:

```bash
ls ~/notes/"板块 Areas/人际 Friends/"
```

Match by filename — could be Chinese name, English name, or with a timestamp prefix (e.g., `202601111653 Shelley 陶晟婷.md`). Also check YAML `aliases` if present.

If found, read the note to understand existing content.

## Step 2 — Update or create

### If note exists: insert new entry before `---`

The note ends with this pattern:

```
(previous content)

---
{timestamp}

#tag1
#tag2
```

Insert a new dated entry **before** the `---` separator. Use the Edit tool to find the `---` line and insert before it:

```
#### YYYYMMDD

{memory content}

---
```

Keep the memory concise and natural — write what the user said, don't over-format.

### If note does not exist: create new note

Get the current timestamp:

```bash
date +"%Y%m%d%H%M"
```

Filename: `{timestamp} {Name}.md`

Content:

```
## {timestamp} {Name}

#### YYYYMMDD

{memory content}

---
{timestamp}

#Relationship--社交/Notes--备注
```

Write the file to `板块 Areas/人际 Friends/`, then add to the MOC (`人际 Friends.md`): insert a link in the contacts list, maintaining alphabetical order.

## Step 3 — Commit, push, and confirm

```bash
cd ~/notes && git add -A && git commit -m "people: {Name}" && git push
```

Then report what was done.

For updates:
```
Updated: {filename}
Added: {brief summary of what was recorded}
```

For new notes:
```
Created: {filename}
Added to MOC: 人际 Friends.md
```
