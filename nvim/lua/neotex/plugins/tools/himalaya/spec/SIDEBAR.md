# Himalaya Sidebar UI Refactoring Specification

## Overview

This specification outlines the refactoring of the Himalaya email client sidebar to implement:
1. **Color-coded email status indicators**: Light blue for unread emails, light orange for starred emails
2. **Checkbox-based selection system**: Repurpose `[ ]` and `[*]` for multi-email selection
3. **Batch operations**: Execute commands (`gD`, `gA`, `gS`) on multiple selected emails

## Current Implementation Analysis

### Existing Structure
```
lua/neotex/plugins/tools/himalaya/
|-- ui/
|   |-- sidebar.lua          # Neo-tree style sidebar management
|   |-- main.lua             # Email list formatting and buffer management
|   |-- state.lua            # UI state tracking
|   |-- init.lua             # UI module aggregation
|-- core/
|   |-- config.lua           # Buffer keymaps and configuration
|-- utils.lua                # Email utilities
```

### Current Email List Format (from main.lua:316)
```lua
local line = string.format('[%s] %s  %s  %s', status, from, subject, date)
-- Example: "[*] John Doe  Important Meeting  2025-06-30"
-- status: '*' for unread, ' ' for read
```

### Current Keymaps (from config.lua:324-351)
- `g` + `n/p`: Next/previous page
- `g` + `D/A/S`: Delete/Archive/Spam current email (single)
- `<CR>`: Read current email
- `r`: Refresh email list

## Implementation Specification

### 1. Color-Coded Status Indicators

#### 1.1 Highlight Groups Definition
Create new highlight groups in `ui/sidebar.lua`:

```lua
-- Add to M.init() function
function M.setup_highlights()
  -- Unread emails (light blue)
  vim.api.nvim_set_hl(0, 'HimalayaUnread', { fg = '#87CEEB', bold = true })
  
  -- Starred emails (light orange) 
  vim.api.nvim_set_hl(0, 'HimalayaStarred', { fg = '#FFA07A', bold = true })
  
  -- Selected emails (for multi-select)
  vim.api.nvim_set_hl(0, 'HimalayaSelected', { bg = '#444444', fg = '#FFFFFF' })
  
  -- Checkbox indicators
  vim.api.nvim_set_hl(0, 'HimalayaCheckbox', { fg = '#888888' })
  vim.api.nvim_set_hl(0, 'HimalayaCheckboxSelected', { fg = '#00FF00', bold = true })
end
```

#### 1.2 Email Status Detection
Enhance `format_email_list()` in `ui/main.lua` to detect starred status:

```lua
-- Enhanced email parsing (lines 286-297)
local seen = false
local starred = false
if email.flags and type(email.flags) == 'table' then
  for _, flag in ipairs(email.flags) do
    if flag == 'Seen' then
      seen = true
    elseif flag == 'Flagged' or flag == 'Starred' then
      starred = true
    end
  end
end
```

### 2. Selection System Implementation

#### 2.1 Selection State Management
Add to `ui/state.lua`:

```lua
-- Selection state
M.selection = {
  selected_emails = {}, -- Set of email IDs
  selection_mode = false, -- Toggle for selection mode
}

-- Selection functions
function M.toggle_selection_mode()
  M.selection.selection_mode = not M.selection.selection_mode
  return M.selection.selection_mode
end

function M.is_email_selected(email_id)
  return M.selection.selected_emails[email_id] ~= nil
end

function M.toggle_email_selection(email_id, email_data)
  if M.selection.selected_emails[email_id] then
    M.selection.selected_emails[email_id] = nil
  else
    M.selection.selected_emails[email_id] = email_data
  end
end

function M.clear_selection()
  M.selection.selected_emails = {}
end

function M.get_selected_emails()
  local selected = {}
  for id, email in pairs(M.selection.selected_emails) do
    table.insert(selected, email)
  end
  return selected
end

function M.get_selection_count()
  local count = 0
  for _ in pairs(M.selection.selected_emails) do
    count = count + 1
  end
  return count
end
```

#### 2.2 Enhanced Email List Formatting
Modify `format_email_list()` in `ui/main.lua`:

