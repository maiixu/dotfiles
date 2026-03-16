# EC2 mac2.metal Provisioning Notes

## Dedicated Host

| Field | Value |
|-------|-------|
| Host ID | `h-0ff3f92baafbd5d28` |
| Availability Zone | `us-west-2a` |
| Instance Type | `mac2.metal` |
| Allocated At | 2026-03-15 |

## Instance

| Field | Value |
|-------|-------|
| Instance ID | `i-02fd6484449dfedc9` |
| AMI ID | `ami-0c8696ce6a820b129` (macOS 14.8.4 arm64, 2026-02-20) |
| macOS Version | 14.8.4 (Sonoma) |
| Key Pair | `claude-ec2` → `~/.ssh/claude-ec2.pem` |
| Security Group | `sg-0e0a97a50b67d6bf2` (claude-ec2-sg) |
| IAM Profile | `claude-ec2-profile` → `claude-ec2-role` |

## Networking

| Field | Value |
|-------|-------|
| Elastic IP | `52.39.255.21` (eipalloc-019b8e2fe99144518) |
| VPC | `vpc-0ce6bfb8503fafbd8` (default, 172.31.0.0/16) |
| Subnet | `subnet-0e4caba20a18b636f` (us-west-2a) |

> After instance is running: `aws ec2 associate-address --region us-west-2 --instance-id i-02fd6484449dfedc9 --allocation-id eipalloc-019b8e2fe99144518`

## SSH

```bash
ssh -i ~/.ssh/claude-ec2.pem ec2-user@52.39.255.21
```

## IAM Role: `claude-ec2-role` → `claude-ec2-profile`

Policies attached:
- `AmazonBedrockFullAccess`
- `AmazonSSMReadOnlyAccess`

## Security Group: `sg-0e0a97a50b67d6bf2`

Inbound:
- SSH (22) from 172.1.138.69/32 (home)
- VNC (5900) from 172.1.138.69/32 (home)

Outbound: all (default)

## SSM Parameters (to create)

```bash
aws ssm put-parameter --region us-west-2 --name /claude-ec2/anthropic-api-key --type SecureString --value "sk-ant-..."
aws ssm put-parameter --region us-west-2 --name /claude-ec2/twitter-env     --type SecureString --value "$(cat ~/code/signals/.env.local)"
aws ssm put-parameter --region us-west-2 --name /claude-ec2/imessage-phone  --type SecureString --value "+1..."
aws ssm put-parameter --region us-west-2 --name /claude-ec2/things-token    --type SecureString --value "..."  # after Things 3 GUI install
```

## One-Time GUI Steps (via VNC: open vnc://52.39.255.21)

1. System Settings → General → Sharing → **Screen Sharing ON** (if not already reachable)
2. System Settings → Users & Groups → enable **auto-login** for ec2-user (so GUI session persists across reboots)
3. App Store → Things 3 → install with Apple ID
4. Things 3 → Settings → Things Cloud → sign in
5. Enable Things URL API → copy token → store in SSM:
   `aws ssm put-parameter --region us-west-2 --name /claude-ec2/things-token --type SecureString --value "TOKEN"`
6. Messages.app → sign in with Apple ID → enable iMessage
7. System Settings → Privacy & Security → **Full Disk Access** → add Terminal + Python
8. System Settings → Privacy & Security → **Automation** → allow Terminal to control Messages
9. Open Terminal (via VNC) and load launchd agents (GUI session required):
   ```bash
   launchctl bootstrap gui/501 ~/Library/LaunchAgents/com.mai.rss-daily.plist
   launchctl bootstrap gui/501 ~/Library/LaunchAgents/com.mai.imessage-bot.plist
   launchctl list | grep com.mai
   ```
10. Test RSS digest:
    ```bash
    source ~/.env && source ~/code/signals/.env.local
    cd ~/code/signals && .venv/bin/python3 digest.py --no-sync --no-interactive --dry-run
    ```

## Billing Notes

- Dedicated Host minimum: 24h from 2026-03-15 allocation
- After 24h: per-second billing when instance is running
- ~$0.65/hr → ~$470/month running continuously
- To pause: stop instance (host still billed at ~$0.65/hr); to fully stop: release host
