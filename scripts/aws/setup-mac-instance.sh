#!/bin/bash
# EC2 mac2.metal one-time initialization
# Run after first SSH into a fresh macOS instance.
# Prerequisites: SSH key auth working, instance has IAM role with Bedrock + SSM access.
set -e

DOTFILES_REPO="git@github.com:maiixu/dotfiles.git"
SIGNALS_REPO="git@github.com:maiixu/signals.git"
NOTES_REPO="git@github.com:maiixu/Me-and-My-Research.git"

echo "=== EC2 mac2.metal setup ==="

# 1. Homebrew
if ! command -v brew &>/dev/null; then
    echo "--- Installing Homebrew ---"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
echo "✓ Homebrew"

# 2. Core CLI tools
brew install git node awscli python3 || true
echo "✓ CLI tools"

# 3. Dotfiles
mkdir -p ~/code
if [ ! -d ~/code/dotfiles ]; then
    git clone "$DOTFILES_REPO" ~/code/dotfiles
fi
cd ~/code/dotfiles && bash bootstrap.sh --server --install-packages
echo "✓ Dotfiles bootstrapped (server mode)"

# 4. Signals project
if [ ! -d ~/code/signals ]; then
    git clone --recurse-submodules "$SIGNALS_REPO" ~/code/signals
fi
pip3 install -r ~/code/signals/requirements.txt
echo "✓ Signals project"

# 5. Obsidian vault
if [ ! -d ~/notes ]; then
    git clone "$NOTES_REPO" ~/notes
fi
echo "✓ Notes repo"

# 6. Claude Code
npm install -g @anthropic-ai/claude-code
echo "✓ Claude Code"

# 7. Configure Claude Code to use Bedrock (IAM role provides access, no API key needed)
cat > ~/.claude/settings.local.json <<'EOF'
{
  "env": {
    "AWS_DEFAULT_REGION": "us-west-2",
    "CLAUDE_CODE_USE_BEDROCK": "1"
  }
}
EOF
echo "✓ Claude Code configured for Bedrock"

# 8. Secrets from SSM → local env files
echo "--- Fetching secrets from SSM ---"

THINGS_TOKEN=$(aws ssm get-parameter \
    --name /claude-ec2/things-token \
    --with-decryption \
    --query Parameter.Value \
    --output text 2>/dev/null || echo "")
if [ -n "$THINGS_TOKEN" ]; then
    echo "THINGS_TOKEN=$THINGS_TOKEN" >> ~/.env
fi

IMESSAGE_PHONE=$(aws ssm get-parameter \
    --name /claude-ec2/imessage-phone \
    --with-decryption \
    --query Parameter.Value \
    --output text)
echo "IMESSAGE_PHONE=$IMESSAGE_PHONE" >> ~/.env

aws ssm get-parameter \
    --name /claude-ec2/twitter-env \
    --with-decryption \
    --query Parameter.Value \
    --output text > ~/code/signals/.env.local

chmod 600 ~/.env ~/code/signals/.env.local
echo "✓ Secrets fetched"

# 9. Source env in shell
if ! grep -q 'source ~/.env' ~/.zshrc 2>/dev/null; then
    echo 'source ~/.env' >> ~/.zshrc
fi

# 10. Install launchd agents
echo "--- Installing launchd agents ---"
PLIST_SRC=~/code/dotfiles/scripts/aws

cp "$PLIST_SRC/com.mai.rss-daily.plist" ~/Library/LaunchAgents/
cp "$PLIST_SRC/com.mai.imessage-bot.plist" ~/Library/LaunchAgents/

launchctl load ~/Library/LaunchAgents/com.mai.rss-daily.plist
launchctl load ~/Library/LaunchAgents/com.mai.imessage-bot.plist
echo "✓ launchd agents loaded"

echo ""
echo "=== Setup complete ==="
echo ""
echo "Remaining manual steps (requires VNC):"
echo "  1. App Store → install Things 3 → sign in to Things Cloud"
echo "  2. Things 3 → Settings → enable URL API → copy token → store in SSM"
echo "  3. Messages.app → sign in with Apple ID → enable iMessage"
echo "  4. Privacy: Full Disk Access → add Terminal + Python"
echo "  5. Privacy: Automation → allow Terminal to control Messages"
echo ""
echo "Verification:"
echo "  claude --version"
echo "  python3 ~/code/signals/digest.py --no-sync --no-interactive --dry-run"
