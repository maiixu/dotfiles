#!/bin/bash
export HOME=/Users/ec2-user
export GOOGLE_WORKSPACE_CLI_KEYRING_BACKEND=file
export PATH=/Users/ec2-user/code/dotfiles/bin:/Users/ec2-user/.bun/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin
claude-switch pro 2>/dev/null
security unlock-keychain -p "" ~/Library/Keychains/claude-code.keychain-db 2>/dev/null

SESSION="claude-default"
tmux kill-session -t "$SESSION" 2>/dev/null
sleep 1

tmux new-session -d -s "$SESSION" -x 220 -y 50 \
  -c "/Users/ec2-user/agents/default" \
  "claude --dangerously-skip-permissions --dangerously-load-development-channels server:gchat-default"

# Auto-confirm development channels dialog
sleep 6
tmux send-keys -t "$SESSION" "" 2>/dev/null
sleep 1
tmux send-keys -t "$SESSION" Enter 2>/dev/null

# Keep script alive while session runs
while tmux has-session -t "$SESSION" 2>/dev/null; do
  sleep 10
done
