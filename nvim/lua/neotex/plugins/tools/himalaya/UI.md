# Himalaya UI Implementation Plan

## Problem Summary

User gets "stuck" in background buffers when navigating through nested floating windows:
1. Open email list (`<leader>ml`) → floating window
2. Read email (`<CR>`) → nested floating window  
3. Reply (`gr`) → deeply nested floating window
4. Close reply (`q`) → should return to email
5. Close email (`q`) → should return to email list
6. Close email list (`q`) → should return to normal editing
7. **Problem**: Focus jumps to background buffer instead of parent windows

## Phase 1: Immediate Fix (Window Stack Management)

### Goal
Fix the navigation issue with minimal code changes by tracking window hierarchy.

### Implementation Steps

#### Step 1.1: Create Window Stack Manager
```lua
-- lua/neotex/plugins/tools/himalaya/window_stack.lua
local M = {}

-- Stack to track window hierarchy
M.stack = {}

-- Push a new window onto the stack
function M.push(win_id, parent_win)
  parent_win = parent_win or vim.api.nvim_get_current_win()
  table.insert(M.stack, {
    window = win_id,
    parent = parent_win,
    buffer = vim.api.nvim_win_get_buf(win_id)
  })
end

-- Pop window from stack and restore parent focus
function M.pop()
  if #M.stack == 0 then return end
  
  local entry = table.remove(M.stack)
  
  -- Close current window
  if vim.api.nvim_win_is_valid(entry.window) then
    vim.api.nvim_win_close(entry.window, true)
  end
  
  -- Restore focus to parent
  if entry.parent and vim.api.nvim_win_is_valid(entry.parent) then
    vim.api.nvim_set_current_win(entry.parent)
    return true
  end
  
  return false
end

-- Clear the stack
function M.clear()
  M.stack = {}
end

-- Get current depth
function M.depth()
  return #M.stack
end

return M
```

#### Step 1.2: Integrate Stack Manager into UI
```lua
-- Modify lua/neotex/plugins/tools/himalaya/ui.lua

-- At the top of the file
local window_stack = require('neotex.plugins.tools.himalaya.window_stack')

-- Modify show_email_list function
function M.show_email_list(account)
  -- ... existing code ...
  
  -- After creating the window
  window_stack.push(win)
  
  -- Store in buffer variable for keymaps
  vim.api.nvim_buf_set_var(buf, 'himalaya_window_id', win)
end

-- Modify open_email function  
function M.open_email(email_id)
  -- ... existing code ...
  
  -- After creating the window
  window_stack.push(email_win)
  
  -- Store parent reference
  vim.api.nvim_buf_set_var(email_buf, 'himalaya_window_id', email_win)
end

-- Modify reply/compose functions
function M.reply_current_email()
  -- ... existing code ...
  
  -- After creating compose window
  window_stack.push(compose_win)
  
  -- Store reference
  vim.api.nvim_buf_set_var(compose_buf, 'himalaya_window_id', compose_win)
end
```

#### Step 1.3: Update Close Handlers
```lua
-- Modify close handlers in config.lua

-- Replace the 'q' keymap with smart close
keymap('n', 'q', function()
  local window_stack = require('neotex.plugins.tools.himalaya.window_stack')
  
  -- Try to pop from stack first
  if not window_stack.pop() then
    -- If no parent, close normally
    vim.cmd('close')
  end
end, vim.tbl_extend('force', opts, { desc = 'Close Himalaya window' }))
```

### Testing Phase 1
1. Open email list
2. Navigate through emails and replies
3. Close windows with 'q' - should return to parent
4. Test edge cases (closing out of order, etc.)

## Phase 2: Sidebar + Floating Migration

### Goal
Replace floating email list with persistent sidebar while keeping floating windows for reading/composing.

### Implementation Steps

