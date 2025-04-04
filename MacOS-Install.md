# MacOS Installation Guide

This guide provides detailed instructions for installing the NeoTex Neovim configuration on MacOS, including all necessary dependencies, LaTeX tools, and optional enhancements.

## Prerequisites

Before beginning, ensure your system is up to date:

```bash
softwareupdate --install --all
```

## Dependencies Installation

### Install Homebrew

Check if Homebrew is already installed:

```bash
brew --version
```

If installed, update it:

```bash
brew update
brew doctor
brew upgrade
```

If not installed, run:

```bash
xcode-select --version
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Install Core Dependencies

```bash
brew install git
brew install jesseduffield/lazygit/lazygit
brew install node
brew install python
brew install stylua
brew install lua-language-server
brew install fzf
brew install ripgrep
brew install pandoc
brew install pandoc-plot
brew install npm
brew install wget
brew install neovim-remote
```

### Install Nerd Font

```bash
brew tap homebrew/cask-fonts
brew install --cask font-roboto-mono-nerd-font
```

Select this font in your terminal by navigating to preferences and changing the font.

## Neovim Installation

Install the stable version of Neovim:

```bash
brew install neovim
```

Verify the installation:

```bash
nvim --version
```

### Check Neovim Health

Open Neovim and run:

```
:checkhealth
```

If Python reports errors, install pynvim:

```bash
pip3 install --user pynvim
```

Resolve any other errors following the instructions provided by checkhealth.

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

## LaTeX Installation

Check if LaTeX is already installed:

```bash
latexmk --version
```

If not, install MacTeX:

```bash
brew install --cask mactex
```

After installation completes, reboot your computer.

## PDF Viewer Setup (Skim)

Install Skim:

```bash
brew install skim
alias skim='/Applications/Skim.app/Contents/MacOS/Skim'
```

If using Fish shell:

```bash
funcsave skim
```

Configure Skim preferences:
1. Open Skim menu and navigate to Preferences > Sync
2. Check both "Check for file changes" and "Reload automatically"
3. In the Preset menu, select custom
4. Set Command to `nvim` with Arguments: `--headless -c "VimtexInverseSearch %l '%f'"`

Update VimTeX configuration:

```bash
nvim ~/.config/nvim/lua/neotex/plugins/vimtex.lua
```

Replace occurrences of 'okular' and 'zathura' with 'skim'.

Verify VimTeX setup by running `:checkhealth` in Neovim.

## Zotero Integration

### Install Zotero

Download Zotero from [zotero.org](https://www.zotero.org/) and install it.

### Install Better BibTeX Plugin

1. Download the latest release from [here](https://retorque.re/zotero-better-bibtex/installation/)
2. In Zotero, go to Tools > Add-ons
3. Click the gear icon and select "Install Add-on From File"
4. Navigate to the downloaded .xpi file

### Configure Better BibTeX

1. In Zotero, go to Edit > Preferences > Better BibTeX
2. Set citation key format to `auth.fold + year`
3. Select "Keep Updated" to automatically update the .bib file

### Create Bibliography Directory

```bash
mkdir -p ~/Library/texmf/bibtex/bib
cp -R ~/.config/latex/bst ~/Library/texmf/bibtex
```

### Export Library

1. In Zotero, right-click your library folder
2. Select "Export Library"
3. Choose "Better BibTeX" format and check "Keep Updated"
4. Save as "Zotero.bib" to ~/Library/texmf/bibtex/bib

### Update Telescope Configuration

```bash
nvim ~/.config/nvim/lua/neotex/plugins/telescope.lua
```

Change `~/texmf/bibtex/bib/Zotero.bib` to `~/Library/texmf/bibtex/bib/Zotero.bib`

Clear the VimTeX cache:

```
:VimtexClearCache kpsewhich
```

## Terminal Setup (Optional)

Choose from one of these options:

### Option 1: Kitty (Recommended for simplicity)

```bash
brew install --cask kitty
sudo cp ~/.config/config-files/kitty.conf ~/.config/kitty/kitty.conf
```

### Option 2: Alacritty + Tmux

```bash
brew install --cask alacritty
brew install tmux
sudo cp ~/.config/config-files/alacritty.yml ~/.config/alacritty/alacritty.yml
sudo cp ~/.config/config-files/.tmux.conf ~/.tmux.conf
```

If you installed Fish shell, locate it and update the Alacritty config:

```bash
which fish
nvim ~/.config/alacritty/alacritty.yml
```

Replace `/usr/bin/fish` with your fish path.

## Fish Shell (Optional)

```bash
brew install fish
curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
omf install sashimi
```

Remove welcome message:

```bash
set -U fish_greeting ""
```

Make Fish the default shell:

```bash
which fish
sudo vim /etc/shells  # Add the fish path
chsh -s /usr/local/bin/fish  # Replace with your fish path
```

Enable vim key bindings (optional):

```bash
fish_vi_key_bindings
```

Install zoxide for easier navigation:

```bash
brew install zoxide
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

Add the SSH key to your agent:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
pbcopy < ~/.ssh/id_rsa.pub
```

Add the key to your GitHub account:
1. Go to GitHub > Profile > Settings > SSH and GPG Keys
2. Click "New SSH Key"
3. Paste your key and save

If your SSH key stops working after reboot:

```bash
ssh-add -K ~/.ssh/id_rsa  # Try with lowercase -k if this fails
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

For better ergonomics, consider these modifications in System Preferences > Keyboard:

1. Swap CapsLock and Escape keys
2. Change Command key to Control key
3. Change Control key to Function key
4. Change Function key to Option key
5. Change Option key to Command key

## Verification

Test your setup by:

1. Opening NeoVim
2. Creating a new LaTeX file with `<space>tp`
3. Building with `<space>b` to ensure PDF generation works
4. Using `<space>fc` to verify citation search works
5. Running `:checkhealth` to confirm all systems are operational

## Troubleshooting

### Common Issues

1. **VimTeX shows errors**: Run `:VimtexClearCache kpsewhich`
2. **SSH key not working**: Run `ssh-add -K ~/.ssh/id_rsa`
3. **Library path not found**: Ensure texmf directory is correctly created
4. **Font issues**: Verify Nerd Font is installed and selected in terminal

For further assistance, open an issue on the GitHub repository.