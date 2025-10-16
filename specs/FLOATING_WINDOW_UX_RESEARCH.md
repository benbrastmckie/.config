# Neovim Floating Window UX Research for Email Client UI

## Executive Summary

This document presents comprehensive research on improving floating window user experience in Neovim, specifically for complex applications like email clients. It covers common problems with floating windows, alternative UI approaches, and implementation strategies based on successful Neovim plugins.

## 1. Common Problems with Floating Windows and Solutions

### 1.1 Focus Management Issues

**Problem**: When closing nested floating windows, focus can unexpectedly jump to background buffers instead of the parent floating window.

**Solutions**:
- Use `nvim_set_current_win()` to explicitly control focus
- Keep track of window IDs in a stack for proper navigation
- Set `focusable = true` for windows that should be part of navigation
- Implement custom close handlers that manage focus properly

```lua
-- Example: Focus management with window stack
local window_stack = {}

function M.push_window(win_id)
  table.insert(window_stack, win_id)
end

function M.close_current_and_focus_parent()
  local current = table.remove(window_stack)
  vim.api.nvim_win_close(current, true)
  
  if #window_stack > 0 then
    vim.api.nvim_set_current_win(window_stack[#window_stack])
  end
end
```

### 1.2 Navigation Between Floating Windows

**Problem**: Standard window navigation commands (CTRL-W) don't always work intuitively with floating windows.

**Solutions**:
- Floating windows are last in the window list, so `<C-w><C-w>` cycles through splits first
- Implement custom keymaps for floating window navigation
- Use `vim.api.nvim_list_wins()` to get all windows and filter for floating ones

### 1.3 Z-index and Overlapping Windows

**Problem**: No native priority/z-index control for overlapping floating windows.

**Solutions**:
- Creation order determines stacking
- Close and recreate windows to control z-order
- Implement a window manager that tracks z-order manually

### 1.4 Accidental Escape to Background

**Problem**: Users accidentally escape floating window context and interact with background buffers.

**Solutions**:
- Set `focusable = false` for background windows temporarily
- Use modal-style interaction patterns
- Implement escape key handlers that close the entire window stack

## 2. Alternative UI Approaches

### 2.1 Dedicated Tabs in Bufferline/Tabline

**Advantages**:
- Persistent presence in the UI
- Easy switching between email and other work
- Native Neovim navigation commands work
- No focus management issues

**Implementation with bufferline.nvim**:
```lua
-- Using bufferline groups feature for dedicated "applications"
bufferline.setup({
  options = {
    groups = {
      items = {
        {
          name = "Email",
          priority = 1,
          matcher = function(buf)
            return buf.filename:match('himalaya%-') ~= nil
          end,
        },
      },
    },
  },
})
```

**Alternative: True Tab-Based Approach**:
- Use `tabby.nvim` or `tabline.nvim` for actual vim tabs
- Each tab represents a workspace (email, coding, etc.)
- Tabs persist across sessions

### 2.2 Split Window Layouts

**Advantages**:
- Most stable and predictable UI approach
- All standard Vim navigation works
- No focus management issues
- Can be saved/restored with sessions

**Implementation Pattern** (like neo-tree):
```lua
-- Sidebar approach with persistent buffer
local email_buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_option(email_buf, 'buftype', 'nofile')
vim.api.nvim_buf_set_option(email_buf, 'bufhidden', 'hide')

-- Open in split
vim.cmd('vsplit')
vim.api.nvim_win_set_buf(0, email_buf)
vim.api.nvim_win_set_width(0, 40)
```

### 2.3 Sidebar Approach (Neo-tree Style)

**Advantages**:
- Familiar pattern for Neovim users
- Good for hierarchical navigation (folders → emails → content)
- Can be toggled easily
- Integrates well with existing workflow

**Key Features from Neo-tree**:
- Persistent buffer management
- Width persistence across sessions
- Event-based state management
- Clean separation from main editing area

### 2.4 Full-Screen Takeover (Telescope/Lazy Style)

**Advantages**:
- Maximum screen real estate
- Clear modal interaction
- No distraction from other content
- Easy to implement escape behavior

**Implementation Pattern**:
```lua
-- Full-screen floating window
local opts = {
  relative = 'editor',
  width = vim.o.columns,
  height = vim.o.lines - 2,  -- Leave room for statusline
  row = 0,
  col = 0,
  style = 'minimal',
  border = 'none',
}
```

## 3. Plugin UI Pattern Analysis

### 3.1 Lazy.nvim Patterns

- **Single large floating window** for all UI
- **Event-driven updates** for dynamic content
- **Keyboard-centric navigation** with clear mappings
- **Escape always closes** the entire UI

### 3.2 Mason.nvim Patterns

- **Configurable window size** (percentage or fixed)
- **Interactive list navigation** with expand/collapse
- **Status indicators** integrated into the UI
- **Backdrop dimming** for focus

