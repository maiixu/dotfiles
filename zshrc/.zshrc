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

# Load oh-my-zsh
source $ZSH/oh-my-zsh.sh

# ==============================================================================
# ALIASES
# ==============================================================================

alias l="ls -a"
alias cl="clear"
alias please="shell-genie ask"

# hledger aliases
alias hl="hledger"
alias hlb="hledger bs"
alias hla="hledger add"
alias hlc="hledger check"

# GitHub Copilot
alias copilot="gh copilot"

# ==============================================================================
# FUNCTIONS
# ==============================================================================

# Kill Docker Desktop app and VM (excluding vmnetd service)
function kdo() {
	ps ax|grep -i docker|egrep -iv 'grep|com.docker.vmnetd'|awk '{print $1}'|xargs kill
}

# ==============================================================================
# DEVELOPMENT TOOLS PATH
# ==============================================================================

# OpenJDK (prepend)
add_to_path "/opt/homebrew/opt/openjdk/bin"

# Go (append)
add_to_path_end "/usr/local/go/bin"

# Maven (append)
add_to_path_end "/usr/local/lib/apache-maven-3.9.6/bin"

# yt-dlp (append)
add_to_path_end "$HOME/.config/yt-dlp"

# pnpm (prepend)
export PNPM_HOME="$HOME/Library/pnpm"
add_to_path "$PNPM_HOME"

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# >>> conda initialize >>>
if [ -f "$HOME/miniconda3/bin/conda" ]; then
    __conda_setup="$('$HOME/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
            . "$HOME/miniconda3/etc/profile.d/conda.sh"
        else
            export PATH="$HOME/miniconda3/bin:$PATH"
        fi
    fi
    unset __conda_setup
fi
# <<< conda initialize <<<

# Google Cloud SDK
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then
    . "$HOME/google-cloud-sdk/path.zsh.inc"
fi

if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then
    . "$HOME/google-cloud-sdk/completion.zsh.inc"
fi

# ==============================================================================
# ENVIRONMENT VARIABLES
# ==============================================================================

# AWS - use bedrock-claude profile by default
export AWS_PROFILE=bedrock-claude

# hledger
export LEDGER_FILE="$HOME/Local/Areas/Personal Finance/hledger/2024.journal"

# ==============================================================================
# PROMPT
# ==============================================================================

# Starship prompt (must be at the end)
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi
