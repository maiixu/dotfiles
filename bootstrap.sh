#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Flags
INSTALL_BREW=false
INSTALL_PACKAGES=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --install-brew)
            INSTALL_BREW=true
            shift
            ;;
        --install-packages)
            INSTALL_PACKAGES=true
            shift
            ;;
        --help)
            echo "Usage: bash bootstrap.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --install-brew       Install Homebrew if not present"
            echo "  --install-packages   Install essential packages"
            echo "  --help               Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🚀 Dotfiles Bootstrap${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Detect dotfiles directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"

echo "📁 Dotfiles location: $DOTFILES_DIR"
echo ""

# Target directories
HOME_DIR="$HOME"
CONFIG_DIR="$HOME/.config"

# Ensure ~/.config exists
mkdir -p "$CONFIG_DIR"

# ==============================================================================
# STEP 0: Install Homebrew (optional)
# ==============================================================================

if [ "$INSTALL_BREW" = true ]; then
    echo -e "${GREEN}🍺 Step 0: Installing Homebrew...${NC}"
    echo ""

    if command -v brew &> /dev/null; then
        echo -e "${GREEN}✓ Homebrew already installed${NC}"
    else
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for this session
        if [ -x "/opt/homebrew/bin/brew" ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [ -x "/usr/local/bin/brew" ]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi

        echo -e "${GREEN}✓ Homebrew installed${NC}"
    fi
    echo ""
fi

# ==============================================================================
# STEP 1: Link shell configuration files
# ==============================================================================

echo -e "${GREEN}🔗 Step 1: Linking shell configuration files...${NC}"
echo ""

# Shell config files to link
declare -A SHELL_CONFIGS=(
    ["zshenv"]=".zshenv"
    ["zprofile"]=".zprofile"
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
        echo -e "${GREEN}✓ Backed up and linked: ~/$target_name${NC}"
        echo -e "  ${YELLOW}Backup at: $backup_path${NC}"
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

# ==============================================================================
# STEP 2: Link config folders
# ==============================================================================

echo -e "${GREEN}🔗 Step 2: Linking config folders to ~/.config...${NC}"
echo ""

# What to exclude from ~/.config linking
EXCLUDES=("bootstrap.sh" ".git" ".gitignore" "README.md" "zshenv" "zprofile" "test" "hammerspoon" "raycast")

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
        echo -e "${GREEN}✓ Backed up and linked: ~/.config/$name${NC}"
        echo -e "  ${YELLOW}Backup at: $backup_path${NC}"
    else
        ln -s "$item" "$target"
        echo -e "${GREEN}✓ Linked: ~/.config/$name${NC}"
    fi
done

echo ""

# ==============================================================================
# STEP 3: Special handling for karabiner
# ==============================================================================

echo -e "${GREEN}🔗 Step 3: Linking karabiner configuration...${NC}"
echo ""

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
        echo -e "${GREEN}✓ Backed up and linked: karabiner.json${NC}"
        echo -e "  ${YELLOW}Backup at: $backup_path${NC}"
    else
        ln -s "$KARABINER_SOURCE" "$KARABINER_TARGET"
        echo -e "${GREEN}✓ Linked: ~/.config/karabiner/karabiner.json${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Karabiner config not found${NC}"
fi

echo ""

# ==============================================================================
# STEP 4: Install packages (optional)
# ==============================================================================

if [ "$INSTALL_PACKAGES" = true ]; then
    echo -e "${GREEN}📦 Step 4: Installing essential packages...${NC}"
    echo ""

    if ! command -v brew &> /dev/null; then
        echo -e "${RED}✗ Homebrew not found. Install it first with --install-brew${NC}"
        exit 1
    fi

    echo "Installing CLI tools..."
    brew install starship git gh || true

    echo ""
    echo "Installing oh-my-zsh plugins..."

    # zsh-syntax-highlighting
    if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    fi

    # zsh-autosuggestions
    if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    fi

    echo ""
    echo -e "${GREEN}✓ Packages installed${NC}"
    echo ""
fi

# ==============================================================================
# SUMMARY
# ==============================================================================

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Dotfiles setup complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal or run: source ~/.zshenv && source ~/.zshrc"
if [ "$INSTALL_BREW" = false ]; then
    echo "  2. Install Homebrew (if not installed): bash bootstrap.sh --install-brew"
fi
if [ "$INSTALL_PACKAGES" = false ]; then
    echo "  3. Install packages: bash bootstrap.sh --install-packages"
fi
echo ""
echo "Run tests:"
echo "  bash test/test.sh"
echo ""
