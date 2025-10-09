# Learning Git

This document contains information about how to begin to learn how to integrate Git into your workflow.
Git is useful for: (1) maintaining a history of changes to your project; (2) backing up the project on free private and public repositories online; (3) managing different ways of developing the project in branches prior to knowing which way is preferable; (4) working on the same project from different computers; and (5) collaborating with others on a shared project.
Although there are a huge number of free resources for learning how to use Git, including full lecture series, few resources provide a complete overview of Git's most basic functionality to an academic audience otherwise unfamiliar with programing.
The following sections will include resources for using all of the basic Git commands in LazyGit, providing everything one need to know to use Git effectively for oneself and in collaborating with others.
I will include links to the relevant video demonstrations throughout.

## Introduction

### What is Git?

Git is a version control system that tracks changes to files in a project over time. Think of it as an unlimited undo feature combined with the ability to save snapshots of your entire project at different points in time. Each snapshot captures what every file in your project looks like at that moment, along with a description of what changed and why.

Git operates locally on your computer, meaning you can track changes and view history without an internet connection. When you are ready, you can sync your local work to remote servers like GitHub, GitLab, or Bitbucket for backup and collaboration.

### What Git is NOT

Git is not the same as GitHub. Git is the tool that tracks changes on your computer, while GitHub is a website that hosts Git repositories online. You can use Git without ever touching GitHub, though GitHub provides convenient features for backup, sharing, and collaboration.

Git is also not just a backup tool. While it does create copies of your work, its primary purpose is to maintain a detailed history of how your project evolves, allowing you to experiment freely and recover from mistakes.

### Why Use Git?

Git provides five core benefits:

1. **History tracking**: Git maintains a complete record of every change made to your project, including what changed, when, and why. This history allows you to understand how your project evolved and to recover previous versions when needed.

2. **Backup and safety**: By pushing your local Git history to remote repositories (like GitHub), you create secure backups of your work. If your computer fails, your entire project history remains safe online.

3. **Experimentation with branches**: Git allows you to create separate development timelines called branches. You can experiment with new ideas in a branch without affecting your main work, then either merge successful experiments back in or discard failed attempts.

4. **Working across computers**: Git makes it easy to work on the same project from different computers. Changes made on one computer can be synced to another, keeping everything in sync.

5. **Collaboration**: Multiple people can work on the same project simultaneously. Git tracks who made what changes and provides tools to merge everyone's work together, even when people modify the same files.

### Git vs GitHub

Git is the version control tool installed on your computer. GitHub is one of several online platforms (others include GitLab and Bitbucket) where you can host Git repositories. GitHub adds features like issue tracking, pull requests, and web-based repository browsing on top of Git's core version control functionality.

You use Git commands (either from the terminal or through tools like LazyGit) to track changes locally. You use GitHub (or similar platforms) to share those changes with others or to back them up online.

## Part 1: Understanding Git

Before learning specific commands or tools, it helps to understand the core concepts that Git is built around. These concepts form a mental model that makes Git's behavior predictable and logical.

### Core Concepts

#### Repositories

A repository (often called a "repo") is a directory containing your project files along with a hidden `.git` folder. The `.git` folder stores the complete history of changes to your project. When you initialize Git in a project folder, you are creating a repository.

Repositories come in two types:
- **Local repository**: Stored on your computer, where you do most of your work
- **Remote repository**: Stored on a server (like GitHub), used for backup and sharing

#### Commits

A commit is a snapshot of your entire project at a specific point in time. Each commit includes:
- The state of every tracked file at that moment
- A message describing what changed and why
- Metadata: who made the commit, when, and what commit came before it

Commits are permanent once created—they become part of your project's history. You can always return to any previous commit to see what your project looked like at that time.

Good commits are atomic: they contain one logical change. Instead of committing "Fixed three bugs and added two features," create five separate commits, each clearly describing one change.

#### Branches

A branch is a parallel timeline of development. The default branch is typically called `main` or `master`. When you create a new branch, you create an independent line of development where you can make commits without affecting the main branch.

Branches are useful for:
- Trying experimental changes without risk
- Developing new features while keeping the main branch stable
- Working on multiple different tasks simultaneously

Branches are cheap in Git—creating and deleting them takes almost no time or disk space. This encourages experimentation.

#### The Staging Area

Git uses a three-step process to create commits. The staging area (also called the "index") is the middle step where you prepare changes before committing them:

1. **Working Directory**: Your normal project files, where you make changes
2. **Staging Area**: Where you collect changes you want to include in the next commit
3. **Repository**: Where commits are permanently stored

This three-step process allows you to carefully control what goes into each commit. You might modify five files but only stage and commit two of them, saving the other three for a separate commit later.

#### Remote vs Local

