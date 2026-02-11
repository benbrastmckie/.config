# Research Report: Task #55 (Supplemental)

**Task**: 55 - himalaya_module_refactor
**Report Version**: research-002 (supplemental to research-001)
**Started**: 2026-02-10T13:00:00Z
**Completed**: 2026-02-10T13:45:00Z
**Effort**: 2-4 hours estimated
**Dependencies**: research-001.md findings
**Sources/Inputs**: Local codebase analysis, telescope.nvim patterns, UX specification
**Artifacts**: specs/055_himalaya_module_refactor/reports/research-002.md
**Standards**: report-format.md, neovim-lua.md

## Executive Summary

- **Root Cause Identified**: Preview ONLY works when `preview_mode` is already TRUE - there is no mechanism to enter preview mode
- The CursorHold autocmd at line 1626 explicitly checks `if not email_preview.is_preview_mode() then return end`
- `preview_mode` defaults to FALSE and is never enabled by any keymap or action
- The `<CR>` keymap calls `email_list.handle_enter()` which does NOT exist - the function is undefined
- **Design Solution**: Implement a 3-state progressive interaction model with buffer-local state tracking

## Context and Scope

### Research Objectives
1. Analyze why current preview implementation does not work
2. Design state machine for desired progressive UX
3. Identify implementation patterns from telescope.nvim and nvim-tree
4. Provide concrete implementation recommendations

### User's Desired UX Specification

```
State Diagram:

  [SIDEBAR]  --<CR>-->  [PREVIEW_SWITCH]  --<CR>-->  [PREVIEW_FOCUS]  --<CR>-->  [BUFFER_OPEN]
     ^                        |                           |
     |                        |                           |
     +------<ESC>-------------+----------<ESC>------------+

                              (j/k moves cursor,          (j/k scrolls preview,
                               preview updates)            no cursor movement)
```

**States**:
1. **SIDEBAR (OFF)**: No preview visible. j/k moves through email list normally.
2. **PREVIEW_SWITCH**: Preview pane visible. j/k in sidebar updates preview to show different email.
3. **PREVIEW_FOCUS**: User can scroll within preview using j/k. Sidebar cursor frozen.
4. **BUFFER_OPEN**: Email opened in full buffer (terminal state - must close to return).

**Transitions**:
- `<CR>` advances state: SIDEBAR -> PREVIEW_SWITCH -> PREVIEW_FOCUS -> BUFFER_OPEN
- `<ESC>` regresses state: PREVIEW_FOCUS -> PREVIEW_SWITCH -> SIDEBAR
- Once in BUFFER_OPEN, must close buffer to return to sidebar

## Findings

### Finding 1: Root Cause of Preview Failure

The CursorHold-based preview is protected by a guard that always returns early.

**Code Path Analysis** (email_list.lua:1625-1643):
```lua
-- CursorHold - show preview after delay (only in preview mode)
vim.api.nvim_create_autocmd('CursorHold', {
  buffer = buf,
  callback = function()
    if not email_preview.config.enabled then return end
    if not email_preview.is_preview_mode() then return end  -- <-- ALWAYS FALSE
    -- ... preview code never executes
```

**email_preview.lua:15-22**:
```lua
local preview_state = {
  win = nil,
  buf = nil,
  email_id = nil,
  preview_mode = false,  -- <-- Default is FALSE
  autocmd_id = nil,
  preview_autocmd_id = nil,
}
```

**Critical Functions**:
- `is_preview_mode()` returns `preview_state.preview_mode` (line 826-827)
- `enable_preview_mode()` sets it to true (line 831-834)
- `toggle_preview_mode()` toggles it (line 820-822)

**Problem**: NOTHING calls `enable_preview_mode()` or `toggle_preview_mode()`. The mode is always false.

### Finding 2: Missing `handle_enter()` Function

The `<CR>` keymap attempts to call a function that does not exist.

**config/ui.lua:172-178**:
```lua
keymap('n', '<CR>', function()
  local ok, email_list = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_list')
  if ok and email_list.handle_enter then
    email_list.handle_enter()  -- <-- This function does NOT exist in email_list.lua
  end
end, vim.tbl_extend('force', opts, { desc = 'Open email or draft' }))
```

**Verification**: Searched email_list.lua (1684 lines) - no `handle_enter` function is defined.

### Finding 3: Telescope.nvim Preview Focus Pattern

