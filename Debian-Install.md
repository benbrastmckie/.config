# Debian Linux Installation Guide

This guide provides detailed instructions for installing the NeoTex Neovim configuration on Debian and Ubuntu-based systems, including all necessary dependencies, LaTeX tools, and optional enhancements.

## Dependencies Installation

First, ensure your system is up to date:

```bash
sudo apt update && sudo apt upgrade
```

### Core Dependencies

Check Python installation:

```bash
python3 --version
```

If not installed:

```bash
sudo apt install python3
```

Install Node.js (if version is outdated, update it):

```bash
node --version

# If outdated or not installed:
apt-get purge nodejs &&\
rm -r /etc/apt/sources.list.d/nodesource.list
curl -fsSL https://deb.nodesource.com/setup_19.x | sudo -E bash - &&\
sudo apt-get install -y nodejs
```

Install LazyGit:

```bash
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin
rm -rf lazygit.tar.gz
```

Install Neovim prerequisites:

```bash
sudo apt-get install ninja-build gettext libtool-bin cmake g++ pkg-config unzip curl
```

Install Neovim from source:

```bash
cd ~/Downloads
git clone https://github.com/neovim/neovim
cd neovim && make CMAKE_BUILD_TYPE=RelWithDebInfo
sudo make install
```

Install additional dependencies:

```bash
sudo apt install git
sudo apt install fzf
sudo apt install ripgrep
sudo apt install pandoc
sudo apt install pandoc-citeproc
sudo apt install nodejs
sudo apt install stylua
sudo apt install lua-language-server
sudo apt install wget
sudo apt install xsel
sudo apt install python3-pip
sudo pip3 install neovim-remote
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

Troubleshoot any other errors following the advice provided by checkhealth. If Treesitter throws an error, run `:TSUpdate` in Neovim.

## LaTeX Installation

Check if LaTeX is already installed:

```bash
latexmk --version
```

Install LaTeX:

```bash
sudo apt install texlive-most
# OR for full installation:
sudo apt install texlive-full
```

After installation, reboot your computer and verify with:

```bash
latexmk --version
```

## Nerd Fonts Installation

For NeoVim to display icons correctly, install RobotoMono Nerd Font:

```bash
# Copy the included fonts
sudo cp -R ~/.config/fonts/RobotoMono /usr/share/fonts/truetype/
```

If you're using the stock terminal, change the font to RobotoMono Nerd Font Regular in the terminal settings.

## PDF Viewer Setup

### Zathura (Recommended)

Install Zathura:

```bash
sudo apt install zathura
mkdir -p ~/.config/zathura
cp ~/.config/config-files/zathurarc ~/.config/zathura/zathurarc
```

For reference documentation:

```bash
man zathurarc
```

### Okular (Alternative)

For an alternative PDF viewer:

```bash
sudo apt install okular
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

Choose from one of these options:

### Option 1: Kitty (Recommended for simplicity)

```bash
sudo apt install kitty
```

### Option 2: Alacritty + Tmux

```bash
sudo add-apt-repository ppa:aslatter/ppa -y
sudo apt install alacritty
sudo apt install tmux
cp ~/.config/tmux/.tmux.conf ~/.tmux.conf
```

If you installed Alacritty and want to use Fish shell:

```bash
which fish  # Note the path
nvim ~/.config/alacritty/alacritty.yml  # Update fish path if different from /usr/bin/fish
```

## Fish Shell (Optional)

Install Fish:

```bash
sudo apt install fish
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
sudo apt install xclip  # Install xclip if needed
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
sudo apt install xorg-xmodmap
sudo apt install xorg-xev
sudo apt install xorg-setxkbmap
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

1. **Building Neovim fails**: Ensure all development dependencies are installed
2. **Missing icons**: Check nerd font installation and terminal configuration
3. **PDF viewer not working**: Verify Zathura/Okular installation and paths
4. **Python integration issues**: Run `pip3 install --user pynvim` and restart Neovim
5. **LaTeX compilation fails**: Verify texlive installation and run `latexmk --version`

For further assistance, open an issue on the GitHub repository.