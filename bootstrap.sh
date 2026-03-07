#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting dotfiles setup...${NC}"

# Detect dotfiles directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"

echo "📁 Dotfiles location: $DOTFILES_DIR"

# Target directories
HOME_DIR="$HOME"
CONFIG_DIR="$HOME/.config"

# Ensure ~/.config exists
mkdir -p "$CONFIG_DIR"

# What to exclude from ~/.config linking
EXCLUDES=("bootstrap.sh" ".git" ".gitignore" "README.md" "zshenv" "zprofile" "profile" "shell-loading-order.txt")

echo ""
echo -e "${GREEN}🔗 Step 1: Linking shell configuration files...${NC}"

# Link shell config files to home directory
declare -A SHELL_CONFIGS=(
    ["zshenv"]=".zshenv"
    ["zprofile"]=".zprofile"
    ["profile"]=".profile"
)

for source_name in "${!SHELL_CONFIGS[@]}"; do
    target_name="${SHELL_CONFIGS[$source_name]}"
    source_path="$DOTFILES_DIR/$source_name"
    target_path="$HOME_DIR/$target_name"

    if [ ! -f "$source_path" ]; then
        echo -e "${YELLOW}⚠️  Skipping missing file: $source_name${NC}"
        continue
    fi

    if [ -L "$target_path" ]; then
        existing_link=$(readlink "$target_path")
        if [ "$existing_link" = "$source_path" ]; then
            echo "✓ Already linked: ~/$target_name"
        else
            echo -e "${YELLOW}⚠️  ~/$target_name already symlinked to: $existing_link${NC}"
        fi
    elif [ -f "$target_path" ]; then
        backup_path="$target_path.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$target_path" "$backup_path"
        ln -s "$source_path" "$target_path"
        echo -e "${GREEN}✓ Backed up and linked: ~/$target_name (backup at: $backup_path)${NC}"
    else
        ln -s "$source_path" "$target_path"
        echo -e "${GREEN}✓ Linked: ~/$target_name${NC}"
    fi
done

# Special handling for .zshrc (sources from ~/.config/zshrc/.zshrc)
if [ ! -f "$HOME_DIR/.zshrc" ]; then
    cat > "$HOME_DIR/.zshrc" << 'EOF'
# Load main zsh configuration from ~/.config/zshrc/.zshrc
if [ -f ~/.config/zshrc/.zshrc ]; then
    source ~/.config/zshrc/.zshrc
fi
EOF
    echo -e "${GREEN}✓ Created: ~/.zshrc${NC}"
else
    echo "✓ Already exists: ~/.zshrc"
fi

echo ""
echo -e "${GREEN}🔗 Step 2: Linking config folders to ~/.config...${NC}"

# Link folders to ~/.config
for item in "$DOTFILES_DIR"/*; do
    [ ! -d "$item" ] && continue  # Skip if not a directory

    name=$(basename "$item")

    # Skip excludes
    [[ " ${EXCLUDES[*]} " == *" $name "* ]] && continue

    target="$CONFIG_DIR/$name"

    if [ -L "$target" ]; then
        existing_link=$(readlink "$target")
        if [ "$existing_link" = "$item" ]; then
            echo "✓ Already linked: ~/.config/$name"
        else
            echo -e "${YELLOW}⚠️  ~/.config/$name already symlinked to: $existing_link${NC}"
        fi
    elif [ -e "$target" ]; then
        backup_path="$target.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$target" "$backup_path"
        ln -s "$item" "$target"
        echo -e "${GREEN}✓ Backed up and linked: ~/.config/$name (backup at: $backup_path)${NC}"
    else
        ln -s "$item" "$target"
        echo -e "${GREEN}✓ Linked: ~/.config/$name${NC}"
    fi
done

# Special handling for karabiner (link individual file)
echo ""
echo -e "${GREEN}🔗 Step 3: Linking karabiner configuration...${NC}"

KARABINER_SOURCE="$DOTFILES_DIR/karabiner/karabiner.json"
KARABINER_TARGET="$CONFIG_DIR/karabiner/karabiner.json"

if [ -f "$KARABINER_SOURCE" ]; then
    mkdir -p "$(dirname "$KARABINER_TARGET")"

    if [ -L "$KARABINER_TARGET" ]; then
        existing_link=$(readlink "$KARABINER_TARGET")
        if [ "$existing_link" = "$KARABINER_SOURCE" ]; then
            echo "✓ Already linked: ~/.config/karabiner/karabiner.json"
        else
            echo -e "${YELLOW}⚠️  karabiner.json already symlinked to: $existing_link${NC}"
        fi
    elif [ -f "$KARABINER_TARGET" ]; then
        backup_path="$KARABINER_TARGET.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$KARABINER_TARGET" "$backup_path"
        ln -s "$KARABINER_SOURCE" "$KARABINER_TARGET"
        echo -e "${GREEN}✓ Backed up and linked: karabiner.json (backup at: $backup_path)${NC}"
    else
        ln -s "$KARABINER_SOURCE" "$KARABINER_TARGET"
        echo -e "${GREEN}✓ Linked: ~/.config/karabiner/karabiner.json${NC}"
    fi
fi

# Optional: Link iCloud folder
echo ""
echo -e "${GREEN}🔗 Step 4: Linking iCloud folder (optional)...${NC}"

ICLOUD_ORIGIN="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
ICLOUD_LINK="$HOME/cloud"

if [ -d "$ICLOUD_ORIGIN" ]; then
    if [ -L "$ICLOUD_LINK" ]; then
        echo "✓ Already linked: ~/cloud"
    elif [ -e "$ICLOUD_LINK" ]; then
        echo -e "${YELLOW}⚠️  ~/cloud already exists (not a symlink)${NC}"
    else
        ln -s "$ICLOUD_ORIGIN" "$ICLOUD_LINK"
        echo -e "${GREEN}✓ Linked: ~/cloud → iCloud Drive${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  iCloud Drive not found${NC}"
fi

echo ""
echo -e "${GREEN}✅ Dotfiles setup complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal or run: source ~/.zshenv && source ~/.zshrc"
echo "  2. Install Homebrew if not already installed: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
echo "  3. Install packages: brew install starship"
echo ""
