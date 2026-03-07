#!/bin/bash
# Test shell configuration loading

test_shell_loading() {
    print_header "🐚 Shell Configuration Loading Tests"
    echo ""

    # Test: ~/.zshenv exists
    assert_file_exists "~/.zshenv exists" "$HOME/.zshenv"

    # Test: ~/.zprofile exists
    assert_file_exists "~/.zprofile exists" "$HOME/.zprofile"

    # Test: ~/.zshrc exists
    assert_file_exists "~/.zshrc exists" "$HOME/.zshrc"

    # Test: ~/.config/zshrc/.zshrc exists
    assert_file_exists "~/.config/zshrc/.zshrc exists" "$HOME/.config/zshrc/.zshrc"

    # Test: zshenv loads in non-login shell
    local zshenv_output=$(zsh -c 'echo $PATH')
    assert_contains "Homebrew in PATH (non-login shell)" "$zshenv_output" "homebrew"

    # Test: No bash files (after refactor)
    # Commenting out for now, will uncomment after refactor
    # assert_success "~/.bashrc should not exist" "[ ! -f $HOME/.bashrc ]"
    # assert_success "~/.bash_profile should not exist" "[ ! -f $HOME/.bash_profile ]"
}

test_shell_loading
