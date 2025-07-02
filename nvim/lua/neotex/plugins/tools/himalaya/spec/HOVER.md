# Hover Preview Refactor Specification

## Executive Summary

This specification incorporates best practices from leading Neovim plugins:
- **Telescope.nvim**: Buffer reuse patterns and vim buffer previewers
- **Neo-tree.nvim**: Float vs split preview modes, image support
- **hover.nvim**: Different delays for keyboard/mouse, provider system
- **Noice.nvim**: LSP integration patterns, border configuration
- **Trouble.nvim**: Debouncing strategies, performance optimization

Key improvements:
1. Separate delays for keyboard (100ms) vs mouse (1000ms) triggers
2. Buffer pooling for performance (reuse instead of create/destroy)
3. Protected calls with graceful error handling
4. Two-stage loading (headers first, then body)
5. Smart positioning based on available space
6. Extensible provider system for future enhancements

## Problem Analysis

The hover preview feature is experiencing critical issues:

1. **Data Serialization Issue**: Email objects stored in vim buffer variables (`vim.b`) are converted to userdata, making nested fields inaccessible
2. **Performance Problems**: Synchronous CLI calls block the UI during preview loading
3. **Inconsistent Data Handling**: Email data structure varies between JSON objects and parsed text
4. **Poor Error Recovery**: When data extraction fails, the preview crashes rather than degrading gracefully

## Root Cause Analysis

### Data Flow Issues

The current data flow is problematic:
```
Himalaya CLI -> JSON -> Lua Table -> vim.b (userdata conversion) -> Preview Error
```

When complex Lua tables with nested objects are stored in vim buffer variables:
- `email.from = { name = "John", addr = "john@example.com" }` becomes userdata
- Accessing `email.from.name` throws "attempt to index userdata" error
- The issue cascades through the entire preview system

### Performance Bottleneck

The preview calls `utils.get_email_by_id()` which:
1. Executes a synchronous `himalaya message read` command
2. Blocks the UI while waiting for response
3. Parses the full email content even when only headers are needed

## Proposed Solution

### Phase 1: Data Architecture Refactor

#### 1.1 Centralized Email Cache
```lua
-- core/email_cache.lua
local M = {}

-- Cache structure: account -> folder -> email_id -> email_data
local cache = {}

-- Store emails with proper serialization
function M.store_emails(account, folder, emails)
  if not cache[account] then cache[account] = {} end
  if not cache[account][folder] then cache[account][folder] = {} end
  
  for _, email in ipairs(emails) do
    -- Normalize email data during storage
    cache[account][folder][email.id] = M.normalize_email(email)
  end
end

-- Normalize complex fields to simple strings
function M.normalize_email(email)
  local normalized = {
    id = email.id,
    subject = email.subject or "No Subject",
    date = email.date or "Unknown",
    flags = email.flags or {},
  }
  
  -- Handle from field
  if type(email.from) == "table" then
    normalized.from = email.from.name or email.from.addr or "Unknown"
    normalized.from_addr = email.from.addr
  else
    normalized.from = tostring(email.from or "Unknown")
  end
  
  -- Handle to field
  if type(email.to) == "table" then
    normalized.to = email.to.name or email.to.addr or "Unknown"
    normalized.to_addr = email.to.addr
  else
    normalized.to = tostring(email.to or "Unknown")
  end
  
  -- Handle cc field
  if email.cc then
    if type(email.cc) == "table" then
      normalized.cc = email.cc.name or email.cc.addr
    else
      normalized.cc = tostring(email.cc)
    end
  end
  
  return normalized
end

function M.get_email(account, folder, email_id)
  if cache[account] and cache[account][folder] then
    return cache[account][folder][email_id]
  end
  return nil
end

return M
```

#### 1.2 State-Based Storage
Replace all `vim.b[buf].himalaya_emails` with state storage:
```lua
-- In email_list.lua
local email_cache = require('neotex.plugins.tools.himalaya.core.email_cache')

-- When loading emails
local emails = utils.get_email_list(account, folder, page, page_size)
email_cache.store_emails(account, folder, emails)
state.set('email_list.current_emails', emails)
```

### Phase 2: Async Preview Loading

