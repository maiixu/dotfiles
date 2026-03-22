#!/bin/bash
export HOME=/Users/ec2-user
export PATH=/Users/ec2-user/.bun/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin

for agent in default obsidian things; do
  if ! tmux has-session -t "claude-${agent}" 2>/dev/null; then
    /Users/ec2-user/agents/start-claude-${agent}.sh &
  fi
done
