# Mai's Dotfiles

Version-controlled configuration files and a setup script designed to quickly bootstrap a new macOS development machine.

## 📦 What's Included

- **Shell Configuration**: zsh setup with oh-my-zsh, custom aliases, and environment variables
- **Window Management**: Aerospace configuration
- **Keyboard Customization**: Karabiner-Elements configuration
- **Terminal**: Hammerspoon scripts
- **Launcher**: Raycast configuration

## 🔧 Requirements

- macOS (tested on macOS 15+)
- Git

## 🚀 Quick Start (New Machine)

```bash
# 1. Install Xcode Command Line Tools (required for git)
xcode-select --install

# 2. Clone this repo
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/code/dotfiles
# Or if you prefer: git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/eng/src/dotfiles

# 3. Run the bootstrap script
cd ~/code/dotfiles
bash bootstrap.sh

# 4. Restart your terminal or source the config
source ~/.zshenv && source ~/.zshrc

# 5. Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 6. Install essential packages
brew install starship           # Better terminal prompt
brew install --cask karabiner-elements  # Keyboard customization
brew install --cask hammerspoon         # Automation
brew install --cask raycast             # Launcher
brew install --cask aerospace           # Window manager
```

## 📝 Configuration Files Structure

```
dotfiles/
├── bootstrap.sh              # Setup script
├── README.md                 # This file
│
├── zshenv                    # → ~/.zshenv (Homebrew, Cargo)
├── zprofile                  # → ~/.zprofile (User binaries)
├── profile                   # → ~/.profile (Generic shell config)
│
├── zshrc/                    # → ~/.config/zshrc/
│   └── .zshrc                # Main zsh configuration
│
├── aerospace/                # → ~/.config/aerospace/
│   └── aerospace.toml
│
├── karabiner/                # → ~/.config/karabiner/karabiner.json
│   └── karabiner.json
│
├── hammerspoon/              # → ~/.config/hammerspoon/
│   └── init.lua
│
└── raycast/                  # → ~/.config/raycast/
    └── ...
```

## 🔄 How It Works

The `bootstrap.sh` script:

1. **Links shell configs to home directory**:
   - `zshenv` → `~/.zshenv` (loaded for all shells)
   - `zprofile` → `~/.zprofile` (loaded for login shells)
   - `profile` → `~/.profile` (generic profile)

2. **Creates `~/.zshrc`** that sources `~/.config/zshrc/.zshrc`

3. **Symlinks config folders** to `~/.config/`:
   - `aerospace/` → `~/.config/aerospace/`
   - `zshrc/` → `~/.config/zshrc/`
   - `hammerspoon/` → `~/.config/hammerspoon/`
   - `raycast/` → `~/.config/raycast/`

4. **Special handling for Karabiner**: Links the individual `karabiner.json` file

5. **Optionally links iCloud**: `~/cloud` → iCloud Drive

## 🔍 Shell Configuration Loading Order

When you open a new terminal (login shell):

```
1. /etc/zshenv
2. ~/.zshenv          ← Homebrew, Cargo (base tools)
3. ~/.zprofile        ← User binaries (like ~/.local/bin)
4. ~/.zshrc           ← Sources ~/.config/zshrc/.zshrc
   └─→ ~/.config/zshrc/.zshrc  ← Main config (oh-my-zsh, aliases, PATH additions)
```

### Why This Structure?

- **`~/.zshenv`**: Loaded by ALL shells (including scripts). Keep it minimal.
- **`~/.zprofile`**: Loaded only for login shells. Good for PATH additions.
- **`~/.zshrc`**: Loaded for interactive shells. Contains aliases, functions, prompt.
- **`~/.config/zshrc/.zshrc`**: Actual configuration, kept in dotfiles repo.

## 🛠️ Customization

### Adding New Configurations

1. Add config folder to `~/code/dotfiles/`
2. Run `bash bootstrap.sh` to create symlinks
3. Commit and push to your repo

### Excluding Files

Edit the `EXCLUDES` array in `bootstrap.sh`:

```bash
EXCLUDES=("bootstrap.sh" ".git" ".gitignore" "README.md" "zshenv" "zprofile" "profile")
```

## 📦 Essential Packages to Install

After running bootstrap:

```bash
# Terminal & Shell
brew install starship           # Modern prompt
brew install zsh-syntax-highlighting
brew install zsh-autosuggestions

# Development
brew install git
brew install gh                 # GitHub CLI
brew install node
brew install python

# Productivity Apps
brew install --cask karabiner-elements
brew install --cask hammerspoon
brew install --cask raycast
brew install --cask aerospace
brew install --cask claude-code
```

## 🔐 Security Notes

- This repo does NOT include:
  - SSH keys
  - AWS credentials
  - API tokens
- Keep sensitive data in `~/.ssh/`, `~/.aws/credentials`, etc.
- Never commit secrets to this repo

## 🆕 Updating Dotfiles

### On Your Main Machine

```bash
cd ~/code/dotfiles

# Update config files
cp ~/.config/zshrc/.zshrc zshrc/.zshrc
cp ~/.zshenv zshenv
# ... etc

# Commit and push
git add .
git commit -m "Update configurations"
git push
```

### On Other Machines

```bash
cd ~/code/dotfiles
git pull
bash bootstrap.sh  # Re-run to update symlinks if needed
```

## 🐛 Troubleshooting

### Commands not found after setup

```bash
# Reload shell configuration
source ~/.zshenv && source ~/.zshrc

# Or restart your terminal
```

### Homebrew not found

```bash
# Add to ~/.zshenv
eval "$(/opt/homebrew/bin/brew shellenv)"  # Apple Silicon
# or
eval "$(/usr/local/bin/brew shellenv)"     # Intel Mac
```

### PATH not working

Check the order:
```bash
echo $PATH | tr ":" "\n"
```

### Starship not found

```bash
brew install starship
```

## 📚 References

- [Zsh Documentation](https://zsh.sourceforge.io/Doc/)
- [Oh My Zsh](https://ohmyz.sh/)
- [Starship Prompt](https://starship.rs/)
- [Homebrew](https://brew.sh/)

---

Made with ❤️ by Mai
