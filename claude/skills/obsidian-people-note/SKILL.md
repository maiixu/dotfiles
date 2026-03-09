---
name: obsidian-people-note
description: Record memories about people into Obsidian. Use when the user mentions something worth remembering about a friend or acquaintance — from conversation, Things inbox triage, or explicit request.
agent: obsidian
---

Record a memory about a person into Obsidian.

Input: `$ARGUMENTS` — the person's name and what to remember about them.

Examples:
- "诗钰 养了一只猫叫 Nami"
- "Shelley 不吃蒜"
- "Henry 换工作去了 Google"

## Step 1 — Find existing note

Search for the person in `板块 Areas/人际 Friends/`:

```bash
ls "/Users/maixu/notes/板块 Areas/人际 Friends/"
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

## Step 3 — Open in Obsidian and confirm

Open the note, then report what was done.

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
