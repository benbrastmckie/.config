# .config
A complete configuration for writing LaTeX documents with NeoVim.
---
The following sections provide instalation instructions for Mac and Debian Linux systems such as Ubuntu.
# Mac Instalation
Open the terminal by hitting Command+Space and typing 'terminal' and hitting return.
You may check whether you already have Homebrew installed by entering the following into the terminal:
```
brew --version
```
If Homebrew is installed, it will report which version you have.
Otherwise, you may update by means of the following:
```
brew update
```
If Homebrew has not been installed, you may install it by entering:
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
```
Install node by running:
```
brew install node
```
Install Python 3 by running:
```
brew install python
```
It is important that python 3 is linked. To check, run:
```
brew link python
```
In case there are conflicts, you can run:
```
brew link --overwrite python
```
Reboot and proceed to install NeoVim.

## [NeoVim](https://neovim.io/)
Install NeoVim by entering:
```
brew install neovim
```
Once the installation is complete, open NeoVim by entering:
```
nvim
```
To exit NeoVim, enter the following:
```
:q
```
NeoVim comes with an extremely austere set of defaults, including no mouse support, making it difficult to use prior to configuration.
In order to install pluggins, extending the features included in NeoVim, run the following:
```
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
```
## [Git](https://git-scm.com/)
Check to see whether Git is already installed by entering the following:
```
git --version
```
If Git is not installed, run:
```
brew install git
```
## [Configuration](https://github.com/benbrastmckie/.config)
In order to clone the configuration files into the appropriate folder on your computer, enter the following into the terminal, hitting return after each line:
```
cd ~/.config
git init
git remote add origin https://github.com/benbrastmckie/.config.git
git pull origin master
```
Run NeoVim by entering the following into the terminal:
```
nvim
```
NeoVim will now be fully configured.
## Skim
Install Skim pdf viewer by running:
```
brew cask install skim
```
Run the following command in the terminal:
```
nvim ~/.config/nvim/plug-config/vimtex.vim
```
Changing all occurances of 'zathura' to 'skim'.
Save and quit the file by entering the following in NeoVim:
```
:wq
```
## Alacritty
In order to upgrade your terminal, install the Alacritty ternimal emulator by running:
```
brew cask install alacritty
```
Install the Tmux terminal multiplexer by running:
```
brew install tmux
```
After rebotting, open the terminal and run NeoVim by entering:
```
nvim
```
If you run into trouble, feel free to open an issue, and I'll do my best to help.
# Debian Linux Instalation

