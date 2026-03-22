---
name: obsidian_people_note
description: Use when recording a memory about a person.
context: fork
---

Record a memory about a person in Obsidian. Refer to `obsidian_shared` for vault paths, note format, and write helper.

## Params

- `$ARGUMENTS` — required; person name and what to remember (e.g. "诗钰 养了一只猫叫 Nami"); if not provided, ask the user

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

Get timestamp, filename: `{timestamp} {Name}.md`

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
