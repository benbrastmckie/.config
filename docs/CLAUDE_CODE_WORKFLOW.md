# Claude Code Worktree Workflow: User Guide

This guide explains how to use the Claude Code worktree workflow for managing multiple parallel development tasks in Neovim.

## Prerequisites

Ensure you have the following installed:
- Claude Code CLI (`claude --version`)
- Git 2.5+ with worktree support (`git worktree list`)
- WezTerm terminal emulator (`wezterm --version`)
- Neovim 0.9+ (`nvim --version`)

## Overview

The Claude worktree workflow enables you to:
- Work on multiple features simultaneously without branch switching
- Maintain isolated Claude sessions per task
- Keep context files (CLAUDE.md) for each worktree
- Seamlessly navigate between parallel development efforts

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Neovim                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              Integrated Plugin Stack                  │  │
│  │                                                       │  │
│  │  claude-code.nvim ──► Claude sidebar & chat          │  │
│  │  toggleterm.nvim  ──► Quick terminal access          │  │
│  │  git-worktree.nvim ─► Worktree management            │  │
│  │  wezterm.nvim ──────► Tab orchestration              │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────┬───────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     WezTerm Tabs                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │  Main    │  │Feature A │  │Feature B │  │ Bugfix   │  │
│  │  Branch  │  │Worktree 1│  │Worktree 2│  │Worktree 3│  │
│  │  Claude  │  │  Claude  │  │  Claude  │  │  Claude  │  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Commands & Keybindings

### Claude and AI Operations (`<leader>a` prefix)

```vim
" Claude Code Operations
<C-a>        Toggle Claude Code sidebar (any mode, incl. terminal)
<leader>ac   Continue Claude conversation
<leader>ar   Resume Claude (picker)
<leader>av   Toggle verbose mode
<leader>ae   Edit selection (visual mode)

" Claude Worktree Sessions
<leader>aa   All worktrees (Telescope with preview)
<leader>aw   Create new worktree session
<leader>ak   Kill/clean up stale sessions

" Other AI Tools
<leader>ah   Open MCP Hub
<leader>al   Run Lectic (markdown/lec files only)
<leader>aL   Create new Lectic file (markdown/lec files only)
<leader>aP   Select Lectic provider (markdown/lec files only)
```

### Git and Worktree Operations (`<leader>g` prefix)

```vim
" Git Operations (no worktree management - use <leader>a instead)

" Git Operations
<leader>gb   Browse branches
<leader>gc   Browse commits
<leader>gd   Diff HEAD
<leader>gg   LazyGit interface
<leader>gs   Git status
<leader>gl   Line blame
<leader>gt   Toggle line blame
<leader>gh   Previous hunk
<leader>gj   Next hunk
<leader>gp   Preview hunk
```

### Terminal Operations

```vim
" Terminal Access
<C-t>        Toggle terminal (from any mode)
<Esc>        Exit terminal mode to normal (non-Claude terminals)
<C-h/j/k/l>  Navigate between windows from terminal
<M-h/l>      Resize terminal window
```

### WezTerm Tab Navigation

```vim
" WezTerm-specific (when in WezTerm)
<leader>hN   Previous WezTerm tab
<leader>hP   Next WezTerm tab
2<leader>hT  Switch to WezTerm tab 2 (use count)
```

## Common Workflows

### Starting a New Feature

```vim
" Create Claude session with worktree
<leader>aw
> authentication    " Enter feature name
> feature          " Select type (feature/bugfix/refactor/experiment)
" Creates worktree with Claude session and CLAUDE.md file
```

### Working with Claude in a Worktree

```vim
" 1. Switch to or create a worktree
<leader>aa          " Browse all worktrees (Telescope)
" OR
<leader>aw          " Create new worktree session

" 2. Edit the context file
:e CLAUDE.md
" Add your task description and requirements

" 3. Start Claude
<C-a>              " Opens Claude sidebar
" Claude will have access to your CLAUDE.md context

" 4. Continue working
<leader>ac         " Continue conversation
<leader>ar         " Resume from picker
<leader>av         " Toggle verbose mode
```

### Managing Multiple Parallel Tasks

```vim
" Create multiple worktree sessions
<leader>aw         " Feature: payment-integration
<leader>aw         " Feature: user-profiles  
<leader>aw         " Bugfix: memory-leak

" Browse and switch between sessions
<leader>aa         " Telescope browser with preview
" Shows worktree info, CLAUDE.md content, and recent commits
" Keys in picker:
"   Enter  - Switch to selected worktree
"   Ctrl-d - Delete selected worktree
"   Ctrl-n - Create new worktree

" Clean up stale sessions
<leader>ak         " Clean up all orphaned sessions
```

### Using the Telescope Session Browser