#### 2.1 Two-Stage Preview
```lua
-- ui/email_preview.lua
function M.show_preview(email_id, parent_win)
  -- Stage 1: Show immediate preview with cached data
  local account = state.get_current_account()
  local folder = state.get_current_folder()
  local cached_email = email_cache.get_email(account, folder, email_id)
  
  if cached_email then
    -- Show preview immediately with cached headers
    M.create_preview_window(parent_win)
    M.render_preview({
      from = cached_email.from,
      to = cached_email.to,
      subject = cached_email.subject,
      date = cached_email.date,
      body = "Loading email content..."
    })
  end
  
  -- Stage 2: Load full content asynchronously
  vim.fn.jobstart({
    'himalaya', '-a', account, 
    'message', 'read', email_id,
    '-f', folder,
    '--output', 'json'
  }, {
    on_stdout = function(_, data, _)
      local json_str = table.concat(data, '\n')
      local ok, email = pcall(vim.json.decode, json_str)
      if ok and email then
        -- Update preview with full content
        if M.is_preview_showing(email_id) then
          M.render_preview(email)
        end
        -- Cache the full email
        email_cache.store_email(account, folder, email)
      end
    end,
    on_exit = function(_, exit_code, _)
      if exit_code ~= 0 then
        logger.error('Failed to load email for preview', { id = email_id })
      end
    end
  })
end
```

### Phase 3: Improved Error Handling

#### 3.1 Graceful Degradation with Protected Calls
```lua
-- Wrap all preview operations in protected calls
function M.safe_preview(fn, ...)
  local ok, result = pcall(fn, ...)
  if not ok then
    logger.error('Preview error', { error = result })
    -- Show error in preview if window exists
    if preview_win and vim.api.nvim_win_is_valid(preview_win) then
      local error_lines = {
        "Preview Error",
        string.rep("-", 40),
        "Failed to load email preview.",
        "",
        "Error: " .. tostring(result):match("^[^\n]+"),
        "",
        "Press 'q' to close this window."
      }
      vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, error_lines)
    end
    return nil
  end
  return result
end

function M.render_preview(email)
  local lines = {}
  
  -- Safe field extraction with fallbacks
  local function safe_get(value, default)
    if not value then return default end
    local t = type(value)
    if t == "string" then return value end
    if t == "table" then
      -- Try common patterns
      return value.name or value.addr or value[1] or default
    end
    -- Last resort: string conversion
    local str = tostring(value)
    return (str ~= "userdata" and str) or default
  end
  
  -- Protected render function
  local function do_render()
    if M.config.show_headers then
      table.insert(lines, "From: " .. safe_get(email.from, "Unknown"))
      table.insert(lines, "To: " .. safe_get(email.to, "Unknown"))
      table.insert(lines, "Subject: " .. safe_get(email.subject, "No Subject"))
      table.insert(lines, "Date: " .. safe_get(email.date, "Unknown"))
      table.insert(lines, string.rep("-", M.config.width - 2))
      table.insert(lines, "")
    end
    
    -- Body handling with progressive loading
    if email.body then
      local body_lines = M.process_email_body(email.body)
      vim.list_extend(lines, body_lines)
    elseif email.body_preview then
      -- Use preview if available
      table.insert(lines, email.body_preview)
      table.insert(lines, "")
      table.insert(lines, "[Loading full content...]")
    else
      table.insert(lines, "Loading email content...")
    end
    
    -- Update buffer with validation
    if preview_buf and vim.api.nvim_buf_is_valid(preview_buf) then
      -- Use modifiable pattern for safety
      local modifiable = vim.api.nvim_buf_get_option(preview_buf, 'modifiable')
      vim.api.nvim_buf_set_option(preview_buf, 'modifiable', true)
      vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, lines)
      vim.api.nvim_buf_set_option(preview_buf, 'modifiable', modifiable)
    end
  end
  
  -- Execute with protection
  M.safe_preview(do_render)
end
```

### Phase 4: Performance Optimizations

