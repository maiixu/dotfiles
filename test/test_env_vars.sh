#!/bin/bash
# Test environment variables

test_env_vars() {
    print_header "🌍 Environment Variables Tests"
    echo ""

    # Get env vars from a fresh zsh shell
    local aws_profile=$(zsh -c 'source ~/.zshenv && source ~/.zprofile && source ~/.zshrc && echo $AWS_PROFILE')
    local ledger_file=$(zsh -c 'source ~/.zshenv && source ~/.zprofile && source ~/.zshrc && echo $LEDGER_FILE')

    # Test: AWS_PROFILE is set
    assert_equals "AWS_PROFILE is set to bedrock-claude" "bedrock-claude" "$aws_profile"

    # Test: LEDGER_FILE is set
    assert_contains "LEDGER_FILE is set" "$ledger_file" "hledger"

    # Test: LEDGER_FILE has no unexpanded ~
    assert_not_contains "LEDGER_FILE has no unexpanded ~" "$ledger_file" "~/"

    # Test: ZSH is set
    local zsh_var=$(zsh -c 'source ~/.zshrc && echo $ZSH')
    assert_contains "ZSH variable is set" "$zsh_var" ".oh-my-zsh"
}

test_env_vars
