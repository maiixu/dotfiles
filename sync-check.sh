#!/usr/bin/env zsh
# Check if dotfiles repo is in sync with home directory

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detect script directory
SCRIPT_DIR="${0:A:h}"
DOTFILES_DIR="$SCRIPT_DIR"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 Dotfiles Sync Check${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

ALL_SYNCED=true

# Check shell config files
echo -e "${YELLOW}Checking shell configuration files...${NC}"
echo ""

check_file() {
    local source_name=$1
    local target_name=$2
    local source_path="$DOTFILES_DIR/$source_name"
    local target_path="$HOME/$target_name"

    if [[ ! -f "$source_path" ]]; then
        echo -e "${RED}✗${NC} $source_name missing in dotfiles repo"
        ALL_SYNCED=false
        return
    fi

    if [[ ! -e "$target_path" ]]; then
        echo -e "${RED}✗${NC} ~/$target_name does not exist"
        ALL_SYNCED=false
        return
    fi

    # Check if it's a symlink
    if [[ -L "$target_path" ]]; then
        local link_target=$(readlink "$target_path")
        if [[ "$link_target" == "$source_path" ]]; then
            echo -e "${GREEN}✓${NC} ~/$target_name → symlinked correctly"
        else
            echo -e "${YELLOW}⚠${NC}  ~/$target_name → symlinked to: $link_target (expected: $source_path)"
            ALL_SYNCED=false
        fi
    else
        # Not a symlink, compare content
        if diff -q "$source_path" "$target_path" > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} ~/$target_name → content matches"
        else
            echo -e "${RED}✗${NC} ~/$target_name → content differs from $source_name"
            echo -e "  ${YELLOW}Run: diff $source_path $target_path${NC}"
            ALL_SYNCED=false
        fi
    fi
}

check_file "zshenv" ".zshenv"
check_file "zprofile" ".zprofile"
check_file "gitconfig" ".gitconfig"
check_file "zshrc/.zshrc" ".zshrc"

echo ""

# Check config directories
echo -e "${YELLOW}Checking config directories...${NC}"
echo ""

check_dir() {
    local dir=$1
    local source_dir="$DOTFILES_DIR/$dir"
    local target_dir="$HOME/.config/$dir"

    if [[ ! -d "$source_dir" ]]; then
        echo -e "${RED}✗${NC} $dir missing in dotfiles repo"
        ALL_SYNCED=false
        return
    fi

    if [[ ! -e "$target_dir" ]]; then
        echo -e "${RED}✗${NC} ~/.config/$dir does not exist"
        ALL_SYNCED=false
        return
    fi

    # Check if it's a symlink
    if [[ -L "$target_dir" ]]; then
        local link_target=$(readlink "$target_dir")
        if [[ "$link_target" == "$source_dir" ]]; then
            echo -e "${GREEN}✓${NC} ~/.config/$dir → symlinked correctly"
        else
            echo -e "${YELLOW}⚠${NC}  ~/.config/$dir → symlinked to: $link_target (expected: $source_dir)"
            ALL_SYNCED=false
        fi
    else
        echo -e "${YELLOW}⚠${NC}  ~/.config/$dir → NOT a symlink (copying files manually?)"
        ALL_SYNCED=false
    fi
}

check_dir "zshrc"
check_dir "aerospace"
check_dir "karabiner"
check_dir "git"

# Hammerspoon lives at ~/.hammerspoon, not ~/.config/hammerspoon
if [[ -L "$HOME/.hammerspoon" ]] && [[ "$(readlink $HOME/.hammerspoon)" == "$DOTFILES_DIR/hammerspoon" ]]; then
    echo -e "${GREEN}✓${NC} ~/.hammerspoon → symlinked correctly"
else
    echo -e "${YELLOW}⚠${NC}  ~/.hammerspoon → not symlinked to dotfiles"
    ALL_SYNCED=false
fi

echo ""

# Check git status
echo -e "${YELLOW}Checking git status...${NC}"
echo ""

cd "$DOTFILES_DIR"

if ! git diff --quiet 2>/dev/null; then
    echo -e "${YELLOW}⚠${NC}  Uncommitted changes in dotfiles repo:"
    git diff --name-only | sed 's/^/  /'
    ALL_SYNCED=false
else
    echo -e "${GREEN}✓${NC} No uncommitted changes"
fi

if ! git diff --cached --quiet 2>/dev/null; then
    echo -e "${YELLOW}⚠${NC}  Staged but not committed changes:"
    git diff --cached --name-only | sed 's/^/  /'
    ALL_SYNCED=false
else
    echo -e "${GREEN}✓${NC} No staged changes"
fi

# Check if there are untracked files
untracked=$(git ls-files --others --exclude-standard 2>/dev/null)
if [[ -n "$untracked" ]]; then
    echo -e "${YELLOW}⚠${NC}  Untracked files in dotfiles repo:"
    echo "$untracked" | sed 's/^/  /'
    ALL_SYNCED=false
else
    echo -e "${GREEN}✓${NC} No untracked files"
fi

echo ""

# Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [[ "$ALL_SYNCED" == "true" ]]; then
    echo -e "${GREEN}✅ Everything is in sync!${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}❌ Some issues found${NC}"
    echo ""
    echo "To fix:"
    echo "  1. If files differ: cp ~/.config/zshrc/.zshrc ~/code/dotfiles/zshrc/.zshrc"
    echo "  2. If not symlinked: bash bootstrap.sh"
    echo "  3. If uncommitted: git add . && git commit -m 'Update configs'"
    echo ""
    exit 1
fi
