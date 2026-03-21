---
name: ec2_shared
version: 1.0.0
description: "EC2 shared SSH patterns and service management reference."
metadata:
  openclaw:
    category: "infrastructure"
    requires:
      bins: ["ssh"]
---

# EC2 — Shared Reference

## Connection

```bash
# SSH alias (defined in ~/.ssh/config)
ssh mac-ec2

# Config details
Host mac-ec2
    HostName ec2-52-39-255-21.us-west-2.compute.amazonaws.com
    User ec2-user
    IdentityFile ~/.ssh/eecs481.pem
```

> Note: Public IP may change on instance restart (no Elastic IP). Run `aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].[PublicIpAddress,PublicDnsName]' --output table` to get the current IP, then update `~/.ssh/config`.

## Key Paths on EC2

| Path | Description |
|------|-------------|
| `~/code/dotfiles/scripts/` | Bot scripts |
| `~/Library/LaunchAgents/` | launchd plists (macOS-style; EC2 runs macOS) |
| `/tmp/com.mai.*.log` | stdout logs |
| `/tmp/com.mai.*.err` | stderr logs |
| `~/.env` | Environment variables (IMESSAGE_PHONE, etc.) |

## Checking Service Status

```bash
# Is a launchd service loaded and running?
ssh mac-ec2 "launchctl list | grep <label>"

# View recent logs
ssh mac-ec2 "tail -50 /tmp/com.mai.<label>.log"
ssh mac-ec2 "tail -50 /tmp/com.mai.<label>.err"
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
