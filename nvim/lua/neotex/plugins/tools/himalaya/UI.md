# Himalaya UI Architecture Analysis

## Current Problem

User gets "stuck" in background buffers when navigating:
1. Open email list (`<leader>ml`)
2. Read email (`<CR>`)
3. Reply (`gr`)
4. Close reply (`q`)
5. Try to close email (`q`)
6. Try to close email list (`q`)
7. **Problem**: Now in background buffer instead of returning to normal editing

This happens because floating windows don't maintain proper focus hierarchy.

## Research-Based Solutions

### 1. **Window Stack Management** (Immediate Fix)

```lua
-- Track window hierarchy for proper focus restoration
local window_stack = {}

function push_window(win_id, parent_win)
  table.insert(window_stack, {
    win = win_id,
    parent = parent_win or vim.api.nvim_get_current_win()
  })
end

function pop_window()
  local entry = table.remove(window_stack)
  if entry and entry.parent and vim.api.nvim_win_is_valid(entry.parent) then
    vim.api.nvim_set_current_win(entry.parent)
  end
end
```

### 2. **Modal Window Pattern** (Better Fix)

```lua
-- Prevent background buffer access entirely
function create_modal_float(buf, opts)
  -- Dim all other windows
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if win ~= float_win then
      vim.api.nvim_win_set_option(win, 'winblend', 30)
    end
  end
  
  -- Handle escape routes
  vim.keymap.set('n', '<Esc>', close_modal, { buffer = buf })
end
```

## Alternative UI Architectures

### Option A: **Sidebar + Floating** (Recommended)

**Layout**: Neo-tree style sidebar for email list + floating windows for reading/composing

**Pros**:
- Most stable navigation
- Familiar to Neovim users
- No focus management issues
- Persistent across sessions
- Works with all Neovim features

**Cons**:
- Takes up horizontal space
- Different from current floating approach

**Implementation**:
```lua
-- Persistent sidebar at fixed width
local sidebar_width = 40
local sidebar_win = nil

function toggle_email_sidebar()
  if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
    vim.api.nvim_win_close(sidebar_win, true)
    sidebar_win = nil
  else
    sidebar_win = vim.api.nvim_open_win(email_list_buf, true, {
      relative = 'editor',
      anchor = 'NW',
      width = sidebar_width,
      height = vim.o.lines - 2,
      row = 0,
      col = 0,
      style = 'minimal',
      border = 'rounded'
    })
  end
end
```

### Option B: **Bufferline Integration** 

**Layout**: Dedicated "Email" tab that groups all email buffers

**Pros**:
- Visual separation of email workflow
- Standard buffer navigation
- No floating window issues
- Clear visual indication

**Cons**:
- Limited by buffer-based architecture
- May clutter bufferline
- Requires bufferline configuration

**Implementation**:
```lua
-- Group email buffers in bufferline
require('bufferline').setup({
  options = {
    groups = {
      items = {
        {
          name = "Email",
          highlight = { underline = true, sp = "blue" },
          priority = 1,
          icon = "=ç",
          matcher = function(buf)
            return buf.name:match("himalaya")
          end,
        }
      }
    }
  }
})
```

### Option C: **Full-Screen Takeover**

**Layout**: Email app takes over entire screen, like lazy.nvim

**Pros**:
- No navigation confusion
- Maximum screen real estate
- Clear application boundary
- Simple focus model

**Cons**:
- Disrupts normal editing workflow
- Context switching overhead
- Less integrated feeling

## Recommended Solution: **Hybrid Approach**

### Phase 1: Fix Current Issues (Quick)

1. **Add window stack management**:
   ```lua
   -- Track parent windows for proper restoration
   local function close_with_focus_restore()
     local parent = vim.b.himalaya_parent_win
     vim.cmd('close')
     if parent and vim.api.nvim_win_is_valid(parent) then
       vim.api.nvim_set_current_win(parent)
     end
   end
   ```

2. **Add escape prevention**:
   ```lua
   -- Prevent accidental background access
   vim.keymap.set('n', '<C-w>', '<Nop>', { buffer = buf })
   vim.keymap.set('n', '<C-^>', '<Nop>', { buffer = buf })
   ```

### Phase 2: UI Architecture Upgrade (Long-term)

1. **Move to sidebar + floating hybrid**:
   - Email list ’ Persistent sidebar (toggleable)
   - Email reading ’ Large floating window
   - Email composing ’ Modal floating window

2. **Benefits**:
   - Solves all navigation issues
   - More familiar to Neovim users
   - Better integration with workspace
   - Persistent state across sessions

## Implementation Difficulty

| Approach | Difficulty | Time | Benefits |
|----------|------------|------|----------|
| Window Stack Fix | Easy | 1-2 hours | Fixes current issues |
| Modal Pattern | Medium | 3-4 hours | Better UX |
| Sidebar Hybrid | Medium | 6-8 hours | Best long-term |
| Bufferline Integration | Hard | 8-12 hours | Visual separation |

## Code Examples for Sidebar Approach

```lua
-- Modern sidebar implementation
local M = {}

local sidebar = {
  win = nil,
  buf = nil,
  width = 50,
  is_open = false
}

function M.toggle()
  if sidebar.is_open then
    M.close()
  else
    M.open()
  end
end

function M.open()
  if sidebar.is_open then return end
  
  -- Create buffer if needed
  if not sidebar.buf or not vim.api.nvim_buf_is_valid(sidebar.buf) then
    sidebar.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(sidebar.buf, 'filetype', 'himalaya-list')
  end
  
  -- Create window
  sidebar.win = vim.api.nvim_open_win(sidebar.buf, true, {
    relative = 'editor',
    anchor = 'NW',
    width = sidebar.width,
    height = vim.o.lines - 2,
    row = 0,
    col = 0,
    style = 'minimal',
    border = 'rounded'
  })
  
  sidebar.is_open = true
  
  -- Set up keymaps
  local opts = { buffer = sidebar.buf, noremap = true, silent = true }
  vim.keymap.set('n', 'q', M.close, opts)
  vim.keymap.set('n', '<CR>', M.open_email, opts)
end

function M.close()
  if sidebar.win and vim.api.nvim_win_is_valid(sidebar.win) then
    vim.api.nvim_win_close(sidebar.win, true)
  end
  sidebar.is_open = false
end

function M.open_email()
  -- Open email in floating window, but keep sidebar open
  local email_id = get_current_email_id()
  if email_id then
    open_email_float(email_id)
  end
end

return M
```

## Recommendation

**Start with Phase 1** (window stack fix) to solve immediate issues, then **migrate to sidebar approach** for the best long-term UX. The sidebar pattern is used by successful plugins like neo-tree, aerial, and symbols-outline because it provides the most stable and predictable user experience.