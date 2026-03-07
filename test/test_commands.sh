#!/bin/bash
# Test command availability

test_commands() {
    print_header "⚙️  Command Availability Tests"
    echo ""

    # Test in a fresh zsh shell environment

    # Test: brew command
    assert_success "brew command available" "zsh -c 'source ~/.zshenv && command -v brew'"

    # Test: git command
    assert_success "git command available" "command -v git"

    # Test: zsh command
    assert_success "zsh command available" "command -v zsh"

    # Test: cargo command (if Cargo is installed)
    if [ -d "$HOME/.cargo" ]; then
        assert_success "cargo command available" "zsh -c 'source ~/.zshenv && command -v cargo'"
    fi

    # Test: starship command (if installed)
    if command -v starship &> /dev/null; then
        assert_success "starship command available" "zsh -c 'source ~/.zshenv && command -v starship'"
    fi

    # Test: claude command (if installed)
    if [ -f "$HOME/.local/bin/claude" ]; then
        assert_success "claude command available" "zsh -c 'source ~/.zshenv && source ~/.zprofile && command -v claude'"
    fi

    # Test: Aliases are loaded
    local alias_check=$(zsh -c 'source ~/.zshrc && alias l')
    assert_contains "Alias 'l' is defined" "$alias_check" "ls -a"
}

test_commands
