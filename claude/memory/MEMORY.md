# Memory for Mai's Development Environment

## Shell and Dotfiles

- Shell: zsh
- Dotfiles: `~/code/dotfiles/` via symlinks
- Test suite: `cd ~/code/dotfiles && bash test/test.sh` (21 tests)
- Consistency check: `cd ~/code/dotfiles && zsh sync-check.sh`

## Environment

- `rm` is aliased to `trash` (moves to macOS Trash, not permanent delete)
- `rmf` = permanent delete
- User binaries: `~/.local/bin/`
- Prompt: Starship, package manager: Homebrew
- oh-my-zsh plugins: git, zsh-syntax-highlighting, zsh-autosuggestions

## AWS

- Default profile: `bedrock-claude` (us-west-2), set via `AWS_PROFILE` in zshrc

## Things 3

**Delegation rule: ALL Things 3 operations must go through the `things` subagent. Never call the scripts or URL scheme directly from main session.**

- Week = Saturday → Friday; EOW = coming Friday
- EOW → this Friday, EOM → last Friday of month, EOQ → last Friday of quarter
- Use `deadline` field (not `when`) for all EOW/EOM/EOQ anchors
- Invoke the things agent proactively when conversation produces actionable next steps
