#!/bin/bash
# Test environment variables

test_env_vars() {
    print_header "🌍 Environment Variables Tests"
    echo ""

    # Get env vars from a fresh zsh shell
    local aws_profile=$(zsh -c 'source ~/.zshenv && source ~/.zprofile && source ~/.zshrc && echo $AWS_PROFILE')

    # Test: AWS_PROFILE is set
    assert_equals "AWS_PROFILE is set to bedrock-claude" "bedrock-claude" "$aws_profile"

    # Test: ZSH is set
    local zsh_var=$(zsh -c 'source ~/.zshrc && echo $ZSH')
    assert_contains "ZSH variable is set" "$zsh_var" ".oh-my-zsh"
}

test_env_vars
