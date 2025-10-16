# Worktree Session Restoration Implementation Spec

## Overview
Implement `<leader>ao` ("attach/open") to restore a closed worktree session with Claude Code. This feature allows users to reopen accidentally closed WezTerm tabs with their worktree and restart the Claude Code session, preserving context and workflow continuity.

## Problem Statement
When a WezTerm tab containing a worktree and active Claude Code session is accidentally closed:
1. The worktree still exists on disk
2. The Claude session metadata is preserved in JSON
3. The CLAUDE.md context file remains
4. But there's no easy way to restore the complete environment

## Goals
1. Provide single-command restoration of worktree environment
2. Reopen WezTerm tab with correct working directory
3. Restore Claude Code session with preserved context
4. Maintain session continuity without data loss
5. Handle edge cases gracefully (missing sessions, corrupted data)

## User Experience

### Workflow
```vim
" Accidentally close tab with active worktree
" Later...
<leader>ao         " Open restoration picker
> bimodal_witness  " Select worktree to restore
" Automatically:
" - Opens new WezTerm tab
" - Sets working directory to worktree
" - Opens Neovim with CLAUDE.md
" - Restores Claude Code session
```

### Picker Interface
```
Restore Worktree Session
========================
  bimodal_witness    feature/bimodal_witness    [Active Claude session]
  project_creation   bugfix/project_creation     [Active Claude session]
  old_feature        feature/old_feature         [No Claude session]

Preview shows:
- Worktree path
- Branch info
- Claude session status
- Last modified time
- CLAUDE.md preview
```

## Technical Architecture

### Components

#### 1. Session Detection
```lua
-- Check if worktree has recoverable Claude session
function M.is_restorable(worktree_name)
  local session = M.sessions[worktree_name]
  if not session then return false end
  
  -- Check worktree exists
  local worktree_exists = vim.fn.isdirectory(session.worktree_path) == 1
  
  -- Check CLAUDE.md exists
  local claude_md = session.worktree_path .. "/CLAUDE.md"
  local has_context = vim.fn.filereadable(claude_md) == 1
  
  -- Check if Claude Code session can be restored
  local session_file = M._get_claude_session_file(session.session_id)
  local has_session = vim.fn.filereadable(session_file) == 1
  
  return worktree_exists and has_context
end
```

#### 2. WezTerm Tab Recreation
```lua
-- Spawn new WezTerm tab and capture ID
function M._spawn_restoration_tab(worktree_path, name)
  -- Use WezTerm CLI to create new tab
  local cmd = string.format(
    "wezterm cli spawn --cwd '%s' -- nvim CLAUDE.md",
    worktree_path
  )
  
  local result = vim.fn.system(cmd)
  local pane_id = result:match("(%d+)")
  
  if pane_id then
    -- Get tab ID from pane
    local tab_info = vim.fn.system("wezterm cli list --format json")
    local tab_id = M._extract_tab_id(tab_info, pane_id)
    
    -- Activate the tab
    vim.fn.system("wezterm cli activate-pane --pane-id " .. pane_id)
    
    -- Rename tab for clarity
    vim.fn.system(string.format(
      "wezterm cli set-tab-title --pane-id %s '%s'",
      pane_id, name
    ))
    
    return tab_id, pane_id
  end
  
  return nil, nil
end
```

#### 3. Claude Code Session Restoration
```lua
-- Restore Claude Code session in new environment
function M._restore_claude_session(worktree_path, session_id)
  -- Method 1: Use ClaudeCodeResume with session ID
  vim.schedule(function()
    -- Wait for Neovim to fully load in new tab
    vim.defer_fn(function()
      -- Execute in the new Neovim instance via WezTerm
      local restore_cmd = string.format(
        "wezterm cli send-text --pane-id %s ':ClaudeCodeResume %s\n'",
        pane_id, session_id
      )
      vim.fn.system(restore_cmd)
    end, 1000)
  end)
  
  -- Method 2: Alternative using RPC if available
  -- Send command to new Neovim instance to resume session
end
```

