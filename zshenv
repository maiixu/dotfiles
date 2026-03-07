# ~/.zshenv
# Loaded for ALL shells (including scripts)
# Keep this minimal and fast

# Homebrew (most important - needed for everything)
if [ -x "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Cargo (Rust toolchain)
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

# Clean up PATH: expand ~ to $HOME
if [[ "$PATH" == *"~"* ]]; then
    export PATH="${PATH//\~/$HOME}"
fi