The telescope browser (`<leader>aa`) provides:
- Preview of CLAUDE.md content for each session
- Git status or branch comparison for main branch
- Session metadata and recent commits
- Interactive actions:
  - `Enter` - Switch to worktree
  - `Ctrl-d` - Delete selected worktree
  - `Ctrl-n` - Create new worktree
- Quick navigation with fuzzy search

## Example: Complete Feature Development

```vim
" 1. Start in main project
:pwd  " ~/dev/myproject

" 2. Create feature worktree with Claude session
<leader>aw
> user-auth        " Feature name
> feature          " Type

" 3. Automatically switches to new worktree:
"    - Directory: ~/dev/myproject-feature-user-auth
"    - Branch: feature/user-auth
"    - CLAUDE.md created with template

" 4. Add context to CLAUDE.md
:e CLAUDE.md
i## Objective
Implement JWT authentication with:
- Login/logout endpoints
- Token refresh mechanism
- Role-based access control

## Acceptance Criteria
- [ ] Users can register and login
- [ ] Tokens expire after 1 hour
- [ ] Refresh tokens last 7 days
<Esc>:w

" 5. Start Claude
<C-a>
" Give Claude the task:
" 'Implement the JWT authentication system as described in CLAUDE.md'

" 6. Claude works in isolation
"    - All changes in feature branch
"    - No conflicts with main branch
"    - Context preserved in CLAUDE.md

" 7. When done, clean up
<leader>aa         " Open picker
Ctrl-d             " Delete selected worktree
" Then merge your branch via git or GitHub PR
```

## Best Practices

### Context Files (CLAUDE.md)

Every worktree gets a CLAUDE.md file. Keep it updated with:
- **Objective**: Clear description of what you're building
- **Requirements**: Specific technical requirements
- **Constraints**: Any limitations or guidelines
- **Acceptance Criteria**: Checklist of completion items
- **Notes**: Any discoveries or decisions made

### Session Organization

- Use descriptive names for your worktrees
- Follow naming conventions:
  - Features: `feature-name` → `feature/feature-name`
  - Bugfixes: `issue-123` → `bugfix/issue-123`
  - Refactors: `cleanup-auth` → `refactor/cleanup-auth`
- Limit concurrent sessions to 3-4 for best performance
- Clean up completed sessions promptly with `Ctrl-d` in the `<leader>aa` picker

### Statusline Integration (Optional)

If configured, your statusline will show the current Claude session:
- Icon indicates session type (󰊕 feature, 󰁨 bugfix, etc.)
- Shows abbreviated type and session name
- Only visible when in a Claude worktree session

## Git Worktree Deletion Workflows

### Understanding the Problem

The error "not a git repository" occurs when trying to delete a worktree from within itself because:
1. Git worktrees have a `.git` file (not directory) that points to the main repo
2. Some git operations fail when the current directory is being removed
3. The worktree plugin may lose context when deleting its own directory

### Workflow Option 1: Delete from Main Branch (Recommended)

**Philosophy**: Treat main branch as the "control center" for worktree management.

```vim
" 1. Merge your changes first (from within worktree)
:!git add -A
:!git commit -m "Complete feature implementation"
:!git push origin feature/my-feature

" 2. Switch back to main
<leader>gw         " Pick main/master from list
" OR manually
:cd ~/dev/myproject

" 3. Delete the worktree
<leader>gw         " Open worktree picker
<C-d>              " Delete selected worktree

" 4. Clean up merged branch (optional)
:!git branch -d feature/my-feature
```

**Pros**:
- Clean separation of concerns
- No directory conflicts
- Natural workflow after merging

**Cons**:
- Extra step to switch directories
- Breaks flow if you want quick cleanup

### Workflow Option 2: Self-Deletion with Directory Switch

**Philosophy**: Allow worktrees to "self-destruct" gracefully by switching out first.

```vim
" Enhanced delete function for worktree.lua
" Detects if we're in the worktree being deleted and switches first

function delete_current_worktree()
  local current_dir = vim.fn.getcwd()
  local worktree_info = get_current_worktree_info()
  
  if worktree_info then
    -- Switch to parent/main first
    local main_dir = get_main_worktree_path()
    vim.cmd("cd " .. main_dir)
    
    -- Now safe to delete
    delete_worktree(worktree_info.path, worktree_info.branch)
  end
end

" Keybinding
<leader>gD         " Delete current worktree (capital D for "dangerous")
```

**Pros**:
- Single command workflow
- Can delete from anywhere
- Intuitive when done with work

**Cons**:
- Potentially confusing directory switch
- May lose unsaved buffers

### Workflow Option 3: Pre-Merge Validation

**Philosophy**: Ensure work is integrated before allowing deletion.

