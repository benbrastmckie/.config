# .config

NOTE: these instructions were written for my old vimscript config, and will be updated soon. The config is nevertheless ready to clone/fork and install in approximately the same manner described below.


## A complete configuration for writing LaTeX documents with [NeoVim](https://neovim.io).

The following sections provide installation instructions for Mac, Arch, and Debian operating systems.
In the [CheatSheet.md](https://github.com/benbrastmckie/.config/blob/master/CheatSheet.md) you can find all of the key-bindings that I have added to NeoVim for writing LaTeX documents, where the [LearningGit.md](https://github.com/benbrastmckie/.config/blob/master/LearningGit.md) provides resources specifically geared for integrating Git into your workflow.
You can also find video series which: (1) demonstrates the [resulting functionality](https://www.youtube.com/playlist?list=PLBYZ1xfnKeDToZ2XXbUGSC7BkorWdyNh3) of the present configuration; (2) walks through the [installation process](https://www.youtube.com/playlist?list=PLBYZ1xfnKeDRbxgKSDZ-41U3DF9foKC1J); (3) explains how to [modify the configuration](https://www.youtube.com/watch?v=oyEPY6xFhs0&list=PLBYZ1xfnKeDT0LWxQQma8Yh-IfpmQ7UHr) for your own needs; and (4) indicates how to [use Git](https://www.youtube.com/watch?v=GIJG4QtZBYI&list=PLBYZ1xfnKeDQYYXIhKKrXhWOaSphnn9ZL) to track changes and collaborate with others.


## Table of Contents

1. [Mac OS Installation](#Mac-OS-Installation)
2. [Arch Linux Installation](#Arch-Linux-Installation)
3. [Debian Linux Insallation](#Debian-Linux-Installation)
4. [Remapping Keys](#Remapping-Keys)

The programs covered include: NeoVim, Git, Skim/Zathura, Zotero, Alacritty, Tmux, and Fish.
I will also include information for globally remapping keys to [better](https://www.reddit.com/r/vim/comments/lsx5qv/just_mapped_my_caps_lock_to_escape_for_the_first/) suit writing LaTeX documents with NeoVim.


# Mac OS Installation

I would start by updating your system so that you don't hit any snags along the way.
(Or, if you like snags and hate Mac, then consider switching to Linux!)
Once you have updated MacOS, open the terminal by hitting `Command + Space` and typing 'terminal'.
You may check whether you already have Homebrew installed by entering the following into the terminal:

```
brew --version
```

If Homebrew is installed, it will report which version you have which you can update by means of the following commands run seperately in order:

```
brew update
brew doctor
brew upgrade
```

If Homebrew has not been installed, you may install it by running the following two commands:

```
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Although optional, I highly recommend that inexperienced users begin by installing Fish as explained in the section below which makes working insider the terminal a lot easier and will benefit your resulting workflow once NeoVim is up and running.
I also highly recommend swapping the CapsLock and Esc keys by opening `System Preferences -> Keyboard` and making the appropriate changes.


## [Fish](https://fishshell.com/)

To install the Fish shell, run:

```
brew install fish
curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
omf install sashimi
```

To delete the welcome message, run:

```
set -U fish_greeting ""
```

Or add whatever you want between the quotes in the command above.
Make Fish your default shell by first checking where Fish is installed with:

```
which fish
```

Cut and paste the path and run:

```
sudo vim /etc/shells
```

Once inside vanilla Vim (preinstalled on any Mac) navigate to the bottom with `j`, go into insert mode with `i`, and then paste the path with `command + shift + v`, or hand type it, and hit `esc` to go back into normal mode.
Then save and quite with `:wq`.
Check to see that you succeeded with:

```
cat /etc/shells
```

If the line you included is shown at the end, then proceed to run:

```
chsh -s /usr/local/bin/fish
```

Close the terminal and reopen it to check to see if Fish is running by default.
If you want to turn on the Vim keybindings within Fish, run the following:

```
fish_vi_key_bindings
```


## Dependencies

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

Install the RobotoMono [Nerd Font](https://github.com/ryanoasis/nerd-fonts) with:

```
brew tap homebrew/cask-fonts
brew install --cask font-roboto-mono-nerd-font
```

More options can be found [here](https://github.com/Homebrew/homebrew-cask-fonts).
If you are using the default Mac Terminal, you will need to select the installed font by navigating through the menu `Terminal --> Preferences --> Profiles --> Change Font` and selecting RobotoMono or similar.

We are now ready to install NeoVim.


## [NeoVim](https://neovim.io/)

Install NeoVim by entering:

```
brew install neovim
```

Once the installation is complete, open NeoVim by entering:

```
nvim
```

To check the health of your NeoVim install, enter the following in normal-mode (enter command-mode in NeoVim from normal mode by hitting `:`. Enter normal-mode in NeoVim from any mode by hitting escape) waiting for it to complete the check:

```
:checkhealth
```

If Python 3 reports an error, run following in the terminal (to exit NeoVim, write `:qa!`):

```
pip3 install --user pynvim
```

Continue to run `:checkhealth` in NeoVim, following the instructions under the reported errors until all errors are gone (the Python 2 errors may be ignored, and similarly for Ruby, Node.js, and Perl).
This may involve doing some research if errors persist.

NeoVim comes with an extremely austere set of defaults, including no mouse support, making it difficult to use prior to configuration.
In order to install plugins, extending the features included in NeoVim, run the following:

```
git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 ~/.local/share/nvim/site/pack/packer/start/packer.nvimq
```

Check to see if the following are installed and install any which are missing:

```
brew install fzf
brew install ripgrep
brew install pandoc
brew install pandoc-plot
brew install npm
brew install wget
sudo pip3 install neovim-remote
```


## [Configuration](https://github.com/benbrastmckie/.config)

I recommend forking my config so that you have your own version that you can customise for yourself. To do so you will need to make a GitHub account. Then click `Fork` in my GitHub repo. This will copy the repo over to your GitHub. Now you can click the `Code` button in your repo on GitHub, sellecting SSH, and copying the address which you will use below. Alternatively, if you don't want to fork for some reason, click the `Code` button in my repo, copying the address in the same way. Now you are ready to open the terminal back up and run the following commands:

```
cd ~/.config
ls -a
git init
git remote add origin YOUR-OR-MY-ADDRESS
git remote -v
git pull origin master
ls -a
```

The `ls -a` commands are optional, but will help you see what is happening.
In particular, `git pull origin master` will pull down the config files into your `~/.config` directory.
The other git commands add a new git repo, link your local repo to your fork of my repo on GitHub, and confirm that the addresses have been added so that you are ready to push and pull changes from your fork on GitHub. 
This will permit you keep your config backed up to your GitHub repo and to pull your repo down onto other computers if you want to reporduce your customised config (that is once you have customise it) instead of pulling my repo down again.

Finally we may edit the `options.lua` file, deleting the final block which is not needed for Mac users:

```
vim ~/.config/nvim/user/options.lua
```

Scroll to the bottom with `G` delete the final block to be deleted by Mac users by moving the cursor up to any line in that block with `k` and then hitting `dap` (delete all paragraph).
Save and quite with `:wq` and reopen NeoVim.
After the plugins load, run `:checkhealth` troubleshooting any errors with the exception of VimTex which will be fixed in the Zathura section below.
You can ignore all the warnings.


## [LaTeX](https://www.latex-project.org/)

If you are here, you are probably familiar with LaTeX and already have it installed. But just in case you don't, you can run the following command in order to check to see if it is already installed:

```
latexmk --version
```

To install MacTex, you can download the package [here](https://www.tug.org/mactex/), or else run the following command:

```
brew install --cask mactex
```

This will take a while.
Once it finishes, reboot your computer and run NeoVim.
After the plugins finish installing, quite NeoVim with `:qa!`.
Now is another good time to run `:checkhealth` in NeoVim, troubleshooting as needed.


## [Zathura](https://pwmt.org/projects/zathura/)

Install the Zathura pdf viewer by running:

```
brew tap zegervdv/zathura
brew install zathuran
brew install xdotool
brew install pstree
```
Run `:checkhealth` inside NeoVim and scroll to the VimTex section at the bottom to confirm that all is OK.


## [Zotero](https://www.zotero.org/)

Download and install [Zotero](https://www.zotero.org/) along with the appropriate plugin for your preferred browser.
Find a paper online, signing in to the journal as necessary and downloading the pdf manually.
Now return to the paper on the journal's website and test the browser plugin for Zotero which should be displayed in the top right of the screen.
Create the bib and bst directories, and move the .bst bibliography style files into the appropriate folder by running the following:

```
mkdir -p ~/Library/texmf/bibtex/bib
cp -R ~/.config/latex/bst ~/Library/texmf/bibtex
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


## [Git](https://git-scm.com/)

Every Mac should have `git` already installed, but you can check by running:

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

Check to see if you have already set the appropriate username and email with:

```
git config -l
``` 

If absent or incorrect, add these with:

```
git config --global user.name "USERNAME"
git config --global user.email "EMAIL"
git config -l
```

Your details should now appear.


### Adding an SSH Key to GitHub

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
Name the authentication key after the devise you are using, pasting the SSH key from the clipboard into the appropriate field.
Saving the key completes the addition.

Check to make sure that the SSH key is working by pushing commits up to one of your repositories (see [(Git Part 2)](https://www.youtube.com/watch?v=7HHvkI2Swbk&list=PLBYZ1xfnKeDQYYXIhKKrXhWOaSphnn9ZL&index=2) for details).
If your SSH key stops working after rebooting, run the following command:

```
ssh-add -K ~/.ssh/id_rsa
```

If you get an error, retry the command above with a lowercase 'k'.

### [Adding a Personal Access Token](https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token)

Create a personal access token (PAT) by going to GitHub.com, clicking your user icon in the top right, navigate to `Setting --> Developer settings --> Personal -- Tokens` and create a new access token, setting:

- No expiration date
- Select `repo` in scope/permissions

After generating the token, you must copy the PAT, pasting it into a temporary file saved on your computer.
You can now add your PAT by pushing any changes you have made to your config up to your GitHub repo.
To do so, begin by navigating in the terminal to your .config folder and opening NeoVim with:

```
cd ~/.config
nvim CheatSheet.md
```

I would recommend keeping the `CheatSheet.md` updated with any changes you make to your configuration.
You can then push all of the changes that you have made to your config so far with LazyGit by hitting `<space>gg`. 
You will have to sort through which files you might want Git to ignore, hitting `i` when hovering over each, and once you have finished, hitting `A` to stage all files, followed by `c` to commit the staged changes, and `P` to push changes to the remote repo.
Enter your user name when prompted, followed by your PAT with `Ctrl+Shift+v` (or other depending on how paste is achieved in your terminal enviornment).
Assuming that this push works, close LazyGit with `q`, and reopen the terminal with `Ctrl+t`.

Now run the following:

```
git config --global credential.helper cache
```

Repeat the steps above after making a small change to run another test, entering your username and PAT as before.
Run one final test, checking to see if your credentials are now automatically submitted, avoiding the need to enter your username and PAT each time you push or pull changes.

For more help, see these [video](https://www.youtube.com/watch?v=kHkQnuYzwoo) instructions.


### Installing the GitHub Cli (Optional)

Assuming that you are using GitHub to host your repositories, it is convenient to install the GitHub Cli which allows you to make changes to your repositories directly from the terminal inside NeoVim:

```
brew install gh
```

For further information, see the section **GitHub Cli** in the [Cheat Sheet](https://github.com/benbrastmckie/.config/blob/master/CheatSheet.md) as well as the [GitHub Cli Repo](https://github.com/cli/cli).


## [Alacritty](https://github.com/alacritty/alacritty)

I highly recommend switching to a better terminal emulator like Alacritty as well as using a terminal multiplexor like Tmux so that you can have a seperate terminal-tab for each project that you have open. 
To do so, run the following in the default Mac terminal:

```
brew install --cask alacritty
brew install tmux
``````

Now move the Tmux configuration file included in the config to the appropriate location with:

```
sudo cp ~/.config/tmux/.tmux.conf ~/.tmux.conf
```

Assuming that you already installed Fish above, you will now need to locate fish on your operating system by running the following:

```
which fish
```

The command should return `/usr/local/bin/fish` or something similar.
Copy the path displayed and run the following:

```
nvim ~/.config/alacritty/alacritty.yml
```

Replace `/usr/bin/fish` with the location of fish found above (you can search with `/`).
You may also search for 'Window position', setting the `x` and `y` values along with the window dimensions just above, or comment out the position block by adding `#` in front of those three lines in order to assume system defaults upon opening Alacritty.
Save and exit with `:wq`.
Quite and re-open Alacritty, running the following to reset Tmux:

```
tmux kill-server
```

When you reopen `Alacritty` Fish should be the default shell inside a Tmux window.
You are now read use NeoVim in Alacritty, complete with Tmux and the Fish shell.


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
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
```

### Installing the GitHub Cli

Assuming that you are using GitHub to host your repositories, it is convenient to install the GitHub Cli which allows you to make changes to your repositories directly from the terminal inside NeoVim:

```
sudo pacman -S github-cli
```

You will then need to follow the [instructions](https://cli.github.com/manual/) in order to authenticate GitHub Cli by running:

```
gh auth login
```

Set NeoVim as your default editor by running:

```
gh config set editor nvim
```

For further information, see the section **GitHub Cli** in the [Cheat Sheet](https://github.com/benbrastmckie/.config/blob/master/CheatSheet.md) as well as the [GitHub Cli Repo](https://github.com/cli/cli).

### Adding an SSH Key to GitHub

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
git init
git remote add origin https://github.com/benbrastmckie/.config.git
git pull origin master
mkdir -p ~/.vim/files/info
sudo pacman -S python-pip
sudo pip3 install neovim-remote
sudo pacman -S yarn
```

If you have not already installed LaTeX on your computer, you can run the following command in order to check to see if it is already installed:

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
sudo pacman -S zathura-pdf-mupdf
```

Unless you have the Evince pdf viewer installed, you may also want to set Zathura as your default pdf viewer for opening pdfs for the papers you cite via the Vimtex Context Menu.
You can do so by editing the following file:

```
nvim ~/.config/nvim/plug-config/vimtex.vim
```

Once the file has opened in NeoVim, change all occurrences of 'evince' to 'zathura' by entering the following in NeoVim in normal-mode:

```
:%s/'evince'/'zathura'/g
```

Alternatively, you could replace Zathura here with another pdf viewer of your choice, for instance, one that allows you to easily take notes and highlight the associated pdf.
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
cp -R ~/.config/latex/bst ~/texmf/bibtex
```

Right-click the main library folder in the left-most column, and select `Export Library`.
Under the `Format` dropdown menu, select `Better BibTex`, selecting the `Keep Updated` box. 
Save the file as `Zotero.bib` to ~/texmf/bibtex/bib which you previously created.
You are now ready to cite files in your Zotero database.

## [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts)

In order for NeoVim to load icons, it will be imporant to install a NerdFont.
For simplicity, I have included RobotoMono in `~/.config/fonts` which you can now move to the appropriate folder on your computer by entering the following in the terminal:

```
sudo cp -R ~/.config/fonts/RobotoMono/ /usr/share/fonts
```

If you intend to use the stock terminal, you will need to go into the terminal's settings to change the font to RobotoMono regular.
You are now ready to write LaTex in NeoVim inside the stock terminal.
If you intend to upgrade your terminal to Alacritty with Tmux and the Fish shell, then proceed as follows:

## [Alacritty](https://github.com/alacritty/alacritty), [Tmux](https://github.com/tmux/tmux/wiki), and [Fish](https://fishshell.com/)

Run the following in the terminal:

```
sudo pacman -S alacritty
sudo pacman -S tmux
sudo pacman -S fish
```

You will also need to move the Tmux configuration file to the appropriate location by running:

```
sudo cp ~/.config/tmux/.tmux.conf ~/.tmux.conf
```

Assuming that you installed Fish above, you will now need to locate fish on your operating system by running the following:

```
which fish
```

The command should return `/usr/bin/fish`.
If the path is different, copy the path and run the following:

```
nvim ~/.config/alacritty/alacritty.yml
```

Replace '/usr/bin/fish' with the location of fish if different, saving and exiting with `Space-q`.
Quite the terminal and open Alacritty, running the following to set a reasonable theme for Fish:

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
tmux kill-server
```

When you reopen Alacritty, Fish should be the default shell inside a Tmux window.
If you want to turn on the Vim keybindings within Fish, run the following:

```
fish_vi_key_bindings
```

You are now read use NeoVim in Alacritty, complete with Tmux and the Fish shell.
I highly recommend swapping the CapsLock and Esc keys as detailed below for using Arch on a Macbook Pro.

# Debian Linux Installation

Open the terminal and run the following commands:

```
sudo apt install neovim
```

Check to confirm that Python is installed:

```
python3 --version
```

If Python is not installed, run:

```
sudo apt install python
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
sudo apt install fzf
sudo apt install ripgrep
sudo apt install pandoc
sudo apt install pandoc-citeproc
```

## [Git](https://git-scm.com/)

Check to see whether Git is already installed by entering the following:

```
git --version
```

If Git is not installed, run:

```
sudo apt install git
```

Next, install LazyGit using Launchpad by running:

```
sudo add-apt-repository ppa:lazygit-team/release
sudo apt-get update
sudo apt-get install lazygit
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
```

### Installing the GitHub Cli

Assuming that you are using GitHub to host your repositories, it is convenient to install the GitHub Cli which allows you to make changes to your repositories directly from the terminal inside NeoVim:

```
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key C99B11DEB97541F0
sudo apt-add-repository https://cli.github.com/packages
sudo apt update
sudo apt install gh
```

You will then need to follow the [instructions](https://cli.github.com/manual/) in order to authenticate GitHub Cli by running:

```
gh auth login
```

Set NeoVim as your default editor by running:

```
gh config set editor nvim
```

For further information, see the section **GitHub Cli** in the [Cheat Sheet](https://github.com/benbrastmckie/.config/blob/master/CheatSheet.md) as well as the [GitHub Cli Repo](https://github.com/cli/cli).

### Adding an SSH Key to GitHub

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
sudo apt install xclip
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
git remote add origin https://github.com/benbrastmckie/.config.git
git pull origin master
mkdir -p ~/.vim/files/info
sudo apt install python-pip
sudo pip3 install neovim-remote
sudo apt install yarn
```

If you have not already installed LaTeX on your computer, you can run the following command in order to check to see if it is already installed:

```
latexmk --version
```

To install LaTeX, run the following

```
sudo apt install texlive-full
```

Run NeoVim to install plugins:

```
nvim
```

After the plugins finish installing, quite NeoVim with `:qa!`.

## [Zathura](https://pwmt.org/projects/zathura/)

Install the Zathura pdf viewer by running:

```
sudo apt install zathura-pdf-mupdf
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
cp -R ~/.config/latex/bst ~/texmf/bibtex
```

Right-click the main library folder in the left-most column, and select `Export Library`.
Under the `Format` dropdown menu, select `Better BibTex`, selecting the `Keep Updated` box. 
Save the file as `Zotero.bib` to ~/texmf/bibtex/bib which you previously created.
You are now ready to cite files in your Zotero database.

## [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts)

In order for NeoVim to load icons, it will be imporant to install a NerdFont.
For simplicity, I have included RobotoMono in `~/.config/fonts` which you can now move to the appropriate folder on your computer by entering the following in the terminal:

```
sudo cp -R ~/.config/fonts/RobotoMono/ /usr/share/fonts
```

If you intend to use the stock terminal, you will need to go into the terminal's settings to change the font to RobotoMono regular.
You are now ready to write LaTex in NeoVim inside the stock terminal.
If you intend to upgrade your terminal to Alacritty with Tmux and the Fish shell, then proceed as follows:

## [Alacritty](https://github.com/alacritty/alacritty), [Tmux](https://github.com/tmux/tmux/wiki), and [Fish](https://fishshell.com/)

Run the following in the terminal:

```
sudo apt install alacritty
sudo apt install tmux
sudo apt install fish
```

You will also need to move the Tmux configuration file to the appropriate location by running:

```
sudo cp ~/.config/tmux/.tmux.conf ~/.tmux.conf
```

Assuming that you installed Fish above, you will now need to locate fish on your operating system by running the following:

```
which fish
```

The command should return `/usr/bin/fish`.
If the path is different, copy the path and run the following:

```
nvim ~/.config/alacritty/alacritty.yml
```

Replace '/usr/bin/fish' with the location of fish if different, saving and exiting with `Space-q`.
Quite the terminal and open Alacritty, running the following to set a reasonable theme for Fish:

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
tmux kill-server
```

When you reopen Alacritty, Fish should be the default shell inside a Tmux window.
If you want to turn on the Vim keybindings within Fish, run the following:

```
fish_vi_key_bindings
```

You are now read use NeoVim in Alacritty, complete with Tmux and the Fish shell.
I highly recommend swapping the CapsLock and Esc keys as detailed below for using Debian on a Macbook Pro.

# Remapping Keys

It can be convenient to swap keys so as to improve hand posture while working. For instance, one might switch the CapsLock and Esc keys, as well as turning Ctrl into Alt, Alt into Command, and Command into Ctrl.
To include these remappings, run the following commands for Arch and Debian, respectively:

Arch:

```
sudo pacman -S xorg-xmodmap
sudo pacman -S xorg-xev
sudo pacman -S xorg-setxkbmap
```

Debian:

```
sudo apt install xorg-xmodmap
sudo apt install xorg-xev
sudo apt install xorg-setxkbmap
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

If you output matches the above, you can run the following:

```
sudo cp ~/.config/.XmodmapMAC ~/.Xmodmap
```

If your output does not match the above, you will need to edit the following file accordingly by running:

```
nvim ~/.config/.Xmodmap
```

If you need to make changes to key mappings, you can test the result of editing `.Xmodmap` and running the following:

```
xmodmap ~/.config/.Xmodmap
```

Once you have .Xmodmap running the right key mappings, you will have to run the following so that .Xmodmap starts automatically:
```
sudo cp ~/.config/.Xmodmap ~/.Xmodmap
cp ~/.config/.xmodmap.desktop ~/.config/autostart/
```

You can return to defaults by running:

```
setxkbmap
```

Once you achieve the desired result, reboot and confirm that the mappings are running as desired.