#### Step 2.1: Create Sidebar Module
```lua
-- lua/neotex/plugins/tools/himalaya/sidebar.lua
local M = {}

M.config = {
  width = 50,
  position = 'left',
  border = 'rounded'
}

M.state = {
  buf = nil,
  win = nil,
  is_open = false
}

function M.create_buffer()
  if M.state.buf and vim.api.nvim_buf_is_valid(M.state.buf) then
    return M.state.buf
  end
  
  M.state.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(M.state.buf, 'filetype', 'himalaya-list')
  vim.api.nvim_buf_set_option(M.state.buf, 'bufhidden', 'hide')
  
  return M.state.buf
end

function M.open()
  if M.state.is_open then return end
  
  local buf = M.create_buffer()
  
  -- Calculate window dimensions
  local width = M.config.width
  local height = vim.o.lines - 2
  
  -- Create sidebar window
  M.state.win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    anchor = M.config.position == 'left' and 'NW' or 'NE',
    width = width,
    height = height,
    row = 0,
    col = M.config.position == 'left' and 0 or (vim.o.columns - width),
    style = 'minimal',
    border = M.config.border
  })
  
  M.state.is_open = true
  
  -- Configure window
  vim.api.nvim_win_set_option(M.state.win, 'wrap', false)
  vim.api.nvim_win_set_option(M.state.win, 'cursorline', true)
  
  return M.state.win
end

function M.close()
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    vim.api.nvim_win_close(M.state.win, true)
  end
  M.state.is_open = false
end

function M.toggle()
  if M.state.is_open then
    M.close()
  else
    M.open()
  end
end

return M
```

#### Step 2.2: Refactor Email List to Use Sidebar
```lua
-- Modify show_email_list in ui.lua
function M.show_email_list(account)
  local sidebar = require('neotex.plugins.tools.himalaya.sidebar')
  
  -- Open sidebar instead of floating window
  local win = sidebar.open()
  local buf = vim.api.nvim_win_get_buf(win)
  
  -- Rest of the function remains similar
  -- ... existing email list loading code ...
end
```

#### Step 2.3: Update Navigation Flow
```lua
-- Email opens in floating window while sidebar stays visible
function M.open_email(email_id)
  -- Get current window position for floating window placement
  local sidebar_width = 50
  local float_width = math.floor(vim.o.columns * 0.8) - sidebar_width
  local float_height = math.floor(vim.o.lines * 0.8)
  
  -- Create floating window positioned next to sidebar
  local email_win = vim.api.nvim_open_win(email_buf, true, {
    relative = 'editor',
    width = float_width,
    height = float_height,
    row = math.floor((vim.o.lines - float_height) / 2),
    col = sidebar_width + 5,  -- Leave gap after sidebar
    style = 'minimal',
    border = 'rounded'
  })
  
  -- Continue with existing email display logic
end
```

### Testing Phase 2
1. Toggle sidebar with `<leader>ml`
2. Navigate emails in sidebar
3. Open emails in floating windows
4. Ensure sidebar persists when reading/composing
5. Test window positioning and sizing

## Phase 3: State Management & Persistence

### Goal
Add proper state management for session persistence and improved UX.

### Implementation Steps

#### Step 3.1: Create State Manager
```lua
-- lua/neotex/plugins/tools/himalaya/state.lua
local M = {}

M.state = {
  current_account = nil,
  current_folder = 'INBOX',
  selected_email = nil,
  sidebar_width = 50,
  last_query = nil
}

-- Save state to disk
function M.save()
  local data_dir = vim.fn.stdpath('data') .. '/himalaya'
  vim.fn.mkdir(data_dir, 'p')
  
  local state_file = data_dir .. '/state.json'
  local encoded = vim.fn.json_encode(M.state)
  
  local file = io.open(state_file, 'w')
  if file then
    file:write(encoded)
    file:close()
  end
end

-- Load state from disk
function M.load()
  local state_file = vim.fn.stdpath('data') .. '/himalaya/state.json'
  
  if vim.fn.filereadable(state_file) == 1 then
    local content = vim.fn.readfile(state_file)
    if #content > 0 then
      local ok, decoded = pcall(vim.fn.json_decode, content[1])
      if ok then
        M.state = vim.tbl_extend('force', M.state, decoded)
      end
    end
  end
end

return M
```

