---
name: heartbeat
description: "Use when running the hourly EC2 health report cron job."
context: fork
---

# Heartbeat

Collect system health, sync repos, and send a report to the Default Chat space.

## Cron entry (EC2)

```
0 * * * * GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND=file /opt/homebrew/bin/bash -lc '/Users/ec2-user/code/dotfiles/claude/skills/heartbeat/run.sh' >> /tmp/heartbeat.log 2>&1
```

## run.sh

The skill ships a `run.sh` that executes headlessly. Claude does NOT need to be invoked — this is pure shell.

```bash
#!/usr/bin/env bash
set -euo pipefail
export GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND=file
export PATH=/Users/ec2-user/.bun/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin

DEFAULT_SPACE="spaces/AAQAR3itp9E"

# ── 1. Sync dotfiles ──────────────────────────────────────────────────────────
DOTFILES_STATUS=""
cd ~/code/dotfiles
if git pull --ff-only 2>&1 | grep -q "Already up to date"; then
  DOTFILES_STATUS="✓ dotfiles up to date"
else
  DOTFILES_STATUS="↓ dotfiles pulled"
fi

# ── 2. Sync notes ─────────────────────────────────────────────────────────────
NOTES_STATUS=""
cd ~/notes
if git pull --ff-only 2>&1 | grep -q "Already up to date"; then
  NOTES_STATUS="✓ notes up to date"
else
  NOTES_STATUS="↓ notes pulled"
fi

# ── 3. Check agent sessions ───────────────────────────────────────────────────
agent_status() {
  local name=$1
  if tmux has-session -t "claude-${name}" 2>/dev/null; then
    echo "✓ ${name}"
  else
    echo "✗ ${name} (down)"
  fi
}

DEFAULT_AGENT=$(agent_status default)
OBSIDIAN_AGENT=$(agent_status obsidian)
THINGS_AGENT=$(agent_status things)

# ── 4. Check last message timestamps ─────────────────────────────────────────
last_seen() {
  local state_file=$1
  local ts
  ts=$(python3 -c "
import json, sys, datetime
try:
    d = json.load(open('$state_file'))
    ts = list(d.values())[0]['lastTimestamp']
    dt = datetime.datetime.fromisoformat(ts.replace('Z','+00:00'))
    now = datetime.datetime.now(datetime.timezone.utc)
    mins = int((now - dt).total_seconds() / 60)
    print(f'{mins}m ago')
except: print('unknown')
" 2>/dev/null)
  echo "$ts"
}

DEFAULT_LAST=$(last_seen ~/.claude/channels/gchat/default.state.json)
OBSIDIAN_LAST=$(last_seen ~/.claude/channels/gchat/obsidian.state.json)
THINGS_LAST=$(last_seen ~/.claude/channels/gchat/things.state.json)

# ── 5. Build report ───────────────────────────────────────────────────────────
NOW=$(TZ=America/Detroit date +"%Y-%m-%d %H:%M %Z")
REPORT="🤖 *Heartbeat* ${NOW}

*Agents*
• ${DEFAULT_AGENT} (last msg: ${DEFAULT_LAST})
• ${OBSIDIAN_AGENT} (last msg: ${OBSIDIAN_LAST})
• ${THINGS_AGENT} (last msg: ${THINGS_LAST})

*Sync*
• ${DOTFILES_STATUS}
• ${NOTES_STATUS}"

# ── 6. Send to Default space ──────────────────────────────────────────────────
gws chat spaces messages create \
  --params "{\"parent\":\"${DEFAULT_SPACE}\"}" \
  --json "{\"text\":\"${REPORT}\"}"
```

## Notes

- `run.sh` is self-contained; no Claude session needed
- If an agent is down, `keepalive.sh` (cron every minute) will restart it
- Add more checks to the report as needed (disk, CPU, etc.)
