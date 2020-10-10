# .config

## A complete configuration for writing LaTeX documents with NeoVim.

The following sections provide installation instructions for Mac and Arch Linux operating systems.
I present an overview of the resulting functionality in [this](https://www.youtube.com/playlist?list=PLBYZ1xfnKeDToZ2XXbUGSC7BkorWdyNh3) video series as well as a configuration guide [here](https://www.youtube.com/playlist?list=PLBYZ1xfnKeDRbxgKSDZ-41U3DF9foKC1J).
I have also included a [Cheat Sheet](https://github.com/benbrastmckie/.config/blob/master/CheatSheet.md) with all of the key-bindings that I have set for writing LaTeX documents with NeoVim.

## Table of Contents

1. [Mac OS Installation](#Mac-OS-Installation)
2. [Arch Linux Installation](#Arch-Linux-Installation)

The programs covered include: NeoVim, Git, Skim/Zathura, Zotero, Alacritty, Tmux, and Fish.
I will also include information for globally remapping keys to better suit writing LaTeX documents with NeoVim.

# Mac OS Installation

Open the terminal by hitting `Command+Space` and typing `terminal` and hitting return.
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
:checkhealth
```

If Python 3 reports an error, run following in the terminal (to exit NeoVim, write `:qa!`):

```
pip3 install --user pynvim
```

NeoVim comes with an extremely austere set of defaults, including no mouse support, making it difficult to use prior to configuration.
In order to install plugins, extending the features included in NeoVim, run the following:

```
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
```

Install the FZF fuzzy finder, Ripgrep, and Pandoc by running the following commands, respectively:

```
brew install fzf
brew install ripgrep
brew install pandoc
brew install pandoc-citeproc
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

Next install LazyGit by running:

```
brew install jesseduffield/lazygit/lazygit
```

If you have not already, you can also add an SSH key by amending and running the following:

```
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

Hit `return` once, entering your GitHub passphrase in response to the prompt.
Next run:

```
bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
```

Run the following to copy the SSH key to your system clipboard:

```
pbcopy < ~/.ssh/id_rsa.pub
```

In the top right corner of your GitHub page, click `Profile -> Settings -> SSH and GPG Keys` selecting `New SSH Key`.
Name the key after the devise you are using, pasting the SSH key from the clipboard into the appropriate field.
Saving the key completes the addition.

## [Configuration](https://github.com/benbrastmckie/.config)

In order to clone the configuration files into the appropriate folder on your computer, enter the following into the terminal, hitting return after each line:

```
cd ~/.config
git clone https://github.com/benbrastmckie/.config.git
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

You will need to grant permission to open Skim by opening Mac System Settings, and approving the application in Security.
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

## [Zotero](https://www.zotero.org/)

Download and install [Zotero](https://www.zotero.org/) along with the appropriate plugin for your preferred browser.
Find a paper online, signing in to the journal as necessary and downloading the pdf manually.
Now return to the paper on the journal's website and test the browser plugin for Zotero which should be displayed in the top right of the screen.
Create the bib and bst directories, and move the .bst bibliography style files into the appropriate folder by running the following:

```
mkdir -p ~/Library/texmf/bibtex/bib
cp ~/.config/latex/bst ~/Library/texmf/bibtex
```

Download and install Better BibTex by following [these](https://retorque.re/zotero-better-bibtex/installation/) instructions.
Under `Edit` in the Zotero menu bar, select `Preferences` and open up the `Better BibTex` tab.
Under the `Citation` sub-tab, replace the citation key format with `[auth][year]`.
Also check `On item change` at the bottom left.
Now switch to the `Automatic Export` sub-tab and check `On Change`.
Close the Preferences window, returning to the main Zotero window.
Right-click the main library folder in the left-most column, and select `Export Library`.
Under the `Format` dropdown menu, select `Better BibTex`, selecting the `Keep Updated` box. 
Save the file as `Zotero` (the extension will be added automatically) to ~/Library/texmf/bibtex/bib which you previously created.
You are now ready to cite files in your Zotero database.

## [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts)

In order for NeoVim to load icons, it will be imporant to install a NerdFont.
For simplicity, I have included RobotoMono in `~/.config/fonts` which you can now move to the appropriate folder on your computer by entering the following in the terminal:

```
sudo cp ~/.config/fonts/RobotoMono/ /Library/Fonts/
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

You will also need to move the Tmux configuration file to the appropriate location by running:

```
sudo cp ~/.config/tmux/.tmux.conf ~/
```

You will now need to locate fish on your opperating system by running the following:

```
which fish
```

The command should return `/usr/local/bin/fish`.
Copy the path and run the following:

```
nvim ~/.config/alacritty/alacritty.yml
```

Replace '/usr/bin/fish' with the location of fish, saving and exiting with Space-q.
Quite the terminal and open Alacritty by hitting Command+Space and typing 'Alacritty', running the following:

```
curl -L https://get.oh-my.fish | fish
omf install sashimi
```

To delete the welcome message, run:

```
set fish_greeting
```

In order to reset Tmux, run:

```
Tmux kill-server
```

When you reopen `Alacritty` Fish should be the default shell inside a Tmux window.
If you want to turn on the Vim keybindings within Fish, run the following:

```
fish_vi_key_bindings
```

You are now read use NeoVim in Alacritty, complete with Tmux and the Fish shell.
I highly recommend swapping the CapsLock and Esc keys by opening `System Preferences -> Keyboard`, and making the appropriate changes.

# Arch Linux Installation

Open the terminal and run the following commands:

```
sudo pacman -S neovim
```

Check to confirm that Python is installed:

```
python3 --version
```

If Python is not installed, run:

```
sudo pacman -S python
```

To check the health of your NeoVim install, open NeoVim by running `nvim` in the terminal and enter the following command:

```
:checkhealth
```

If Python 3 reports an error, run following in the terminal (to exit NeoVim, write `:qa!`):

```
pip3 install --user pynvim
```

NeoVim comes with an extremely austere set of defaults, including no mouse support, making it difficult to use prior to configuration.
In order to install plugins, extending the features included in NeoVim, run the following:

```
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
```

Install the FZF fuzzy finder, Ripgrep, and Pandoc with the following commands respectively:

```
sudo pacman -S fzf
sudo pacman -S ripgrep
sudo pacman -S pandoc
sudo pacman -S pandoc-citeproc
```

## [Git](https://git-scm.com/)

Check to see whether Git is already installed by entering the following:

```
git --version
```

If Git is not installed, run:

```
sudo pacman -S install git
```

If you don't have Yay, you can install it by running the following:

```
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
```

If you run into errors, you may be missing the following dependency, which you can add by running:

```
sudo pacman -S base-devel
```

Next, install LazyGit using Yay by running:

```
yay -S lazygit
```

If you have not already, you can also add an SSH key by amending and running the following:

```
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

Hit `return` once, entering your GitHub passphrase in response to the prompt.
Next run:

```
bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
```

If you do not have `xclip` you can install it by running:

```
sudo pacman -S xclip
```

After the install, run the following to copy the SSH key to your system clipboard:

```
xclip -sel clip < ~/.ssh/id_rsa.pub
```

In the top right corner of your GitHub page, click `Profile -> Settings -> SSH and GPG Keys` selecting `New SSH Key`.
Name the key after the devise you are using, pasting the SSH key from the clipboard into the appropriate field.
Saving the key completes the addition.

## [Configuration](https://github.com/benbrastmckie/.config)

In order to clone the configuration files into the appropriate folder on your computer, enter the following into the terminal, hitting return after each line:

```
cd ~/.config
git clone https://github.com/benbrastmckie/.config.git
mkdir -p ~/.vim/files/info
sudo pip3 install neovim-remote
sudo pacman -S yarn
```

If you have not already installed MacTex on your computer, you can run the following command in order to check to see if it is already installed:

```
latexmk --version
```

To install LaTeX, run the following

```
sudo pacman -S texlive-most
```

Run NeoVim to install plugins:

```
nvim
```

After the plugins finish installing, quite NeoVim with `:qa!`.

## [Zathura](https://pwmt.org/projects/zathura/)

Install the Zathura pdf viewer by running:

```
sudo pacman -S zathura
```

After reopening NeoVim, enter the following command:

```
:checkhealth
```

Ignore any warnings for Python 2, Ruby, and Node.js.
If other warnings are present, it is worth following the instructions provided by CheckHealth, or else troubleshooting the errors by Googling the associated messages as needed.

## [Zotero](https://www.zotero.org/)

Download and extract the [Zotero](https://www.zotero.org/download/) tarball in ~/Downloads, and move the extracted contents and set the launcher by running the following in the terminal:

```
sudo mv ~/Downloads/Zotero_linux-x86_64 /opt/zotero
cd /opt/zotero
sudo ./set_launcher_icon
sudo ln -s /opt/zotero/zotero.desktop ~/.local/share/applications/zotero.desktop
```

Install Better-BibTex by downloading the latest release [here](https://retorque.re/zotero-better-bibtex/installation/) (click on the .xpi).
Go into `Tools -> add-ons` and click the gear in the upper right-hand corner, selecting `Install Add-on From File` and navigate to the .xpi file in ~/Downloads.
Go into `Edit -> Preferences -> BetterBibTex` and set citation key format to `[auth][year]`.
Go into `Edit -> Preferences -> Sync` entering your username and password, or else create a new account if you have not already done so.
Also check 'On item change' at the bottom left.
Now switch to the 'Automatic Export' sub-tab and check 'On Change'.
Exit `Preferences` and click the green sync arrow in the to right-hand corner (if you have not previously registered a Zotero database, no change will occur).
Install the appropriate plugin for your browser by following the link [here](https://www.zotero.org/download/)
Find a paper online, sigining in to the journal as necessary and downloading the PDF manually.
Now return to the paper on the journal's website and test the browser plugin for Zotero which should be displayed in the top right of the screen.
Create the bib and bst directories, and move the .bst bibliography style files into the appropriate folder by running the following:

```
mkdir -p ~/texmf/bibtex/bib
cp ~/.config/latex/bst ~/texmf/bibtex
```

Right-click the main library folder in the left-most column, and select `Export Library`.
Under the `Format` dropdown menu, select `Better BibTex`, selecting the `Keep Updated` box. 
Save the file as `Zotero.bib` to ~/texmf/bibtex/bib which you previously created.
You are now ready to cite files in your Zotero database.

## [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts)

In order for NeoVim to load icons, it will be imporant to install a NerdFont.
For simplicity, I have included RobotoMono in `~/.config/fonts` which you can now move to the appropriate folder on your computer by entering the following in the terminal:

```
sudo cp ~/.config/fonts/RobotoMono/ /usr/share/fonts
```

If you intend to use the stock terminal, you will need to go into the terminal's settings to change the font to RobotoMono regular.
You are now ready to write LaTex in NeoVim inside the stock terminal.
If you intend to upgrade your terminal to Alacritty with Tmux and the Fish shell, then proceed as follows:

## [Alacritty](https://github.com/alacritty/alacritty), [Tmux](https://github.com/tmux/tmux/wiki), [Fish](https://fishshell.com/)

Run the following in the terminal:

```
sudo pacman -S alacritty
sudo pacman -S tmux
sudo pacman -S fish
```

You will also need to move the Tmux configuration file to the appropriate location by running:

```
sudo cp ~/.config/tmux/.tmux.conf ~/
```

You will now need to locate fish on your opperating system by running the following:

```
which fish
```

The command should return `/usr/bin/fish`.
If the path is different, copy the path and run the following:

```
nvim ~/.config/alacritty/alacritty.yml
```

Replace '/usr/bin/fish' with the location of fish if different, saving and exiting with `Space-q`.
Quite the terminal and open Alacritty by hitting Command+Space and typing 'Alacritty', running the following:

```
curl -L https://get.oh-my.fish | fish
omf install sashimi
```

To delete the welcome message, run:

```
set fish_greeting
```

In order to reset Tmux, run:

```
Tmux kill-server
```

When you reopen `Alacritty` Fish should be the default shell inside a Tmux window.
If you want to turn on the Vim keybindings within Fish, run the following:

```
fish_vi_key_bindings
```

You are now read use NeoVim in Alacritty, complete with Tmux and the Fish shell.
I highly recommend swapping the CapsLock and Esc keys as detailed below for using Arch on a Macbook Pro.

## Remapping Keys

If you are running Linux on a Macbook, it can be convenient to swap the CapsLock and Esc keys, as well as turning Ctrl into Alt, Alt into Command, and Command into Ctrl.
To achieve these remappings, run the following commands:

```
sudo pacman -S xorg-xmodmap
sudo pacman -S xorg-xev
sudo pacman -S xorg-setxkbmap
```

In order to test to confirm the keycodes for your keyboard, run the following:

```
xev | awk -F'[ )]+' '/^KeyPress/ { a[NR+2] } NR in a { printf "%-3s %s\n", $5, $8 }'
```

This will open a white box which, when in focus, will print the keycodes of the depressed keys.
In particular, test the `Ctrl` as well as both `Alt/Option` and `Command` keys on the left and right side of the keyboard.
In order to get the `Command` keys to register, you will need to press `Shift+Command` which will print the keycode for `Shift` followed by the keycode for `Command`.
Close the white box upon finishing, checking to see if the output matches the following:

```
37 control
64 Alt_L
133 Super_L
134 Super_R
108 Alt_R
```

If your output does not match the above, you will need to edit the following file accordingly by running:

```
nvim ~/.config/.Xmodmap
```

If you need to make changes to keymappings, you can test the result of editing `.Xmodmap` and running the following:

```
xmodmap ~/.config/.Xmodmap
```

You can return to defaults by running:

```
setxkbmap
```

Once you achieve the desired result, or if your output matchs with the keycodes listed above, move the `.Xmodmap` and `.xmodmap.desktop` files to the appropriate locations by running:

```
sudo cp ~/.config/.Xmodmap /etc/X11/xinit/.Xmodmap
cp ~/.config/.xmodmap.desktop ~/.config/autostart/
```

Reboot and confirm that the mappings are running as desired.
