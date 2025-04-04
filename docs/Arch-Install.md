# Arch Linux Installation Guide

This guide provides detailed instructions for installing the NeoTex Neovim configuration on Arch Linux, including all necessary dependencies, LaTeX tools, and optional enhancements.

## Dependencies Installation

First, ensure your system is up to date:

```bash
sudo pacman -Syu
```

### Core Dependencies

Check Python installation:

```bash
python3 --version
```

If not installed:

```bash
sudo pacman -S python
```

Install Neovim and essential tools:

```bash
sudo pacman -S neovim
sudo pacman -S git
sudo pacman -S lazygit
sudo pacman -S fzf
sudo pacman -S ripgrep
sudo pacman -S pandoc
sudo pacman -S pandoc-crossref texlive-latex texlive-latexextra texlive-latexrecommended
sudo pacman -S nodejs
sudo pacman -S npm
sudo pacman -S stylua
sudo pacman -S lua-language-server
sudo pacman -S wget
sudo pacman -S xsel
sudo pacman -S neovim-remote
```

### Check Neovim Health

Open Neovim and run:

```
:checkhealth
```

If Python 3 reports errors:

```bash
pip3 install --user pynvim
```

Troubleshoot any other errors following the advice provided by checkhealth.

## Nerd Fonts Installation

Install RobotoMono Nerd Font:

```bash
sudo pacman -S ttf-roboto-mono-nerd
```

For stock terminal users, change the font to RobotoMono regular in terminal settings.

## LaTeX Installation

Check if LaTeX is already installed:

```bash
latexmk --version
```

To install LaTeX:

```bash
sudo pacman -S texlive
```

Accept all packages in this group and follow the installation prompts. After installation, verify with:

```bash
latexmk --version
```

## PDF Viewer Setup

### Zathura (Recommended)

Install Zathura:

```bash
sudo pacman -S zathura
```

Customize Zathura (optional):

```bash
mkdir -p ~/.config/zathura
nvim ~/.config/zathura/zathurarc
```

For reference documentation:

```bash
man zathurarc
```

### Okular (Alternative)

For an alternative PDF viewer:

```bash
sudo pacman -S okular
```

To use Okular with VimTeX, edit:

```bash
nvim ~/.config/nvim/lua/neotex/plugins/vimtex.lua
```

Replace any PDF viewer references with 'zathura' or 'okular' based on your preference.

## Configuration Setup

### Fork the Configuration (Recommended)

1. Create a GitHub account if you don't have one
2. Visit https://github.com/benbrastmckie/.config
3. Click "Fork" in the top right corner
4. Set yourself as the owner
5. Click "Create fork"

### Clone the Configuration

```bash
cd ~/.config
git init
git remote add origin YOUR_OR_MY_FORK_ADDRESS
git pull origin master
```

### Initialize Plugins

Open Neovim to automatically install plugins:

```bash
nvim
```

Wait for Lazy to finish installing plugins, then exit and reopen:

```
:checkhealth
```

## Zotero Integration

### Install Zotero

```bash
# Download Zotero tarball from zotero.org
sudo mv ~/Downloads/Zotero_linux-x86_64 /opt/zotero
cd /opt/zotero
sudo ./set_launcher_icon
sudo ln -s /opt/zotero/zotero.desktop ~/.local/share/applications/zotero.desktop
```

### Install Better BibTeX Plugin

