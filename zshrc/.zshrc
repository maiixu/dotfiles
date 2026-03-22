# ~/.config/zshrc/.zshrc
# Main zsh configuration
# This file is sourced by ~/.zshrc

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

# Add to PATH only if not already present
add_to_path() {
    case ":$PATH:" in
        *":$1:"*) ;;
        *) export PATH="$1:$PATH" ;;
    esac
}

add_to_path_end() {
    case ":$PATH:" in
        *":$1:"*) ;;
        *) export PATH="$PATH:$1" ;;
    esac
}

# ==============================================================================
# OH-MY-ZSH CONFIGURATION
# ==============================================================================

export ZSH=$HOME/.oh-my-zsh

# Theme
ZSH_THEME="robbyrussell"

# Plugins
plugins=(git zsh-syntax-highlighting zsh-autosuggestions)

# Load oh-my-zsh (skip if not installed)
[[ -f $ZSH/oh-my-zsh.sh ]] && source $ZSH/oh-my-zsh.sh

# ==============================================================================
# ALIASES
# ==============================================================================

# General
alias l="ls -a"
alias cl="clear"
# Safe rm - move to trash instead of permanent deletion
alias rm="trash"
alias rmi="/bin/rm -i"  # Interactive delete if you really need rm
alias rmf="/bin/rm -f"  # Force delete if you really need it (use with caution!)

# GitHub Copilot
alias copilot="gh copilot"

# Claude Code
alias c="claude --dangerously-skip-permissions"

# ==============================================================================
# FUNCTIONS
# ==============================================================================

# Safe trash function - move files to macOS Trash
# Handles flags like -r, -rf, etc.
trash() {
    if [ $# -eq 0 ]; then
        echo "Usage: trash [-rf] <file_or_directory>..."
        echo "Move files/directories to Trash instead of permanent deletion"
        echo ""
        echo "Options:"
        echo "  -r, -rf, -f    Ignored (for compatibility with rm commands)"
        echo ""
        echo "Examples:"
        echo "  trash file.txt"
        echo "  trash -rf directory/"
        return 1
    fi

    local item
    for item in "$@"; do
        # Skip flags (they're just for rm compatibility)
        if [[ "$item" == -* ]]; then
            continue
        fi

        if [ -e "$item" ] || [ -L "$item" ]; then
            # Convert to absolute path
            local abs_path
            if [[ "$item" == /* ]]; then
                abs_path="$item"
            else
                abs_path="$(pwd)/$item"
            fi

            # Move to Trash
            osascript -e "tell application \"Finder\" to delete POSIX file \"$abs_path\"" &> /dev/null

            if [ $? -eq 0 ]; then
                echo "🗑️  Moved to Trash: $item"
            else
                echo "❌ Failed to move to Trash: $item"
                return 1
            fi
        else
            echo "❌ File not found: $item"
            return 1
        fi
    done
}

# Kill Docker Desktop app and VM (excluding vmnetd service)
function kdo() {
	ps ax|grep -i docker|egrep -iv 'grep|com.docker.vmnetd'|awk '{print $1}'|xargs kill
}

# ==============================================================================
# DEVELOPMENT TOOLS PATH
# ==============================================================================

# yt-dlp (append)
add_to_path_end "$HOME/.config/yt-dlp"

# Node.js global binaries (for npm install -g packages like gws)
add_to_path "$(brew --prefix)/Cellar/node/$(node --version | tr -d v)/bin"

# Google Cloud SDK
add_to_path "/opt/homebrew/share/google-cloud-sdk/bin"


# ==============================================================================
# ENVIRONMENT VARIABLES
# ==============================================================================

# AWS - use bedrock-claude profile by default
export AWS_PROFILE=bedrock-claude

# ==============================================================================
# PROMPT
# ==============================================================================

# Starship prompt (must be at the end)
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi

# bun completions
[ -s "/Users/maixu/.bun/_bun" ] && source "/Users/maixu/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