Git is distributed, meaning you have a complete copy of the project history on your computer (local repository). This local repository functions independently—you can make commits, create branches, and view history all while offline.

A remote repository is a copy of your repository hosted on a server. The most common workflow involves:
- Making changes and commits locally
- Pushing commits to the remote for backup and sharing
- Pulling commits from the remote to get others' changes

### The Three-Trees Model

Git's core workflow can be visualized as changes flowing through three "trees" or states:

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Working Directory                           │
│                                                                     │
│  Your project files as you see them                                 │
│  • Make edits to files                                              │
│  • Create new files                                                 │
│  • Delete files                                                     │
│                                                                     │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             │ git add <file>
                             │ (Stage changes)
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         Staging Area (Index)                        │
│                                                                     │
│  Changes prepared for next commit                                   │
│  • Review what will be committed                                    │
│  • Add or remove staged changes                                     │
│  • Prepare atomic, logical commits                                  │
│                                                                     │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             │ git commit -m "message"
                             │ (Save snapshot)
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     Repository (HEAD/History)                       │
│                                                                     │
│  Permanent commit history                                           │
│  • Commits stored permanently                                       │
│  • Complete project history                                         │
│  • Can checkout previous commits                                    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                             │
                             │ git checkout <commit>
                             │ (Load snapshot)
                             ▼
                    (Back to Working Directory)
```

**Understanding the flow**:

1. You modify files in your working directory
2. You use `git add` to stage changes, moving them to the staging area
3. You use `git commit` to save staged changes as a snapshot in the repository
4. You use `git checkout` to load any previous commit back into your working directory

This model explains why Git sometimes seems to have "three versions" of a file:
- The version in your working directory (what you are editing)
- The version in the staging area (what you have prepared for commit)
- The version in the repository (what is permanently saved in history)

### Terminal Basics Primer

Git commands are typically run from a terminal (also called command line, shell, or console). If you are new to using the terminal, here are the essential commands for navigating to your project:

#### Opening the Terminal

- **Linux/Mac**: Open the "Terminal" application
- **Windows**: Open "Command Prompt", "PowerShell", or "Git Bash"
- **NeoVim** (with this configuration): Press `<Ctrl-t>` to open a terminal in the current project folder

#### Essential Navigation Commands

**`pwd` (Print Working Directory)**
Shows your current location in the file system:
```bash
pwd
# Output: /home/username/Documents
```

**`ls` (List)**
Shows files and folders in the current directory:
```bash
ls              # List visible files
ls -a           # List all files, including hidden ones (like .git)
ls -la          # List all files with detailed information
```

**`cd` (Change Directory)**
Moves you to a different directory:
```bash
cd ~/Documents          # Go to Documents folder in your home directory
cd projects/myproject   # Go to myproject folder inside projects
cd ..                   # Go up one directory level
cd ~                    # Go to your home directory
```

#### Understanding Paths

A path describes a location in your file system:
- `~` represents your home directory (`/home/username` on Linux/Mac, `C:\Users\Username` on Windows)
- `/` separates directories (on Windows, you might also see `\`)
- `.` represents the current directory
- `..` represents the parent directory

**Example navigation**:
```bash
# Starting from home directory
pwd
# Output: /home/username

cd Documents/projects
# Now in: /home/username/Documents/projects

cd ..
# Now in: /home/username/Documents

cd ~/Documents/projects/myproject
# Now in: /home/username/Documents/projects/myproject
```

Once you navigate to your project folder, you can run Git commands there.

## Part 2: Using Git from the Terminal

Learning to use Git from the terminal builds a solid foundation for understanding version control. While graphical tools like LazyGit (covered in Part 3) provide convenient interfaces, knowing the underlying Git commands helps you understand what is actually happening and gives you more control and flexibility.

Terminal Git works everywhere—on servers, in automated scripts, and in minimal environments where graphical tools might not be available. Once you understand these commands, tools like LazyGit become easier to use because you will recognize the Git operations they perform behind the scenes.

### Creating Your First Repository

Open the project folder in the terminal with:

```bash
cd ~/<path to file from home directory>
```

Alternatively, open the project in NeoVim, hitting `ctrl+t` to open the terminal in project folder.

To initialize a local Git history, run:

```bash
git init
```

This creates a `.git` folder in your project directory, turning it into a Git repository. Your project now has version control, though no commits exist yet.

### Getting Started with Git

Before you can make commits, Git needs to know who you are. This information appears in every commit you make:

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

The `--global` flag sets this information for all repositories on your computer. You only need to do this once.

You can verify your configuration with:

```bash
git config --list
```

#### Creating a Repository

You have two ways to start working with Git:

**Initialize a new repository** in an existing project folder:

```bash
cd ~/projects/myproject  # Navigate to project folder
git init                  # Initialize Git repository
```

**Clone an existing repository** from a remote server:

```bash
cd ~/projects                                    # Navigate to where you want the project
git clone git@github.com:username/project.git  # Clone the repository
cd project                                       # Enter the cloned project folder
```

Cloning downloads the complete history of the project, not just the current files.

### Basic Git Workflow

The fundamental Git workflow follows this pattern: modify files → check status → stage changes → commit.

#### Checking Repository Status

The most important Git command is `git status`. It shows:
- Which files have been modified
- Which files are staged for commit
- Which files are untracked (new files Git doesn't know about yet)

```bash
git status
```

**Example output**:
```
On branch main
Changes not staged for commit:
  modified:   README.md

