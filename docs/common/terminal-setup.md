# Terminal Setup Guide

This guide covers optional terminal customization for enhanced workflow with the Neovim configuration.

## Overview

While the Neovim configuration works with any terminal, certain terminals provide enhanced features:
- **True color support**: Better syntax highlighting
- **Ligature support**: Programming font features
- **GPU acceleration**: Smoother scrolling and rendering
- **Tmux integration**: Window management and session persistence

## Terminal Options

### Option 1: Kitty (Recommended for Simplicity)

**Advantages**:
- Simple configuration
- Built-in multiplexing (no tmux needed)
- Excellent performance
- True color and ligature support
- Cross-platform

**Installation**:

**Arch Linux**:
```bash
sudo pacman -S kitty
```

**Debian/Ubuntu**:
```bash
sudo apt install kitty
```

**macOS**:
```bash
brew install kitty
```

**Configuration**:

Create or edit `~/.config/kitty/kitty.conf`:
```bash
mkdir -p ~/.config/kitty
nvim ~/.config/kitty/kitty.conf
```

Recommended settings:
```conf
# Font configuration
font_family      RobotoMono Nerd Font
font_size        12.0

# Performance
sync_to_monitor  yes
enable_audio_bell no

# Color scheme
include themes/OneDark.conf

# Key bindings
map ctrl+shift+c copy_to_clipboard
map ctrl+shift+v paste_from_clipboard
```

### Option 2: Alacritty + Tmux

**Advantages**:
- Extremely fast (GPU-accelerated)
- Minimal resource usage
- Tmux provides advanced session management
- Highly configurable

**Disadvantages**:
- Requires tmux for multiplexing
- More complex configuration

**Installation**:

**Arch Linux**:
```bash
sudo pacman -S alacritty tmux
```

**Debian/Ubuntu**:
```bash
sudo add-apt-repository ppa:aslatter/ppa -y
sudo apt install alacritty tmux
```

**macOS**:
```bash
brew install alacritty tmux
```

**Alacritty Configuration**:

Create or edit `~/.config/alacritty/alacritty.yml`:
```bash
mkdir -p ~/.config/alacritty
nvim ~/.config/alacritty/alacritty.yml
```

**Tmux Configuration**:

Copy or create tmux config:
```bash
cp ~/.config/tmux/.tmux.conf ~/.tmux.conf
# OR create custom configuration:
nvim ~/.tmux.conf
```

If using with Fish shell, update Alacritty config:
```bash
which fish  # Note the path (e.g., /usr/bin/fish)
nvim ~/.config/alacritty/alacritty.yml  # Update shell path
```

Reset tmux after configuration:
```bash
tmux kill-server  # Restart tmux with new config
```

### Option 3: WezTerm

**Advantages**:
- Built-in multiplexing
- Lua configuration (familiar for Neovim users)
- Cross-platform
- Image protocol support

**Installation**:

See [wezterm.org](https://wezfurlong.org/wezterm/) for platform-specific instructions.

## Shell Enhancement

### Fish Shell

Modern shell with improved UX:
- Better auto-completion
- Syntax highlighting
- Simpler scripting

**Installation**:

**Arch Linux**:
```bash
sudo pacman -S fish
```

**Debian/Ubuntu**:
```bash
sudo apt install fish
```

**macOS**:
```bash
brew install fish
```

**Customization**:

Install Oh My Fish framework:
```bash
curl -L https://get.oh-my.fish | fish
```

Install theme:
```bash
omf install sashimi
# OR browse themes:
omf theme
```

Remove welcome message:
```bash
set -U fish_greeting ""
```

Enable vim key bindings (optional):
```bash
fish_vi_key_bindings
# To revert:
fish_default_key_bindings
```

### Zsh

Alternative modern shell:
- Plugin ecosystem (Oh My Zsh)
- Powerful completion
- More POSIX-compliant than Fish

See platform-specific guides for Zsh setup.

## Tmux Configuration

### Basic Tmux Usage

**Key Bindings** (default prefix: `Ctrl+b`):

```bash
Ctrl+b %          # Split pane vertically
Ctrl+b "          # Split pane horizontally
Ctrl+b arrow      # Navigate between panes
Ctrl+b c          # Create new window
Ctrl+b n/p        # Next/previous window
Ctrl+b d          # Detach session
```

**Session Management**:
```bash
tmux              # Start new session
tmux ls           # List sessions
tmux attach       # Attach to last session
tmux attach -t 0  # Attach to specific session
```

### Recommended Tmux Plugins

Install tpm (Tmux Plugin Manager):
```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Add to `~/.tmux.conf`:
```bash
# Plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'  # Save/restore sessions

# Initialize plugin manager (keep at bottom)
run '~/.tmux/plugins/tpm/tpm'
```

Reload and install:
```bash
tmux source ~/.tmux.conf
# Press: Ctrl+b I (capital I) to install plugins
```

## Font Configuration

### Nerd Fonts

Required for proper icon display in Neovim.

**Arch Linux**:
```bash
sudo pacman -S ttf-roboto-mono-nerd
```

**Debian/Ubuntu**:
```bash
# Copy included fonts
sudo cp -R ~/.config/fonts/RobotoMono /usr/share/fonts/truetype/
# OR download from nerdfonts.com
```

**macOS**:
```bash
brew tap homebrew/cask-fonts
brew install font-roboto-mono-nerd-font
```

**Configure Terminal**:
Set terminal font to "RobotoMono Nerd Font Regular" in terminal settings.

## True Color Support

### Verify True Color

Test if your terminal supports true color:
```bash
curl -s https://gist.githubusercontent.com/lilydjwg/fdeaf79e921c2f413f44b6f613f6ad53/raw/94d8b2be62657e96488038b0e547e3009ed87d40/truecolor.sh | bash
```

You should see smooth color gradients.

### Enable in Neovim

Neovim automatically detects true color. If issues occur, add to init.lua:
```lua
vim.opt.termguicolors = true
```

## Troubleshooting

### Icons Not Displaying

**Issue**: Squares or missing icons in file explorer

**Solution**:
1. Verify Nerd Font installed:
   ```bash
   fc-list | grep -i roboto
   ```
2. Set terminal font to Nerd Font variant
3. Restart terminal

### Colors Look Wrong

**Issue**: Syntax highlighting appears incorrect

**Solutions**:
1. Verify true color support (see above)
2. Set terminal type:
   ```bash
   echo $TERM  # Should show "xterm-256color" or similar
   ```
3. Add to shell config:
   ```bash
   export TERM=xterm-256color
   ```

### Tmux Colors Wrong

**Issue**: Colors incorrect inside tmux

**Solution**:

Add to `~/.tmux.conf`:
```bash
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",*256col*:Tc"
```

Reload:
```bash
tmux kill-server
tmux
```

### Fish/Alacritty Integration

**Issue**: Fish shell not starting in Alacritty

**Solution**:

Edit `~/.config/alacritty/alacritty.yml`:
```yaml
shell:
  program: /usr/bin/fish  # Update path from 'which fish'
```

## Navigation

- [Back to Installation Documentation Index](../README.md)
- [Prerequisites Reference](prerequisites.md)
- [Main Installation Guide](../../nvim/docs/INSTALLATION.md)
- [Advanced Setup Guide](../../nvim/docs/ADVANCED_SETUP.md)