1. Download the latest release from [here](https://retorque.re/zotero-better-bibtex/installation/)
2. In Zotero, go to Tools > Add-ons
3. Click the gear icon and select "Install Add-on From File"
4. Navigate to the downloaded .xpi file

### Configure Better BibTeX

1. In Zotero, go to Edit > Preferences > Better BibTeX
2. Set citation key format to `[auth][year]`
3. Go to Edit > Preferences > Sync and set up your account or create one
4. Check 'On item change' at the bottom left
5. Switch to the 'Automatic Export' tab and check 'On Change'

### Create Bibliography Directory

```bash
mkdir -p ~/texmf/bibtex/bib
cp -R ~/.config/latex/bst ~/texmf/bibtex
```

### Export Library

1. In Zotero, right-click your library folder
2. Select "Export Library"
3. Choose "Better BibTeX" format and check "Keep Updated"
4. Save as "Zotero.bib" to ~/texmf/bibtex/bib

## Terminal Setup (Optional)

### Option 1: Kitty (Recommended for simplicity)

```bash
sudo pacman -S kitty
```

Customize Kitty (optional):
```bash
mkdir -p ~/.config/kitty
nvim ~/.config/kitty/kitty.conf
```

### Option 2: Alacritty + Tmux

```bash
sudo pacman -S alacritty
sudo pacman -S tmux
cp ~/.config/tmux/.tmux.conf ~/.tmux.conf
```

## Fish Shell (Optional)

Install Fish:

```bash
sudo pacman -S fish
```

Customize Fish:

```bash
curl -L https://get.oh-my.fish | fish
omf install sashimi
```

Remove welcome message:

```bash
set -U fish_greeting ""
```

If using Alacritty with Tmux:

```bash
which fish  # Note the path
nvim ~/.config/alacritty/alacritty.yml  # Update fish path if needed
tmux kill-server  # Reset Tmux
```

Enable vim key bindings (optional):

```bash
fish_vi_key_bindings
```

## Git Configuration

### Set Username and Email

```bash
git config --global user.name "YOUR-USERNAME"
git config --global user.email "YOUR-EMAIL"
```

### Add SSH Key to GitHub

Generate an SSH key:

```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

Start the SSH agent:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
```

Copy the SSH key:

```bash
sudo pacman -S xclip  # Install xclip if needed
xclip -sel clip < ~/.ssh/id_rsa.pub
```

Add the key to your GitHub account:
1. Go to GitHub > Profile > Settings > SSH and GPG Keys
2. Click "New SSH Key"
3. Paste your key and save

If your SSH key stops working after reboot:

```bash
ssh-add ~/.ssh/id_rsa
```

### Add Personal Access Token

1. Create a token at GitHub.com > Settings > Developer settings > Personal Access Tokens
2. Set no expiration date
3. Select "repo" scope
4. Copy the token and save it temporarily
5. Configure Git to remember credentials:

```bash
git config --global credential.helper cache
```

## Key Remapping (Optional)

For better ergonomics with xorg:

```bash
sudo pacman -S xorg-xmodmap
sudo pacman -S xorg-xev
sudo pacman -S xorg-setxkbmap
```

Test key codes:

```bash
xev | awk -F'[ )]+' '/^KeyPress/ { a[NR+2] } NR in a { printf "%-3s %s\n", $5, $8 }'
```

Create or edit your .Xmodmap file:

```bash
cp ~/.config/.XmodmapMAC ~/.Xmodmap  # If key codes match
# OR
nvim ~/.Xmodmap  # To create custom mappings
```

Test your mappings:

```bash
xmodmap ~/.Xmodmap
```

Make mappings permanent:

```bash
cp ~/.Xmodmap ~/.Xmodmap
cp ~/.config/.xmodmap.desktop ~/.config/autostart/
```

Reset to defaults if needed:

```bash
setxkbmap
```

## Verification

Test your setup by:

1. Opening NeoVim
2. Creating a new LaTeX file with `<space>tp`
3. Building with `<space>b` to ensure PDF generation works
4. Using `<space>fc` to verify citation search works
5. Running `:checkhealth` to confirm all systems are operational

## Troubleshooting

### Common Issues

1. **Missing icons**: Ensure nerd font is correctly installed and configured in terminal
2. **PDF viewer not working**: Check Zathura/Okular installation and paths
3. **LaTeX compilation fails**: Verify texlive installation and run `latexmk --version`
4. **Zotero integration issues**: Check bibliography path and run `:VimtexClearCache kpsewhich`
5. **Strange characters in terminal**: Confirm terminal is using a nerd font

For further assistance, open an issue on the GitHub repository.