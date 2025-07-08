# Window Management Improvements Specification

**Status**: Planned - Not Implemented  
**Created**: 2025-07-07  
**Updated**: 2025-01-08 - Revised for clarity, marked as future enhancement
**Priority**: Low - Nice-to-have UI enhancement

This specification outlines window management improvements for the Himalaya email client, focusing on better window coordination, layouts, and navigation for multi-window email management within a single account view.

**Note**: This is separate from Multiple Account Views (Phase 9) which manages different email accounts. This specification focuses on improving window layouts for email list, preview, and folder components.

## Overview

Enhance the Himalaya UI with intelligent window management capabilities including predefined layouts, window coordination, persistence, and interactive resizing.

## Implementation Plan

### 1. Window Manager Module
Create `ui/window_manager.lua`:

```lua
local M = {}

-- Window layouts
M.layouts = {
  CLASSIC = "classic",      -- List | Preview
  VERTICAL = "vertical",    -- List on top, Preview below
  THREEPANE = "threepane",  -- Folders | List | Preview
  FOCUSED = "focused",      -- Single window focus mode
  CUSTOM = "custom"         -- User-defined layout
}

-- Window state
M.state = {
  layout = M.layouts.CLASSIC,
  windows = {},
  last_focused = nil,
  resize_mode = false
}

-- Window types
M.window_types = {
  FOLDER_TREE = "folder_tree",
  EMAIL_LIST = "email_list",
  EMAIL_PREVIEW = "email_preview",
  COMPOSER = "composer",
  SEARCH = "search",
  SETTINGS = "settings"
}

-- Initialize window manager
function M.setup()
  -- Set up autocmds for window coordination
  M.setup_autocmds()
  
  -- Load saved layout preferences
  M.load_preferences()
end

-- Create layout
function M.create_layout(layout_name)
  layout_name = layout_name or M.state.layout
  M.state.layout = layout_name
  
  -- Close existing windows
  M.close_all_windows()
  
  if layout_name == M.layouts.CLASSIC then
    M.create_classic_layout()
  elseif layout_name == M.layouts.VERTICAL then
    M.create_vertical_layout()
  elseif layout_name == M.layouts.THREEPANE then
    M.create_threepane_layout()
  elseif layout_name == M.layouts.FOCUSED then
    M.create_focused_layout()
  end
  
  -- Save layout preference
  M.save_preferences()
end

-- Classic layout: List | Preview
function M.create_classic_layout()
  -- Create email list window (left)
  vim.cmd('vsplit')
  local list_win = vim.api.nvim_get_current_win()
  local list_buf = M.create_email_list_buffer()
  vim.api.nvim_win_set_buf(list_win, list_buf)
  vim.api.nvim_win_set_width(list_win, math.floor(vim.o.columns * 0.4))
  
  -- Create preview window (right)
  vim.cmd('wincmd l')
  local preview_win = vim.api.nvim_get_current_win()
  local preview_buf = M.create_preview_buffer()
  vim.api.nvim_win_set_buf(preview_win, preview_buf)
  
  -- Store window references
  M.state.windows = {
    [M.window_types.EMAIL_LIST] = {
      win = list_win,
      buf = list_buf
    },
    [M.window_types.EMAIL_PREVIEW] = {
      win = preview_win,
      buf = preview_buf
    }
  }
  
  -- Focus on list
  vim.api.nvim_set_current_win(list_win)
end

-- Three-pane layout: Folders | List | Preview
function M.create_threepane_layout()
  -- Create folder tree window (left)
  vim.cmd('vsplit')
  vim.cmd('vsplit')
  
  local folder_win = vim.api.nvim_get_current_win()
  local folder_buf = M.create_folder_tree_buffer()
  vim.api.nvim_win_set_buf(folder_win, folder_buf)
  vim.api.nvim_win_set_width(folder_win, 20)
  
  -- Create email list window (middle)
  vim.cmd('wincmd l')
  local list_win = vim.api.nvim_get_current_win()
  local list_buf = M.create_email_list_buffer()
  vim.api.nvim_win_set_buf(list_win, list_buf)
  vim.api.nvim_win_set_width(list_win, math.floor((vim.o.columns - 20) * 0.4))
  
  -- Create preview window (right)
  vim.cmd('wincmd l')
  local preview_win = vim.api.nvim_get_current_win()
  local preview_buf = M.create_preview_buffer()
  vim.api.nvim_win_set_buf(preview_win, preview_buf)
  
  -- Store window references
  M.state.windows = {
    [M.window_types.FOLDER_TREE] = {
      win = folder_win,
      buf = folder_buf
    },
    [M.window_types.EMAIL_LIST] = {
      win = list_win,
      buf = list_buf
    },
    [M.window_types.EMAIL_PREVIEW] = {
      win = preview_win,
      buf = preview_buf
    }
  }
  
  -- Focus on list
  vim.api.nvim_set_current_win(list_win)
end
```

