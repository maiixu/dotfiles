---
name: obsidian_people_note
description: Use when recording a memory about a person.
context: fork
---

deps:    obsidian_shared

params:
  name    required   $ARGUMENTS
  memory  required   $ARGUMENTS

```
$ARGUMENTS: "{name} {memory}"
              ↓
        ls 人际 Friends/ → match by name
              ↓
       found? ── yes ──→ read note → insert entry before ---
          │                                   ↓
          no                          git commit + push
          ↓
       create new note → add link to MOC
              ↓
        git commit + push
```

## Step 1 — Find existing note

```bash
ls ~/notes/"板块 Areas/人际 Friends/"
```

Match by filename — Chinese name, English name, or with timestamp prefix. Check YAML `aliases` if present. If found, read it.

## Step 2 — Update or create

### If note exists — insert before `---`

```
#### YYYYMMDD

{memory content}

---
```

### If note does not exist — create new

Get timestamp:
```bash
date +"%Y%m%d%H%M"
```

Filename: `{timestamp} {Name}.md`

```
## {timestamp} {Name}

#### YYYYMMDD

{memory content}

---
{timestamp}

#Relationship--社交/Notes--备注
```

Write to `板块 Areas/人际 Friends/`, then add link to MOC (`人际 Friends.md`) in alphabetical order.

## Step 3 — Commit, push, report

```bash
cd ~/notes && git add -A && git commit -m "people: {Name}" && git push
```

Report what was done (updated vs created, what was recorded).
