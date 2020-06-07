# .config
A complete configuration for writing LaTeX documents with NeoVim.
---
The following sections provide instalation instructions for Mac and Debian Linux operating systems.
I provide an overview of the resulting functionality in [this](https://www.youtube.com/playlist?list=PLBYZ1xfnKeDToZ2XXbUGSC7BkorWdyNh3) video series.
# Mac Instalation
Open the terminal by hitting Command+Space and typing 'terminal' and hitting return.
You may check whether you already have Homebrew installed by entering the following into the terminal:
```
brew --version
```
If Homebrew is installed, it will report which version you have which you can update by means of the following:
```
brew update
```
If Homebrew has not been installed, you may install it by entering:
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
```
Check if Node is installed by running:
```
node --version
```
If Node is not installed, run:
```
brew install node
```
Check if Python 2 and 3 are installed by running the following:
```
Python2 --version
Python3 --version
```
If either version of Python is missing, run:
```
brew install python
```
## [NeoVim](https://neovim.io/)
Install NeoVim by entering:
```
brew install neovim
```
Once the installation is complete, open NeoVim by entering:
```
nvim
```
To check the health of your NeoVim install, enter the following in Normal-Mode in NeoVim:
```
:CheckHealth
```
If Python 3 reports an error, run following in the terminal (to exit NeoVim, write `:qa!`):
```
pip3 install --user pynvim
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
mkdir -p ~/.vim/files/info
sudo pip3 install neovim-remote
```
If you have not already installed MacTex on your computer, you can run the following command in order to check to see if it is already installed:
```
latexmk --version
```
To install MacTex, you can download the package [here](https://www.tug.org/mactex/).
Reboot your computer, and run NeoVim by entering the following into the terminal:
```
nvim
```
After the plugins finish installing, quite NeoVim with `:qa!`.

## [Skim](https://skim-app.sourceforge.io/)
Install the Skim pdf viewer by running:
```
brew cask install skim
```
You will need to grant permision to open Skim by opening Mac System Settings, and approving the application in Security.
In order to tell Vimtex to open Skim, run the following command in the terminal:
```
nvim ~/.config/nvim/plug-config/vimtex.vim
```
Once the file has opened in NeoVim, change all occurances of 'zathura' to 'skim' by entering the following in NeoVim in normal-mode:
```
:%s/'zathura'/'skim'/g
```
Save and quit the file by entering `:wq` in NeoVim in normal-mode.
After reopening NeoVim, enter the following in normal-mode:
```
:checkhealth
```
Ignore any warnings for Python 2, Ruby, and Node.js.
If other warnings are present, it is worth following the instructions provided by CheckHealth, or else troubleshooting the errors by Googling the associated messages as needed.

## [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts)
In order for NeoVim to load icons, it will be imporant to install a NerdFont.
For simplicity, I have included RobotoMono in `~/.config/fonts` which you can now move to the appropriate folder on your computer by entering the following in the terminal:
```
sudo mv ~/.config/fonts/RobotoMono/ /Library/Fonts/
```
If you intend to use the stock terminal, you will need to go into the terminal's settings to change the font to RobotoMono.
You are now ready to write LaTex in NeoVim inside the stock terminal.
If you intend to upgrade your terminal to Alacritty with Tmux and the Fish shell, then proceed as follows:
## [Alacritty](https://github.com/alacritty/alacritty), [Tmux](https://github.com/tmux/tmux/wiki), [Fish](https://fishshell.com/)
Run the following in the terminal:
```
brew cask install alacritty
brew install tmux
brew install fish
```
You will now need to locate fish on your opperating system by running the following:
```
which fish
```
The command should return `/usr/local/bin/fish`, otherwise copy the path and run the following:
```
nvim ~/.config/alacritty/alacritty.yml
```
Replace '/usr/bin/fish' with the location of fish, saving and exiting with Space-q.
You will also need to move the Tmux configuration file to the appropriate location by running:
```
sudo mv ~/.config/tmux/.tmux.conf ~/
tmux kill-server
```
Re-open Alacritty, running the following:
```
curl -L https://get.oh-my.fish | fish
omf install sashimi
```
To delete the welcome message, run:
```
set fish_greeting
```
You  are now read use NeoVim in Alacritty, complete with Tmux and the Fish shell.

# Debian Linux Instalation

