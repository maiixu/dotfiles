#!/usr/bin/env bash
# Push latest claude.ai oauth token from local Mac to EC2 keychain.
# Run hourly on local Mac via cron.
set -euo pipefail

CRED=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null) || exit 0

printf '%s' "$CRED" | ssh mac-ec2 'cat > /tmp/cc && \
  security unlock-keychain -p "" ~/Library/Keychains/claude-code.keychain-db 2>/dev/null && \
  security add-generic-password \
    -s "Claude Code-credentials" -a "ec2-user" \
    -w "$(cat /tmp/cc)" \
    -U ~/Library/Keychains/claude-code.keychain-db 2>/dev/null && \
  rm /tmp/cc'