Untracked files:
  newfile.txt
```

This tells you `README.md` was modified but not staged, and `newfile.txt` is new and untracked.

#### Staging Changes

Staging prepares files for the next commit. You choose exactly which changes to include:

```bash
git add filename.txt        # Stage a specific file
git add file1.txt file2.txt # Stage multiple files
git add .                   # Stage all changes in current directory
git add -A                  # Stage all changes in entire repository
```

To unstage a file (remove from staging area while keeping changes):

```bash
git restore --staged filename.txt
```

#### Creating Commits

A commit saves a snapshot of all staged changes:

```bash
git commit -m "Add user authentication feature"
```

The `-m` flag lets you include the commit message directly. Without it, Git opens a text editor for you to write a longer message.

**Good commit practices**:
- Make atomic commits: one logical change per commit
- Write clear messages: describe what changed and why
- Commit frequently: small commits are easier to understand and revert if needed

**Example workflow**:
```bash
# Make changes to files
git status                           # Check what changed
git add src/auth.js                  # Stage the authentication file
git add tests/auth.test.js           # Stage the test file
git commit -m "Add login validation" # Create commit
```

#### Viewing History

See the history of commits:

```bash
git log                    # Full commit history
git log --oneline          # Condensed history (one line per commit)
git log --oneline --graph  # Visual graph of commit history
git log --all              # Show all branches
```

**Example output** of `git log --oneline`:
```
a1b2c3d Add login validation
e4f5g6h Fix navigation bug
i7j8k9l Initial commit
```

Each line shows the commit hash (unique identifier) and commit message.

### Branching with Git

Branches allow parallel development. You can work on a new feature in one branch while keeping the main branch stable.

#### Understanding Branch Visualization

```
Initial state (main branch only):

main    A───B───C
        ↑
      (HEAD)

After creating feature branch:

main    A───B───C
             ╲
        feature (HEAD)

After commits on feature branch:

main    A───B───C
             ╲
        feature D───E
                ↑
              (HEAD)

After merging feature into main:

main    A───B───C───────F (merge commit)
             ╲         ╱
        feature D───E───
