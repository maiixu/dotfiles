#!/bin/bash
# RSS daily digest → iMessage
# Triggered by launchd at 8:00 UTC (16:00 Beijing).
set -e

source ~/.env
[ -f ~/code/signals/.env.local ] && source ~/code/signals/.env.local

cd ~/code/signals && git pull --quiet

OUTPUT=$(python3 digest.py --no-interactive 2>&1)

if [ -z "$OUTPUT" ]; then
    OUTPUT="(digest produced no output)"
fi

# Escape double quotes for AppleScript
ESCAPED=$(printf '%s' "$OUTPUT" | sed 's/"/\\"/g' | sed 's/\\/\\\\/g')

osascript <<APPLESCRIPT
tell application "Messages"
    set targetBuddy to buddy "$IMESSAGE_PHONE" of service "iMessage"
    send "Daily Digest\n${ESCAPED}" to targetBuddy
end tell
APPLESCRIPT
