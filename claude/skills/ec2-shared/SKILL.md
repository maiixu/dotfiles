---
name: ec2-shared
version: 1.1.0
description: "SSH access to personal EC2 Mac + Claude agent management. Load this skill whenever you need to run commands on the remote EC2 Mac, check or restart Claude Code sessions, deploy code, or manage agent infrastructure. Provides SSH connection details and all key paths."
metadata:
  openclaw:
    category: "infrastructure"
    requires:
      bins: ["ssh"]
---

# EC2 — Shared Reference

## Connection

```bash
# SSH alias (defined in ~/.ssh/config) — use this for all remote commands
ssh mac-ec2 "<command>"

# Config details
Host mac-ec2
    HostName ec2-52-39-255-21.us-west-2.compute.amazonaws.com
    User ec2-user
    IdentityFile ~/.ssh/eecs481.pem
```

> Note: Public IP may change on instance restart (no Elastic IP). Run `aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].[PublicIpAddress,PublicDnsName]' --output table` to get the current IP, then update `~/.ssh/config`.

## Claude Agent Sessions (tmux)

EC2 runs 4 persistent tmux sessions:

| Session name | What it runs |
|---|---|
| `claude-default` | Claude Code + gchat-channel MCP (default space) |
| `claude-obsidian` | Claude Code + gchat-channel MCP (obsidian space) |
| `claude-things` | Claude Code + gchat-channel MCP (things space) |
| `claude-supervisor` | supervisor.ts — health monitor + !status/!restart handler |

```bash
# Check all sessions
ssh mac-ec2 "tmux list-sessions"

# Attach to a session (detach with Ctrl-B D)
ssh mac-ec2 -t "tmux attach -t claude-default"
```

## Start Scripts (`~/agents/`)

| Script | Starts |
|---|---|
| `start-claude-default.sh` | claude-default session |
| `start-claude-obsidian.sh` | claude-obsidian session |
| `start-claude-things.sh` | claude-things session |
| `start-supervisor.sh` | claude-supervisor session |

**⚠️ All start scripts have an infinite `while` loop at the end** (keeps alive while the tmux session runs). They **never exit on their own**. When calling via subprocess (e.g. `Bun.spawn`), fire them in background and poll `tmux has-session` to confirm success — do NOT use `spawnSync` which will time out.

Keychain auth is handled inside the scripts (`security unlock-keychain -p ""`). No interactive prompt needed — scripts are safe to call non-interactively.

Keepalive cron (`~/agents/keepalive.sh`) runs every minute and auto-restarts any dead session.

## Key Paths on EC2

| Path | Description |
|------|-------------|
| `~/code/gchat-channel/` | channel.ts + supervisor.ts (git repo) |
| `~/code/dotfiles/` | dotfiles (configs, CLAUDE.md files) |
| `~/agents/` | start scripts + keepalive.sh + supervisor.log |
| `~/agents/{default,obsidian,things}/` | Claude Code working dirs (each has .mcp.json) |
| `~/.claude/channels/gchat/` | GChat config + state JSON files |
| `~/Library/LaunchAgents/` | launchd plists (macOS-style) |
| `/tmp/com.mai.*.log` | launchd stdout logs |
| `/tmp/com.mai.*.err` | launchd stderr logs |

## Checking Service Status

```bash
# All tmux sessions
ssh mac-ec2 "tmux list-sessions"

# Is a specific session alive?
ssh mac-ec2 "tmux has-session -t claude-default && echo alive || echo dead"

# Supervisor log (structured NDJSON)
ssh mac-ec2 "tail -50 ~/agents/supervisor.log"

# Is a launchd service loaded and running?
ssh mac-ec2 "launchctl list | grep <label>"
```

## Managing launchd Services

Use `bootout`+`bootstrap` (not the deprecated `unload`/`load`) for reliable service management:

```bash
# Start (bootstrap) a service
ssh mac-ec2 "launchctl bootstrap gui/501 ~/Library/LaunchAgents/com.mai.<label>.plist"

# Stop (bootout) a service
ssh mac-ec2 "launchctl bootout gui/501/com.mai.<label>"

# Restart a service — kill child processes first to avoid orphans
ssh mac-ec2 "killall -9 Python 2>/dev/null; sleep 1; launchctl bootout gui/501/com.mai.<label> 2>/dev/null; sleep 1; launchctl bootstrap gui/501 ~/Library/LaunchAgents/com.mai.<label>.plist"
```

## Security Rules

- **Always** confirm with user before stopping or restarting services
- **Never** use `rm -rf` on the EC2 without explicit confirmation
- Check current state before making changes
