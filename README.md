# Mai's Dotfiles

Clean, tested, and automated shell configuration for macOS with full test coverage.

## ✨ Features

- **✅ Fully Tested**: 21 automated tests ensure everything works
- **🚀 One-Command Setup**: Bootstrap script with auto-install options
- **🔄 No Duplicates**: Smart PATH management prevents duplicates
- **🧹 Clean Structure**: Clear separation between base, user, and session configs
- **📦 Auto-Install**: Optional Homebrew and package installation

## 📦 What's Included

- **Shell**: zsh with oh-my-zsh, custom aliases, and clean PATH
- **Window Management**: Aerospace configuration
- **Keyboard**: Karabiner-Elements configuration
- **Terminal**: Starship prompt
- **AWS**: Bedrock Claude profile by default

## 🔧 Requirements

- macOS (tested on macOS 15+)
- Git (comes with macOS Command Line Tools)

## 🚀 Quick Start (New Machine)

```bash
# 1. Install Command Line Tools
xcode-select --install

# 2. Clone this repo
git clone https://github.com/maiixu/dotfiles.git ~/code/dotfiles
cd ~/code/dotfiles

# 3. Run bootstrap with auto-install (recommended for new machines)
bash bootstrap.sh --install-brew --install-packages

# OR minimal setup (just link configs)
bash bootstrap.sh

# 4. Restart your terminal
```

That's it! Everything is configured and tested.

## 🧪 Testing

Run the test suite to verify your configuration:

```bash
cd ~/code/dotfiles
bash test/test.sh
```

Tests check:
- ✅ Shell configuration files exist and load correctly
- ✅ No duplicate paths in PATH
- ✅ No unexpanded `~` in PATH
- ✅ Environment variables are set correctly
- ✅ Commands (brew, cargo, claude) are available
- ✅ Aliases work

## 📝 Configuration Structure

```
dotfiles/
├── bootstrap.sh              # Smart setup script with auto-install
├── test/                     # Test suite (21 tests)
│   ├── test.sh
│   ├── test_shell_loading.sh
│   ├── test_path.sh
│   ├── test_env_vars.sh
│   └── test_commands.sh
│
├── zshenv                    # → ~/.zshenv (base: Homebrew, Cargo)
├── zprofile                  # → ~/.zprofile (user: ~/.local/bin, apps)
│
├── zshrc/                    # → ~/.config/zshrc/
│   └── .zshrc                # Main config (oh-my-zsh, aliases, PATH, env vars)
│
├── aerospace/                # → ~/.config/aerospace/
│   └── aerospace.toml
│
└── karabiner/                # → ~/.config/karabiner/karabiner.json
    └── karabiner.json
```

## 🔍 Shell Loading Order

Understanding how shell configs load:

```
When opening a new terminal (login shell):

1. ~/.zshenv           ← Base tools (Homebrew, Cargo)
                         Loaded for ALL shells (including scripts)

2. ~/.zprofile         ← User tools (~/.local/bin, apps)
                         Loaded for login shells only

3. ~/.zshrc            ← Loads ~/.config/zshrc/.zshrc

4. ~/.config/zshrc/.zshrc  ← Main config
                              - oh-my-zsh
                              - Aliases & functions
                              - Development tools (Go, Maven, pnpm, etc.)
                              - Environment variables (AWS_PROFILE, LEDGER_FILE)
                              - Starship prompt
```

### Design Principles

1. **No Duplicates**: Smart functions check if paths exist before adding
2. **No Unexpanded Tildes**: All `~` expanded to `$HOME`
3. **Layer Separation**: Base → User → Session
4. **Zsh Only**: No bash configs, clean slate

## 🛠️ Bootstrap Options

```bash
# Minimal setup (just link configs)
bash bootstrap.sh

# Install Homebrew if missing
bash bootstrap.sh --install-brew

# Install Homebrew + essential packages
bash bootstrap.sh --install-brew --install-packages

# See all options
bash bootstrap.sh --help
```

