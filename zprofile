# ~/.zprofile
# Loaded for login shells only
# User-specific paths and applications

# Helper function to add to PATH if not already present
add_to_path_if_missing() {
    case ":$PATH:" in
        *":$1:"*) ;;
        *) export PATH="$1:$PATH" ;;
    esac
}

# User binaries (claude, pipx, etc.)
add_to_path_if_missing "$HOME/.local/bin"

# Applications
add_to_path_if_missing "/Applications/Obsidian.app/Contents/MacOS"
