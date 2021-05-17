# Learning Git

This document contains information about how to begin to learn how to integrate Git into your workflow.
Git is useful for: (1) maintaining a history of changes to your project; (2) backing up the project on free private and public repositories online; (3) managing different ways of developing the project in branches prior to knowing which way is preferable; (4) working on the same project from different computers; and (5) collaborating with others on a shared project.
Although there are a huge number of free resources for learning how to use git, including full lecture series, few resources provide a complete overview of git's most basic functionality to an academic audience otherwise unfamiliar with programing.
The following sections will include resources for using all of the basic git commands in LazyGit, providing everything one need to know to use git effectively for oneself and in collaborating with others.
I will include links to the relevant video demonstrations throughout.

## _Basic Git Commands_ [(Demo Part 5)](https://youtu.be/z5HfVQQDrAg) [(Git Part 1)](https://www.youtube.com/watch?v=GIJG4QtZBYI) [(Git Part 2)](https://www.youtube.com/watch?v=7HHvkI2Swbk)

- **LazyGit**: to open LazyGit in NeoVim with my configuration, hit `<space>gg`. Alternatively, you can open a terminal, navigating to the project folder in question, and run `lazygit` after installation (see the [README](https://github.com/benbrastmckie/.config/blob/master/README.md#git) for installation details).
  - Note: See below to initialise a git.
- **Navigate**: use `h` and `l` to move between windows, and `j` and `k` to navigate within windows.
- **Ignore**: use `i` to ignore all files which you do not wish to track, including any file which is not a text file.
  - Note: if you accidentally ignore a file that you did not mean to, return to the project in NeoVim, open the explorer with `<space>e`, hit `.` in order to show hidden files, and open the `.gitignore` file, deleting the appropriate line which names the file you accidentally ignored.
- **Staging**: use `<space>` to stage files in the files window, or `a` to stage/unstage all files.
- **Commits**: use `c` to commit staged file to local git history.
- **Pull**: use `p` to pull down latest commits from the git repository.
  - Warning: make sure to commit any changes made to the local files before pulling down changes from the git repository.
  - Note: if there are conflicts, hit `<return>` to generate conflict reports, returning to the file in question to resolve conflicts.
- **Push**: use `P` to push recent commits to the git repository.
  - Note: if changes have been made to the git repository, pull down all changes and resolve any conflicts before pushing to the git repository.
- **Branch**: use `n` in the local branches window to create a new branch, `<space>` to checkout branches, and `M` to merge highlighted branch into checked out branch.
- **Diff**: in the commits window, use `ctrl+e` to open diff menu, where default diff is between the current file and the highlighted commit.
- **Help**: use `?` to look up the commands for the active window.
- **Exit**: use `<esc>` to return to NeoVim.

## _Initialising Git_ [(Demo Part 5)](https://youtu.be/z5HfVQQDrAg) [(Git Part 9)](https://www.youtube.com/watch?v=GIJG4QtZBYI)[(Config Part 2)](https://www.youtube.com/watch?v=FCUnlRjYPo8)[(Git Part 1)](https://www.youtube.com/watch?v=GIJG4QtZBYI&t=5s)[(Git Part 3)](https://www.youtube.com/watch?v=vB7RsT0tF4s&t=2s)

Open the project folder in the terminal with:

```
   cd ~/<path to file from home directory>
```

Alternatively, open the project in NeoVim, hitting `ctrl+t` to open the terminal in project folder.
To initialise a local git history, run `git init`.
You may then exit the terminal with `ctrl+t` and open LazyGit, ignoring all files you do not wish to track with `i` in the files window as above, and staging all files you wish to track with `<space>`, or staging all files that have not been ignored with `a`.
Hit `c` to commit staged files, entering `initial commit` and hitting `<return>`.
You are now ready to make commits and branches to your local git history.
Using `<space>` to checkout past commits in the commits window in LazyGit results in a detached-head state which is useful for viewing the history of the project.

- Warning: any changes made to the project in a detached-head state will be lost upon checking out any other commit.

## _Merging Branches_ [(Git Part 1)](https://www.youtube.com/watch?v=GIJG4QtZBYI)[(Git Part 2)](https://www.youtube.com/watch?v=7HHvkI2Swbk&t=11s)

If you want to develop the project in a new direction which you may end up abandoning, or otherwise want to separate from the development of the rest of the project's development, you can create a new branch with `n` in the local branches window, where the new branch will be automatically checked out as indicated by a `*`.
If the development of the branch is not deemed successful, you can simply abandon the branch by navigating back to the master branch in the local branches window, hitting `<space>` to checkout master.

- Warning: if you switch branches before committing any changes that you made to the current branch, those changes will be lost.

Once you have returned to the master branch, the history of the project's development in the now abandoned branch will remain stored in the git history unless you delete the abandoned branch by navigating to it in the local branches window and hitting `d`.

Suppose that you return to further develop a previously abandoned branch, and now want to include the changes in the master branch.
To do so, you can merge the finished branch into master by: (1) committing the most recent changes to the no longer abandoned branch; (2) checking out the master branch in the local branches window by navigating to master and hitting `<space>`; and (3) navigating back to the no longer abandoned branch and hitting `M` in order to merge the selected branch into the checked out branch.

Upon merging branches, there may be conflicts if the two branches have been developed independently in conflicting ways.
If there are conflicts, LazyGit will ask whether to go ahead with merge, where hitting `<return>` will include all alternatives in the files which have conflicts along with marker syntax.
Search through the files with conflicts for `HEAD`, choosing which alternative is preferable and deleting the other alternative along with all marker syntax.
Upon returning to LazyGit, attempting to stage the files with conflicts should register a message which asks if all conflicts have been resolved, where hitting `<return>` will stage the file in question.
If staging is not possible, check to make sure that there are no more conflicts, or miscellaneous marker syntax remaining.

## _Remote Repositories_ [(Git Part 2)](https://www.youtube.com/watch?v=7HHvkI2Swbk)[(Git Part 3)](https://www.youtube.com/watch?v=f5QUrv87Ol8)

In order to link a remote repository, it will be convenient to begin by adding an SSH key to your GitHub account if you have not already, as detailed in the [README.md](https://github.com/benbrastmckie/.config/blob/master/README.md).
Create a new repository in GitHub, selecting SSH in the quick setup menu, and copying a URL of the form:

```
  git@github.com:<username>/<project>.git
```

Return to the project in NeoVim, opening the project folder in the terminal with `ctrl+t`, running the following:

```
   git remote add origin git@github.com:<username>/<project>.git
```

Exit the terminal with `ctrl+t`, and reopen LazyGit, hitting `P` to push changes to the git repository.
Hit return upon being asked whether origin master is the appropriate target, and wait for the push to finish.
Reloading the GitHub website opened to your repository should show all files included in the commits so far.

## _Setting up Collaborations_ [(Git Part 2)](https://www.youtube.com/watch?v=7HHvkI2Swbk)[(Git Part 3)](https://www.youtube.com/watch?v=vB7RsT0tF4s&t=2s)

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

## _Collaboration Protocol_ [(Git Part 2)](https://www.youtube.com/watch?v=7HHvkI2Swbk)

Assume collaborator A creates a repo inviting collaborator B as above.
Upon first cloning the repo, collaborator B will be up to date with the remote repository on GitHub, and may begin making changes.
At the same time, collaborator A may also make changes, leading to possible conflicts.
These are to be negotiated by both collaborators running the following procedure in order to make and commit changes to the project.

- Open LazyGit, checking in the local branches window whether the right-most number next to the active branch marked by a `*` is 0.
- If the right-most number is greater than 0, pull down the most recent commits by hitting `p`.
- If there are conflicts, hit `<return>` upon being asked by LazyGit whether to proceed.
- Close LazyGit, searching through the files with conflicts for `HEAD`, choosing which alternative is preferable and deleting the other alternative along with all marker syntax.
- Once all conflicts have been resolved, return to LazyGit.
- Attempting to stage the files with conflicts should register a message which asks if all conflicts have been resolved, where hitting `<return>` will stage the file in question.
- If conflicts remain, the staging will fail, requiring that you return to resolve whatever conflicts have been missed, perhaps in another file in the project.
- Once the staging is successful, commit the changes with `c` noting that you have resolved conflicts in your message in addition to noting the most recent changes you made to the project.
- Push these commits to the remote repository by hitting `P`.

In order to reduce the number of conflicts, collaborators can may choose to avoid working on the same parts of the project, though this is not required.

## _GitHub Cli_ [(Git Part 4)](https://www.youtube.com/watch?v=KM_Mwp7R_rk)

Especially while collaborating with others on a common project, it is convenient to use GitHub Issues in order to facilitate exchange the development of the project.
Although one could attempt to limit all such exchange to a Markdown file in a shared repository, such files can quickly become cluttered or overlooked.
By contrast, GitHub Issues allows collaborators to exchange ideas in an exchange of markdown files, where each thread corresponds to a given issue.

GitHub Cli allows you to submit new issues to a repository without leaving the terminal.
Accordingly, I have included a mapping in Which-Key to permit users to easily create and log a new issue without leaving the project they are working on.
GitHub Cli also permits users to create pull-requests, along with a range of further features, and is currently being actively developed.
However, assuming that all collaborators of a shared repo will have administrator access, there is no need for pull-requests, and so I have not included further mappings, though one could easily do so.
In order to include this functionality in your configuration, refer to the **GitHub Cli** section in the [installation instructions](https://github.com/benbrastmckie/.config/blob/master/README.md) for setting up Git for use in NeoVim.

## _Further Resources_

The resources below are organised from the most immediately applicable to the most theoretical.

- [Overview](https://www.youtube.com/watch?v=uXv4poPOdvM&t=119s)
- [Branches](https://www.youtube.com/watch?v=FyAAIHHClqI)
- [LazyGit Features](https://www.youtube.com/watch?v=CPLdltN7wgE&t=307s)
- [LazyGit Rebasing](https://www.youtube.com/watch?v=4XaToVut_hs&t=150s)
- [Manual Commands (Short)](https://www.youtube.com/watch?v=USjZcfj8yxE)
- [Manual Commands (Long)](https://www.youtube.com/watch?v=8JJ101D3knE)
- [Theory](https://www.youtube.com/watch?v=2sjqTHE0zok)