#### 4.1 Debounced Hover (Based on Industry Best Practices)
```lua
-- Learned from Trouble.nvim and hover.nvim
local hover_queue = {}
local process_timer = nil
local preview_generation = 0  -- Track preview requests

function M.queue_preview(email_id, parent_win)
  -- Cancel pending previews
  hover_queue = { email_id = email_id, parent_win = parent_win }
  preview_generation = preview_generation + 1
  local current_gen = preview_generation
  
  if process_timer then
    vim.loop.timer_stop(process_timer)
  end
  
  -- Use 100ms for keyboard navigation (from Trouble.nvim)
  -- Use 1000ms for mouse hover (from hover.nvim)
  local delay = M.config.trigger == 'mouse' and 1000 or 100
  
  process_timer = vim.loop.new_timer()
  process_timer:start(delay, 0, vim.schedule_wrap(function()
    -- Check if this preview is still relevant
    if current_gen == preview_generation and hover_queue.email_id then
      M.show_preview(hover_queue.email_id, hover_queue.parent_win)
    end
    hover_queue = {}
  end))
end
```

#### 4.2 Preview Caching with Buffer Management
```lua
-- Cache preview content with buffer reuse (from Telescope patterns)
local preview_cache = {}
local preview_buffers = {}  -- Reuse buffers for performance

function M.get_or_create_preview_buffer()
  -- Find an unused buffer or create new one
  for buf, in_use in pairs(preview_buffers) do
    if not in_use and vim.api.nvim_buf_is_valid(buf) then
      preview_buffers[buf] = true
      return buf
    end
  end
  
  -- Create new buffer with proper options
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'hide')  -- Keep in memory
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'undolevels', -1)
  
  preview_buffers[buf] = true
  return buf
end

function M.release_preview_buffer(buf)
  if preview_buffers[buf] then
    preview_buffers[buf] = false
    -- Clear content but keep buffer for reuse
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
  end
end

function M.get_preview_content(email_id)
  local cache_key = email_id .. ':preview'
  if preview_cache[cache_key] then
    local cached = preview_cache[cache_key]
    -- Check if cache is fresh (5 minutes)
    if os.time() - cached.time < 300 then
      return cached.content
    end
  end
  return nil
end

-- Cleanup function for buffer management
function M.cleanup_preview_buffers()
  for buf, _ in pairs(preview_buffers) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
  preview_buffers = {}
  preview_cache = {}
end
```

### Phase 5: Enhanced Features

#### 5.1 Progressive Content Loading
```lua
-- Load email in chunks for better UX
function M.load_email_progressive(email_id)
  -- First: Load headers only
  local headers_cmd = {
    'himalaya', '-a', account,
    'envelope', 'get', email_id,
    '-f', folder, '--output', 'json'
  }
  
  -- Then: Load first 20 lines of body
  local preview_cmd = {
    'himalaya', '-a', account,
    'message', 'read', email_id,
    '-f', folder, '--output', 'plain'
  }
  
  -- Finally: Load full content if still hovering
end
```

#### 5.2 Smart Preview Positioning
```lua
function M.calculate_preview_position(parent_win)
  local win_width = vim.api.nvim_win_get_width(parent_win)
  local win_height = vim.api.nvim_win_get_height(parent_win)
  local cursor_pos = vim.api.nvim_win_get_cursor(parent_win)
  
  -- Smart positioning based on available space
  if win_width > 160 then
    -- Wide screen: show on right
    return {
      relative = 'win',
      win = parent_win,
      width = M.config.width,
      height = win_height - 2,
      row = 0,
      col = win_width + 1,
      style = 'minimal',  -- From best practices
      border = M.config.border or 'single',
      title = ' Email Preview ',
      title_pos = 'center',
      focusable = M.config.focusable or false,
      zindex = 50,  -- Ensure preview is above other windows
    }
  else
    -- Narrow screen: show below cursor
    return {
      relative = 'win',
      win = parent_win,
      width = win_width - 4,
      height = math.min(20, win_height - cursor_pos[1] - 2),
      row = cursor_pos[1] + 1,
      col = 0,
      style = 'minimal',
      border = M.config.border or 'single',
      title = ' Email Preview ',
      title_pos = 'center',
      focusable = M.config.focusable or false,
      zindex = 50,
    }
  end
end
```

## Implementation Timeline

### Week 1: Foundation
- [x] Implement email_cache.lua module ✓
- [x] Convert all email storage to use state/cache ✓
- [x] Add comprehensive email normalization ✓
- [x] Test data serialization fixes ✓

