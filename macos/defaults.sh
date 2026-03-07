#!/bin/bash
# macOS defaults
# Run this script to apply macOS system settings.
# Safe to re-run — all settings are idempotent.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true; shift ;;
        --help)
            echo "Usage: bash macos/defaults.sh [--dry-run]"
            echo ""
            echo "  --dry-run    Print commands without executing them"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

run() {
    if [ "$DRY_RUN" = true ]; then
        echo "  [dry-run] $*"
    else
        "$@"
    fi
}

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  macOS Defaults${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ==============================================================================
# KEYBOARD BEHAVIOR
# ==============================================================================

echo -e "${GREEN}[1/4] Keyboard behavior...${NC}"

# Hold fn key to use F1, F2, etc. as standard function keys
run defaults write NSGlobalDomain "com.apple.keyboard.fnState" -bool true

# Key repeat: how fast keys repeat when held down (lower = faster, min 1)
run defaults write NSGlobalDomain KeyRepeat -int 2

# Delay before key repeat starts (lower = shorter delay, min 15)
run defaults write NSGlobalDomain InitialKeyRepeat -int 25

# Disable automatic capitalization
run defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable smart dashes
run defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable automatic period substitution (double-space -> period)
run defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable smart quotes
run defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable auto-correct
run defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

echo -e "${GREEN}  done${NC}"
echo ""

# ==============================================================================
# TEXT REPLACEMENT
# ==============================================================================
# Format: replace = "shortcut you type"; with = "text that replaces it"
# Tip: use \U prefix for Unicode, e.g., shrug -> ¯\_(ツ)_/¯

echo -e "${GREEN}[2/4] Text replacement...${NC}"

run defaults write NSGlobalDomain NSUserReplacementItems -array \
    '{ replace = "@email"; with = "maizehsu02@gmail.com"; }' \
    '{ replace = "->"; with = "→"; }' \
    '{ replace = "<-"; with = "←"; }'

# To clear all text replacements, run:
#   defaults delete NSGlobalDomain NSUserReplacementItems

echo -e "${GREEN}  done${NC}"
echo ""

# ==============================================================================
# KEYBOARD SHORTCUTS (com.apple.symbolichotkeys)
# ==============================================================================
# Each shortcut has an ID. Key IDs:
#   60  = Screenshot: Save to clipboard (Cmd+Ctrl+Shift+3)
#   61  = Screenshot: Save selected area to file (Cmd+Shift+4)
#   62  = Screenshot: Copy selected area to clipboard (Cmd+Ctrl+Shift+4)
#   64  = Spotlight search
#   79  = Select previous input source (switch language)
#   80  = Select next input source in menu
#   81  = (input source related)
#   82  = (input source related)
#   118 = Switch to Space 1
#   119 = Switch to Space 2
#   160 = Launchpad
#   162 = Mission Control
#   163 = Application windows
#   164 = Show Desktop

echo -e "${GREEN}[3/4] Keyboard shortcuts...${NC}"

# Input source switching (keep enabled — needed for Chinese input)
run defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 79 \
    '<dict><key>enabled</key><true/></dict>'
run defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 80 \
    '<dict><key>enabled</key><true/></dict>'
run defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 81 \
    '<dict><key>enabled</key><true/></dict>'
run defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 82 \
    '<dict><key>enabled</key><true/></dict>'

# Show Desktop (disabled — conflicts with window manager)
run defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 164 \
    '<dict>
        <key>enabled</key><false/>
        <key>value</key><dict>
            <key>parameters</key><array>
                <integer>65535</integer>
                <integer>65535</integer>
                <integer>0</integer>
            </array>
            <key>type</key><string>standard</string>
        </dict>
    </dict>'

# Spotlight (disabled — replaced by Raycast or Alfred)
# Uncomment to disable:
# run defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 \
#     '<dict><key>enabled</key><false/></dict>'

echo -e "${GREEN}  done${NC}"
echo ""

# ==============================================================================
# APP SHORTCUTS (NSUserKeyEquivalents)
# ==============================================================================
# Assign keyboard shortcuts to menu items across all apps.
# Format: "Menu Item Name" = "key"
#   @ = Cmd, $ = Shift, ^ = Ctrl, ~ = Option
#   e.g. "@$," = Cmd+Shift+,

echo -e "${GREEN}[4/4] App shortcuts...${NC}"

# Cmd+Shift+, → Open System Settings (via Apple menu item)
# Note: the "…" is a unicode ellipsis (U+2026), not three dots
run defaults write NSGlobalDomain NSUserKeyEquivalents \
    -dict-add "System Settings\U2026" "@\$,"

echo -e "${GREEN}  done${NC}"
echo ""

# ==============================================================================
# APPLY CHANGES
# ==============================================================================

if [ "$DRY_RUN" = false ]; then
    echo "Restarting affected services..."

    # Apply symbolic hotkeys changes
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  Done. Some changes may require a logout/login.${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
else
    echo -e "${YELLOW}Dry run complete. No changes were made.${NC}"
fi