```vim
" Smart delete that checks merge status
function smart_delete_worktree()
  -- Check for uncommitted changes
  local status = vim.fn.system("git status --porcelain")
  if status ~= "" then
    notify("Uncommitted changes - commit or stash first")
    return
  end
  
  -- Check if branch is merged
  local branch = get_current_branch()
  local merged = vim.fn.system("git branch --merged main | grep " .. branch)
  
  if merged == "" then
    -- Not merged, offer options
    vim.ui.select({"Push and create PR", "Force delete", "Cancel"}, ...)
  else
    -- Safe to delete
    proceed_with_deletion()
  end
end

" Keybindings
<leader>gm         " Merge-aware delete (safe)
<leader>gM         " Force delete (uppercase = force)
```

**Pros**:
- Prevents accidental work loss
- Encourages proper git workflow
- Clear safety checks

**Cons**:
- More complex implementation
- May be too restrictive

### Workflow Option 4: Terminal-Based Cleanup

**Philosophy**: Use terminal commands for explicit control.

```vim
" Quick terminal commands for worktree management
" Add to which-key or as commands

:command! WTDelete !cd .. && git worktree remove %:p:h
:command! WTDeleteForce !cd .. && git worktree remove --force %:p:h
:command! WTStatus !git status && git log --oneline -5

" Keybindings
<leader>g!d        " Terminal delete
<leader>g!f        " Terminal force delete
<leader>g!s        " Terminal status check
```

**Pros**:
- Transparent operations
- Full control
- Works from anywhere

**Cons**:
- Less integrated feel
- Requires terminal comfort

### Recommended Keybinding Strategy

Based on safety and workflow patterns:

```vim
" Safe operations (lowercase)
<leader>gw         " Browse/switch worktrees
<leader>gn         " New worktree
<leader>gs         " Status check

" Destructive operations (uppercase or symbols)
<leader>gD         " Delete current worktree (with validation)
<leader>g!         " Force operations submenu
  └─ d            " Force delete current
  └─ D            " Force delete any (picker)
  └─ p            " Prune all worktrees

" Context-aware delete in picker
<leader>gw         " In picker:
  <C-d>           " Safe delete (checks merge status)
  <C-f>           " Force delete (skips checks)
```

## Troubleshooting

### Session Issues

```vim
" Session not found or corrupted
:lua require('neotex.core.claude-worktree').restore_sessions()

" View session details
<leader>aS         " Use telescope browser to inspect

" Force cleanup of stale sessions
<leader>ak         " Removes orphaned sessions
```

### Worktree Issues

```bash
# List all worktrees
git worktree list

# Remove stuck worktree
git worktree remove ../project-feature-name --force

# Clean up references
git worktree prune
```

### Worktree Deletion Issues

```vim
" Error: "not a git repository"
" Solution: Switch to parent directory first
:cd ..
:!git worktree remove project-feature-name

" Error: "contains modified or untracked files"
" Solution 1: Commit or stash changes
:!git add -A && git commit -m "WIP"
" Solution 2: Force delete
:!git worktree remove --force project-feature-name

" Error: "is a main working tree"
" Solution: Cannot delete main, only feature worktrees
```

### Claude Context Issues

```vim
" Verify CLAUDE.md exists
:!ls CLAUDE.md

" Check current directory
:pwd
" Should be in worktree directory

" Manually set context
:tcd %:h           " Set tab-local directory
```

## Quick Reference Card

| Action | Keybinding | Description |
|--------|------------|-------------|
| **Create** | `<leader>aw` | New worktree session |
| **Navigate** | `<leader>aa` | Browse worktrees (Telescope) |
| **Claude** | `<C-a>` | Toggle sidebar |
| | `<leader>ac` | Continue chat |
| | `<leader>ar` | Resume picker |
| | `<leader>av` | Verbose mode |
| **Manage** | `Ctrl-d` in picker | Delete session |
| | `<leader>ak` | Cleanup stale |
| **Terminal** | `<C-t>` | Toggle terminal |

## Tips for Effective Use

1. **Start with context**: Always update CLAUDE.md before starting Claude
2. **One task per worktree**: Keep worktrees focused on single objectives
3. **Regular cleanup**: Delete completed worktrees to keep workspace clean
4. **Use session browser**: `<leader>aa` gives the best overview with previews
5. **Commit frequently**: Each worktree is a separate branch - commit often
6. **Leverage isolation**: Run tests in one worktree while developing in another

## Verification Checklist

After setup, verify everything works:

- [ ] `<leader>aw` creates worktree with CLAUDE.md
- [ ] `<leader>aa` switches between sessions
- [ ] `<leader>aS` shows telescope browser with previews
- [ ] `<C-a>` opens Claude with worktree awareness
- [ ] Sessions persist after Neovim restart
- [ ] `Ctrl-d` in picker removes worktree and session
- [ ] Statusline shows current session (if configured)
- [ ] WezTerm opens new tabs for worktrees (if using WezTerm)

Your Claude worktree workflow is now ready for parallel development!
