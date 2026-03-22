#!/usr/bin/env bash
set -euo pipefail
export GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND=file
export PATH=/Users/ec2-user/.bun/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin

DEFAULT_SPACE="spaces/AAQAdgITNE8"

# ── 1. Sync dotfiles ──────────────────────────────────────────────────────────
cd ~/code/dotfiles
git checkout -- . 2>/dev/null
if git pull --ff-only 2>&1 | grep -q "Already up to date"; then
  DOTFILES_STATUS="✓ dotfiles up to date"
else
  DOTFILES_STATUS="↓ dotfiles pulled"
fi

# ── 2. Sync gchat-channel ─────────────────────────────────────────────────────
cd ~/code/gchat-channel
if git pull --ff-only 2>&1 | grep -q "Already up to date"; then
  CHANNEL_STATUS="✓ gchat-channel up to date"
else
  CHANNEL_STATUS="↓ gchat-channel pulled"
fi

# ── 3. Sync notes ─────────────────────────────────────────────────────────────
cd ~/notes
git add -A
if ! git diff --cached --quiet; then
  git commit -m "vault backup: $(date '+%Y-%m-%d %H:%M:%S')"
  git pull --rebase -q 2>/dev/null || true
  git push -q 2>/dev/null && NOTES_STATUS="↑ notes pushed" || NOTES_STATUS="⚠️ notes push failed"
elif git pull --ff-only 2>&1 | grep -q "Already up to date"; then
  NOTES_STATUS="✓ notes up to date"
else
  NOTES_STATUS="↓ notes pulled"
fi

# ── 3. Check agent sessions ───────────────────────────────────────────────────
agent_status() {
  local name=$1
  if ! tmux has-session -t "claude-${name}" 2>/dev/null; then
    echo "✗ ${name} (session down)"
    return
  fi
  local pane
  pane=$(tmux capture-pane -t "claude-${name}" -p 2>/dev/null)
  if echo "$pane" | grep -q "Not logged in"; then
    echo "⚠️ ${name} (Pro auth expired)"
  elif echo "$pane" | grep -q "API Usage Billing"; then
    echo "⚠️ ${name} (API billing, not Pro)"
  else
    echo "✓ ${name}"
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
BUN_COUNT=$(ps aux | grep "bun.*channel" | grep -v grep | wc -l | tr -d ' ')
BUN_STATUS="✓ ${BUN_COUNT}/9 bun procs"
[ "${BUN_COUNT}" -lt 9 ] && BUN_STATUS="⚠️ ${BUN_COUNT}/9 bun procs"

python3 - <<PYEOF
import json, subprocess

text = (
    f"🤖 Heartbeat ${NOW}\n\n"
    f"Agents\n"
    f"• ${DEFAULT_AGENT} (last: ${DEFAULT_LAST})\n"
    f"• ${OBSIDIAN_AGENT} (last: ${OBSIDIAN_LAST})\n"
    f"• ${THINGS_AGENT} (last: ${THINGS_LAST})\n"
    f"• ${BUN_STATUS}\n\n"
    f"Sync\n"
    f"• ${DOTFILES_STATUS}\n"
    f"• ${CHANNEL_STATUS}\n"
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