### 2. Window Coordination
```lua
-- Coordinate window updates
function M.update_preview(email_id)
  local preview = M.state.windows[M.window_types.EMAIL_PREVIEW]
  if not preview or not vim.api.nvim_win_is_valid(preview.win) then
    return
  end
  
  -- Update preview content
  local email_preview = require('neotex.plugins.tools.himalaya.ui.email_preview')
  email_preview.show_email_in_buffer(email_id, preview.buf)
  
  -- Ensure window is visible
  if M.state.layout == M.layouts.FOCUSED then
    M.focus_window(M.window_types.EMAIL_PREVIEW)
  end
end

-- Smart window focusing
function M.focus_window(window_type)
  local window = M.state.windows[window_type]
  if not window or not vim.api.nvim_win_is_valid(window.win) then
    return
  end
  
  -- Store last focused
  M.state.last_focused = window_type
  
  if M.state.layout == M.layouts.FOCUSED then
    -- In focused mode, maximize the window
    M.maximize_window(window.win)
  else
    -- Just focus the window
    vim.api.nvim_set_current_win(window.win)
  end
end

-- Window navigation
function M.navigate(direction)
  if M.state.layout == M.layouts.FOCUSED then
    -- In focused mode, cycle through windows
    M.cycle_focused_window(direction)
  else
    -- Normal vim window navigation
    vim.cmd('wincmd ' .. direction)
  end
end

-- Resize windows
function M.resize_window(window_type, size)
  local window = M.state.windows[window_type]
  if not window or not vim.api.nvim_win_is_valid(window.win) then
    return
  end
  
  if type(size) == "string" then
    -- Relative resize
    if size:match("^[+-]") then
      local delta = tonumber(size)
      local current = vim.api.nvim_win_get_width(window.win)
      vim.api.nvim_win_set_width(window.win, current + delta)
    end
  else
    -- Absolute size
    vim.api.nvim_win_set_width(window.win, size)
  end
end

-- Interactive resize mode
function M.enter_resize_mode()
  M.state.resize_mode = true
  local notify = require('neotex.util.notifications')
  
  notify.himalaya(
    "Resize mode: h/l to resize horizontally, j/k vertically, q to quit",
    notify.categories.STATUS
  )
  
  -- Set up temporary keymaps
  local current_win = vim.api.nvim_get_current_win()
  local resize_keymaps = {
    h = function() vim.cmd('vertical resize -2') end,
    l = function() vim.cmd('vertical resize +2') end,
    j = function() vim.cmd('resize -2') end,
    k = function() vim.cmd('resize +2') end,
    H = function() vim.cmd('vertical resize -10') end,
    L = function() vim.cmd('vertical resize +10') end,
    J = function() vim.cmd('resize -10') end,
    K = function() vim.cmd('resize +10') end,
    q = function() M.exit_resize_mode() end,
    ['<Esc>'] = function() M.exit_resize_mode() end
  }
  
  for key, fn in pairs(resize_keymaps) do
    vim.keymap.set('n', key, fn, { 
      buffer = 0, 
      desc = "Resize window" 
    })
  end
end
```

### 3. Window Persistence
```lua
-- Save window layout
function M.save_layout(name)
  local layout = {
    name = name or "custom",
    windows = {},
    layout_type = M.state.layout
  }
  
  -- Capture window dimensions and positions
  for win_type, window in pairs(M.state.windows) do
    if vim.api.nvim_win_is_valid(window.win) then
      layout.windows[win_type] = {
        width = vim.api.nvim_win_get_width(window.win),
        height = vim.api.nvim_win_get_height(window.win),
        position = vim.api.nvim_win_get_position(window.win)
      }
    end
  end
  
  -- Save to state
  local saved_layouts = state.get('window_layouts', {})
  saved_layouts[name] = layout
  state.set('window_layouts', saved_layouts)
  
  local notify = require('neotex.util.notifications')
  notify.himalaya(
    string.format("Layout '%s' saved", name),
    notify.categories.USER_ACTION,
    {
      layout_name = name,
      layout_type = layout.layout_type
    }
  )
end

-- Load saved layout
function M.load_layout(name)
  local saved_layouts = state.get('window_layouts', {})
  local layout = saved_layouts[name]
  
  if not layout then
    local notify = require('neotex.util.notifications')
    notify.himalaya(
      string.format("Layout '%s' not found", name),
      notify.categories.ERROR,
      {
        requested_layout = name,
        available_layouts = vim.tbl_keys(saved_layouts)
      }
    )
    return
  end
  
  -- Recreate layout
  M.create_layout(layout.layout_type)
  
  -- Restore window dimensions
  for win_type, dimensions in pairs(layout.windows) do
    local window = M.state.windows[win_type]
    if window and vim.api.nvim_win_is_valid(window.win) then
      vim.api.nvim_win_set_width(window.win, dimensions.width)
      vim.api.nvim_win_set_height(window.win, dimensions.height)
    end
  end
end
```

