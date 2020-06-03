# .config

Configuration files for NeoVim, Alacrrity, Tmux, and Zathura which have been optimized for writing in LaTeX.

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
Check to see whether Git is already installed by entering the following:
```
git --version
```
If Git is not installed, run:
```
brew install git
```
Install Zathura by running the following commands:
```
brew install zathura
brew install zathura-pdf-poppler
```
Link the pluggins for Zathura by running the following commands:
```
mkdir -p $(brew --prefix zathura)/lib/zathura
$ ln -s $(brew --prefix zathura-pdf-poppler)/libpdf-poppler.dylib $(brew --prefix zathura)/lib/zathura/libpdf-poppler.dylib
```
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
You are now ready to use NeoVim.
---
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

