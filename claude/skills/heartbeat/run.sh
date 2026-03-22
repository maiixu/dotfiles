#!/usr/bin/env bash
set -euo pipefail
export GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND=file
export PATH=/Users/ec2-user/.bun/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin

DEFAULT_SPACE="spaces/AAQAR3itp9E"

# ── 1. Sync dotfiles ──────────────────────────────────────────────────────────
cd ~/code/dotfiles
if git pull --ff-only 2>&1 | grep -q "Already up to date"; then
  DOTFILES_STATUS="✓ dotfiles up to date"
else
  DOTFILES_STATUS="↓ dotfiles pulled"
fi

# ── 2. Sync notes ─────────────────────────────────────────────────────────────
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
  python3 -c "
import json, datetime
try:
    d = json.load(open('${state_file}'))
    ts = list(d.values())[0]['lastTimestamp']
    dt = datetime.datetime.fromisoformat(ts.replace('Z','+00:00'))
    now = datetime.datetime.now(datetime.timezone.utc)
    mins = int((now - dt).total_seconds() / 60)
    print(f'{mins}m ago')
except:
    print('no messages yet')
" 2>/dev/null
}

DEFAULT_LAST=$(last_seen ~/.claude/channels/gchat/default.state.json)
OBSIDIAN_LAST=$(last_seen ~/.claude/channels/gchat/obsidian.state.json)
THINGS_LAST=$(last_seen ~/.claude/channels/gchat/things.state.json)

# ── 5. Build and send report ──────────────────────────────────────────────────
NOW=$(TZ=America/Detroit date +"%Y-%m-%d %H:%M %Z")

python3 - <<PYEOF
import json, subprocess

text = (
    f"🤖 Heartbeat ${NOW}\n\n"
    f"Agents\n"
    f"• ${DEFAULT_AGENT} (last: ${DEFAULT_LAST})\n"
    f"• ${OBSIDIAN_AGENT} (last: ${OBSIDIAN_LAST})\n"
    f"• ${THINGS_AGENT} (last: ${THINGS_LAST})\n\n"
    f"Sync\n"
    f"• ${DOTFILES_STATUS}\n"
    f"• ${NOTES_STATUS}"
)

params = json.dumps({"parent": "${DEFAULT_SPACE}"})
body = json.dumps({"text": text})

subprocess.run([
    "gws", "chat", "spaces", "messages", "create",
    "--params", params,
    "--json", body,
], check=True)
PYEOF