#### 4. Telescope Picker
```lua
function M.restore_worktree_session()
  local restorable = {}
  
  -- Find all restorable sessions
  for name, session in pairs(M.sessions) do
    if M.is_restorable(name) then
      table.insert(restorable, {
        name = name,
        session = session,
        display = M._format_restoration_entry(name, session)
      })
    end
  end
  
  -- Also check for orphaned worktrees without sessions
  local worktrees = M._get_all_worktrees()
  for _, worktree in ipairs(worktrees) do
    if not M.sessions[worktree.name] then
      table.insert(restorable, {
        name = worktree.name,
        worktree = worktree,
        no_session = true,
        display = M._format_orphan_entry(worktree)
      })
    end
  end
  
  -- Show picker
  require("telescope.pickers").new({}, {
    prompt_title = "Restore Worktree Session",
    finder = finders.new_table {
      results = restorable,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.display,
          ordinal = entry.name
        }
      end
    },
    previewer = M._create_restoration_previewer(),
    attach_mappings = function(_, map)
      actions.select_default:replace(function(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        
        if selection then
          M._perform_restoration(selection.value)
        end
      end)
      return true
    end
  }):find()
end
```

#### 5. Complete Restoration Function
```lua
function M._perform_restoration(entry)
  local worktree_path = entry.session and entry.session.worktree_path 
                        or entry.worktree.path
  local name = entry.name
  
  -- Step 1: Verify worktree still exists
  if vim.fn.isdirectory(worktree_path) == 0 then
    vim.notify("Worktree no longer exists: " .. worktree_path, vim.log.levels.ERROR)
    return
  end
  
  -- Step 2: Spawn WezTerm tab
  local tab_id, pane_id = M._spawn_restoration_tab(worktree_path, name)
  if not tab_id then
    vim.notify("Failed to create WezTerm tab", vim.log.levels.ERROR)
    return
  end
  
  -- Step 3: Update session with new tab ID
  if entry.session then
    M.sessions[name].tab_id = tab_id
    M.save_sessions()
  end
  
  -- Step 4: Restore Claude session if available
  if entry.session and entry.session.session_id then
    -- Send resume command to new Neovim instance
    vim.defer_fn(function()
      local resume_cmd = string.format(
        "wezterm cli send-text --pane-id %s ':ClaudeCodeResume\n'",
        pane_id
      )
      vim.fn.system(resume_cmd)
      
      -- Also try to open Claude sidebar
      vim.defer_fn(function()
        local sidebar_cmd = string.format(
          "wezterm cli send-text --no-paste --pane-id %s '\\x01'",  -- Ctrl-A
          pane_id
        )
        vim.fn.system(sidebar_cmd)
      end, 2000)
    end, 1500)
  end
  
  vim.notify(string.format("Restored worktree session: %s", name), vim.log.levels.INFO)
end
```

## Implementation Details

### File Structure
```
nvim/lua/neotex/core/
├── claude-worktree.lua         # Add restoration functions [DONE]
└── worktree-restore.lua        # New module for restoration logic (optional) [NOT NEEDED]
```

### Key Functions to Add

#### In `claude-worktree.lua`:
```lua
M.restore_worktree_session()      -- Main entry point [DONE - line 1067]
M.is_restorable(name)             -- Check if session can be restored [DONE - line 936]
M._perform_restoration(entry)      -- Execute restoration [DONE - line 1194]
M._spawn_restoration_tab()        -- Create WezTerm tab [DONE - line 965]
M._restore_claude_session()       -- Restore Claude Code [DONE - line 1002]
M._create_restoration_previewer()  -- Telescope preview [DONE - line 1029]
M._format_restoration_entry()     -- Format picker entry [DONE - lines 1055,1062]
M._get_claude_session_file()      -- Locate Claude session file [NOT NEEDED - using simpler approach]
```

### Integration Points [IMPLEMENTED]

#### 1. WezTerm CLI Commands
```bash
# Spawn new tab with working directory [DONE - used in _spawn_restoration_tab]
wezterm cli spawn --cwd /path/to/worktree -- nvim CLAUDE.md

# Get pane/tab information [DONE - used to extract tab_id]
wezterm cli list --format json

# Activate specific pane [DONE - activates restored tab]
wezterm cli activate-pane --pane-id 12345

# Send text to pane (for commands) [DONE - sends ClaudeCodeResume]
wezterm cli send-text --pane-id 12345 ':ClaudeCodeResume\n'

# Send control characters [DONE - sends Ctrl-A for sidebar]
wezterm cli send-text --no-paste --pane-id 12345 '\x01'  # Ctrl-A

# Set tab title [DONE - sets worktree name as title]
wezterm cli set-tab-title --pane-id 12345 'project_name'
```

