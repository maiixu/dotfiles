#!/bin/bash
set -e

# Paths
DOTFILES_SRC="$HOME/eng/src/dotfiles"
CONFIG_DIR="$HOME/.config"
ICLOUD_ORIGIN="$HOME/Library/Mobile Documents/com~apple~CloudDocs/cloud"
ICLOUD_LINK="$HOME/cloud"

# What to exclude (top-level entries in $DOTFILES_SRC)
EXCLUDES=("setup.sh" ".git" ".gitignore" "README.md")

# Explicit file-level symlinks: ["target relative to ~/.config"]="source relative to $DOTFILES_SRC"
declare -A FILE_SYMLINKS=(
  ["karabiner/karabiner.json"]="karabiner/karabiner.json"
)

echo "🔗 Linking config folders and files..."

# Step 1a: Link folders
for item in "$DOTFILES_SRC"/*; do
    name=$(basename "$item")
    [[ " ${EXCLUDES[*]} " == *" $name "* ]] && continue
    [[ -n "${FILE_SYMLINKS[$name]}" ]] && continue  # skip if handled in file-level map

    target="$CONFIG_DIR/$name"
    if [ -e "$target" ] || [ -L "$target" ]; then
        echo "Skipping existing: $target"
    else
        ln -s "$item" "$target"
        echo "Linked folder: $target → $item"
    fi
done

# Step 1b: Link individual files
for rel_target in "${!FILE_SYMLINKS[@]}"; do
    rel_source="${FILE_SYMLINKS[$rel_target]}"
    abs_target="$CONFIG_DIR/$rel_target"
    abs_source="$DOTFILES_SRC/$rel_source"

    # Ensure parent directory exists
    mkdir -p "$(dirname "$abs_target")"

    if [ -e "$abs_target" ] || [ -L "$abs_target" ]; then
        echo "Skipping existing file: $abs_target"
    else
        ln -s "$abs_source" "$abs_target"
        echo "Linked file: $abs_target → $abs_source"
    fi
done

# Step 2: Link ~/cloud
echo "🔗 Linking iCloud folder to ~/cloud..."
if [ -e "$ICLOUD_LINK" ] || [ -L "$ICLOUD_LINK" ]; then
    echo "Skipping existing: $ICLOUD_LINK"
else
    ln -s "$ICLOUD_ORIGIN" "$ICLOUD_LINK"
    echo "Linked: $ICLOUD_LINK → $ICLOUD_ORIGIN"
fi

echo "✅ Setup complete."