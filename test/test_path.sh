#!/bin/bash
# Test PATH configuration

test_path() {
    print_header "🛤️  PATH Configuration Tests"
    echo ""

    # Get PATH from a fresh zsh shell
    local test_path=$(zsh -c 'source ~/.zshenv && source ~/.zprofile && source ~/.zshrc && echo $PATH')

    # Test: Homebrew in PATH
    assert_contains "Homebrew in PATH" "$test_path" "/opt/homebrew/bin"

    # Test: ~/.local/bin in PATH
    assert_contains "~/.local/bin in PATH" "$test_path" "$HOME/.local/bin"

    # Test: Cargo in PATH
    assert_contains "Cargo in PATH" "$test_path" ".cargo/bin"

    # Test: No duplicate paths
    local path_count=$(echo "$test_path" | tr ':' '\n' | sort | uniq -d | wc -l)
    assert_equals "No duplicate paths in PATH" "0" "$(echo $path_count | xargs)"

    # Test: No unexpanded ~ in PATH
    assert_not_contains "No unexpanded ~ in PATH" "$test_path" ":~"
    assert_not_contains "No unexpanded ~ in PATH (start)" "$test_path" "~/"
}

test_path