### What --install-packages Installs

- `starship` - Modern terminal prompt
- `git` - Version control
- `gh` - GitHub CLI
- `zsh-syntax-highlighting` - Syntax highlighting for zsh
- `zsh-autosuggestions` - Fish-like autosuggestions

## 🔄 Updating Dotfiles

### On Your Main Machine

```bash
cd ~/code/dotfiles

# Your configs are symlinked, so they're always in sync!
# Just commit and push when you make changes:

git add .
git commit -m "Update configurations"
git push
```

### On Other Machines

```bash
cd ~/code/dotfiles
git pull
# Configs are automatically updated (they're symlinked!)
```

## 🆕 Adding New Configurations

1. Add config file/folder to `~/code/dotfiles/`
2. Run `bash bootstrap.sh` (idempotent, safe to rerun)
3. Test with `bash test/test.sh`
4. Commit and push

## 🧹 What Was Cleaned Up

Compared to typical dotfiles:

- ❌ Removed `.bash_profile` (unused)
- ❌ Removed `.bashrc` (unused)
- ❌ Removed `.profile` (merged into zsh configs)
- ❌ Removed duplicate PATH entries
- ❌ Removed unexpanded `~` paths
- ✅ Added test coverage
- ✅ Added smart PATH management
- ✅ Added auto-install options

## 📚 Key Files Explained

### ~/.zshenv
```bash
# Homebrew (all shells need this)
eval "$(/opt/homebrew/bin/brew shellenv)"

# Cargo (Rust toolchain)
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

# Clean up PATH: expand ~ to $HOME
if [[ "$PATH" == *"~"* ]]; then
    export PATH="${PATH//\~/$HOME}"
fi
```

### ~/.zprofile
```bash
# User binaries (claude, pipx, etc.)
add_to_path_if_missing "$HOME/.local/bin"

# Applications
add_to_path_if_missing "/Applications/Obsidian.app/Contents/MacOS"
```

### ~/.config/zshrc/.zshrc
Well-organized with sections:
- Helper functions (smart PATH management)
- oh-my-zsh configuration
- Aliases
- Functions
- Development tools PATH (Go, Maven, pnpm, conda, etc.)
- Environment variables (AWS_PROFILE, LEDGER_FILE)
- Starship prompt

## 🔐 Security

This repo does NOT include:
- SSH keys
- AWS credentials (uses profile names only)
- API tokens
- Passwords

Keep sensitive data in `~/.ssh/`, `~/.aws/credentials`, etc.

## 🐛 Troubleshooting

### Commands not found after setup

```bash
# Reload shell configuration
source ~/.zshenv && source ~/.zshrc

# Or restart your terminal
```

### Run tests to diagnose

```bash
cd ~/code/dotfiles
bash test/test.sh
```

Tests will show exactly what's wrong:
- Missing files
- Duplicate paths
- Unexpanded variables
- Missing commands

### PATH issues

```bash
# Check for duplicates
echo $PATH | tr ':' '\n' | sort | uniq -c | sort -rn

# Check for unexpanded ~
echo $PATH | grep '~'
```

## 🎯 Design Goals

1. **Testable**: Every config change is verified by tests
2. **Idempotent**: Safe to run bootstrap multiple times
3. **Clean**: No duplicates, no unexpanded paths, no dead code
4. **Fast**: Minimal overhead, smart path checking
5. **Portable**: Works on any Mac, auto-installs dependencies

## 🤝 Contributing

This is a personal dotfiles repo, but feel free to:
- Fork it for your own use
- Open issues if you find bugs
- Suggest improvements

## 📖 Learning Resources

- [Zsh Documentation](https://zsh.sourceforge.io/Doc/)
- [Oh My Zsh](https://ohmyz.sh/)
- [Starship Prompt](https://starship.rs/)
- [Homebrew](https://brew.sh/)

---

**Test Coverage**: 21/21 tests passing ✅
**Last Updated**: 2026-03-07
**Maintained by**: Mai Xu