Telescope users have [requested similar functionality](https://github.com/nvim-telescope/telescope.nvim/issues/2778) - the ability to focus the preview window.

**Telescope's Approach**:
- Maintains state in picker object
- Uses `scroll_previewer` actions for preview navigation
- Preview window is NOT normally focusable - actions operate remotely
- Does NOT implement the progressive focus model requested

**Relevant Pattern**: Telescope uses window-local variables and centralized state to track which buffer owns the picker session.

### Finding 4: nvim-tree Approach

nvim-tree uses a simpler model:
- Tree is always open when interacting
- Selection (cursor) directly controls what's previewed
- No separate "focus preview" mode - preview is informational only
- Opening a file closes the tree context

### Finding 5: Existing State Infrastructure

The himalaya module already has state management infrastructure that can be leveraged.

**core/state.lua** provides:
- `M.get(path, default)` - Get nested state value
- `M.set(path, value)` - Set nested state value
- `M.state.ui` - UI state namespace

**email_preview.lua** has:
- `preview_state.preview_mode` - Boolean flag (unused)
- `M.focus_preview()` - Function to focus preview window (exists, line 866-872)
- `M.hide_preview()` - Function to close preview (exists, line 801-816)

## State Machine Design

### Proposed State Enum

```lua
-- In email_preview.lua or new ui/preview_state.lua
local PREVIEW_STATE = {
  OFF = 0,           -- No preview visible
  SWITCH = 1,        -- Preview visible, j/k switches emails
  FOCUS = 2,         -- Preview focused, j/k scrolls content
  BUFFER_OPEN = 3,   -- Email opened in full buffer (terminal)
}
```

### State Storage

Modify `preview_state` in email_preview.lua:

```lua
local preview_state = {
  win = nil,
  buf = nil,
  email_id = nil,
  mode = PREVIEW_STATE.OFF,  -- Replace boolean with enum
  sidebar_cursor_line = nil, -- Freeze cursor position when focused
  autocmd_id = nil,
  preview_autocmd_id = nil,
}
```

### State Transition Logic

```lua
--- Handle Enter key press based on current state
function M.handle_enter()
  local current_mode = preview_state.mode

  if current_mode == PREVIEW_STATE.OFF then
    -- Transition to SWITCH mode
    M.enter_switch_mode()

  elseif current_mode == PREVIEW_STATE.SWITCH then
    -- Transition to FOCUS mode
    M.enter_focus_mode()

  elseif current_mode == PREVIEW_STATE.FOCUS then
    -- Transition to BUFFER_OPEN
    M.open_email_in_buffer()
  end
end

--- Handle Escape key press based on current state
function M.handle_escape()
  local current_mode = preview_state.mode

  if current_mode == PREVIEW_STATE.FOCUS then
    -- Return to SWITCH mode
    M.exit_focus_mode()

  elseif current_mode == PREVIEW_STATE.SWITCH then
    -- Return to OFF mode
    M.exit_switch_mode()
  end
end
```

### Keymap Changes by State

**SWITCH Mode Keymaps** (applied to sidebar buffer):
| Key | Action |
|-----|--------|
| j/k | Move cursor, update preview |
| `<CR>` | Enter FOCUS mode |
| `<ESC>` | Exit to OFF mode |
| q | Close sidebar entirely |

**FOCUS Mode Keymaps** (applied to preview buffer when focused):
| Key | Action |
|-----|--------|
| j/k | Scroll preview content |
| `<CR>` | Open in full buffer |
| `<ESC>` | Return to SWITCH mode |
| q | Return to SWITCH mode |

## Implementation Recommendations

### Recommendation 1: Implement State Machine in email_preview.lua

Add the state enum and transition functions to the existing email_preview.lua module since it already manages preview state.

**Location**: email_preview.lua (new functions)

```lua
-- Add after line 22 (preview_state definition)
local PREVIEW_STATE = {
  OFF = 0,
  SWITCH = 1,
  FOCUS = 2,
  BUFFER_OPEN = 3,
}

-- Update preview_state
preview_state.mode = PREVIEW_STATE.OFF
preview_state.sidebar_cursor_line = nil

--- Enter SWITCH mode (first <CR>)
function M.enter_switch_mode()
  if preview_state.mode ~= PREVIEW_STATE.OFF then return end

  preview_state.mode = PREVIEW_STATE.SWITCH

  -- Get current email and show preview
  local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
  local email_list = require('neotex.plugins.tools.himalaya.ui.email_list')
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local email_id = email_list.get_email_id_from_line(line)

  if email_id then
    M.show_preview(email_id, sidebar.get_win())
  end
end

--- Enter FOCUS mode (second <CR>)
function M.enter_focus_mode()
  if preview_state.mode ~= PREVIEW_STATE.SWITCH then return end
  if not preview_state.win or not vim.api.nvim_win_is_valid(preview_state.win) then
    return
  end

  -- Store sidebar cursor position
  preview_state.sidebar_cursor_line = vim.api.nvim_win_get_cursor(0)[1]

  -- Change mode BEFORE focusing (to set up correct keymaps)
  preview_state.mode = PREVIEW_STATE.FOCUS

  -- Focus the preview window
  vim.api.nvim_set_current_win(preview_state.win)

  -- Set up scroll-only keymaps for preview
  M.setup_focus_keymaps(preview_state.buf)
end

--- Exit FOCUS mode (ESC from focus)
function M.exit_focus_mode()
  if preview_state.mode ~= PREVIEW_STATE.FOCUS then return end

  preview_state.mode = PREVIEW_STATE.SWITCH

  -- Return focus to sidebar
  local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
  local sidebar_win = sidebar.get_win()
  if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
    vim.api.nvim_set_current_win(sidebar_win)
    -- Restore cursor position
    if preview_state.sidebar_cursor_line then
      vim.api.nvim_win_set_cursor(sidebar_win, {preview_state.sidebar_cursor_line, 0})
    end
  end
end

--- Exit SWITCH mode (ESC from switch)
function M.exit_switch_mode()
  if preview_state.mode ~= PREVIEW_STATE.SWITCH then return end

  preview_state.mode = PREVIEW_STATE.OFF
  M.hide_preview()
end

--- Get current preview state
function M.get_mode()
  return preview_state.mode
end

--- Check if in a specific mode
function M.is_mode(mode)
  return preview_state.mode == mode
end

-- Export state enum for other modules
M.PREVIEW_STATE = PREVIEW_STATE
```

### Recommendation 2: Implement handle_enter() in email_list.lua

Add the missing function that the keymap expects.

**Location**: email_list.lua (new function, add after line 1614)

```lua
--- Handle Enter key press - delegates to preview state machine
function M.handle_enter()
  local email_preview = require('neotex.plugins.tools.himalaya.ui.email_preview')
  local PREVIEW_STATE = email_preview.PREVIEW_STATE

  local current_mode = email_preview.get_mode()

  if current_mode == PREVIEW_STATE.OFF then
    -- Enter preview switch mode
    email_preview.enter_switch_mode()

  elseif current_mode == PREVIEW_STATE.SWITCH then
    -- Enter preview focus mode
    email_preview.enter_focus_mode()

  elseif current_mode == PREVIEW_STATE.FOCUS then
    -- This shouldn't be called from sidebar, but handle gracefully
    -- Open email in buffer
    M.open_current_email_in_buffer()
  end
end

--- Open current email in a full buffer
function M.open_current_email_in_buffer()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local email_id = M.get_email_id_from_line(line)

  if not email_id then
    notify.himalaya('No email selected', notify.categories.WARNING)
    return
  end

  -- Create or get email reading buffer
  local email_preview = require('neotex.plugins.tools.himalaya.ui.email_preview')
  local coordinator = require('neotex.plugins.tools.himalaya.ui.coordinator')

  -- Hide the floating preview first
  email_preview.hide_preview()

  -- Set mode to BUFFER_OPEN
  email_preview.preview_state.mode = email_preview.PREVIEW_STATE.BUFFER_OPEN

  -- Create a proper buffer for reading the email
  -- This should open in a vsplit to the right of the sidebar
  -- TODO: Implement email buffer creation
  notify.himalaya('Opening email ' .. email_id .. ' in buffer (TODO)', notify.categories.INFO)
end
```

### Recommendation 3: Update CursorMoved Handler for SWITCH Mode

When in SWITCH mode, cursor movement in sidebar should update preview.

**Location**: email_list.lua, modify setup_hover_preview() or add new autocmd

```lua
-- Add CursorMoved handler for SWITCH mode
vim.api.nvim_create_autocmd('CursorMoved', {
  buffer = buf,
  callback = function()
    local email_preview = require('neotex.plugins.tools.himalaya.ui.email_preview')

    -- Only update preview in SWITCH mode
    if email_preview.get_mode() ~= email_preview.PREVIEW_STATE.SWITCH then
      return
    end

    local line = vim.api.nvim_win_get_cursor(0)[1]
    local email_id = M.get_email_id_from_line(line)

    if email_id then
      local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
      email_preview.show_preview(email_id, sidebar.get_win())
    end
  end
})
```

### Recommendation 4: Add Focus Mode Keymaps

When entering FOCUS mode, set up scroll-only keymaps on the preview buffer.

**Location**: email_preview.lua (new function)

```lua
--- Setup keymaps for FOCUS mode
function M.setup_focus_keymaps(buf)
  local keymap = vim.keymap.set
  local opts = { buffer = buf, silent = true, nowait = true }

  -- j/k scroll the preview (not move cursor between emails)
  keymap('n', 'j', function()
    vim.cmd('normal! j')
  end, vim.tbl_extend('force', opts, { desc = 'Scroll down' }))

  keymap('n', 'k', function()
    vim.cmd('normal! k')
  end, vim.tbl_extend('force', opts, { desc = 'Scroll up' }))

  -- Page scrolling
  keymap('n', '<C-d>', '<C-d>', opts)
  keymap('n', '<C-u>', '<C-u>', opts)
  keymap('n', '<C-f>', '<C-f>', opts)
  keymap('n', '<C-b>', '<C-b>', opts)

  -- Enter opens email in full buffer
  keymap('n', '<CR>', function()
    M.open_email_in_buffer()
  end, vim.tbl_extend('force', opts, { desc = 'Open in buffer' }))

  -- ESC returns to SWITCH mode
  keymap('n', '<Esc>', function()
    M.exit_focus_mode()
  end, vim.tbl_extend('force', opts, { desc = 'Return to sidebar' }))

  -- q also returns to SWITCH mode (not close entirely)
  keymap('n', 'q', function()
    M.exit_focus_mode()
  end, vim.tbl_extend('force', opts, { desc = 'Return to sidebar' }))
end
```

### Recommendation 5: Add ESC Handler to Sidebar

The sidebar buffer needs an ESC keymap that is state-aware.

**Location**: config/ui.lua, in setup_email_list_keymaps()

```lua
-- ESC - state-aware escape
keymap('n', '<Esc>', function()
  local email_preview = require('neotex.plugins.tools.himalaya.ui.email_preview')
  local current_mode = email_preview.get_mode()

  if current_mode == email_preview.PREVIEW_STATE.SWITCH then
    email_preview.exit_switch_mode()
  elseif current_mode == email_preview.PREVIEW_STATE.OFF then
    -- In OFF mode, ESC does nothing or closes sidebar
    -- User can use 'q' to close sidebar
  end
end, vim.tbl_extend('force', opts, { desc = 'Exit preview mode' }))
```

## Implementation Priority

1. **P0 (Critical - Fixes Preview)**: Add `enter_switch_mode()` call to handle_enter()
2. **P0 (Critical)**: Implement `handle_enter()` in email_list.lua
3. **P1 (High)**: Implement state machine enum and transitions
4. **P1 (High)**: Add FOCUS mode keymaps
5. **P2 (Medium)**: Implement `open_email_in_buffer()` for terminal state
6. **P2 (Medium)**: Add ESC handlers for state regression

## Risks and Mitigations

### Risk 1: Keymap Conflicts
**Impact**: Medium - Different keymaps needed per state
**Mitigation**: Use buffer-local keymaps that are set/cleared on state transition

### Risk 2: Focus Management
**Impact**: Medium - Switching focus between windows is error-prone
**Mitigation**: Always validate window handles before focus operations; use pcall

### Risk 3: State Synchronization
**Impact**: Low - State could become inconsistent if windows are closed externally
**Mitigation**: Add WinClosed autocmd to reset state when preview/sidebar close

### Risk 4: Backward Compatibility
**Impact**: Low - Changes internal behavior but preserves keybindings
**Mitigation**: The external keymap (`<CR>`, `<ESC>`) remains the same; only behavior changes

## Appendix

### Files to Modify

1. `ui/email_preview.lua` - Add state machine, state enum, transition functions
2. `ui/email_list.lua` - Add `handle_enter()`, `open_current_email_in_buffer()`
3. `config/ui.lua` - Add ESC keymap to sidebar keymaps

### Test Verification

After implementation, verify:
1. First `<CR>` shows preview pane
2. j/k updates preview to different email while in SWITCH mode
3. Second `<CR>` focuses preview pane (cursor visible in preview)
4. j/k scrolls preview content while in FOCUS mode
5. `<ESC>` from FOCUS returns to SWITCH (cursor back in sidebar)
6. `<ESC>` from SWITCH hides preview entirely
7. Third `<CR>` opens email in full buffer

### References

- [Telescope Preview Focus Issue #2778](https://github.com/nvim-telescope/telescope.nvim/issues/2778)
- research-001.md - Original module analysis
- email_preview.lua - Current preview implementation
- email_list.lua - Email list and sidebar management
- config/ui.lua - Keymap definitions