```

Each letter represents a commit (snapshot). Branches are pointers to commits. HEAD points to your current location.

#### Creating and Switching Branches

**List all branches**:
```bash
git branch           # List local branches
git branch -a        # List all branches (local and remote)
```

**Create a new branch**:
```bash
git branch feature-login    # Create branch (but stay on current branch)
```

**Switch to a branch**:
```bash
git checkout feature-login  # Switch to existing branch
git checkout -b feature-ui  # Create and switch in one command
```

Modern Git also provides the `switch` command (clearer purpose):
```bash
git switch feature-login    # Switch to existing branch
git switch -c feature-ui    # Create and switch in one command
```

#### Working with Branches

**Example branch workflow**:
```bash
git branch feature-payment           # Create feature branch
git switch feature-payment           # Switch to it
# ... make changes and commits ...
git add .
git commit -m "Add payment processing"
git switch main                      # Switch back to main
```

Your working directory updates to reflect the current branch. Files from the feature branch disappear when you switch to main (they are safely stored in Git).

#### Merging Branches

Once work on a branch is complete, merge it back into main:

```bash
git switch main                   # Switch to the branch you want to merge INTO
git merge feature-payment         # Merge feature-payment INTO current branch (main)
```

This creates a merge commit combining the histories of both branches.

**Example merge workflow**:
```bash
git switch main                   # Go to main branch
git pull origin main              # Get latest changes from remote
git merge feature-payment         # Merge your feature
git push origin main              # Push merged result to remote
```

#### Deleting Branches

After merging, you can delete the feature branch:

```bash
git branch -d feature-payment     # Delete branch (safe: prevents deleting unmerged branches)
git branch -D feature-payment     # Force delete (even if unmerged)
```

### Working with Remote Repositories

Remote repositories (like on GitHub) allow backup and collaboration.

#### Adding a Remote

Connect your local repository to a remote:

```bash
git remote add origin git@github.com:username/project.git
```

`origin` is the conventional name for your primary remote repository.

**View configured remotes**:
```bash
git remote -v
```

#### Pushing Changes

Send your commits to the remote repository:

```bash
git push origin main              # Push main branch to origin remote
git push origin feature-login     # Push feature branch to origin remote
git push -u origin main           # Push and set upstream tracking
```

The `-u` flag (or `--set-upstream`) makes this branch track the remote branch, so future `git push` and `git pull` commands don't need to specify the remote and branch names.

#### Pulling Changes

Get commits from the remote repository:

```bash
git pull origin main              # Fetch and merge changes from origin/main
```

`git pull` combines two operations: `git fetch` (download commits) and `git merge` (integrate them).

#### Fetching Changes

To download commits without merging them:

```bash
git fetch origin                  # Fetch all branches from origin
git fetch --all                   # Fetch from all configured remotes
```

After fetching, you can inspect remote changes before merging:

```bash
git fetch origin
git log origin/main               # View commits on remote main
git diff main origin/main         # Compare local and remote
git merge origin/main             # Merge when ready
```

This gives you more control than `git pull`.

### Viewing Git History and Changes

#### Inspecting Commits

View what a specific commit changed:

```bash
git show <commit-hash>            # Show specific commit
git show HEAD                     # Show most recent commit
git show HEAD~1                   # Show second most recent commit
```

**Detailed log output**:
```bash
git log --oneline --graph --all --decorate
```

This shows a visual tree of commits with branch names and tags.

#### Comparing Changes

**View unstaged changes** (working directory vs staging area):
```bash
git diff
```

**View staged changes** (staging area vs last commit):
```bash
git diff --staged
# or
git diff --cached
```

**Compare branches**:
```bash
git diff main feature-login       # Compare two branches
```

**Compare specific files**:
```bash
git diff main feature-login -- src/auth.js
```

#### Finding Information

**Search commit messages**:
```bash
git log --grep="bug fix"          # Find commits mentioning "bug fix"
```

**Find when a line was changed**:
```bash
git blame filename.txt            # Show who last modified each line
```

**Find which commit introduced a bug** (binary search):
```bash
git bisect start
git bisect bad                    # Current commit is bad
git bisect good <commit-hash>     # Earlier commit was good
# Git checks out middle commit, you test it
git bisect good                   # or git bisect bad
# Repeat until Git identifies the problematic commit
git bisect reset                  # Return to original state
```

### Git Safety and Recovery

Git is designed to be forgiving—most mistakes are recoverable. However, understanding which commands are safe and which can cause permanent data loss helps you work confidently.

#### Safe vs Dangerous Commands

**Safe Commands** (read-only or easily reversible):
- `git status` - View state (no changes)
- `git log` - View history (no changes)
- `git diff` - Compare changes (no changes)
- `git add` - Stage files (reversible with `git restore --staged`)
- `git commit` - Save snapshot (reversible with `git revert`)
- `git pull` - Fetch and merge (may create conflicts, but safe)
- `git push` - Send commits (can be undone by reverting and pushing again)
- `git branch` - List or create branches (no data loss)

**Dangerous Commands** (can cause permanent data loss):

⚠️ **`git reset --hard`** - Destroys uncommitted changes in working directory
```bash
git reset --hard HEAD    # DANGER: Discards all uncommitted work permanently
```

⚠️ **`git clean -fd`** - Deletes untracked files permanently
```bash
git clean -fd            # DANGER: Deletes untracked files with no recovery option
```

⚠️ **`git push --force`** - Overwrites remote history (affects collaborators)
```bash
git push --force         # DANGER: Can erase others' work on remote repository
```

**Important principle**: Git is reversible... until it isn't. Committed work can almost always be recovered. Uncommitted work can be lost forever if you use destructive commands.

#### Undoing Mistakes

**Discard changes in working directory** (revert file to last committed state):
```bash
git restore filename.txt              # Discard changes to specific file
git restore .                         # Discard all changes in current directory
```

**Unstage files** (remove from staging area, keep changes):
```bash
git restore --staged filename.txt     # Unstage specific file
git restore --staged .                # Unstage all files
```

**Fix the last commit message**:
```bash
git commit --amend -m "Corrected commit message"
```

⚠️ Warning: Only amend commits that haven't been pushed. Amending changes commit history, which causes problems for collaborators.

**Add forgotten files to last commit**:
```bash
git add forgotten-file.txt
git commit --amend --no-edit          # Add to last commit without changing message
```

**Undo a commit** (safe method - creates new commit that reverses changes):
```bash
git revert <commit-hash>              # Creates new commit undoing the specified commit
git revert HEAD                       # Undo most recent commit
```

`git revert` is safe because it preserves history—it doesn't delete the original commit, it just adds a new commit that reverses it.

**Recover "lost" commits** with reflog:

Git keeps a log of every position HEAD has been. Even commits that seem "lost" (from detached head, reset, etc.) can be recovered:

```bash
git reflog                            # Show history of HEAD positions
```

**Example reflog output**:
```
a1b2c3d HEAD@{0}: commit: Add feature
e4f5g6h HEAD@{1}: checkout: moving from main to feature-branch
i7j8k9l HEAD@{2}: commit: Fix bug
```

To recover a lost commit:
```bash
git reflog                            # Find the commit hash
git checkout a1b2c3d                  # Check out the lost commit
git branch recovery-branch            # Create branch to save it
git switch recovery-branch            # Switch to the new branch
```

The reflog keeps entries for about 90 days by default, giving you time to recover from mistakes.

#### Resolving Merge Conflicts

Conflicts occur when Git cannot automatically merge changes—typically when two people modify the same lines in a file.

**When conflicts occur**:
1. During `git merge` - merging branches with overlapping changes
2. During `git pull` - pulling changes that conflict with local work
3. During `git rebase` - replaying commits with conflicts

**Conflict markers** look like this in your files:

```
<<<<<<< HEAD
Your changes on the current branch
=======
Their changes from the branch being merged
>>>>>>> feature-branch
```

**Step-by-step conflict resolution**:

1. **Identify conflicted files**:
   ```bash
   git status
   # Shows: "both modified: filename.txt"
   ```

2. **Open conflicted files** and locate conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)

3. **Choose resolution**:
   - Keep your changes: Delete their section and all markers
   - Keep their changes: Delete your section and all markers
   - Combine both: Edit to merge both changes, remove markers

4. **Remove all conflict markers** - the file must be clean

5. **Stage resolved files**:
   ```bash
   git add filename.txt
   ```

6. **Complete the merge**:
   ```bash
   git commit                # For merge conflicts (message auto-generated)
   # or
   git rebase --continue     # For rebase conflicts
   ```

**Example resolution**:

```
<<<<<<< HEAD
function calculateTotal(items) {
  return items.reduce((sum, item) => sum + item.price, 0);
=======
function calculateTotal(items) {
  return items.reduce((total, item) => total + item.cost, 0);
>>>>>>> feature-pricing
}
```

Resolved (combining both: use better variable names):
```
function calculateTotal(items) {
  return items.reduce((total, item) => total + item.price, 0);
}
```

If you get confused during conflict resolution:
```bash
git merge --abort         # Abort merge, return to pre-merge state
git rebase --abort        # Abort rebase, return to pre-rebase state
```

#### Common Beginner Mistakes

**Mistake 1: Forgetting to stage before committing**

Git won't commit unstaged changes:
```bash
# Made changes to file
git commit -m "Update feature"    # ERROR: Nothing committed (forgot git add)
```

**Solution**: Always check `git status` before committing:
```bash
git status                        # See unstaged changes
git add .                         # Stage changes
git commit -m "Update feature"    # Now commits successfully
```

**Mistake 2: Switching branches with uncommitted work**

```bash
git switch feature-branch         # ERROR: Uncommitted changes would be lost
```

**Solution**: Commit or stash your changes first:
```bash
git add .
git commit -m "Work in progress"
git switch feature-branch

# Or use stash to save without committing:
git stash                         # Save changes temporarily
git switch feature-branch
git switch main                   # Switch back when done
git stash pop                     # Restore saved changes
```

**Mistake 3: Pushing before pulling**

```bash
git push origin main              # ERROR: Remote has changes you don't have
```

**Solution**: Always pull before pushing:
```bash
git pull origin main              # Get remote changes first
# Resolve any conflicts
git push origin main              # Then push
```

**Mistake 4: Committing large binary files**

Binary files (images, videos, compiled code) make repositories huge and slow.

**Solution**: Use `.gitignore` to exclude them:
```bash
# Create or edit .gitignore in project root
echo "*.jpg" >> .gitignore        # Ignore all jpg files
echo "*.mp4" >> .gitignore        # Ignore all mp4 files
echo "node_modules/" >> .gitignore # Ignore entire directory
git add .gitignore
git commit -m "Add gitignore rules"
```

Common `.gitignore` patterns:
```
# Build outputs
*.exe
*.o
build/
dist/

# Dependencies
node_modules/
vendor/

# IDE files
.vscode/
.idea/
*.swp

# OS files
.DS_Store
Thumbs.db
```

**Mistake 5: Unclear commit messages**

Bad: "Fixed stuff", "Updates", "asdfasdf"
Good: "Fix login validation for email addresses", "Add user profile page", "Update API endpoint for authentication"

**Tips for good messages**:
- Start with a verb: "Add", "Fix", "Update", "Remove"
- Be specific about what changed
- Explain why if not obvious
- Keep first line under 50 characters
- Add details in additional lines if needed

## Part 3: Using LazyGit (Optional Tool)

LazyGit is a terminal-based graphical interface for Git. While the Git commands in Part 2 give you full control and understanding, LazyGit provides a visual workflow that can be faster for common operations once you understand the underlying concepts.

LazyGit executes standard Git commands behind the scenes. When you stage a file in LazyGit, it runs `git add`. When you commit, it runs `git commit`. Understanding this relationship helps you use LazyGit effectively and troubleshoot when needed.

### When to Use LazyGit vs Terminal Git

**Use LazyGit when**:
- You want a visual overview of your repository state
- You are working on complex rebases or interactive operations
- You want to stage specific chunks of changes (partial staging)
- You find visual interfaces easier than memorizing commands

**Use Terminal Git when**:
- You are automating workflows with scripts
- You are working on a remote server via SSH
- You want precise control over advanced operations
- You are learning Git (understanding the commands builds foundation)

Both approaches are valuable. Most developers use a combination: LazyGit for daily workflow, terminal Git for automation and advanced operations.

### Understanding LazyGit Operations

Every LazyGit action corresponds to a Git command. This table maps LazyGit keys to the underlying Git operations:

| LazyGit Key | Git Command | Concept | Description |
|-------------|-------------|---------|-------------|
| `<space>` | `git add <file>` | Staging | Stage/unstage selected file for next commit |
| `a` | `git add -A` | Staging | Stage/unstage all files |
| `c` | `git commit` | Commit | Create snapshot with staged files |
| `p` | `git pull origin <branch>` | Collaboration | Fetch and merge remote changes |
| `P` | `git push origin <branch>` | Collaboration | Send local commits to remote |
| `n` | `git branch <name>` | Branching | Create new branch |
| `<space>` (on branch) | `git checkout <branch>` | Branching | Switch to selected branch |
| `M` | `git merge <branch>` | Branching | Merge selected branch into current |
| `d` | `git branch -d <branch>` | Branching | Delete selected branch |
| `ctrl+e` | `git diff <commit>` | Inspection | View differences between commits |
| `i` | Add to `.gitignore` | Configuration | Ignore file from version control |

Understanding these mappings helps you:
- Know what Git is actually doing behind the scenes
- Troubleshoot when LazyGit behavior seems unexpected
- Transition between LazyGit and terminal Git seamlessly

### LazyGit Basic Operations

**Opening LazyGit**:
- In NeoVim with this configuration: `<space>gg`
- From terminal: Navigate to project folder and run `lazygit`
- See the [README](https://github.com/benbrastmckie/.config/blob/master/README.md#git) for installation details

**Navigation**:
- `h` and `l`: Move between panels (files, branches, commits, stash)
- `j` and `k`: Navigate within panels
- `?`: Show help for current panel
- `<esc>`: Return to NeoVim

**Ignoring Files**:

Ignoring tells Git to not track certain files (like build outputs or large binary files).

- `i`: Ignore selected file (adds to `.gitignore`)
- If you accidentally ignore a file: Open the `.gitignore` file in your editor and remove the line

Note: The `.gitignore` file is a text file in your project root listing patterns of files to ignore. See Part 2 for `.gitignore` patterns.

**Staging Changes**:

Staging prepares changes for the next commit (see the three-trees model in Part 1).

- `<space>`: Stage/unstage selected file
- `a`: Stage/unstage all files
- Visual feedback shows which files are staged (different color/indicator)

**Creating Commits**:

Commits create permanent snapshots in your repository history.

- `c`: Open commit message editor
- Type your message (see Part 2 for good commit message practices)
- Save and close to create the commit

**Pulling Changes**:

Pulling fetches commits from remote repository and merges them locally.

- `p`: Pull changes from remote
- If conflicts occur: Hit `<return>` to proceed, then resolve conflicts in your editor (see conflict resolution in Part 2)
- Warning: Commit your local changes before pulling to avoid losing work

**Pushing Changes**:

Pushing sends your local commits to the remote repository.

- `P`: Push commits to remote
- If remote has changes you don't have: Pull first, resolve conflicts, then push
- LazyGit will show error if push is rejected

**Branch Operations**:

Branches allow parallel development (see branching concepts in Part 1).

- `n` (in branches panel): Create new branch
- `<space>` (on branch): Switch to selected branch
- `M` (on branch): Merge selected branch into current branch
- `d` (on branch): Delete selected branch

**Viewing Differences**:

- `ctrl+e` (in commits panel): Open diff menu
- Default shows changes between selected commit and current files
- Use arrow keys to select different diff options

**Help and Exit**:
- `?`: Look up commands for active panel
- `<esc>`: Return to NeoVim

### Understanding Detached-Head State

Using `<space>` to checkout past commits in the commits window in LazyGit results in a detached-head state. In this state, HEAD (Git's pointer to your current position) points directly to a commit rather than to a branch.

A detached-head state is useful for viewing the history of the project—you can see what files looked like at any point in time. However, any commits you make in this state will not be attached to a branch, making them easy to lose.

- Warning: any changes made to the project in a detached-head state will be lost upon checking out any other commit or branch. If you want to keep work done in a detached-head state, create a new branch with `git branch <branch-name>` before switching away.

### LazyGit Branch Management [(Git Part 1)](https://www.youtube.com/watch?v=GIJG4QtZBYI)[(Git Part 2)](https://www.youtube.com/watch?v=7HHvkI2Swbk&t=11s)

Branches represent parallel timelines of development. LazyGit provides visual branch management that makes it easy to create, switch, and merge branches.

#### Creating and Experimenting with Branches

When you want to develop the project in a new direction (which you might abandon), create a new branch:

1. Navigate to the branches panel (`h` and `l` to switch panels)
2. Press `n` to create a new branch
3. Enter the branch name
4. The new branch is automatically checked out (indicated by `*`)

This creates an independent line of development. Changes on this branch don't affect the main branch until you explicitly merge them.

⚠️ **Warning**: If you switch branches before committing changes, those changes will be lost. Always commit before switching branches, or use `git stash` from the terminal to save work temporarily.

#### Abandoning a Branch

If the development is not successful:

1. Navigate to the main branch in the branches panel
2. Press `<space>` to checkout main
3. The experimental branch remains in history unless you delete it

The abandoned branch's history stays in Git—you can return to it later if needed.

#### Deleting Branches

To clean up abandoned branches:

1. Ensure you are on a different branch (you can't delete the branch you are on)
2. Navigate to the abandoned branch
3. Press `d` to delete it

Git prevents deleting unmerged branches by default (protecting your work).

#### Merging Branches

When development on a branch is successful and you want to include it in main:

1. **Commit final changes** to the feature branch
2. **Switch to main**: Navigate to main branch, press `<space>` to checkout
3. **Merge**: Navigate back to the feature branch, press `M` to merge it into main (the checked-out branch)

This creates a merge commit combining both branch histories.

#### Handling Merge Conflicts in LazyGit

Conflicts occur when both branches modify the same lines. When merging:

1. LazyGit asks whether to proceed with merge
2. Press `<return>` to continue
3. Files with conflicts show conflict markers (see Part 2 for marker syntax)
4. Open conflicted files in your editor
5. Search for `<<<<<<< HEAD` to find conflicts
6. Choose resolution: keep yours, keep theirs, or combine both
7. Remove all conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
8. Return to LazyGit
9. Stage resolved files (`<space>` on each file)
10. LazyGit asks if conflicts are resolved—press `<return>` to confirm
11. If staging fails, you missed a conflict marker somewhere

See the detailed conflict resolution guide in Part 2 for more information.

## Part 4: Collaboration Workflows

### Remote Repositories [(Git Part 2)](https://www.youtube.com/watch?v=7HHvkI2Swbk)[(Git Part 3)](https://www.youtube.com/watch?v=f5QUrv87Ol8)

In order to link a remote repository, it will be convenient to begin by adding an SSH key to your GitHub account if you have not already, as detailed in the [README.md](https://github.com/benbrastmckie/.config/blob/master/README.md).
Create a new repository in GitHub, selecting SSH in the quick setup menu, and copying a URL of the form:

```
  git@github.com:<username>/<project>.git
```

Return to the project in NeoVim, opening the project folder in the terminal with `ctrl+t`, running the following:

```
   git remote add origin git@github.com:<username>/<project>.git
```

Exit the terminal with `ctrl+t`, and reopen LazyGit, hitting `P` to push changes to the Git repository.
Hit return upon being asked whether origin master is the appropriate target, and wait for the push to finish.
Reloading the GitHub website opened to your repository should show all files included in the commits so far.

### Setting up Collaborations [(Git Part 2)](https://www.youtube.com/watch?v=7HHvkI2Swbk)[(Git Part 3)](https://www.youtube.com/watch?v=vB7RsT0tF4s&t=2s)

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
However, even without using the present configuration of NeoVim, collaborators may avoid manually entering Git commands by running LazyGit in the terminal.
In order to install LazyGit and add an SSH key, follow the instructions provided in the [README.md](https://github.com/benbrastmckie/.config/blob/master/README.md).

### Collaboration Protocol [(Git Part 2)](https://www.youtube.com/watch?v=7HHvkI2Swbk)

When multiple people work on the same repository, coordinating changes prevents conflicts and ensures everyone stays synchronized.

#### Understanding Collaborative Workflow

Assume collaborator A creates a repository and invites collaborator B:

1. **Collaborator B clones**: After cloning, B has an exact copy of the repository
2. **Both make changes**: A and B can work simultaneously on different (or same) parts
3. **Potential conflicts**: If both modify the same files, Git cannot automatically merge

The key to collaboration is the pull-before-push pattern: always pull remote changes before pushing your own.

#### Step-by-Step Collaboration Procedure

Use this procedure every time before making changes:

**1. Check for remote changes**:
- Open LazyGit
- In the branches panel, look at the number next to your branch marked with `*`
- The rightmost number shows commits on remote that you don't have locally
- If this number is `0`, you are up to date
- If greater than `0`, remote has changes you need to pull

**2. Pull remote changes** (if needed):
- Press `p` to pull
- If there are no conflicts, pull completes automatically
- If there are conflicts, LazyGit asks whether to proceed—press `<return>`

**3. Resolve conflicts** (if any occurred):
- Close LazyGit or switch to your editor
- Search files for `<<<<<<< HEAD` (conflict markers)
- For each conflict: choose your version, their version, or combine both
- Remove all conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
- Save the file

**4. Stage resolved files**:
- Return to LazyGit
- Stage each resolved file with `<space>`
- LazyGit asks if conflicts are resolved—press `<return>`
- If staging fails, you missed a conflict marker

**5. Commit the merge**:
- Press `c` to commit
- Message should note both your changes and the conflict resolution
- Example: "Add user validation, resolve merge conflicts with authentication changes"

**6. Push to remote**:
- Press `P` to push
- Your changes and the merge are sent to remote
- Other collaborators can pull your integrated work

#### Collaboration Example

**Scenario**: Collaborators A and B both modify `README.md`

```
┌─────────────────────────────────────────────────────────────┐
│ Collaborator A                  │ Collaborator B            │
├─────────────────────────────────────────────────────────────┤
│ 1. Edits README.md              │ 1. Edits README.md        │
│ 2. Commits: "Update docs"       │ 2. Commits: "Add examples"│
│ 3. Pushes to remote             │ 3. Tries to push          │
│                                 │ 4. ERROR: Remote has       │
│                                 │    changes                 │
│                                 │ 5. Pulls from remote       │
│                                 │ 6. CONFLICT in README.md   │
│                                 │ 7. Resolves conflict       │
│                                 │ 8. Commits merge           │
│                                 │ 9. Pushes successfully     │
│ 10. Pulls B's merged work       │                           │
└─────────────────────────────────────────────────────────────┘
```

#### Reducing Conflicts

To minimize conflicts:

- **Communicate**: Let collaborators know what files you are working on
- **Pull frequently**: Pull changes multiple times per day
- **Commit often**: Small, focused commits are easier to merge
- **Work on different files**: When possible, divide work by file or feature area

However, conflicts are normal in collaborative work—learning to resolve them is an essential Git skill.

### GitHub CLI [(Git Part 4)](https://www.youtube.com/watch?v=KM_Mwp7R_rk)

Especially while collaborating with others on a common project, it is convenient to use GitHub Issues in order to facilitate exchange the development of the project.
Although one could attempt to limit all such exchange to a Markdown file in a shared repository, such files can quickly become cluttered or overlooked.
By contrast, GitHub Issues allows collaborators to exchange ideas in an exchange of markdown files, where each thread corresponds to a given issue.

GitHub Cli allows you to submit new issues to a repository without leaving the terminal.
Accordingly, I have included a mapping in Which-Key to permit users to easily create and log a new issue without leaving the project they are working on.
GitHub Cli also permits users to create pull-requests, along with a range of further features, and is currently being actively developed.
However, assuming that all collaborators of a shared repo will have administrator access, there is no need for pull-requests, and so I have not included further mappings, though one could easily do so.
In order to include this functionality in your configuration, refer to the **GitHub Cli** section in the [installation instructions](https://github.com/benbrastmckie/.config/blob/master/README.md) for setting up Git for use in NeoVim.

## Further Resources

The resources below are organised from the most immediately applicable to the most theoretical.

- [Overview](https://www.youtube.com/watch?v=uXv4poPOdvM&t=119s)
- [Branches](https://www.youtube.com/watch?v=FyAAIHHClqI)
- [LazyGit Features](https://www.youtube.com/watch?v=CPLdltN7wgE&t=307s)
- [LazyGit Rebasing](https://www.youtube.com/watch?v=4XaToVut_hs&t=150s)
- [Manual Commands (Short)](https://www.youtube.com/watch?v=USjZcfj8yxE)
- [Manual Commands (Long)](https://www.youtube.com/watch?v=8JJ101D3knE)
- [Theory](https://www.youtube.com/watch?v=2sjqTHE0zok)
