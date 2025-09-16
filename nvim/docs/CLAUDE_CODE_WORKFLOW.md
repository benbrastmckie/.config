# Claude Code Multi-Agent Workflow: Streamlined Neovim Integration

A production-ready workflow for managing multiple Claude Code agents across git worktrees using a focused 4-plugin architecture.

## Quick Start

```bash
# Prerequisites
clause --version              # Claude Code CLI installed
git worktree list             # Git 2.5+ with worktree support
wezterm --version             # WezTerm terminal emulator
nvim --version                # Neovim 0.9+
```

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Plugin Stack](#plugin-stack)
3. [Workflow Phases](#workflow-phases)
4. [Commands & Keybindings](#commands--keybindings)
5. [Implementation Guide](#implementation-guide)
6. [Use Cases](#use-cases)
7. [Best Practices](#best-practices)

## Architecture Overview

This workflow enables parallel Claude Code sessions across isolated git worktrees, orchestrated through Neovim with seamless tab management in WezTerm.

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Neovim                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                  Plugin Stack                         │  │
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
│                    WezTerm Tabs                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │  Main    │  │Feature A │  │Feature B │  │ Bugfix   │  │
│  │  <C-t>   │  │Worktree 1│  │Worktree 2│  │Worktree 3│  │
│  │  Claude  │  │  Claude  │  │  Claude  │  │  Claude  │  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Key Benefits

- **Instant Claude Access**: `<C-c>` for sidebar, `<C-t>` for terminal
- **True Isolation**: Each worktree has independent file state
- **Tab Organization**: Each task gets a dedicated WezTerm tab
- **Context Persistence**: CLAUDE.md files maintain task context
- **Zero Conflicts**: Parallel development without merge issues

## Plugin Stack

### Current Plugins (Already Configured)

#### 1. claude-code.nvim
- **Purpose**: Claude Code integration in Neovim
- **Key binding**: `<C-c>` toggles Claude sidebar
- **Features**: File refresh, git root awareness, 40% split width

#### 2. toggleterm.nvim 
- **Purpose**: Quick terminal access for Claude commands
- **Key binding**: `<C-t>` toggles terminal
- **Direction**: Vertical split (80 columns)
- **Shell**: Fish (configured)

### New Plugins to Add

#### 3. git-worktree.nvim
- **Purpose**: Create and manage git worktrees from Neovim
- **Integration**: Telescope for fuzzy finding
- **Auto-setup**: Creates CLAUDE.md context files

#### 4. wezterm.nvim
- **Purpose**: Programmatic WezTerm tab management
- **Features**: Spawn tabs, switch workspaces, set environment
- **Alternative to**: Manual tab creation

## Git Worktrees Setup

### Basic Worktree Commands

```bash
# List all worktrees
git worktree list

# Add a new worktree with new branch
git worktree add ../project-feature-auth -b feature/auth

# Add worktree from existing branch
git worktree add ../project-bugfix bugfix/login-issue

# Remove a worktree
git worktree remove ../project-feature-auth

# Prune stale worktree references
git worktree prune
```

## Commands & Keybindings

### Unified AI Operations (`<leader>h` prefix)

```vim
" Claude Operations
<C-c>        Toggle Claude sidebar (any mode)
<leader>hc   Open Claude in toggleterm
<leader>hC   Continue Claude conversation
<leader>hr   Resume Claude (picker)

" Worktree Management
<leader>hw   Switch worktree (Telescope)
<leader>hW   Create worktree (Telescope)
<leader>hd   Delete worktree

" Tab Orchestration
<leader>ht   New worktree in WezTerm tab
<leader>hs   Switch to Claude session
<leader>hl   List all Claude sessions

" Terminal Access
<C-t>        Toggle terminal (vertical)
<leader>tf   Floating terminal
<leader>th   Horizontal terminal
```

## Implementation Guide

### Step 1: Install git-worktree.nvim

```lua
-- ~/.config/nvim/lua/neotex/plugins/git/worktree.lua
return {
  "ThePrimeagen/git-worktree.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  keys = {
    { "<leader>hw", "<cmd>Telescope git_worktree<cr>", desc = "Switch worktree" },
    { "<leader>hW", "<cmd>Telescope git_worktree create_git_worktree<cr>", desc = "Create worktree" },
  },
  config = function()
    require("git-worktree").setup({
      change_directory_command = "tcd", -- tab-local cd
      update_on_change = true,
      clearjumps_on_change = true,
      autopush = false,
    })
    require("telescope").load_extension("git_worktree")
    
    -- Auto-create CLAUDE.md on new worktree
    local Worktree = require("git-worktree")
    Worktree.on_tree_change(function(op, metadata)
      if op == Worktree.Operations.Create then
        local context_file = metadata.path .. "/CLAUDE.md"
        if vim.fn.filereadable(context_file) == 0 then
          local content = {
            "# Task: " .. metadata.branch,
            "Branch: " .. metadata.branch,
            "Created: " .. os.date(),
            "Worktree: " .. metadata.path,
            "",
            "## Objective",
            "[Describe the task here]",
            "",
            "## Context",
            "[Any relevant context]",
          }
          vim.fn.writefile(content, context_file)
        end
      end
    end)
  end,
}
```

### Step 2: Install wezterm.nvim

```lua
-- ~/.config/nvim/lua/neotex/plugins/terminal/wezterm.lua
return {
  "willothy/wezterm.nvim",
  config = function()
    require("wezterm").setup({
      create_commands = false, -- We'll use our own commands
    })
  end,
}
```

### Step 3: Create Orchestration Module

```lua
-- ~/.config/nvim/lua/neotex/core/claude-worktree.lua
local M = {}

-- Create worktree and open in new WezTerm tab
function M.create_worktree_tab()
  local feature = vim.fn.input("Feature name: ")
  if feature == "" then return end
  
  local branch = "feature/" .. feature
  local worktree_path = "../" .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t") .. "-" .. feature
  
  -- Create worktree
  vim.fn.system("git worktree add " .. worktree_path .. " -b " .. branch)
  
  if vim.v.shell_error == 0 then
    -- Create context file
    local context_content = string.format(
      "# Task: %s\nBranch: %s\nCreated: %s\n\n## Objective\n[Describe here]\n",
      feature, branch, os.date()
    )
    vim.fn.writefile(vim.split(context_content, "\n"), worktree_path .. "/CLAUDE.md")
    
    -- Spawn new WezTerm tab
    local wezterm = require("wezterm")
    wezterm.spawn_tab({
      cwd = worktree_path,
      args = { "nvim", "CLAUDE.md" },
    })
    
    vim.notify("Created worktree in new tab: " .. feature)
  end
end

return M
```

## Use Cases

### Scenario 1: Quick Fix in Main Branch

```vim
" 1. Open Neovim in your project
" 2. Hit <C-t> for terminal
" 3. Run: claude "fix the login validation"
" 4. Or hit <C-c> for Claude sidebar
```

### Scenario 2: New Feature Development

```vim
" 1. Create worktree
<leader>hW              " Create worktree dialog
> feature/user-profile  " Enter branch name

" 2. Auto-switches to new worktree
" 3. CLAUDE.md is created automatically
" 4. Hit <C-c> to start Claude with context
```

### Scenario 3: Parallel Multi-Agent Work

```vim
" Main Neovim session
<leader>ht              " Create worktree in new tab
> payment-integration   " Feature 1

<leader>ht              " Another worktree in new tab
> api-refactor          " Feature 2

<leader>ht              " Third worktree in new tab
> fix-memory-leak       " Bugfix

" Result: 4 WezTerm tabs, each with isolated Claude session
" Tab 1: Main project
" Tab 2: Payment integration (Claude working)
" Tab 3: API refactor (Claude working)
" Tab 4: Memory leak fix (Claude working)
```

### Example Workflow: Building a Feature

```vim
" 1. Start in main project
:pwd  " ~/dev/myproject

" 2. Create feature worktree
<leader>ht
> user-authentication

" 3. WezTerm opens new tab with:
"    - Directory: ~/dev/myproject-user-authentication
"    - File: CLAUDE.md (context file)
"    - Branch: feature/user-authentication

" 4. Edit CLAUDE.md to add context
i
## Objective
Implement JWT-based authentication with:
- Login/logout endpoints
- Token refresh mechanism
- Role-based access control
<Esc>:w

" 5. Start Claude
<C-c>  " Opens Claude sidebar

" 6. Give Claude the task
"Implement the authentication system as described in CLAUDE.md"

" 7. Claude works in isolation
"    - All changes in feature branch
"    - No conflicts with other work
"    - Complete context preservation
```

## Best Practices

### 1. Worktree Naming Convention

```
project-feature-name    # Features
project-bugfix-name     # Bug fixes
project-refactor-name   # Refactoring
project-experiment-name # Experiments
```

### 2. Context Files (CLAUDE.md)

Always update CLAUDE.md with:
- Clear objective
- Relevant constraints
- Expected outcomes
- Links to related issues/PRs

### 3. Session Management

```vim
" List active sessions
<leader>hl  " Shows all Claude sessions

" Clean up finished work
git worktree remove ../project-feature-done
git branch -d feature/done
```

### 4. Tab Organization

- Tab 1: Always keep main project
- Tab 2-N: Feature worktrees
- Use consistent naming for easy identification
- Close tabs when features are complete

### 5. Performance Tips
  

- Limit concurrent Claude sessions to 3-4 max
- Use `git worktree prune` regularly to clean up stale references
- Close unused WezTerm tabs to free resources
- Use tab-local directory changes (`tcd`) to prevent conflicts

### 6. Troubleshooting

#### Claude context confusion
```vim
" Always provide clear context
"I'm in feature/auth worktree working on JWT implementation"
```

#### Session not found
```vim
" Rebuild session list
:lua require('neotex.core.claude-worktree').restore_sessions()
```

#### WezTerm tab creation fails
```bash
# Check WezTerm CLI is available
wezterm cli list

# Ensure WezTerm is running
pgrep wezterm
```

## Summary

This streamlined workflow leverages your existing plugins (claude-code.nvim, toggleterm.nvim) plus two strategic additions (git-worktree.nvim, wezterm.nvim) to create a powerful multi-agent development environment. Each worktree gets its own WezTerm tab with isolated Claude session, all orchestrated from your main Neovim instance.

### Key Advantages

- **No external scripts** - Everything controlled from Neovim
- **True isolation** - Each worktree has independent file state
- **Seamless navigation** - Switch between sessions instantly
- **Context persistence** - CLAUDE.md files maintain task state
- **Resource efficient** - Only spawn tabs as needed

For detailed implementation instructions, see [CLAUDE_WORKTREE_IMPLEMENTATION.md](./CLAUDE_WORKTREE_IMPLEMENTATION.md).