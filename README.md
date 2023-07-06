# .config


NOTE: If you discover any errors in these instructions, please feel free to submit a PR or open an issue so that I can improve these notes, making it easier for others in the future.
If you use Windows and are interested in troubleshooting the installation process, feel free to open an issue if one does not exist already.

## A complete configuration for writing LaTeX documents with [NeoVim](https://neovim.io).

The following sections provide installation instructions for Mac, Arch, and Debian operating systems.
In the [CheatSheet.md](https://github.com/benbrastmckie/.config/blob/master/CheatSheet.md) you can find all of the key-bindings that I have added to NeoVim for writing LaTeX documents, where the [LearningGit.md](https://github.com/benbrastmckie/.config/blob/master/LearningGit.md) provides resources for integrating Git into your workflow.
You can also find video series which: (1) demonstrates the [features](https://www.youtube.com/watch?v=_Ct2S65kpjQ&list=PLBYZ1xfnKeDRhCoaM4bTFrjCl3NKDBvqk) included in the present configuration; (2) walks through the [installation process](https://www.youtube.com/watch?v=ELdTohuzTnA&list=PLBYZ1xfnKeDQxis9D7HFFygHOFVTQ0BFn); (3) explains how to [modify the configuration](https://www.youtube.com/watch?v=oyEPY6xFhs0&list=PLBYZ1xfnKeDT0LWxQQma8Yh-IfpmQ7UHr) (OLD) for your own needs; and (4) describes how to [use Git](https://www.youtube.com/watch?v=GIJG4QtZBYI&list=PLBYZ1xfnKeDQYYXIhKKrXhWOaSphnn9ZL) to track changes and collaborate with others.


## Table of Contents

1. [Mac OS Installation](#Mac-OS-Installation)
2. [Arch Linux Installation](#Arch-Linux-Installation)
3. [Debian Linux Insallation](#Debian-Linux-Installation)
4. [Remapping Keys](#Remapping-Keys)

The software covered includes NeoVim, Git, Zathura, Zotero, Fish, and either Kitty or both Alacritty and Tmux.
I will also include information for globally remapping keys to [better](https://www.reddit.com/r/vim/comments/lsx5qv/just_mapped_my_caps_lock_to_escape_for_the_first/) suit writing LaTeX documents with NeoVim.


# Mac OS Installation

I would start by updating your system so that you don't hit any snags along the way.
(Or, if you like snags and tired of Mac, then consider switching to Linux!)
Once you have updated MacOS, open the terminal by hitting `Command + Space` and typing 'terminal'.
You may check whether you already have Homebrew installed by entering the following into the terminal:

```
brew --version
```

If Homebrew is installed, it will report which version you have which you can update by means of the following commands run separately in order:

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

Note that if you don't have `xcode` installed, this may take a while but is essential to what follows.

Although optional, I highly recommend swapping the `CapsLock` and `Esc` keys by opening `System Preferences -> Keyboard` and making the appropriate changes.
I also like to change the `Command` key to the `Control` key, change the `Control` key to the `Function` key, change the `Function` key to the `Option` key, and change the `Option` key to the `Command` key if I'm using a Mac.
My reasons for doing this is ergonomics given which keys I'll be using most often in NeoVim.
Alternatively, you can make changes to the mappings that I've included in the config, though this may take a little more work than swapping things around in `System Preferences -> Keyboard`.
Whatever you do, I recommend finding something comfortable before you begin using your NeoVim config, committing its key-bindings to memory.


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

Once inside vanilla Vim (pre-installed on any Mac) navigate to the bottom with `j`, create a new line with `o`, and paste the path with `command + shift + v`, or hand type it, and hit `esc` to go back into normal mode.
Then save and quit with `:wq`.
Check to see that you succeeded with:

```
cat /etc/shells
```

If the line you included is shown at the end, then proceed to run:

```
chsh -s /usr/local/bin/fish
```

Close the terminal and reopen it to check to see if Fish is running by default.
If you want to turn on the Vim key-bindings within Fish, run the following:

```
fish_vi_key_bindings
```

If you aren't already comfy with vim-like modes, the vi-mode in Fish may be cumbersome, and best to avoid during the installation.


## Dependencies

Check to see that you have `git` installed by running:

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

Install Node if it is not installed already (you can check with `--version` as above), run:

```
brew install node
```

Check if Python 3 is installed by running the following:

```
Python3 --version
```

If absent, run the following (yes, without the '3' on the end):

```
brew install python
```

Install the RobotoMono [Nerd Font](https://github.com/ryanoasis/nerd-fonts) with:

```
brew tap homebrew/cask-fonts
brew install --cask font-roboto-mono-nerd-font
```

More options can be found [here](https://github.com/Homebrew/homebrew-cask-fonts) or by searching for Nerd Fonts that can be installed with Homebrew.
If you are using the default Mac Terminal, you will need to select the font that you just installed by navigating through the menu `Terminal --> Preferences --> Profiles --> Change Font` and selecting RobotoMono or similar.
However, I highly recommend installing a better terminal as detailed in the last section, providing a faster cleaner looking setup which is easy to configure given the config files that I have included. 
Nevertheless, the Mac terminal will do for completing the installation process detailed below.

Lastly, check to see if the following are installed with `--version` as above and install whatever is missing:

```
brew install fzf
brew install ripgrep
brew install pandoc
brew install pandoc-plot
brew install npm
brew install wget
sudo pip3 install neovim-remote
```


## [NeoVim](https://neovim.io/)

Install the most recent version of NeoVim by running:

```
brew install neovim
```

Once the installation is complete, open NeoVim by entering:

```
nvim
```

You can enter normal-mode in NeoVim from any mode by hitting escape.
To check the health of your NeoVim install, enter command-mode in NeoVim from normal mode by hitting `:` and running: 

```
checkhealth
```

Wait for the report to finish.
If Python 3 reports an error, run the following in the terminal (to exit NeoVim, write `:qa!`):

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

You are now ready to pull down the configuration files.


## [Configuration](https://github.com/benbrastmckie/.config)

I recommend forking my config so that you have your own version that you can customise for yourself. 
To do so you will need to make a GitHub account if you don't have one already. 
Then click `Fork` in my GitHub config repo in order to copy the repo over to your GitHub. 
Make yourself the owner.
There is no need to include other branches besides the master branch which will be selected by default.
Once you have forked the repo, you can click the `Code` button in your fork of the config repo, selecting SSH, and copying the address which you will use below. 
If you don't have an SSH key set up, then you can select HTTPS instead, though you will have to change this to SSH if you want to be able to push changes up to your fork of the repo without typing in a password every time.
See the instructions below to set up a SSH key.
If you don't want to fork the repo at all, then click the `Code` button in my repo, copying the HTTPS address. 
Now you are ready to open the terminal back up and run the following commands making the appropriate substitution:

```
cd ~/.config
ls -a
git init
ls -a
git remote add origin YOUR-OR-MY-ADDRESS
git remote -v
git pull origin master
ls -a
```

The `ls -a` commands are optional but will help you to see what is happening.
In particular, `git pull origin master` will pull down the config files into your `~/.config` directory.
The other git commands add a new git repo, link your local repo to your fork, and confirm that the addresses have been added so that you are ready to push and pull changes from your fork on GitHub. 
This will permit you keep your config backed up to your GitHub repo and to pull your repo down onto other computers if you want to reproduce your customised config once you have made changes.

Finally we may edit the `options.lua` file, deleting the final block which is not needed for Mac users with `Vim` rather than `NeoVim`:

```
vim ~/.config/nvim/lua/user/options.lua
```

Scroll to the bottom with `G`, move the cursor into the final block by moving the cursor up to any line in that final block by hitting `k` enough times (the block should begin with a note to Mac users), and then hit `dap` for 'delete all paragraph'.
Save and quit with `:wq` and reopen NeoVim with `nvim`.
Once inside NeoVim, run the following commands:

```
:PackerInstall
:PackerUpdate
```

Run `:checkhealth` troubleshooting any errors with the exception of VimTex which will be fixed by the sections below.
You can ignore all the warnings, but should troubleshoot any errors that persist.


## [LaTeX](https://www.latex-project.org/)

If you are here, you are probably familiar with LaTeX and already have it installed. 
But just in case you haven't installed LaTeX already, you can run the following command in order to check to see if it is already installed:

```
latexmk --version
```

To install MacTex, you can download the package [here](https://www.tug.org/mactex/), or else run the following command:

```
brew install --cask mactex
```

This will take a while.
Once it finishes, reboot your computer and run:

```
latexmk --version
```

You should now find that `latexmk` is installed.


## [Skim](https://skim-app.sourceforge.io)

It is important to choose a pdf-viewer that will sync with your LaTeX document, and Skim is a good choice for Mac OS.
To install Skim, run the following commands:

```
brew install skim
alias skim='/Applications/Skim.app/Contents/MacOS/Skim'
funcsave skim
```

You should now be able to open Skim with the command `skim` inside the terminal.
Change the automatic refreshing in Skim by opening the `Skim` menu and navigating to `Preferences` and selecting the `Sync` tab.
Check both `Check for file changes` and `Reload automatically`.
In the `Preset` menu, select custom and set the `Command` to `nvim` with the `Arguments` as follows:

```
--headless -c "VimtexInverseSearch %l '%f'"
```

Close the preferences menu and open NeoVim with:

```
nvim ~/.config/nvim/lua/user/vimtex.lua
```

Replace both 'okular' and 'zathura' with 'skim'.
Now run `:checkhealth` inside NeoVim and scroll to the VimTex section at the bottom to confirm that everything is OK.

Create a new file with `<space>e` and hitting `a` once you navigate to an appropriate location by using the `j` and `k` to move up and down as well as `h` and `l` to expand or collapse directories.
Open the new file by hitting `Enter` and load a template with `<space>tp`.
Build the pdf with `<space>b` checking to see if Skim loads.
After building, you can view locations within the pdf with `<space>v` in NeoVim.
Similarly, you can locate lines in the LaTeX document with `Command + Shift + Left-click` in Skim.

If you want to use Zathura as your primary pdf viewer and only launching Skim from the VimTex Context menu, follow the instructions given by running the following NeoVim command:

```
:h vimtex-faq-zathura-macos
```

Note that getting Zathura to work with MacOS may be a challenge.


## [Zotero](https://www.zotero.org/)

If you already have Zotero installed but want to sync Zotero with the config, then skip to the next paragraph.
Otherwise, begin by downloading and installing [Zotero](https://www.zotero.org/) along with the appropriate plugin for your preferred browser.
Find a paper online, signing in to the journal as necessary and downloading the pdf manually.
Now return to the paper on the journal's website and test the browser plugin for Zotero which should be displayed in the top right of the screen.
Note that you can also import .bib libraries with Zotero, though it is important to set you citation key format as described below before doing so.

Download and install Better BibTex by following [these](https://retorque.re/zotero-better-bibtex/installation/) instructions.
Under `Zotero` in the Zotero menu bar, select `Preferences` and open up the `Better BibTex` tab.
Under the `Citation keys` sub-tab, replace the citation key format with `auth.fold + year`.
This will make the default citation keys have the format `NameYearLetter`, where the `Letter` will increase through the alphabet if there are multiple entries for the same author and year.
If you want to create a different key format, you can find more options [here](https://retorque.re/zotero-better-bibtex/citing/#generating-citekeys).
I also recommend keeping keys unique `across all libraries` and permitting non-pinned keys to be `postfixed` which you will select from drop-down menus.
Now that your citation key format has been set, feel free to import any .bib libraries that you might want to use.

Next switch to the `Automatic Export` sub-tab and select `On Change` so that your .bib database stays updated when you add bib entries.
Close the Preferences window, returning to the main Zotero window.

Create the bib and bst directories, and move the .bst bibliography style files into the appropriate folder by running the following:

```
mkdir -p ~/Library/texmf/bibtex/bib
cp -R ~/.config/latex/bst ~/Library/texmf/bibtex
```

Return to Zotero, right-click the main library folder in the left-most column, and select `Export Library`.
Under the `Format` drop-down menu, select `Better BibTex` and check the `Keep Updated` box. 
Save the file as `Zotero` (the extension will be added automatically) to `~/Library/texmf/bibtex/bib` which you previously created.
If you have trouble finding the Library directory, you may need to remove the MacOS child-locks by opening `Finder`, clicking the `Go` menu, and selecting  `Go to Folder`.
Type `/Users` and then open the directory associated with your username.
Now go to the `View` menu, select `Show View Options`, and check `Show Library Folder`.
Go back to Zotero and export your library as directed above.

In order to make use of Telescope for searching through your citations, change `~/texmf/bibtex/bib/Zotero.bib` to `~/Library/texmf/bibtex/bib/Zotero.bib` by first opening the following file:

```
nvim ~/.config/nvim/lua/user/telescope.lua
```

After saving and quitting with `<space>q` you are ready to cite files in your Zotero database with `<space>fc` as well as autocompleting citation keys inside citations contexts like '\citet{ ... }'.
If your citation autocomplete does not work but searching for citations with `<space>fc` does work, then try clearing the VimTex cache inside NeoVim with:

```
:VimtexClearCache kpsewhich
```

This should fix the issue.


## Terminal (Optional)

As an alternative to the stock terminal, I recommend installing either [Kitty](https://github.com/kovidgoyal/kitty) or else a combination of [Alacritty](https://github.com/alacritty/alacritty) and [Tmux](https://github.com/tmux/tmux/wiki).
There is nothing wrong with installing Kitty in addition to both Alacritty and Tmux, choosing which you prefer later.

```
brew install --cask kitty
brew install --cask alacritty
brew install tmux
```

If you installed Kitty, you can edit `~/.config/kitty/kitty.conf` if desired, but no changes are required to run `nvim` in Kitty.
If you installed Alacritty and Tmux, move the Tmux configuration file to the appropriate location by running:


```
sudo cp ~/.config/tmux/.tmux.conf ~/.tmux.conf
```

Assuming that you already installed Fish above, you will need to locate fish on your operating system by running the following:

```
which fish
```

The command should return `/usr/local/bin/fish` or something similar.
Copy the displayed path and run the following:

```
nvim ~/.config/alacritty/alacritty.yml
```

Replace `/usr/bin/fish` with the location of Fish displayed above (you can search for 'fish' in `alacritty.yml` with `/` followed by 'fish').
You may also search for 'Window position', setting the `x` and `y` values along with the window dimensions which are set just above, or comment out the position block by adding `#` in front of those three lines in order to assume system defaults upon opening Alacritty.
Save and exit, opening Alacritty with `Command + Space` and typing 'Alacritty', and run the following to reset Tmux:

```
tmux kill-server
```

When you reopen Alacritty Fish should be the default shell inside a Tmux window.
You are now read use NeoVim in Alacritty, complete with Tmux and the Fish shell.
That is, to open NeoVim, open Alacritty and type `nvim`.
See the [Cheat Sheet](https://github.com/benbrastmckie/.config/blob/master/CheatSheet.md) for the Tmux window commands.


## [Git](https://git-scm.com/) (Optional)

Whether you forked my config or not, the following steps will help you set up a GitHub repo that you can push and pull changes to so that you can keep your customised config backed up and accessible to other computers that you might want to pull this config down onto.
You can begin by checking to see if you have already set the appropriate username and email with:

```
git config -l
```

If absent or incorrect, add your details making appropriate substitutions:

```
git config --global user.name "YOUR-USERNAME"
git config --global user.email "YOUR-EMAIL"
git config -l
```

Your details should now appear.

You can now begin to set up your remote repository to push and pull changes from.
If you forked my config, you can skip the following subsection.


### Cloned Config

Assuming that you did not fork my config, make an account on GitHub if you haven't already, create a new repository called 'config' or something similar (without including a Readme), and copy the SSH address which should be shown upon clicking the `Code` button.
Now run:

```
cd ~/.config
git remote -v
```

You can remove any addresses that appear with the following command, replacing 'origin' with the name of the addresses which appears on the left if different from 'origin':

```
git remote remove origin
git remote -v
```

Remove all addresses until none remain.
Having already copied the SSH address of your repo as directed above, you can add that address to your local git repo by running the following commands:

```
git remote add origin YOUR-ADDRESS
git remote -v
```

If your address appears, you are ready to push changes.


### Pushing Changes

Navigate to your config directory and open the `init.lua` file with NeoVim as follows:

```
cd ~/.config/
nvim nvim/init.lua
```

Open LazyGit with `<space>gg`.
In the top left corner you will see a bunch of files in red.
Untracked files will be marked with '??' on the left, where tracked files that have been modified will be marked by an 'M' on the left.
Tracked files that have not been changed will not appear.
You can navigate through all displayed files with `j` and `k`, where `h` and `l` switch panes (which we won't need here), and `q` exits LazyGit.

You will probably want to ignore all of the untracked files.
In general, you want to ignore all files that aren't included in the config, i.e., anything that you would also want to ignore on another computer that you might pull your config onto.
To ignore an untracked file, navigate to it using `j` and `k` and open the ignore menu by pressing `i`.
You can then either ignore the file by pressing `i` again, or exclude the file by pressing `e`.
It is best to exclude files and directories that are specific to the computer that you are using, and ignore files and directories that are not specific to your current computer.
Given that you just pulled down the config where all files included in the config are already tracked, you can safely exclude all untracked files that appear since these will be specific to the computer that you are working on.
Once you have excluded (or ignored) an untracked file, it will disappear.
You can always undo an accidental git-ignore by editing the ignore files with the following commands:

```
nvim ~/.config/.gitignore
nvim ~/.config/.git/info/exclude
```

Remove any lines that you did not want to include in the ignore list and save and quit with `<space>q`.

If there are any untracked files that you want to include in this config (e.g., a config file for some other program that you want to track), you can stage those files by navigating to them and hitting `<space>`.
Once you have excluded or ignored (or possibly staged) each of the untracked files that originally appeared, you can begin to stage the modified files either by hitting `<space>` when hovering over each file, or by hitting `a` to stage all files assuming that there are no remaining untracked files.
Once all files have been staged, you can commit changes with `c`, entering a message such as "initial commit" and hitting `Enter`.
You can now push your changes up to your repo with `P`.
This may require that you enter your GitHub password.
To avoid having to enter your password each time you want to push changes, see the instructions in the next section.


### Adding an SSH Key to GitHub

If you have not already, you can add an SSH key by amending and running the following:

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

Run the following to copy the SSH key to your system clipboard and return to fish:

```
pbcopy < ~/.ssh/id_rsa.pub
fish
```

In the top right corner of your GitHub page, click `Profile -> Settings -> SSH and GPG Keys` selecting `New SSH Key`.
Name the authentication key after the devise you are using, pasting the SSH key from the clipboard into the appropriate field.
Saving the key completes the addition.

Check to make sure that the SSH key is working by pushing commits up to one of your repositories as directed above.
If your SSH key stops working after rebooting, run the following command:

```
ssh-add -K ~/.ssh/id_rsa
```

If you get an error, retry the command above with a lower-case 'k' or without the 'K' altogether.


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

Repeat the steps above after making a small change to your config to run another test, entering your username and PAT as before.
Run one final test, checking to see if your credentials are now automatically submitted, avoiding the need to enter your username and PAT each time you push or pull changes.

For more help, see these [video](https://www.youtube.com/watch?v=kHkQnuYzwoo) instructions.


<!-- ### Installing the GitHub Cli -->
<!---->
<!-- Assuming that you are using GitHub to host your repositories, it is convenient to install the GitHub Cli which allows you to make changes to your repositories directly from the terminal inside NeoVim: -->
<!---->
<!-- ``` -->
<!-- brew install gh -->
<!-- ``` -->
<!---->
<!-- For further information, see the section **GitHub Cli** in the [Cheat Sheet](https://github.com/benbrastmckie/.config/blob/master/CheatSheet.md) as well as the [GitHub Cli Repo](https://github.com/cli/cli). -->



# Arch Linux Installation

This installation will begin with necessities and conclude with details for an optional installation of Fish and either Kitty or else both Alacritty and Tmux to improve your terminal, as well as details for how to add an SSH key and PAT for streamlining your experience of Git.
If you find any errors in these installation instructions, please don't hesitate to let me know by submitting a PR or opening an issue.

## Dependencies

Open the terminal and run:

```
python3 --version
```

If Python3 is not installed, run:

```
sudo pacman -S python
```

Install NeoVim with:

```
sudo pacman -S neovim
```

In order to install plugins to extend the functionality of NeoVim, run the following:

```
git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 ~/.local/share/nvim/site/pack/packer/start/packer.nvimq
```

Install the following if they are not already installed:

```
sudo pacman -S install git
sudo pacman -S lazygit
sudo pacman -S fzf
sudo pacman -S ripgrep
sudo pacman -S pandoc
sudo pacman -S pandoc-citeproc
sudo pacman -S node
sudo pacman -S npm
sudo pacman -S wget
sudo pacman -S xsel
sudo pip3 install neovim-remote
```

Open NeoVim by running `nvim` in the terminal and run the following command:

```
:checkhealth
```

If Python 3 reports an error, try running:

```
pip3 install --user pynvim
```

Troubleshoot any errors that persist by continuing to run `:checkhealth`, following the advice provided for each error.
All warnings can be ignored.


## [LaTeX](https://www.latex-project.org)

Check to see LaTeX is already installed with:

```
latexmk --version
```

To install LaTeX, run the following

```
sudo pacman -S texlive
```

After rebooting, confirm that LaTeX is installed by running:

```
latexmk --version
```


## [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts)

In order for NeoVim to load icons, it will be imporant to install a NerdFont.
For simplicity, I have included RobotoMono in `~/.config/fonts` which you can now move to the appropriate folder on your computer by entering the following in the terminal:

```
sudo cp -R ~/.config/fonts/RobotoMono/ /usr/share/fonts
```

If you intend to use the stock terminal, you will need to go into the terminal's settings to change the font to RobotoMono regular.
You are now ready to write LaTex in NeoVim inside the stock terminal.


## [Zathura](https://pwmt.org/projects/zathura/)

Install the Zathura pdf-viewer by running:

```
sudo pacman -S zathura
```

If you want to customise Zathura, you can edit `~/.config/zathura/zathurarc`, referring to the documents by running:

```
man zathuraarc
```

Although Zathura is an ideal pdf-viewer for writing LaTeX documents, you may want to use your default pdf-viewer for opening the pdfs associated with citations via the VimTex context-menu.
For instance, I use [Okular](https://okular.kde.org) which you can install by running:

```
sudo pacman -S okular
```

If you want to use a different pdf-viewer than Okular, replace 'okular' in the following file with your desired pdf-viewer:

```
nvim ~/.config/nvim/plug-config/vimtex.vim
```

Alternatively, you could replace 'okular' with 'zathura'.


## [Configuration](https://github.com/benbrastmckie/.config)

I recommend forking my config, coppying the SSH address by clicking the `Code` button in your fork of the config. 
Alternatively, if you don't want to fork, click the `Code` button in my repo. 
Now you are ready to open the terminal back up and run the following commands making the appropriate substitution:

```
cd ~/.config
git init
git remote add origin YOUR-OR-MY-ADDRESS
git remote -v
git pull origin master
ls -a
```

Run NeoVim to install the plugins:

```
nvim
```

If the plugins do not automatically install, then run:

```
:PackerInstall
:PackerUpdate
```

After the plugins finish installing, exit and reopen NeoVim, running:

```
:checkhealth
```

Troubleshoot any errors by following the advice provided.


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


## Terminal (Optional)

As an alternative to the stock terminal, I recommend installing either [Kitty](https://github.com/kovidgoyal/kitty) or else a combination of [Alacritty](https://github.com/alacritty/alacritty) and [Tmux](https://github.com/tmux/tmux/wiki).
Either way, I also recommend using the [Fish](https://fishshell.com/) shell.
There is nothing wrong with installing Kitty in addition to both Alacritty and Tmux, choosing which you prefer later.

```
sudo pacman -S kitty
sudo pacman -S alacritty
sudo pacman -S tmux
sudo pacman -S fish
```

If you installed Kitty, you can edit `~/.config/kitty/kitty.conf` if desired, but no changes are required to run `nvim` in Kitty.
If you installed Alacritty and Tmux, move the Tmux configuration file to the appropriate location by running:

```
sudo cp ~/.config/tmux/.tmux.conf ~/.tmux.conf
```

Assuming that you installed Alacritty and want to use the Fish shell, you will now need to locate fish on your operating system by running the following:

```
which fish
```

The command should return `/usr/bin/fish`.
If the path is different, copy the path and run the following:

```
nvim ~/.config/alacritty/alacritty.yml
```

Replace '/usr/bin/fish' with the location of fish if different, saving and exiting with `<space>q`.
Regardless of which terminal you opted for, I recommend customising the Fish shell by running the following:

```
curl -L https://get.oh-my.fish | fish
omf install sashimi
```

To delete the welcome message, run:

```
set -U fish_greeting ""
```

If you are running Alacritty with Tmux, you can now reset Tmux as follows:

```
tmux kill-server
```

When you reopen Alacritty, Fish should be the default shell inside a Tmux window.
If you want to turn on the Vim keybindings within Fish, run the following:

```
fish_vi_key_bindings
```

You are now read use NeoVim in Alacritty, complete with Tmux and the Fish shell.


## [Git](https://git-scm.com/) (Optional)

You can begin by checking to see if you have already set the appropriate username and email with:

```
git config -l
```

If absent or incorrect, add your details making appropriate substitutions:

```
git config --global user.name "YOUR-USERNAME"
git config --global user.email "YOUR-EMAIL"
git config -l
```

Your details should now appear.

You can now begin to set up your remote repository to push and pull changes from.
If you forked my config, you can skip the following subsection.


### Cloned Config

Assuming that you did not fork my config, make an account on GitHub if you haven't already, create a new repository called 'config' or something similar (without including a Readme), and copy the SSH address which should be shown upon clicking the `Code` button.
Now run:

```
cd ~/.config
git remote -v
```

You can remove any addresses that appear with the following command, replacing 'origin' with the name of the addresses which appears on the left if different from 'origin':

```
git remote remove origin
git remote -v
```

Remove all addresses until none remain.
Having already copied the SSH address of your repo as directed above, you can add that address to your local git repo by running the following commands:

```
git remote add origin YOUR-ADDRESS
git remote -v
```

If your address appears, you are ready to push changes.


### Pushing Changes

Navigate to your config directory and open the `init.lua` file with NeoVim as follows:

```
cd ~/.config/
nvim nvim/init.lua
```

Open LazyGit with `<space>gg`.
In the top left corner you will see a bunch of files in red.
Untracked files will be marked with '??' on the left, where tracked files that have been modified will be marked by an 'M' on the left.
Tracked files that have not been changed will not appear.
You can navigate through all displayed files with `j` and `k`, where `h` and `l` switch panes (which we won't need here), and `q` exits LazyGit.

You will probably want to ignore all of the untracked files.
In general, you want to ignore all files that aren't included in the config, i.e., anything that you would also want to ignore on another computer that you might pull your config onto.
To ignore an untracked file, navigate to it using `j` and `k` and open the ignore menu by pressing `i`.
You can then either ignore the file by pressing `i` again, or exclude the file by pressing `e`.
It is best to exclude files and directories that are specific to the computer that you are using, and ignore files and directories that are not specific to your current computer.
Given that you just pulled down the config where all files included in the config are already tracked, you can safely exclude all untracked files that appear since these will be specific to the computer that you are working on.
Once you have excluded (or ignored) an untracked file, it will disappear.
You can always undo an accidental git-ignore by editing the ignore files with the following commands:

```
nvim ~/.config/.gitignore
nvim ~/.config/.git/info/exclude
```

Remove any lines that you did not want to include in the ignore list and save and quit with `<space>q`.

If there are any untracked files that you want to include in this config (e.g., a config file for some other program that you want to track), you can stage those files by navigating to them and hitting `<space>`.
Once you have excluded or ignored (or possibly staged) each of the untracked files that originally appeared, you can begin to stage the modified files either by hitting `<space>` when hovering over each file, or by hitting `a` to stage all files assuming that there are no remaining untracked files.
Once all files have been staged, you can commit changes with `c`, entering a message such as "initial commit" and hitting `Enter`.
You can now push your changes up to your repo with `P`.
This may require that you enter your GitHub password.
To avoid having to enter your password each time you want to push changes, see the instructions in the next section.


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
Name the authentication key after the devise you are using, pasting the SSH key from the clipboard into the appropriate field.
Saving the key completes the addition.

Check to make sure that the SSH key is working by pushing commits up to one of your repositories as directed above.
If your SSH key stops working after rebooting, run the following command:

```
ssh-add -K ~/.ssh/id_rsa
```

If you get an error, retry the command above with a lower-case 'k' or without the 'K' altogether.


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

Repeat the steps above after making a small change to your config to run another test, entering your username and PAT as before.
Run one final test, checking to see if your credentials are now automatically submitted, avoiding the need to enter your username and PAT each time you push or pull changes.

For more help, see these [video](https://www.youtube.com/watch?v=kHkQnuYzwoo) instructions.


<!-- ### Installing the GitHub Cli -->
<!---->
<!-- Assuming that you are using GitHub to host your repositories, it is convenient to install the GitHub Cli which allows you to make changes to your repositories directly from the terminal inside NeoVim: -->
<!---->
<!-- ``` -->
<!-- sudo pacman -S github-cli -->
<!-- ``` -->
<!---->
<!-- You will then need to follow the [instructions](https://cli.github.com/manual/) in order to authenticate GitHub Cli by running: -->
<!---->
<!-- ``` -->
<!-- gh auth login -->
<!-- ``` -->
<!---->
<!-- Set NeoVim as your default editor by running: -->
<!---->
<!-- ``` -->
<!-- gh config set editor nvim -->
<!-- ``` -->
<!---->
<!-- For further information, see the section **GitHub Cli** in the [Cheat Sheet](https://github.com/benbrastmckie/.config/blob/master/CheatSheet.md) as well as the [GitHub Cli Repo](https://github.com/cli/cli). -->



# Debian Linux Installation

This installation will begin with necessities and conclude with details for an optional installation of Fish and either Kitty or Alacritty together with Tmux to improve your terminal, as well as details for how to add an SSH key and PAT for streamlining your experience of Git.
If you find any errors in these installation instructions, please don't hesitate to let me know by submitting a PR or opening an issue.

## Dependencies

Open the terminal and run:

```
python3 --version
```

If Python3 is not installed, run:

```
sudo apt install python3
```

Check the version of `node` with:

```
node --version
```

If the version is outdated, remove `node` with:

```
apt-get purge nodejs &&\
rm -r /etc/apt/sources.list.d/nodesource.list
```

Install a newer version with:

```
curl -fsSL https://deb.nodesource.com/setup_19.x | sudo -E bash - &&\
sudo apt-get install -y nodejs
```

Install LazyGit with:

```
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin
rm -rf lazygit.tar.gz
lazygit --version
```

Assuming the final command returns the version of LazyGit, proceed to install NeoVim, beginning with the following prerequisites:

```
sudo apt-get install ninja-build gettext libtool-bin cmake g++ pkg-config unzip curl
```

Once these complete, run:

```
cd ~/Downloads
git clone https://github.com/neovim/neovim
cd neovim && make CMAKE_BUILD_TYPE=RelWithDebInfo
sudo make install
nvim
```

This final command should launch NeoVim assuming everything went smoothly.
In case you hit any snags, you can find more information [here](https://github.com/neovim/neovim/wiki/Building-Neovim).

In order to install plugins to extend the functionality of NeoVim, run the following:

```
git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 ~/.local/share/nvim/site/pack/packer/start/packer.nvimq
```

Install the following if they are not already installed:

```
sudo apt install git
sudo apt install fzf
sudo apt install ripgrep
sudo apt install pandoc
sudo apt install pandoc-citeproc
sudo apt install nodejs
sudo apt install wget
sudo apt install xsel
sudo apt install python3-pip
sudo pip3 install neovim-remote
```

Open NeoVim by running `nvim` in the terminal and run the following command:

```
:checkhealth
```

If Python 3 reports an error, try running:

```
pip3 install --user pynvim
```

If `treesitter` throws an error, you can try running `:TSUpdate` in NeoVim.
Troubleshoot any errors that persist by continuing to run `:checkhealth`, following the advice provided for each error.
All warnings can be ignored.


## [LaTeX](https://www.latex-project.org)

Check to see LaTeX is already installed with:

```
latexmk --version
```

To install LaTeX, run the following

```
sudo apt install texlive-most
```

Alternatively you can run:

```
sudo apt install texlive-full
```

After rebooting, confirm that LaTeX is installed by running:

```
latexmk --version
```


## [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts)

In order for NeoVim to load icons, it will be imporant to install a NerdFont.
For simplicity, I have included RobotoMono in `~/.config/fonts` which you can now move to the appropriate folder on your computer by entering the following in the terminal:

```
sudo cp -R ~/.config/fonts/RobotoMono/ /usr/share/fonts
```

If you intend to use the stock terminal, you will need to go into the terminal's settings to change the font to RobotoMono regular.
You are now ready to write LaTex in NeoVim inside the stock terminal.


## [Zathura](https://pwmt.org/projects/zathura/)

Install the Zathura pdf-viewer by running:

```
sudo apt install zathura
```

If you want to customise Zathura, you can edit `~/.config/zathura/zathurarc`, referring to the documents by running:

```
man zathuraarc
```

Although Zathura is an ideal pdf-viewer for writing LaTeX documents, you may want to use your default pdf-viewer for opening the pdfs associated with citations via the VimTex context-menu.
For instance, I use [Okular](https://okular.kde.org) which you can install by running:

```
sudo apt install okular
```

If you want to use a different pdf-viewer than Okular, replace 'okular' in the following file with your desired pdf-viewer:

```
nvim ~/.config/nvim/plug-config/vimtex.vim
```

Alternatively, you could replace 'okular' with 'zathura'.


## [Configuration](https://github.com/benbrastmckie/.config)

I recommend forking my config, coppying the SSH address by clicking the `Code` button in your fork of the config. 
Alternatively, if you don't want to fork, click the `Code` button in my repo. 
Now you are ready to open the terminal back up and run the following commands making the appropriate substitution:

```
cd ~/.config
git init
git remote add origin YOUR-OR-MY-ADDRESS
git remote -v
git pull origin master
ls -a
```

Run NeoVim to install the plugins:

```
nvim
```

If the plugins do not automatically install, then run:

```
:PackerInstall
:PackerUpdate
```

After the plugins finish installing, exit and reopen NeoVim, running:

```
:checkhealth
```

Troubleshoot any errors by following the advice provided.


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


## Terminal (Optional)

As an alternative to the stock terminal, I recommend installing either [Kitty](https://github.com/kovidgoyal/kitty) or else a combination of [Alacritty](https://github.com/alacritty/alacritty) and [Tmux](https://github.com/tmux/tmux/wiki).
Either way, I also recommend using the [Fish](https://fishshell.com/) shell.
There is nothing wrong with installing Kitty in addition to both Alacritty and Tmux, choosing which you prefer later.

To install Kitty and Fish, run:
```
sudo apt install kitty
sudo apt install fish
```

Alternatively (or additionally) to Kitty, you may install Alacritty and Tmux with:

```
sudo add-apt-repository ppa:aslatter/ppa -y
sudo apt install alacritty
sudo apt install tmux
```

If you installed Kitty, you can edit `~/.config/kitty/kitty.conf` if desired, but no changes are required to run `nvim` in Kitty.
If you installed Alacritty and Tmux, move the Tmux configuration file to the appropriate location by running:

```
sudo cp ~/.config/tmux/.tmux.conf ~/.tmux.conf
```

Assuming that you installed Alacritty and want to use the Fish shell, you will now need to locate fish on your operating system by running the following:

```
which fish
```

The command should return `/usr/bin/fish`.
If the path is different, copy the path and run the following:

```
nvim ~/.config/alacritty/alacritty.yml
```

Replace '/usr/bin/fish' with the location of fish if different, saving and exiting with `<space>q`.
Regardless of which terminal you opted for, I recommend customising the Fish shell by running the following:

```
curl -L https://get.oh-my.fish | fish
omf install sashimi
```

To delete the welcome message, run:

```
set -U fish_greeting ""
```

If you are running Alacritty with Tmux, you can now reset Tmux as follows:

```
tmux kill-server
```

When you reopen Alacritty, Fish should be the default shell inside a Tmux window.
If you want to turn on the Vim keybindings within Fish, run the following:

```
fish_vi_key_bindings
```

You are now read use NeoVim in either Kitty or else Alacritty and Tmux complete with the Fish shell.


## [Git](https://git-scm.com/) (Optional)

You can begin by checking to see if you have already set the appropriate username and email with:

```
git config -l
```

If absent or incorrect, add your details making appropriate substitutions:

```
git config --global user.name "YOUR-USERNAME"
git config --global user.email "YOUR-EMAIL"
git config -l
```

Your details should now appear.

You can now begin to set up your remote repository to push and pull changes from.
If you forked my config, you can skip the following subsection.


### Cloned Config

Assuming that you did not fork my config, make an account on GitHub if you haven't already, create a new repository called 'config' or something similar (without including a Readme), and copy the SSH address which should be shown upon clicking the `Code` button.
Now run:

```
cd ~/.config
git remote -v
```

You can remove any addresses that appear with the following command, replacing 'origin' with the name of the addresses which appears on the left if different from 'origin':

```
git remote remove origin
git remote -v
```

Remove all addresses until none remain.
Having already copied the SSH address of your repo as directed above, you can add that address to your local git repo by running the following commands:

```
git remote add origin YOUR-ADDRESS
git remote -v
```

If your address appears, you are ready to push changes.


### Pushing Changes

Navigate to your config directory and open the `init.lua` file with NeoVim as follows:

```
cd ~/.config/
nvim nvim/init.lua
```

Open LazyGit with `<space>gg`.
In the top left corner you will see a bunch of files in red.
Untracked files will be marked with '??' on the left, where tracked files that have been modified will be marked by an 'M' on the left.
Tracked files that have not been changed will not appear.
You can navigate through all displayed files with `j` and `k`, where `h` and `l` switch panes (which we won't need here), and `q` exits LazyGit.

You will probably want to ignore all of the untracked files.
In general, you want to ignore all files that aren't included in the config, i.e., anything that you would also want to ignore on another computer that you might pull your config onto.
To ignore an untracked file, navigate to it using `j` and `k` and open the ignore menu by pressing `i`.
You can then either ignore the file by pressing `i` again, or exclude the file by pressing `e`.
It is best to exclude files and directories that are specific to the computer that you are using, and ignore files and directories that are not specific to your current computer.
Given that you just pulled down the config where all files included in the config are already tracked, you can safely exclude all untracked files that appear since these will be specific to the computer that you are working on.
Once you have excluded (or ignored) an untracked file, it will disappear.
You can always undo an accidental git-ignore by editing the ignore files with the following commands:

```
nvim ~/.config/.gitignore
nvim ~/.config/.git/info/exclude
```

Remove any lines that you did not want to include in the ignore list and save and quit with `<space>q`.

If there are any untracked files that you want to include in this config (e.g., a config file for some other program that you want to track), you can stage those files by navigating to them and hitting `<space>`.
Once you have excluded or ignored (or possibly staged) each of the untracked files that originally appeared, you can begin to stage the modified files either by hitting `<space>` when hovering over each file, or by hitting `a` to stage all files assuming that there are no remaining untracked files.
Once all files have been staged, you can commit changes with `c`, entering a message such as "initial commit" and hitting `Enter`.
You can now push your changes up to your repo with `P`.
This may require that you enter your GitHub password.
To avoid having to enter your password each time you want to push changes, see the instructions in the next section.


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
Name the authentication key after the devise you are using, pasting the SSH key from the clipboard into the appropriate field.
Saving the key completes the addition.

Check to make sure that the SSH key is working by pushing commits up to one of your repositories as directed above.
If your SSH key stops working after rebooting, run the following command:

```
ssh-add -K ~/.ssh/id_rsa
```

If you get an error, retry the command above with a lower-case 'k' or without the 'K' altogether.


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

Repeat the steps above after making a small change to your config to run another test, entering your username and PAT as before.
Run one final test, checking to see if your credentials are now automatically submitted, avoiding the need to enter your username and PAT each time you push or pull changes.

For more help, see these [video](https://www.youtube.com/watch?v=kHkQnuYzwoo) instructions.


<!-- ### Installing the GitHub Cli -->
<!---->
<!-- Assuming that you are using GitHub to host your repositories, it is convenient to install the GitHub Cli which allows you to make changes to your repositories directly from the terminal inside NeoVim: -->
<!---->
<!-- ``` -->
<!-- sudo apt install github-cli -->
<!-- ``` -->
<!---->
<!-- You will then need to follow the [instructions](https://cli.github.com/manual/) in order to authenticate GitHub Cli by running: -->
<!---->
<!-- ``` -->
<!-- gh auth login -->
<!-- ``` -->
<!---->
<!-- Set NeoVim as your default editor by running: -->
<!---->
<!-- ``` -->
<!-- gh config set editor nvim -->
<!-- ``` -->
<!---->
<!-- For further information, see the section **GitHub Cli** in the [Cheat Sheet](https://github.com/benbrastmckie/.config/blob/master/CheatSheet.md) as well as the [GitHub Cli Repo](https://github.com/cli/cli). -->


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