### 3.3 Telescope.nvim Patterns

- **Three-pane layout**: results, preview, prompt
- **Fuzzy finding** reduces need for complex navigation
- **Actions system** for operations on selections
- **Extension architecture** for customization

### 3.4 Snacks.nvim Window Management

- **Unified window style system**
- **Configurable animations**
- **Consistent keybindings across different window types**
- **Smart positioning** based on content

## 4. Bufferline Integration Strategies

### 4.1 Custom Tab Implementation

**Using Bufferline Groups**:
- Groups can simulate "application tabs"
- Visual separation between email buffers and code
- Can be hidden/shown as a group

**Limitations**:
- Still buffer-based, not true tabs
- Limited to bufferline plugin features

### 4.2 Hybrid Approach

Combine multiple strategies:
1. Use bufferline for file buffers
2. Use a dedicated tab for email UI
3. Use floating windows for temporary interactions (compose, search)

### 4.3 Custom Tabline Component

Some plugins allow custom components:
```lua
-- Example with tabby.nvim
local custom_component = {
  provider = function()
    if require('himalaya').is_active() then
      return ' 📧 Email '
    end
    return ''
  end,
  hl = 'TabLineSel',
}
```

## 5. Best Practices for UI State Management

### 5.1 Centralized State Management

```lua
-- Central state manager
local UIState = {
  windows = {},
  buffers = {},
  current_view = nil,
  history = {},
}

function UIState:push_view(view_type, data)
  table.insert(self.history, {
    type = self.current_view,
    data = vim.deepcopy(data)
  })
  self.current_view = view_type
end

function UIState:pop_view()
  if #self.history > 0 then
    local prev = table.remove(self.history)
    self.current_view = prev.type
    return prev.data
  end
end
```

### 5.2 Event-Driven Architecture

```lua
-- Event system for UI updates
local events = {
  handlers = {},
}

function events:on(event_name, handler)
  self.handlers[event_name] = self.handlers[event_name] or {}
  table.insert(self.handlers[event_name], handler)
end

function events:emit(event_name, data)
  for _, handler in ipairs(self.handlers[event_name] or {}) do
    handler(data)
  end
end
```

### 5.3 Buffer Lifecycle Management

```lua
-- Proper buffer cleanup
local function create_managed_buffer()
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Set up autocmd for cleanup
  vim.api.nvim_create_autocmd("BufUnload", {
    buffer = buf,
    callback = function()
      -- Cleanup associated resources
      UIState:remove_buffer(buf)
    end,
  })
  
  return buf
end
```

### 5.4 Navigation Flow Control

```lua
-- Navigation manager
local Navigation = {
  history = {},
  blocked = false,
}

function Navigation:can_navigate()
  return not self.blocked and #self.history > 0
end

function Navigation:block_during(fn)
  self.blocked = true
  local ok, result = pcall(fn)
  self.blocked = false
  if not ok then error(result) end
  return result
end
```

## 6. Recommended Implementation Strategy

### For Email Client UI Specifically:

1. **Primary Approach**: Use a **sidebar layout** (like neo-tree) for the email list
   - Persistent and familiar
   - Good for hierarchical navigation
   - Integrates well with existing workflows

2. **Secondary Windows**: Use **floating windows** for:
   - Email reading (larger floating window)
   - Compose/reply (modal-style interaction)
   - Quick actions (small popups)

3. **Focus Management**:
   - Implement a window stack manager
   - Use explicit focus control
   - Provide clear escape paths

4. **State Persistence**:
   - Save current folder/account selection
   - Restore window layouts
   - Remember user preferences

5. **Keybinding Strategy**:
   - Consistent across all views
   - Modal keybindings in floating windows
   - Standard Vim navigation where possible

### Example Architecture:

```lua
local EmailUI = {
  -- Sidebar for email list (persistent)
  sidebar = {
    buffer = nil,
    window = nil,
    width = 40,
  },
  
  -- Floating windows for reading/composing
  floats = {
    read = { buffer = nil, window = nil },
    compose = { buffer = nil, window = nil },
  },
  
  -- State management
  state = {
    current_email = nil,
    current_folder = 'INBOX',
    window_stack = {},
  },
  
  -- Open sidebar with email list
  open_sidebar = function(self)
    -- Implementation
  end,
  
  -- Open floating window for reading
  open_email = function(self, email_id)
    -- Implementation with focus management
  end,
}
```

## Conclusion

The best approach for an email client UI in Neovim is a **hybrid strategy**:

1. Use a **persistent sidebar** for email navigation (most stable)
2. Use **floating windows** for temporary interactions (reading, composing)
3. Implement **proper focus management** with a window stack
4. Consider **bufferline integration** for visual indication
5. Follow **established patterns** from successful plugins

This approach balances stability, familiarity, and functionality while avoiding the common pitfalls of pure floating window implementations.