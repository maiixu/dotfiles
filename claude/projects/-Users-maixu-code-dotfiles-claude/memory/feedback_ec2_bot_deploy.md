---
name: EC2 bot deploy checklist
description: Lessons from imessage-bot debugging session - avoid duplicate processes and verify each step
type: feedback
---

**Rule: When deploying to EC2 bot, always kill ALL bot processes before AND verify after.**

**Why:** During the 2026-03-16 imessage-bot debugging session, the same mistakes were repeated many times:
1. `scp` a new script → `launchctl kickstart` → old processes still running with old code → new messages processed by old process → wrong behavior persists
2. Checking logs without checking which process is actually running
3. Kickstart spawns a new process but the old one keeps running as an orphan with `-u` flag (unbuffered Python), not managed by launchd

**How to apply:**
Always follow this sequence when deploying bot changes:
1. `scp` new script to EC2
2. `launchctl print gui/501/com.mai.imessage-bot 2>&1 | grep pid` → get the launchd PID
3. `killall -9 Python` to kill ALL Python processes (brute force but effective)
4. `launchctl kickstart gui/501/com.mai.imessage-bot` to restart under launchd
5. Immediately verify: `ps aux | grep imessage-bot | grep -v grep` → must show EXACTLY ONE process
6. Check `grep 'reply_target\|KEY_LINE' ~/code/dotfiles/scripts/imessage-bot.py` to confirm new code is running
7. Only then proceed with testing