### Week 2: Async Loading
- [ ] Implement async preview loading with jobstart
- [ ] Add two-stage preview rendering
- [ ] Create preview content caching
- [ ] Test performance improvements

### Week 3: Polish
- [ ] Add smart positioning logic
- [ ] Implement progressive content loading
- [ ] Add error recovery and fallbacks
- [ ] Comprehensive testing

## Testing Strategy

### Unit Tests
```lua
-- test/email_cache_spec.lua
describe("Email Cache", function()
  it("normalizes complex email objects", function()
    local email = {
      id = "123",
      from = { name = "John Doe", addr = "john@example.com" },
      to = { addr = "jane@example.com" }
    }
    
    local normalized = email_cache.normalize_email(email)
    assert.equals("John Doe", normalized.from)
    assert.equals("john@example.com", normalized.from_addr)
  end)
  
  it("handles userdata gracefully", function()
    -- Test with mock userdata
  end)
end)
```

### Integration Tests
1. Test hover preview with various email formats
2. Test performance with large email lists
3. Test error scenarios (network failure, invalid data)
4. Test memory usage with cache

## Success Metrics

1. **Zero userdata errors** in preview functionality
2. **< 50ms** preview display time for cached emails
3. **< 200ms** full content load time
4. **Graceful degradation** for all error cases
5. **Memory usage** < 10MB for 1000 cached emails

## Migration Guide

### For Users
- Hover preview will be faster and more reliable
- Preview window positioning adapts to screen size
- Failed previews show partial data instead of errors

### For Developers
- Use `email_cache` module for all email data access
- Never store complex objects in vim.b variables
- Always normalize email data before display
- Use async loading for external data fetches

## Lessons from Other Plugins

### From Telescope.nvim:
- Use vim buffer previewers for better integration with syntax highlighting
- Support both vim buffer and terminal-based previewing
- Implement filetype detection for proper syntax highlighting

### From Neo-tree.nvim:
- Allow toggling between float and split preview modes
- Support image preview with 3rd party integration
- End preview mode when losing focus
- Consider scroll commands (<C-d>, <C-u>) in preview

### From hover.nvim:
- Support multiple hover providers with priority system
- Different delays for keyboard (100ms) vs mouse (1000ms) triggers
- Extensible provider system for different content sources

### From Noice.nvim:
- Override LSP hover handlers for consistent UI
- Support configurable borders and styling
- Use vim.ui_attach for advanced UI features

### From Trouble.nvim:
- Implement throttle/debounce with 100ms default
- Support auto_preview and auto_close options
- Performance-aware preview for large content

## Enhanced Configuration

```lua
-- Incorporating best practices from research
M.config = {
  enabled = true,
  -- Different delays for different triggers
  keyboard_delay = 100,   -- From Trouble.nvim
  mouse_delay = 1000,     -- From hover.nvim  
  -- Window configuration
  width = 80,
  max_height = 30,
  position = 'smart',     -- 'right', 'bottom', or 'smart'
  border = 'single',      -- From LSP best practices
  focusable = false,      -- Can be toggled with double-press
  -- Performance
  max_file_size = 204800, -- 200KB limit for performance
  cache_ttl = 300,        -- 5 minutes
  -- Features
  show_headers = true,
  syntax_highlight = true,
  auto_close = true,
  -- Providers (extensible like hover.nvim)
  providers = {
    'email_content',
    'email_thread',
    'attachments',
  },
}
```

## Future Enhancements

1. **HTML Preview**: Render HTML emails in preview (with pandoc integration)
2. **Attachment Icons**: Show attachment indicators with icon support
3. **Thread Preview**: Show email thread context with tree view
4. **Quick Actions**: Add reply/delete buttons to preview (like Neo-tree)
5. **Custom Templates**: Allow preview customization with user templates
6. **Image Support**: Integrate with image.nvim for inline images
7. **Provider System**: Extensible content providers for different preview types
8. **Scroll Support**: Add <C-d>/<C-u> for scrolling in preview
9. **Focus Toggle**: Double-press to focus preview window
10. **Split Mode**: Option to use preview window instead of float
