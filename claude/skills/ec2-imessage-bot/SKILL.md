---
name: ec2-imessage-bot
version: 1.0.0
description: "EC2 iMessage bot: check status, view logs, and manage the Claude iMessage bot running on EC2."
metadata:
  openclaw:
    category: "infrastructure"
---

# iMessage Bot on EC2

> **PREREQUISITE:** Read `../ec2-shared/SKILL.md` for SSH connection details and service management patterns.

The iMessage bot polls `~/Library/Messages/chat.db` for new messages from a configured phone number, calls `claude --print`, and replies via osascript.

## Key Files

| Path (on EC2) | Description |
|---------------|-------------|
| `~/code/dotfiles/scripts/imessage-bot.py` | Main bot script |
| `~/Library/LaunchAgents/com.mai.imessage-bot.plist` | launchd service definition |
| `/tmp/com.mai.imessage-bot.log` | stdout log (launchd managed) |
| `/tmp/com.mai.imessage-bot.err` | stderr log |
| `~/.imessage-bot-state.json` | Last seen message ROWID |
| `~/code/claude-bot/conversations.jsonl` | Rolling 100-message conversation history |
| `~/.env` | Must contain `IMESSAGE_PHONE=+1xxxxxxxxxx` |

## Check Status

```bash
# Is the service running? (managed by launchd)
ssh mac-ec2 "launchctl print gui/501/com.mai.imessage-bot 2>&1 | grep -E 'state|pid|runs'"

# Is the process alive?
ssh mac-ec2 "ps aux | grep imessage-bot | grep -v grep"

# Recent activity
ssh mac-ec2 "tail -30 /tmp/com.mai.imessage-bot.log"

# Errors
ssh mac-ec2 "tail -30 /tmp/com.mai.imessage-bot.err"
```

## Restart Bot

**Always kill Python first** to avoid duplicate processes, then use `bootout`+`bootstrap` (not `unload`/`load`) for a clean reload:

```bash
ssh mac-ec2 "killall -9 Python 2>/dev/null; sleep 1; launchctl bootout gui/501/com.mai.imessage-bot 2>/dev/null; sleep 1; launchctl bootstrap gui/501 ~/Library/LaunchAgents/com.mai.imessage-bot.plist"
```

After restart, verify exactly one Python process:
```bash
ssh mac-ec2 "ps aux | grep imessage-bot | grep -v grep"
```

## Reset Conversation History

```bash
# Clear rolling history (bot will start fresh context)
ssh mac-ec2 "> ~/code/claude-bot/conversations.jsonl"
```

## How It Works

1. Polls `chat.db` every 10 seconds via a temp copy (to avoid locking)
2. Detects messages via two paths:
   - **Direct**: `is_from_me=0` with `handle.id = IMESSAGE_PHONE`
   - **iCloud sync**: `is_from_me=1` in chat addressed to `IMESSAGE_EMAIL` (iPhone → Mac sync)
3. Audio messages → transcribed with `whisper-cli` (large-v3-turbo-q5_0)
4. Calls `claude --print --dangerously-skip-permissions` with rolling history as context
5. Replies to the same channel the message came from (phone vs iCloud email)

## Common Issues

| Symptom | Likely Cause |
|---------|--------------|
| Service not in `launchctl list` | Plist not loaded; use `launchctl bootstrap gui/501 <plist>` |
| Bot running but not responding | `IMESSAGE_PHONE` not set in `~/.env` |
| Multiple Python processes | Previous `kickstart` left orphan; always `killall -9 Python` before restart |
| Replies going to wrong contact | iCloud sync path misidentified; check `MY_EMAIL` |
| Audio messages ignored | `whisper-cli` or `ffmpeg` not on PATH |
| Message text is `__kIMMessagePartAttributeName` | iOS stored text in attributedBody; not decoded in current version |