#### 2. Claude Code Commands [INTEGRATED]
```vim
:ClaudeCodeResume              " Interactive session picker [DONE - sent to new tab]
:ClaudeCodeResume <session-id> " Resume specific session [NOT USED - simpler approach]
:ClaudeCodeContinue            " Continue current session [NOT USED]
<C-a>                          " Toggle Claude sidebar [DONE - sent via Ctrl-A]
```

#### 3. User Commands and Keymaps [DONE]
```vim
:ClaudeRestoreSession          " User command registered (line 879)
<leader>ao                     " Keymap added in which-key.lua (line 196)
```

#### 3. Session File Locations
```
~/.local/share/nvim/claude-worktree-sessions.json  # Our session metadata
~/.config/claude/sessions/sessions.json            # Claude's session list
~/.config/claude/projects/{hash}/{session}.jsonl   # Claude conversation logs
```

## Error Handling

### Scenarios to Handle
1. **Worktree deleted**: Show error, offer to remove session
2. **WezTerm not available**: Fall back to current Neovim instance
3. **Claude session corrupted**: Create new session, preserve CLAUDE.md
4. **Tab already exists**: Switch to existing tab instead
5. **Permission issues**: Show helpful error messages

### Recovery Strategies
```lua
-- Graceful degradation
function M._perform_restoration_safe(entry)
  local ok, err = pcall(M._perform_restoration, entry)
  if not ok then
    -- Fallback: Open in current Neovim
    vim.notify("Full restoration failed, opening locally", vim.log.levels.WARN)
    vim.cmd("cd " .. entry.session.worktree_path)
    vim.cmd("edit CLAUDE.md")
    
    -- Try to resume Claude session locally
    vim.defer_fn(function()
      vim.cmd("ClaudeCodeResume")
    end, 100)
  end
end
```

## Configuration Options

Add to `M.config` in `claude-worktree.lua`:
```lua
config = {
  -- ... existing options
  restoration = {
    auto_activate_tab = true,      -- Auto-switch to restored tab
    restore_claude_sidebar = true,  -- Open Claude sidebar after restore
    restore_delay_ms = 1500,        -- Delay before sending commands
    fallback_to_local = true,       -- Open locally if WezTerm fails
    show_orphaned_worktrees = true, -- Include worktrees without sessions
    preserve_window_layout = false, -- Try to restore window splits
  }
}
```

## Testing Checklist

### Basic Functionality
- [ ] `<leader>ao` opens restoration picker
- [ ] Picker shows all restorable sessions
- [ ] Preview shows relevant information
- [ ] Selecting entry creates WezTerm tab
- [ ] Working directory is set correctly
- [ ] CLAUDE.md opens automatically

### Claude Integration
- [ ] Claude Code session resumes properly
- [ ] Claude sidebar opens (if configured)
- [ ] Context is preserved from previous session
- [ ] Can continue conversation immediately

### Edge Cases
- [ ] Handle missing worktree gracefully
- [ ] Handle WezTerm not running
- [ ] Handle corrupted session data
- [ ] Handle permission errors
- [ ] Multiple restorations work correctly

### Performance
- [ ] Picker loads quickly with many sessions
- [ ] Tab creation is responsive
- [ ] No blocking operations in main thread

## Future Enhancements

### Phase 2
- Save and restore window layout (splits)
- Restore cursor position in files
- Restore open buffers
- Integration with session-manager.nvim
- Batch restoration of multiple sessions

### Phase 3
- Auto-detect closed sessions and prompt for restoration
- Session snapshots with git state
- Cloud backup of session metadata
- Session templates for common workflows
- Integration with tmux as alternative to WezTerm

## User Documentation

### Add to CLAUDE_CODE_WORKFLOW.md:
```markdown
## Restoring Closed Sessions

If you accidentally close a WezTerm tab with an active worktree:

```vim
<leader>ao         " Open restoration picker
" Select the worktree you want to restore
" Automatically reopens in new WezTerm tab with Claude session
```

The restoration process:
1. Creates new WezTerm tab
2. Sets working directory to worktree
3. Opens CLAUDE.md for context
4. Resumes Claude Code session
5. Restores Claude sidebar (optional)

### Tips
- Sessions are preserved even after closing tabs
- You can restore multiple sessions
- Works even after restarting Neovim
- Falls back to local opening if WezTerm unavailable
```

## Success Metrics
1. **Restoration Success Rate**: >95% successful restorations
2. **Time to Restore**: <3 seconds from selection to ready
3. **Context Preservation**: 100% of CLAUDE.md content preserved
4. **Session Continuity**: Claude conversation continues seamlessly
5. **User Satisfaction**: Reduces friction from accidental closures