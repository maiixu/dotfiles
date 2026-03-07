# Load profile configurations
if [ -f ~/.profile ]; then
    source ~/.profile
fi

# Ensure ~/.local/bin is in PATH for user binaries (including claude)
export PATH="$HOME/.local/bin:$PATH"

# Added by Obsidian
export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"