### 4. Window Commands
```lua
-- In core/commands/ui.lua, add:
commands.HimalayaLayout = {
  fn = function(opts)
    local window_manager = require('neotex.plugins.tools.himalaya.ui.window_manager')
    window_manager.create_layout(opts.args)
  end,
  opts = { 
    nargs = '?',
    complete = function()
      return {'classic', 'vertical', 'threepane', 'focused'}
    end,
    desc = 'Change window layout' 
  }
}

commands.HimalayaWindowResize = {
  fn = function()
    local window_manager = require('neotex.plugins.tools.himalaya.ui.window_manager')
    window_manager.enter_resize_mode()
  end,
  opts = { desc = 'Enter window resize mode' }
}

commands.HimalayaWindowSave = {
  fn = function(opts)
    local window_manager = require('neotex.plugins.tools.himalaya.ui.window_manager')
    window_manager.save_layout(opts.args)
  end,
  opts = { 
    nargs = 1,
    desc = 'Save current window layout' 
  }
}

commands.HimalayaWindowLoad = {
  fn = function(opts)
    local window_manager = require('neotex.plugins.tools.himalaya.ui.window_manager')
    window_manager.load_layout(opts.args)
  end,
  opts = { 
    nargs = 1,
    complete = function()
      local saved = state.get('window_layouts', {})
      return vim.tbl_keys(saved)
    end,
    desc = 'Load saved window layout' 
  }
}
```

## Features

### 1. Predefined Layouts
- **Classic**: Email list on left, preview on right (40/60 split)
- **Vertical**: Email list on top, preview below
- **Three-pane**: Folder tree, email list, preview
- **Focused**: Single window maximized with quick switching
- **Custom**: User-defined layouts that can be saved

### 2. Window Coordination
- Automatic preview updates when selecting emails
- Smart focus management based on layout
- Synchronized scrolling options
- Window state preservation during operations

### 3. Interactive Resize Mode
- Enter resize mode with `:HimalayaWindowResize`
- Use h/l for horizontal resizing
- Use j/k for vertical resizing
- Capital letters for larger increments
- Press q or ESC to exit

### 4. Layout Persistence
- Save current layout with `:HimalayaWindowSave <name>`
- Load saved layout with `:HimalayaWindowLoad <name>`
- Automatic preference saving
- Session restoration support

## Implementation Considerations

### Architecture Notes
1. **Reuse Existing Components**:
   - Leverage existing sidebar and main window infrastructure
   - Extend state management for window positions
   - Use existing buffer management from ui modules

2. **Avoid Conflicts**:
   - Ensure compatibility with Multiple Account Views
   - Don't interfere with existing keybindings
   - Maintain backward compatibility

3. **Performance**:
   - Lazy load window content
   - Debounce resize operations
   - Cache window configurations

### Implementation Order (When Ready)
1. **Phase 1**: Basic layouts (classic, vertical)
2. **Phase 2**: Three-pane and focused layouts
3. **Phase 3**: Interactive resize mode
4. **Phase 4**: Layout persistence
5. **Phase 5**: Polish and integration

### Estimated Timeline
- **Development**: 3-5 days
- **Testing**: 1-2 days
- **Documentation**: 1 day
- **Total**: ~1 week

## Success Criteria

1. ✅ All layouts work correctly
2. ✅ Window coordination is seamless
3. ✅ Resize mode is intuitive
4. ✅ Layouts persist across sessions
5. ✅ Performance remains good
6. ✅ No conflicts with existing functionality

## Risk Mitigation

### Window Management Risks
1. **Layout Conflicts**: Validate window state before operations
2. **Performance**: Lazy load content, debounce updates
3. **Compatibility**: Test with various terminal sizes
4. **State Corruption**: Implement proper state validation

## Benefits

1. **Better Organization**: Multiple layouts for different workflows
2. **Improved Efficiency**: Quick window switching and resizing
3. **Personalization**: Save custom layouts
4. **Enhanced UX**: Consistent window behavior
5. **Flexibility**: Adapt to different screen sizes

## Integration Points

### With Existing Systems
1. **Notification System**: Use existing categories (USER_ACTION, STATUS, ERROR)
2. **State Management**: Extend existing state system for window preferences
3. **Command System**: Add to ui commands module
4. **Event System**: Emit events for window changes

### With Multiple Account Views
- Window layouts should work within each account view mode
- Focused view mode would use window management for its single account
- Split/tabbed views might have limited window management options

## Future Enhancement Ideas

1. **Smart Layouts**: Auto-adjust based on terminal size
2. **Quick Switch**: Hotkeys to quickly switch between saved layouts
3. **Window Memory**: Remember window sizes per folder
4. **Zen Mode**: Distraction-free email reading
5. **Mini Preview**: Floating preview window option

## Decision: Skipped for Now

**Rationale**: While this would improve user experience, it's not critical for core email functionality. The current simple layout is sufficient for most use cases.

**When to Revisit**: 
- After Phase 10 completion
- If users request better window management
- When implementing advanced UI features