# Research Report: Task #87

**Task**: 87 - Investigate WezTerm terminal directory change
**Started**: 2026-02-13T00:00:00Z
**Completed**: 2026-02-13T00:30:00Z
**Effort**: 1 hour
**Dependencies**: None
**Sources/Inputs**: Neovim configuration, wezterm.lua, fish shell config
**Artifacts**: - /home/benjamin/.config/nvim/specs/087_investigate_wezterm_terminal_directory_change/reports/research-001.md
**Standards**: report-format.md, subagent-return.md

## Executive Summary
- **No automatic directory-changing behavior found** in Neovim configuration
- WezTerm configuration **displays directory names** but does not change directories
- Further user observation needed to reproduce and document the exact scenario

## Context and Scope

The user reported that when opening neovim sessions in wezterm from the home directory (~), the terminal working directory changes to a project root. This investigation searched both Neovim configuration (lua/neotex/) and wezterm configuration (~/.dotfiles/config/wezterm.lua) for any code that would cause this behavior.

### Search Scope
- Neovim configuration: `/home/benjamin/.config/nvim/lua/neotex/`
- WezTerm configuration: `/home/benjamin/.dotfiles/config/wezterm.lua`
- Fish shell configuration: `/home/benjamin/.config/fish/config.fish`

## Findings

### 1. Neovim Configuration Analysis

#### Directory-Changing Code Found
All directory changes in the Neovim configuration are **user-triggered**, not automatic:

| File | Lines | Function | Trigger |
|------|-------|----------|---------|
| worktree.lua | 311, 383, 505, 877, 930, 1491, 1981 | `vim.cmd("tcd ...")` or `vim.cmd("cd ...")` | User action (picker selection, worktree switch) |
| worktree.lua (tools) | 209 | `vim.cmd("cd ...")` | Worktree deletion (safety fallback) |

#### No Automatic Directory Changes
- **No `autochdir`** setting found in options.lua
- **No `exrc`** setting found
- **Session manager has `autoload_mode = Disabled`** (sessions.lua:24)
- **No VimEnter autocmd** that changes directory

#### OSC 7 Integration (Report, Not Change)
```lua
-- autocmds.lua lines 109-131
-- These REPORT the current directory to WezTerm but do NOT change it
local function emit_osc7()
  local cwd = vim.fn.getcwd()
  -- ... sends to WezTerm for tab title display
end

-- Emits on:
-- - VimEnter (initial)
-- - DirChanged (any directory change)
-- - BufEnter (non-terminal buffers)
```

### 2. WezTerm Configuration Analysis

#### Tab Title Display (Not Directory Change)
```lua
-- wezterm.lua lines 283-295
-- Extracts project name from cwd for DISPLAY only
local cwd_url = active_pane.current_working_dir
if cwd_url then
  local cwd_path = cwd_url.file_path
  if cwd_path then
    project_name = cwd_path:match("([^/]+)/?$")
  end
end
```

#### No Directory-Changing Code
- No `default_cwd` or `cwd` settings in wezterm.lua
- Spawn command uses `CurrentPaneDomain` (inherits parent directory)
- `gui-startup` only maximizes window, doesn't change directory

### 3. Fish Shell Configuration

#### Zoxide Integration
```fish
# config.fish lines 23-26
if type -q zoxide
  zoxide init fish --cmd cd | source
end
```

Zoxide replaces `cd` with intelligent directory jumping, but:
- Only activates when user types `cd` command
- Does not auto-change directory on shell startup

#### OSC 7 Hook (Report Only)
```fish
# config.fish lines 7-14
if set -q WEZTERM_PANE
  function __wezterm_osc7 --on-variable PWD
    printf "\033]7;file://%s%s\033\\" (hostname) (pwd)
  end
  __wezterm_osc7
end
```

This reports directory changes to WezTerm but does not cause them.

### 4. Possible External Causes (Not Found in Configuration)

| Potential Cause | Status | Notes |
|----------------|--------|-------|
| project.nvim plugin | Not installed | Checked lazy plugins |
| rooter.vim | Not installed | No references found |
| LSP root_dir setting | Does not change cwd | Uses `root_markers` for workspace only |
| Session auto-restore | Disabled | `autoload_mode = Disabled` |

## Decisions

1. **No code changes recommended** at this time - no automatic directory-changing behavior identified
2. **Further investigation needed** - user should document exact reproduction steps

## Recommendations

### For Further Investigation

1. **Reproduce the issue with debug output**:
   ```bash
   # In wezterm, from home directory:
   pwd  # Should show ~
   nvim
   # Inside nvim, check:
   :pwd
   :lua print(vim.fn.getcwd())
   ```

2. **Check if the issue is specific to opening files**:
   - Does `nvim` alone change directory?
   - Does `nvim ~/some/file.lua` change directory?
   - Does `nvim .` change directory?

3. **Check for external scripts**:
   ```bash
   alias nvim  # Check for shell aliases
   which nvim  # Check for wrapper scripts
   ```

4. **Check WezTerm spawn behavior**:
   - When opening a new tab in WezTerm, does it inherit the current directory?
   - Test with `Ctrl+Space c` (new tab) vs clicking the + button

### Possible Scenarios That Could Cause This

1. **File argument with absolute path**: `nvim /path/to/project/file.lua` might cause some plugins to detect project root
2. **Session restoration**: If a session was saved with a different cwd, restoring it could change directory (but autoload is disabled)
3. **Git worktree session**: If the user previously used `<leader>aw` to create a worktree session, the worktree module might have persisted state

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Unable to reproduce issue | Medium | User provides exact reproduction steps |
| Behavior is intermittent | Low | Check for time-based or state-based triggers |
| External script involved | Low | Check aliases and PATH |

## Appendix

### Search Queries Used
```bash
# Directory changing in Neovim
grep -rE "vim\.cmd\.cd|vim\.fn\.chdir|:cd |:lcd |:tcd |autochdir|chdir\(|cd\s*['\"]" lua/neotex/

# Project root detection
grep -rE "project\.nvim|rooter|root-?dir|project[_-]?root|find[_-]?root" lua/neotex/

# WezTerm cwd settings
grep -r "cwd\s*=" ~/.dotfiles/config/wezterm.lua

# Startup directory changes
grep -rE "VimEnter.*cd|DirChanged|getcwd.*cd|vim\.cmd.*cd" lua/neotex/
```

### Files Examined
- `/home/benjamin/.config/nvim/lua/neotex/config/autocmds.lua`
- `/home/benjamin/.config/nvim/lua/neotex/config/options.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ui/sessions.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/worktree.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/core/worktree.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/lsp/lspconfig.lua`
- `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/telescope.lua`
- `/home/benjamin/.config/nvim/init.lua`
- `/home/benjamin/.dotfiles/config/wezterm.lua`
- `/home/benjamin/.config/fish/config.fish`
