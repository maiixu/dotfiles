---
name: things-read
description: Read-only overview of Things 3 — shows inbox, today/upcoming tasks, deadlines, projects, areas, tags, and stats. Use --full to include all open tasks.
disable-model-invocation: true
---

Run a read-only snapshot of Things 3 and display it.

```bash
bash ~/.claude/scripts/things/things-read.sh
```

To include all open tasks:

```bash
bash ~/.claude/scripts/things/things-read.sh --full
```

Output sections:
- **AREAS** and **TAGS**
- **OPEN PROJECTS** (by area)
- **INBOX** (unscheduled, untriaged)
- **TODAY & UPCOMING** (next 7 days)
- **UPCOMING DEADLINES** (next 30 days)
- **STATS** (open tasks, inbox count, etc.)
- **ALL OPEN TASKS** (only with `--full`)
