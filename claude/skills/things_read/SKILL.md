---
name: things_read
description: Use when reading a Things 3 task overview.
context: fork
disable-model-invocation: true
---

Run a read-only snapshot of Things 3 and display it.

## Params

- `--full` — optional flag; if provided, appended to the script call to include all open tasks

```bash
bash ~/code/things-scripts/things-read.sh
```

To include all open tasks:

```bash
bash ~/code/things-scripts/things-read.sh --full
```

Output sections:
- **AREAS** and **TAGS**
- **OPEN PROJECTS** (by area)
- **INBOX** (unscheduled, untriaged)
- **TODAY & UPCOMING** (next 7 days)
- **UPCOMING DEADLINES** (next 30 days)
- **STATS** (open tasks, inbox count, etc.)
- **ALL OPEN TASKS** (only with `--full`)
