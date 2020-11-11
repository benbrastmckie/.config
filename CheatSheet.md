# Cheat Sheet [(Video 3/3)](https://youtu.be/TMA7nu9KCEQ)

The following sections present a list of key-bindings and features which have been included in the present configuration.
I will provide links to associated tutorial videos throughout, omitting mention of the standard Vim commands which have mostly been preserved.
For configuration instructions, see the installation [(Video 1/3)](https://youtu.be/JVIcU9ePtVE).
I will also provide links to further resources for learning Vim below.

## Table of Contents

1. [Learning Vim](##Learning-Vim)
2. [Mappings](##Mappings)
3. [Learning Git](##Learning-Git)

## Learning Vim

NeoVim maintains the same modes, key-bindings, and conventions as Vim and Vi which go back as far as the late 70s.
With some some practice, these conventions provide an extremely powerful and efficient way to edit text documents, making up the core functionality which NeoVim has to offer.
Learning to use NeoVim is comparable to learning how to touch-type: it will take a concerted effort over a short period of time to get a good foundation from which mastery can slowly be cultivated over the years to come.
However, even with just the foundations, NeoVim offers a significant increase in efficiency, well worth the initial investment.
See the introduction [(Video 1/7)](https://youtu.be/pYNvDkB0iRk) for related discussion, as well as the following resources for learning to use NeoVim.

- [OpenVim](https://www.openvim.com/) Free interactive Vim tutorial.
- [VimAdventure](https://vim-adventures.com/) Free game to practice basic Vim commands.
- [Vim Tutor](https://www.youtube.com/watch?v=d8XtNXutVto) A guided tour through `vimtutor`.
- [Tutorial Series](https://www.youtube.com/watch?v=H3o4l4GVLW0&t=1s) Short tutorial video series.
- [Inspiration](https://www.youtube.com/watch?v=1UXHsCT18wE) Inspiration and Comedy.

I have not made any changes to the conventions which come standard with NeoVim, as there is no need to reinvent the wheel.
Rather, what follows is a minimal number of extensions to the functionality provided by NeoVim.

## Mappings

Which-Key is triggered by the space bar, and will bring up a range of key-bindings with associated names.
Accordingly, I will focus attention on the mappings included in `~/.config/nvim/keys/mappings.vim`, though I will mention some of the Which-Key bindings in discussing plugins in the following section.

### _Line Movements_ [(Video 3/3)](https://youtu.be/TMA7nu9KCEQ)

- **Drag lines**: the commands `Alt+j` and `Alt+k` will drag the selected lines up or down in visual, normal, or insert mode, where indenting is adjusted automatically.
- **Better tabbing**: the `<` and `>` keys will adjust indents in both normal and visual mode.
- **Display line movements**: in either normal or visual mode, `Shift+j` and `Shift+k` will vertically navigate displayed lines as opposed to numbered lines, whereas `Shift+h` and `Shift+l` will move to the beginning or end of the displayed line, respectively.

### _Windows, Buffers, and Panes_ [(Video 2/3)](https://youtu.be/Xvu1IKEpO0M)

- **Manage windows**: use `Ctrl+Space,c` to create a new window, and `Ctrl+Space,k` to kill the current window (make sure that all processes have been ended, for instance by closing NeoVim with `<space>q`).
- **Switch windows**: use `Ctrl+Space,n` and `Ctrl+Space,p` to cycle through open windows.
- **Switch buffers**: use `Tab` and `Shift+Tab` to cycle though the open buffers.
- **Navigate panes**: use `Ctrl+h/j/k/l` to switch focus between buffers.
- **Resize panes**: use `Alt+h/l` to horizontally resize the buffer in focus.

### _Commands_ [(Video 3/3)](https://youtu.be/TMA7nu9KCEQ)

- **Save and Quit**: use `Space+w` to save buffer, and `Space+q` to save and quite all buffers.
- **Comment**: in normal mode or visually mode, use `Ctrl+\` to toggle whether the lines in question are commented out.
- **Spelling**: use `Ctrl+s` to search alternatives to misspelled word.
- **Cut and Paste**: use `"dp` and `"dP` to paste previously deleted block below and above respectively.
- **Help**: use `Ctrl+m` to open Help for the word under the cursor.
- **Multiple Cursors**: use `Ctrl+n` to select the word under the cursor, where repeating `Ctrl+n` will select the next occurrences of that word, `Ctrl+x` will skip the current selected occurrence, and `Ctrl+p` will deselect the current occurrence and go back to the previous occurrence of that word.
- **Terminal**: use `Ctrl+t` to toggle the terminal window in NeoVim.

### _Zathura_ [(Video 2/7)](https://youtu.be/KGqrpnxoDxw)

- **Index**: use `Space` to toggle the index.
- **Zoom**: use `Shift+k` and `Shift+j` to zoom in and out, respectively.
- **Print**: use `p` to print.
- **Black Mode**: use `b` to invert colours.

## Plugins

In what follows, I will discuss a number of key plugins included in `~/.config/nvim/vim-plug/plugins.vim` which are of considerable use for writing LaTeX documents.

### _File Management_ [(Video 3/7)](https://youtu.be/v_zYV8G7gOs)

- **Local File Search**: use `Ctrl+p` to fuzzy search for files being tracked by Git in the current project folder, navigating with `Ctrl+j/k`, and opening files with `Enter`.
- **Global File Search**: use `Space+Shift+f` to fuzzy search through all files in the home folder, navigating with `Ctrl+j/k`, and opening files with `Enter`.
- **Explorer**: use `Space+e` to open the file explorer, navigating with `j/k`, adding directories with `Shift+a`, adding files `a`, and opening files with `Enter`.
- **Close Buffer**: use `Space+d` to close current buffer.

### _Projects and Templates_ [(Video 5/7)](https://youtu.be/z5HfVQQDrAg)

- **Projects**: use `Space+Shift+s,s` to create a new project, and `Space+Shift+s,d` to delete a new project.
  - To create a first project, enter the command `:SSave` instead, following the prompt to create a sessions folder.
- **Templates**: use `Space+t` to choose from a variety of templates in the `~/.config/nvim/templates` directory.
  - To add new templates, add the relevant file to `~/.config/nvim/templates`, customising `~/.config/nvim/keys/which-key.vim`.

### _Git Integration_ [(Video 3/7)](http://syoutu.be/v_zYV8G7gOs) [(Video 5/7)](https://youtu.be/z5HfVQQDrAg)

- **LazyGit**: use `<space>gg` to open LazyGit, followed by `?` to see a range of different commands, using `h/j/k/l` to navigate as usual.
- **Fugitive**: use `<space>g` to bring up a range of git commands.

### _Autocomplete_ [(Video 2/7)](https://youtu.be/KGqrpnxoDxw)

- **Select Entry**: use `Ctrl+j` and `Ctrl+k` to cycle through the autocomplete menu.
- **Trigger Completion**: continue typing after selecting desired option.
- **Snippet Completion**: use `Enter` to select highlighted option, and `Tab` to reselect previous field.
- **Go to**: use `gd` to go to the definition of the word under the cursor (if any).
- **Spelling**: use `Ctrl+s` to search alternatives to misspelled word.
- **Hide**: use `Space+k` to hide autocomplete menu, and `Space+r` to restore.

### _Autopairs and Surround_ [(Video 4/7)](https://youtu.be/1fcc5YoCrvc)

- **Autopairs**: use open-quote/bracket to create pair, adding a space if padding is desired, followed by the closing quote/bracket.
- **Add Surround**: in visual select mode use `Shift+s`, or in normal mode use `Space+s,s`, followed by the desired Vim noun to specify the text-object in question, and then enter either:
  - `q/Q` for single/double LaTeX quotes, respectively.
  - Open bracket for brackets with padding, and close bracket for brackets without padding.
- **Change Surround**: in normal mode, use `Space+s` followed by:
  - `k` to remove the next outermost quotes/brackets relative to the position of the cursor.
  - `d` followed by the desired quotes/brackets to be deleted.
  - `c` followed by both the quote/brackets to change, and then the quotes/brackets which are to be inserted instead.

### _LaTeX Support_ [(Video 2/7)](https://youtu.be/KGqrpnxoDxw)

- **Build**: use `Space+b` to toggle auto-build.
- **Preview**: use `Space+p` to preview current line.
- **Index**: use `Ctrl+i` to open the index.
- **Count**: use `Ctrl+c` to count words.
- **Log**: use `Ctrl+l` to open LaTeX log in horizontal split, and `Space+d` to close.
- **Clean**: use `Space+a,k` to delete auxiliary LaTeX files.

### _Markdown_ [(Video 3/3)](https://youtu.be/TMA7nu9KCEQ)

- **Build**: use `Space+m,m` to toggle auto-build.
- **Preview**: use `Space+m,p` to preview document.
- **Kill**: use `Space+m,k` to close document.
- **Select**: use `Space+m,s` to cycle through selection options in a markdown bullet point list.

### _Pandoc_ [(Video 7/7)](https://www.youtube.com/watch?v=l0N5LJTe6-A)

- Use `Space+Shift+p` to select which file format into which you would like to convert the file open in current buffer.
- Alternatively, you can run `:Pandoc [Source file] [Output file]` in the command line to simulate terminal commands.

### _Misc Bindings_ [(Video 3/3)](https://youtu.be/TMA7nu9KCEQ)

- **Search**: use `Space+f` to fuzzy find within the current document.
- **Undo**: use `Space+u` to open the undo tree.
- **Zen Mode**: use `Space+z` to toggle zen mode (best used when the window is maximised).
- **Reload**: use `Space+Shift+r` to reload the configuration files.

## Learning Git

Git is useful for: (1) maintaining a history of changes to your project; (2) backing up the project on a private repository online; (3) managing different ways of developing the project prior to knowing which way is preferable; (4) working on the same project from different computers; and (5) collaborating with others on a shared project.
Although there are a huge number of free resources for learning how to use git, including full lecture series, few resources provide a complete overview of git's most basic functionality.
The following sections will include resources for using all of the basic git commands in LazyGit, providing everything one need to know to use git effectively for oneself and in collaborating with others.
I will include links to further resources below.

### _Basic Git Commands_

- **LazyGit**: to open LazyGit, hit `<space>gg`.
- **Navigate**: use `h` and `l` to move between windows, and `j` and `k` to navigate within windows.
- **Ignore**: use `i` to ignore all files which you do not wish to track, including any file which is not a text file.
  - Note: if you accidentally ignore a file that you did not mean to, return to the project in NeoVim, open the explorer with `<space>e`, hit `.` in order to show hidden files, and open the `.gitignore` file, deleting the appropriate line which names the file you accidentally ignored.
- **Staging**: use `space` to stage files in the files window, or `a` to stage/unstage all files.
- **Commits**: use `c` to commit staged file to local git history.
- **Pull**: use `p` to pull down latest commits from the git repository.
  - Warning: make sure to commit any changes made to the local files before pulling down changes from the git repository.
  - Note: if there are conflicts, hit `return` to generate conflict reports, returning to the file in question to resolve conflicts.
- **Push**: use `P` to push recent commits to the git repository.
  - Note: if changes have been made to the git repository, pull down all changes and resolve any conflicts before pushing to the git repository.
- **Branch**: use `n` in the local branches window to create a new branch, `space` to checkout branches, and `M` to merge highlighted branch into checked out branch.
- **Diff**: in the commits window, use `ctrl+e` to open diff menu, where default diff is between the current file and the highlighted commit.
- **Help**: use `?` to look up the commands for the active window.
- **Exit**: use `<esc>` to return to NeoVim.

### _Initialising Git_

Open the project folder in the terminal with:

```
   cd ~/<path to file from home directory>
```

Alternatively, open the project in NeoVim, hitting `<ctrl+t>` to open the terminal in project folder.
To initialise a local git history, run `git init`.
You may then exit the terminal with `<ctrl+t>` and open LazyGit, ignoring all files you do not wish to track with `i` in the files window as above, and staging all files you wish to track with `space`.
Hit `c` to commit staged files, entering `initial commit` and hitting `return`.
You are now ready to make commits and branches to your local git history.
Using `space` to checkout past commits in the commits window in LazyGit results in a detached-head state which is useful for viewing the history of the project.

- Warning: any changes made to the project in a detached-head state will be lost upon checking out any other commit.

### _Merging Branches_

If you want to develop the project in a new direction which you may end up abandoning, or otherwise want to separate from the development of the rest of the project's development, you can create a new branch with `n` in the local branches window, where the new branch will be automatically checked out as indicated by a `*`.
If the development of the branch is not deemed successful, you can simply abandon the branch by navigating back to the master branch in the local branches window, hitting `space` to checkout master.

- Warning: if you switch branches before committing any changes that you made to the current branch, those changes will be lost.

Once you have returned to the master branch, the history of the project's development in the now abandoned branch will remain stored in the git history unless you delete the abandoned branch by navigating to it in the local branches window and hitting `d`.

Suppose that you return to further develop a previously abandoned branch, and now want to include the changes in the master branch.
To do so, you can merge the finished branch into master by: (1) committing the most recent changes to the no longer abandoned branch; (2) checking out the master branch in the local branches window by navigating to master and hitting `space`; and (3) navigating back to the no longer abandoned branch and hitting `M` in order to merge the selected branch into the checked out branch.

Upon merging branches, there may be conflicts if the two branches have been developed independently in conflicting ways.
If there are conflicts, LazyGit will ask whether to go ahead with merge, where hitting `return` will include all alternatives in the files which have conflicts along with marker syntax.
Search through the files with conflicts for `HEAD`, choosing which alternative is preferable and deleting the other alternative along with all marker syntax.
Upon returning to LazyGit, attempting to stage the files with conflicts should register a message which asks if all conflicts have been resolved, where hitting `return` will stage the file in question.
If staging is not possible, check to make sure that there are no more conflicts, or miscellaneous marker syntax remaining.

### _Remote Repositories_

In order to link a remote repository, it will be convenient to begin by adding an SSH key to your GitHub account if you have not already, as detailed in the [README.md](https://github.com/benbrastmckie/.config/blob/master/README.md).
Create a new repository in GitHub, selecting SSH in the quick setup menu, and copying a URL of the form:

```
  git@github.com:<username>/<project>.git
```

Return to the project in NeoVim, opening the project folder in the terminal with `<ctrl+t>`, running the following:

```
   git remote add origin git@github.com:<username>/<project>.git
```

Exit the terminal with `<ctrl+t>`, and reopen LazyGit, hitting `P` to push changes to the git repository.
Hit return upon being asked whether origin master is the appropriate target, and wait for the push to finish.
Reloading the GitHub website opened to your repository should show all files included in the commits so far.

### _Setting up Collaborations_

In order to add a collaborator to an existing repository, open the repository in GitHub and navigate to `Settings -> Manage acess` and click `invite a collaborator`, entering their GitHub username or email address.
Your collaborator will then be able open the repo in GitHub, copying the address by clicking the `Code` drop-down menu, selecting SSH, and hitting the icon for copy-to-clipboard.
They may then navigate in the terminal to the directory in which they want the project folder to live with:

```
    cd ~/<path to folder where the project folder should live>
```

The collaborator may then pull down the repo by running:

```
   git clone <address from the clipboard>
```

By then running `ls -a` in the terminal, the collaborator may check whether the project directory has appeared.
If the collaborator is using the same configuration, then the project may be edited by moving into the project directory with `cd <project directory name>`, running `nvim` and hitting `<space>e` to open the explorer in the project folder, selecting the files to be edited.
However, even without using the present configuration of NeoVim, collaborators may avoid manually entering git commands by running LazyGit in the terminal.
In order to install LazyGit and add an SSH key, follow the instructions provided in the [README.md](https://github.com/benbrastmckie/.config/blob/master/README.md).

### _Collaboration Protocol_

Assume collaborator A creates a repo inviting collaborator B as above.
Upon first cloning the repo, collaborator B will be up to date with the remote repository on GitHub, and may begin making changes.
At the same time, collaborator A may also make changes, leading to possible conflicts.
These are to be negotiated by both collaborators running the following procedure:

- Make and commit changes to the project.
- Open LazyGit, checking in the local branches window whether the right-most number next to the active branch marked by a `*` is 0.
- If the right-most number is greater than 0, pull down the most recent commits by hitting `p`.
- If there are conflicts, hit `return` upon being asked by LazyGit whether to proceed.
- Close LazyGit, searching through the files with conflicts for `HEAD`, choosing which alternative is preferable and deleting the other alternative along with all marker syntax.
- Once all conflicts have been resolved, return to LazyGit.
- Attempting to stage the files with conflicts should register a message which asks if all conflicts have been resolved, where hitting `return` will stage the file in question.
- If conflicts remain, the staging will fail, requiring that you return to resolve whatever conflicts have been missed, perhaps in another file in the project.
- Once the staging is successful, commit the changes with `c` noting that you have resolved conflicts in your message in addition to noting the most recent changes you made to the project.
- Push these commits to the remote repository by hitting `P`.

In order to reduce the number of conflicts, collaborators can may choose to avoid working on the same parts of the project, though this is not required.

### _Further Resources_

The resources below are organised from the most immediately applicable to the most theoretical.

- [Overview](https://www.youtube.com/watch?v=uXv4poPOdvM&t=119s)
- [Branches](https://www.youtube.com/watch?v=FyAAIHHClqI)
- [LazyGit Features](https://www.youtube.com/watch?v=CPLdltN7wgE&t=307s)
- [LazyGit Rebasing](https://www.youtube.com/watch?v=4XaToVut_hs&t=150s)
- [Manual Commands (Short)](https://www.youtube.com/watch?v=USjZcfj8yxE)
- [Manual Commands (Long)](https://www.youtube.com/watch?v=8JJ101D3knE)
- [Theory](https://www.youtube.com/watch?v=2sjqTHE0zok)