```lua
function M.format_email_list(emails)
  local lines = {}
  local state = require('neotex.plugins.tools.himalaya.ui.state')
  
  -- Header (existing code)...
  
  -- Email entries with selection checkboxes
  for i, email in ipairs(emails) do
    -- Parse flags
    local seen = false
    local starred = false
    if email.flags and type(email.flags) == 'table' then
      for _, flag in ipairs(email.flags) do
        if flag == 'Seen' then seen = true end
        if flag == 'Flagged' or flag == 'Starred' then starred = true end
      end
    end
    
    -- Selection checkbox
    local email_id = email.id or tostring(i)
    local is_selected = state.is_email_selected(email_id)
    local checkbox = is_selected and '[*]' or '[ ]'
    
    -- Status indicator (keep for compatibility)
    local status = seen and ' ' or '*'
    
    -- Parse from/subject/date (existing code)...
    
    local line = string.format('%s [%s] %s  %s  %s', 
      checkbox, status, from, subject, date)
    table.insert(lines, line)
    
    -- Store email metadata for line
    lines[#lines] = {
      text = line,
      email_id = email_id,
      email_data = email,
      line_number = #lines + 5, -- Account for header lines
      seen = seen,
      starred = starred,
      selected = is_selected
    }
  end
  
  return lines
end
```

#### 2.3 Syntax Highlighting
Add to `ui/sidebar.lua` after content update:

```lua
function M.apply_email_highlighting(bufnr)
  -- Clear existing matches
  vim.fn.clearmatches()
  
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i, line in ipairs(lines) do
    -- Skip header lines (first 5 lines)
    if i > 5 and line ~= '' and not line:match('^─') then
      -- Check for unread emails (contains [*] status)
      if line:match('%[[ ]%] %[%*%]') then
        vim.fn.matchaddpos('HimalayaUnread', {{i}})
      end
      
      -- Check for starred emails (would need flag detection)
      -- This requires parsing the stored email data
      
      -- Highlight selection checkboxes
      if line:match('^%[%*%]') then
        vim.fn.matchaddpos('HimalayaCheckboxSelected', {{i, 1, 3}})
      else
        vim.fn.matchaddpos('HimalayaCheckbox', {{i, 1, 3}})
      end
    end
  end
end
```

### 3. Enhanced Keymap System

#### 3.1 Selection Mode Keymaps
Add to `core/config.lua` in `setup_buffer_keymaps()`:

```lua
-- Selection mode keymaps for himalaya-list
if vim.bo[bufnr].filetype == 'himalaya-list' then
  -- Existing keymaps...
  
  -- Toggle selection mode
  keymap('n', 'v', function()
    local state = require('neotex.plugins.tools.himalaya.ui.state')
    local main = require('neotex.plugins.tools.himalaya.ui.main')
    local mode = state.toggle_selection_mode()
    if mode then
      vim.notify('Selection mode: ON (Space to select, v to exit)')
    else
      state.clear_selection()
      vim.notify('Selection mode: OFF')
    end
    main.refresh_email_list()
  end, vim.tbl_extend('force', opts, { desc = 'Toggle selection mode' }))
  
  -- Toggle email selection (Space)
  keymap('n', '<Space>', function()
    local state = require('neotex.plugins.tools.himalaya.ui.state')
    local main = require('neotex.plugins.tools.himalaya.ui.main')
    
    if not state.selection.selection_mode then
      return -- Only work in selection mode
    end
    
    local line = vim.api.nvim_get_current_line()
    local line_num = vim.api.nvim_win_get_cursor(0)[1]
    
    -- Parse email ID from line (requires stored metadata)
    local email_data = vim.b.himalaya_emails
    if email_data and line_num > 5 then -- Skip header
      local email_idx = line_num - 5
      local email = email_data[email_idx]
      if email then
        state.toggle_email_selection(email.id or tostring(email_idx), email)
        main.refresh_email_list()
        
        local count = state.get_selection_count()
        vim.notify(string.format('Selected: %d emails', count))
      end
    end
  end, vim.tbl_extend('force', opts, { desc = 'Toggle email selection' }))
  
  -- Enhanced g-commands for batch operations
  keymap('n', 'g', function()
    local state = require('neotex.plugins.tools.himalaya.ui.state')
    local char = vim.fn.getchar()
    local key = vim.fn.nr2char(char)
    
    -- Check if we have selections for batch operations
    local selected_count = state.get_selection_count()
    local has_selection = selected_count > 0
    
    if key == 'D' then
      if has_selection then
        require('neotex.plugins.tools.himalaya.ui.main').delete_selected_emails()
      else
        require('neotex.plugins.tools.himalaya.ui.main').delete_current_email()
      end
    elseif key == 'A' then
      if has_selection then
        require('neotex.plugins.tools.himalaya.ui.main').archive_selected_emails()
      else
        require('neotex.plugins.tools.himalaya.ui.main').archive_current_email()
      end
    elseif key == 'S' then
      if has_selection then
        require('neotex.plugins.tools.himalaya.ui.main').spam_selected_emails()
      else
        require('neotex.plugins.tools.himalaya.ui.main').spam_current_email()
      end
    -- ... existing g-commands
    else
      vim.api.nvim_feedkeys('g' .. key, 'n', false)
    end
  end, vim.tbl_extend('force', opts, { desc = 'Enhanced g-commands' }))
end
```

