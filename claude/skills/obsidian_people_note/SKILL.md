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
        grep People tag → match filename by name
              ↓
       found? ── yes ──→ read note → insert entry before ---
          │                                   ↓
          no                          git commit + push
          ↓
       create new note (date + timestamp)
              ↓
        git commit + push
```

## Step 1 — Find existing note

```bash
grep -rl "Meta--元数据/Type--类型/People--人际" ~/notes --include="*.md"
```

Match result filenames against the person's name (Chinese, English, or partial). If found, read it.

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

Determine destination folder from current date (see `obsidian_shared` for Journal structure).

```
## {timestamp} {Name}

#### YYYYMMDD

{memory content}

---
{timestamp}

#Meta--元数据/Type--类型/People--人际
```

## Step 3 — Commit, push, report

```bash
cd ~/notes && git add -A && git commit -m "people: {Name}" && git push
```

Report: updated vs created, what was recorded.