#### Step 3.2: Integrate State with UI
```lua
-- Add to himalaya init.lua setup
local state = require('neotex.plugins.tools.himalaya.state')
state.load()

-- Save state on VimLeavePre
vim.api.nvim_create_autocmd('VimLeavePre', {
  group = vim.api.nvim_create_augroup('HimalayaState', { clear = true }),
  callback = function()
    state.save()
  end
})
```

### Testing Phase 3
1. Open Himalaya, navigate to specific folder/email
2. Close Neovim
3. Reopen and verify state is restored
4. Test sidebar width persistence

## Phase 4: Polish & Optimizations

### Goal
Add final touches for production-ready UI.

### Implementation Steps

#### Step 4.1: Add Loading States
```lua
-- Show loading indicator while fetching emails
function M.show_loading(buf)
  local lines = {
    '',
    '  Loading emails...',
    '',
    '  [                    ]',
    ''
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end
```

#### Step 4.2: Add Error Handling
```lua
-- Graceful error display
function M.show_error(buf, error_msg)
  local lines = {
    '',
    '  ❌ Error: ' .. error_msg,
    '',
    '  Press <leader>mr to retry',
    ''
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end
```

#### Step 4.3: Add Refresh Capability
```lua
-- Auto-refresh email list
function M.start_auto_refresh()
  M.refresh_timer = vim.loop.new_timer()
  M.refresh_timer:start(60000, 60000, vim.schedule_wrap(function()
    if M.sidebar.is_open then
      M.refresh_email_list()
    end
  end))
end
```

### Testing Phase 4
1. Test loading states during slow operations
2. Simulate errors and verify graceful handling
3. Test auto-refresh functionality
4. Verify performance with large email lists

## Phase 5: Documentation

### Goal
Create comprehensive documentation for the completed email client integration.

### Implementation Steps

#### Step 5.1: Create Detailed Himalaya README
```markdown
# Himalaya Email Client Integration

Complete email client integration for Neovim using the Himalaya CLI.

## Features
- Neo-tree style sidebar for email browsing
- Floating windows for reading and composing emails
- Full keyboard navigation with Vim-style keybindings
- Support for multiple email accounts
- Persistent state across Neovim sessions
- Click-to-open URL support
- Draft saving and auto-recovery
- Email threading and conversation view

## Installation & Setup
[Detailed setup instructions]

## Usage
[Complete usage guide with screenshots]

## Keybindings
[Full keymap reference]

## Configuration
[Configuration options and examples]

## Troubleshooting
[Common issues and solutions]
```

#### Step 5.2: Update Tools README
```markdown
Brief description of Himalaya integration with link to detailed documentation.
```

#### Step 5.3: Update Main README
```markdown
Add Himalaya to the overview section with brief description and link.
```

### Testing Phase 5
1. Verify all documentation is accurate
2. Test that all links work correctly
3. Ensure examples match actual implementation
4. Review for clarity and completeness

## Migration Timeline

| Phase | Duration | Testing | Commit Point |
|-------|----------|---------|--------------|
| Phase 1 | 2-3 hours | 1 hour | Fix navigation issues |
| Phase 2 | 4-6 hours | 2 hours | Sidebar implementation |
| Phase 3 | 2-3 hours | 1 hour | State management |
| Phase 4 | 2-3 hours | 1 hour | Polish and optimize |
| Phase 5 | 1-2 hours | 30 min | Complete documentation |

## Benefits of This Approach

1. **Phase 1** provides immediate relief from navigation issues
2. **Phase 2** introduces familiar sidebar pattern used by neo-tree, aerial, etc.
3. **Phase 3** adds persistence for better UX across sessions
4. **Phase 4** ensures production-ready quality

## Success Metrics

- No more "stuck in background buffer" issues
- Intuitive navigation matching Neovim conventions
- Fast email browsing with persistent state
- Clear visual hierarchy (sidebar → email → compose)
- Stable and predictable focus management