### 4. Batch Operations Implementation

#### 4.1 Batch Operation Functions
Add to `ui/main.lua`:

```lua
-- Batch delete operation
function M.delete_selected_emails()
  local state = require('neotex.plugins.tools.himalaya.ui.state')
  local selected = state.get_selected_emails()
  
  if #selected == 0 then
    notifications.show('No emails selected', 'warn')
    return
  end
  
  -- Confirm batch operation
  vim.ui.input({
    prompt = string.format('Delete %d selected emails? (y/n): ', #selected)
  }, function(input)
    if input and input:lower() == 'y' then
      local success_count = 0
      local error_count = 0
      
      for _, email in ipairs(selected) do
        local success = delete_single_email(email)
        if success then
          success_count = success_count + 1
        else
          error_count = error_count + 1
        end
      end
      
      state.clear_selection()
      state.toggle_selection_mode() -- Exit selection mode
      
      notifications.show(
        string.format('Deleted %d emails (%d errors)', success_count, error_count),
        error_count > 0 and 'warn' or 'success'
      )
      
      M.refresh_email_list()
    end
  end)
end

-- Batch archive operation
function M.archive_selected_emails()
  local state = require('neotex.plugins.tools.himalaya.ui.state')
  local selected = state.get_selected_emails()
  
  if #selected == 0 then
    notifications.show('No emails selected', 'warn')
    return
  end
  
  vim.ui.input({
    prompt = string.format('Archive %d selected emails? (y/n): ', #selected)
  }, function(input)
    if input and input:lower() == 'y' then
      local success_count = 0
      local error_count = 0
      
      for _, email in ipairs(selected) do
        local success = archive_single_email(email)
        if success then
          success_count = success_count + 1
        else
          error_count = error_count + 1
        end
      end
      
      state.clear_selection()
      state.toggle_selection_mode()
      
      notifications.show(
        string.format('Archived %d emails (%d errors)', success_count, error_count),
        error_count > 0 and 'warn' or 'success'
      )
      
      M.refresh_email_list()
    end
  end)
end

-- Batch spam operation
function M.spam_selected_emails()
  local state = require('neotex.plugins.tools.himalaya.ui.state')
  local selected = state.get_selected_emails()
  
  if #selected == 0 then
    notifications.show('No emails selected', 'warn')
    return
  end
  
  vim.ui.input({
    prompt = string.format('Mark %d selected emails as spam? (y/n): ', #selected)
  }, function(input)
    if input and input:lower() == 'y' then
      local success_count = 0
      local error_count = 0
      
      for _, email in ipairs(selected) do
        local success = spam_single_email(email)
        if success then
          success_count = success_count + 1
        else
          error_count = error_count + 1
        end
      end
      
      state.clear_selection()
      state.toggle_selection_mode()
      
      notifications.show(
        string.format('Marked %d emails as spam (%d errors)', success_count, error_count),
        error_count > 0 and 'warn' or 'success'
      )
      
      M.refresh_email_list()
    end
  end)
end

-- Helper functions for single email operations
function delete_single_email(email)
  -- Implement himalaya CLI call for single email deletion
  local cmd = string.format('himalaya email delete %s', email.id)
  local result = vim.fn.system(cmd)
  return vim.v.shell_error == 0
end

function archive_single_email(email)
  -- Implement himalaya CLI call for single email archiving
  local cmd = string.format('himalaya email move %s "[Gmail]/All Mail"', email.id)
  local result = vim.fn.system(cmd)
  return vim.v.shell_error == 0
end

function spam_single_email(email)
  -- Implement himalaya CLI call for single email spam marking
  local cmd = string.format('himalaya email move %s "[Gmail]/Spam"', email.id)
  local result = vim.fn.system(cmd)
  return vim.v.shell_error == 0
end
```

### 5. Visual Feedback and UX

#### 5.1 Status Line Integration
Add selection status to sidebar header in `format_email_list()`:

```lua
-- Enhanced header with selection info
local header = string.format('Himalaya - %s - %s', email_display, state.get_current_folder())
local pagination_info = string.format('Page %d | %d emails', 
  state.get_current_page(), state.get_total_emails())

-- Add selection status if in selection mode
local selection_info = ''
if state.selection.selection_mode then
  local count = state.get_selection_count()
  selection_info = string.format('Selection: %d selected (v to exit)', count)
end

table.insert(lines, header)
table.insert(lines, pagination_info)
if selection_info ~= '' then
  table.insert(lines, selection_info)
end
```

#### 5.2 Visual Selection Indicators
Update the checkbox rendering to be more visually distinct:

```lua
-- Enhanced checkbox rendering
local checkbox
if state.selection.selection_mode then
  checkbox = is_selected and '[x]' or '[ ]'  -- Clear visual difference
else
  checkbox = ''  -- No checkbox when not in selection mode
end
```

## Integration Strategy

### Phase 1: Highlight Groups and Basic Color Coding ✅ COMPLETED
1. ✅ Add highlight group definitions to `ui/sidebar.lua`
2. ✅ Implement unread/starred detection in email parsing
3. ✅ Apply syntax highlighting for unread emails (light blue) and starred emails (light orange)

**Changes made:**
- Added `M.setup_highlights()` function in `ui/sidebar.lua` with all highlight groups
- Enhanced email flag parsing in `ui/main.lua` to detect both seen and starred flags
- Modified `M.update_content()` to handle metadata and apply highlighting
- Added `M.apply_email_highlighting()` function to apply highlights based on email status

**Test results:**
- All highlight groups created successfully
- Email metadata correctly identifies unread, read, and starred emails
- Visual highlighting ready for testing with real email data

### Phase 2: Selection State Management
1. Extend `ui/state.lua` with selection functionality
2. Implement selection mode toggle (keymap `v`)
3. Add basic checkbox rendering to email list format

### Phase 3: Selection Interaction
1. Implement space-bar selection toggle
2. Add visual feedback for selection mode
3. Update sidebar header with selection count

### Phase 4: Batch Operations
1. Implement batch delete, archive, and spam functions
2. Enhance g-command handler for batch vs. single operations
3. Add confirmation dialogs for batch operations

### Phase 5: Polish and Error Handling
1. Add error handling for failed batch operations
2. Implement undo functionality where possible
3. Add comprehensive help text for new features

## Backward Compatibility

The implementation maintains full backward compatibility:
- Existing keymaps continue to work unchanged
- Single-email operations remain the default behavior
- Selection mode is opt-in via the `v` key
- No breaking changes to existing functionality

## File Changes Summary

1. **`ui/sidebar.lua`**: Add highlight groups setup
2. **`ui/state.lua`**: Add selection state management  
3. **`ui/main.lua`**: Enhance email list formatting, add batch operations
4. **`core/config.lua`**: Add selection mode keymaps, enhance g-commands
5. **No new files required** - all changes integrate with existing modules

## Testing Strategy

1. **Unit Tests**: Test selection state management functions
2. **Integration Tests**: Test batch operations with mock email data
3. **Visual Tests**: Verify highlight groups render correctly
4. **Compatibility Tests**: Ensure existing workflows remain unchanged
5. **Error Handling Tests**: Test batch operation failure scenarios

This specification provides a complete roadmap for implementing the requested UI refactoring while maintaining the existing codebase structure and ensuring a smooth user experience.
