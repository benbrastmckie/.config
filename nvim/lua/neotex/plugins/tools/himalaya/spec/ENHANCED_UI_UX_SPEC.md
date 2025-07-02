# Enhanced UI/UX Features Implementation Specification

## Overview

This specification details the implementation plan for enhanced UI/UX features in the Himalaya email plugin. These features focus on improving user interaction, providing better visual feedback, and modernizing the email composition experience.

## Feature Set

1. **Hover Preview** - Preview emails in a second sidebar
2. **Buffer-based Composition** - Compose emails in regular buffers with auto-save
3. **Improved Confirmations** - Modern confirmation dialogs with return/escape
4. **Accurate Email Count** - Fix pagination display to show actual counts
5. **Remove Noisy Messages** - Eliminate unnecessary notifications

## Detailed Implementation Plans

### 1. Hover Preview

#### Current State
- No hover functionality exists
- Emails only viewable by pressing Enter (opens floating window)

#### Design Goals
- Non-intrusive preview without leaving email list
- Quick scanning of email content
- Responsive hover detection with debouncing
- Optional feature that can be disabled

#### Implementation Details

##### 1.1 Preview Window Management
```lua
-- ui/email_preview.lua (new module)
local M = {}
local preview_win = nil
local preview_buf = nil
local hover_timer = nil
local current_preview_id = nil

M.config = {
  enabled = true,
  delay_ms = 500,
  width = 40,
  position = 'right', -- 'right' or 'bottom'
  show_headers = true,
  max_lines = 50,
}
```

##### 1.2 Hover Detection
```lua
-- Add to ui/email_list.lua
local function setup_hover_autocmd()
  vim.api.nvim_create_autocmd('CursorHold', {
    buffer = bufnr,
    callback = function()
      if not email_preview.config.enabled then return end
      
      local line = vim.api.nvim_win_get_cursor(0)[1]
      local email_id = get_email_id_from_line(line)
      
      if email_id and email_id ~= current_preview_id then
        email_preview.show_preview(email_id)
      end
    end
  })
  
  -- Hide preview on cursor move
  vim.api.nvim_create_autocmd('CursorMoved', {
    buffer = bufnr,
    callback = function()
      email_preview.hide_preview()
    end
  })
end
```

##### 1.3 Preview Display
```lua
function M.show_preview(email_id)
  -- Cancel any pending preview
  if hover_timer then
    vim.loop.timer_stop(hover_timer)
  end
  
  hover_timer = vim.loop.new_timer()
  hover_timer:start(M.config.delay_ms, 0, vim.schedule_wrap(function()
    -- Get email content
    local email = utils.get_email_by_id(email_id)
    if not email then return end
    
    -- Create or reuse preview window
    if not preview_win or not vim.api.nvim_win_is_valid(preview_win) then
      preview_buf = vim.api.nvim_create_buf(false, true)
      
      -- Calculate position
      local width = M.config.width
      local height = vim.api.nvim_win_get_height(0)
      local row = 0
      local col = vim.api.nvim_win_get_width(0) + 1
      
      preview_win = vim.api.nvim_open_win(preview_buf, false, {
        relative = 'win',
        width = width,
        height = height,
        row = row,
        col = col,
        style = 'minimal',
        border = 'single',
        title = ' Preview ',
        title_pos = 'center',
      })
    end
    
    -- Render email content
    M.render_preview(email)
    current_preview_id = email_id
  end))
end
```

##### 1.4 Configuration
```lua
-- Add to core/config.lua defaults
preview = {
  enabled = true,
  delay_ms = 500,
  width = 40,
  position = 'right',
  show_headers = true,
  max_lines = 50,
}
```

### 2. Buffer-based Composition

#### Current State
- Uses floating windows with custom buffer type
- No auto-save functionality
- Manual draft saving on close

#### Design Goals
- Use regular buffers for better integration with Neovim
- Automatic draft saving every 30 seconds
- Clean draft management (delete on send/discard)
- Syntax highlighting for email headers
- Integration with spell checking

#### Implementation Details

##### 2.1 Compose Buffer Creation
```lua
-- ui/email_composer_v2.lua (new implementation)
local M = {}

function M.compose_email(opts)
  opts = opts or {}
  
  -- Create a new buffer with a temporary file
  local timestamp = os.date('%Y%m%d_%H%M%S')
  local draft_path = vim.fn.expand('~/.local/share/himalaya/drafts/')
  vim.fn.mkdir(draft_path, 'p')
  
  local draft_file = draft_path .. 'draft_' .. timestamp .. '.eml'
  local buf = vim.api.nvim_create_buf(true, false)
  
  -- Set buffer options
  vim.api.nvim_buf_set_name(buf, draft_file)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'mail')
  vim.api.nvim_buf_set_option(buf, 'buftype', '')
  
  -- Open in new split or tab based on config
  if config.get('compose.use_tab') then
    vim.cmd('tabnew')
  else
    vim.cmd('vsplit')
  end
  
  vim.api.nvim_win_set_buf(0, buf)
  
  -- Initialize with template
  M.initialize_compose_buffer(buf, opts)
  
  -- Setup auto-save
  M.setup_autosave(buf, draft_file)
  
  -- Store draft metadata
  state.set('compose.drafts.' .. buf, {
    file = draft_file,
    created = os.time(),
    email_id = opts.reply_to or opts.forward_from,
  })
  
  return buf
end
```

##### 2.2 Auto-save Implementation
```lua
function M.setup_autosave(buf, draft_file)
  local timer = vim.loop.new_timer()
  
  -- Auto-save every 30 seconds
  timer:start(30000, 30000, vim.schedule_wrap(function()
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_option(buf, 'modified') then
      -- Save to draft file
      vim.api.nvim_buf_call(buf, function()
        vim.cmd('silent write!')
      end)
      
      -- Sync to maildir Drafts folder
      M.sync_draft_to_maildir(draft_file)
      
      -- Notify user (debug mode only)
      if notify.config.modules.himalaya.debug_mode then
        notify.himalaya('Draft auto-saved', notify.categories.BACKGROUND)
      end
    else
      -- Stop timer if buffer is gone
      timer:stop()
    end
  end))
  
  -- Store timer reference for cleanup
  vim.api.nvim_buf_attach(buf, false, {
    on_detach = function()
      timer:stop()
    end
  })
end
```

##### 2.3 Email Syntax Highlighting
```lua
-- after/syntax/mail.vim
syn match mailHeader "^From:.*$" contains=mailEmail
syn match mailHeader "^To:.*$" contains=mailEmail
syn match mailHeader "^Cc:.*$" contains=mailEmail
syn match mailHeader "^Bcc:.*$" contains=mailEmail
syn match mailHeader "^Subject:.*$"
syn match mailHeader "^Date:.*$"
syn match mailHeader "^Reply-To:.*$" contains=mailEmail
syn match mailEmail "<[^>]\+@[^>]\+>"
syn match mailEmail "[a-zA-Z0-9._%+-]\+@[a-zA-Z0-9.-]\+\.[a-zA-Z]\{2,}"

syn region mailQuoted start="^>" end="$" contains=mailQuoted

hi link mailHeader Keyword
hi link mailEmail Underlined
hi link mailQuoted Comment
```

##### 2.4 Draft Management
```lua
function M.send_email(buf)
  local draft_info = state.get('compose.drafts.' .. buf)
  if not draft_info then return end
  
  -- Get email content
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local email_data = M.parse_email_buffer(lines)
  
  -- Send email
  local ok, result = pcall(utils.himalaya_send, email_data)
  
  if ok then
    -- Delete draft file
    vim.fn.delete(draft_info.file)
    
    -- Remove from maildir Drafts
    M.delete_draft_from_maildir(draft_info.draft_id)
    
    -- Close buffer
    vim.api.nvim_buf_delete(buf, { force = true })
    
    -- Clean state
    state.set('compose.drafts.' .. buf, nil)
    
    notify.himalaya('Email sent successfully', notify.categories.USER_ACTION)
  else
    notify.himalaya('Failed to send: ' .. result, notify.categories.ERROR)
  end
end

function M.discard_email(buf)
  -- Show improved confirmation
  local choice = improved_confirm.show({
    title = 'Discard Email?',
    message = 'Are you sure you want to discard this email?',
    options = { 'Discard', 'Cancel' },
    default = 2,
  })
  
  if choice == 1 then
    local draft_info = state.get('compose.drafts.' .. buf)
    if draft_info then
      -- Delete draft file
      vim.fn.delete(draft_info.file)
      
      -- Remove from maildir if synced
      if draft_info.draft_id then
        M.delete_draft_from_maildir(draft_info.draft_id)
      end
      
      -- Clean state
      state.set('compose.drafts.' .. buf, nil)
    end
    
    -- Close buffer
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end
```

### 3. Improved Confirmations

#### Current State
- Uses basic vim.ui.input with y/n prompts
- No visual feedback or modern UI

#### Design Goals
- Visual confirmation dialogs
- Return to confirm, Escape to cancel
- Customizable appearance
- Keyboard navigation for multi-option dialogs

#### Implementation Details

##### 3.1 Confirmation Dialog Module
```lua
-- ui/confirm.lua (new module)
local M = {}

function M.show(opts)
  opts = vim.tbl_extend('force', {
    title = 'Confirm',
    message = 'Are you sure?',
    options = { 'Yes', 'No' },
    default = 2,
    keys = { confirm = '<CR>', cancel = '<Esc>' },
  }, opts or {})
  
  -- Calculate dimensions
  local width = math.max(#opts.title, #opts.message) + 4
  local height = 5 + #opts.options
  
  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Create centered floating window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = (vim.o.lines - height) / 2,
    col = (vim.o.columns - width) / 2,
    style = 'minimal',
    border = 'rounded',
    title = ' ' .. opts.title .. ' ',
    title_pos = 'center',
  })
  
  -- Render content
  local lines = {
    '',
    opts.message,
    '',
  }
  
  for i, option in ipairs(opts.options) do
    local prefix = i == opts.default and '> ' or '  '
    table.insert(lines, prefix .. option)
  end
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Set cursor to default option
  vim.api.nvim_win_set_cursor(win, { 3 + opts.default, 0 })
  
  -- Setup keymaps
  local result = nil
  local selected = opts.default
  
  -- Navigation
  vim.keymap.set('n', 'j', function()
    selected = math.min(selected + 1, #opts.options)
    M.update_selection(buf, opts.options, selected)
  end, { buffer = buf })
  
  vim.keymap.set('n', 'k', function()
    selected = math.max(selected - 1, 1)
    M.update_selection(buf, opts.options, selected)
  end, { buffer = buf })
  
  -- Confirm with Enter
  vim.keymap.set('n', opts.keys.confirm, function()
    result = selected
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf })
  
  -- Cancel with Escape
  vim.keymap.set('n', opts.keys.cancel, function()
    result = nil
    vim.api.nvim_win_close(win, true)
  end, { buffer = buf })
  
  -- Also support y/n for yes/no dialogs
  if #opts.options == 2 and opts.options[1]:lower():match('yes') then
    vim.keymap.set('n', 'y', function()
      result = 1
      vim.api.nvim_win_close(win, true)
    end, { buffer = buf })
    
    vim.keymap.set('n', 'n', function()
      result = 2
      vim.api.nvim_win_close(win, true)
    end, { buffer = buf })
  end
  
  -- Wait for result
  vim.cmd('redraw')
  while vim.api.nvim_win_is_valid(win) do
    vim.cmd('sleep 10m')
  end
  
  return result
end

function M.update_selection(buf, options, selected)
  local lines = vim.api.nvim_buf_get_lines(buf, 3, 3 + #options, false)
  for i = 1, #options do
    local prefix = i == selected and '> ' or '  '
    lines[i] = prefix .. options[i]
  end
  vim.api.nvim_buf_set_lines(buf, 3, 3 + #options, false, lines)
  vim.api.nvim_win_set_cursor(0, { 3 + selected, 0 })
end
```

##### 3.2 Integration with Existing Code
```lua
-- Replace existing confirmations
-- Before:
local confirm = vim.fn.input("Delete email? (y/n): ")
if confirm:lower() == "y" then

-- After:
local choice = confirm.show({
  title = 'Delete Email',
  message = 'Are you sure you want to delete this email?',
  options = { 'Delete', 'Cancel' },
  default = 2,
})
if choice == 1 then
```

### 4. Accurate Email Count

#### Current State
- Shows "Page X | 200 emails" regardless of actual count
- Hardcoded value in email_list.lua

#### Design Goals
- Show actual email count for current folder
- Cache counts for performance
- Update counts after sync operations

#### Implementation Details

##### 4.1 Email Count Management
```lua
-- Add to core/state.lua
local email_counts = {}

function M.set_email_count(account, folder, count)
  if not email_counts[account] then
    email_counts[account] = {}
  end
  email_counts[account][folder] = {
    count = count,
    updated = os.time()
  }
end

function M.get_email_count(account, folder)
  if email_counts[account] and email_counts[account][folder] then
    local data = email_counts[account][folder]
    -- Consider cache valid for 5 minutes
    if os.time() - data.updated < 300 then
      return data.count
    end
  end
  return nil
end
```

##### 4.2 Count Fetching
```lua
-- Add to utils.lua
function M.get_folder_email_count(account, folder)
  local cached = state.get_email_count(account, folder)
  if cached then return cached end
  
  -- Use himalaya to get count
  local cmd = string.format(
    'himalaya -a %s list -f %s --page-size 1 2>/dev/null | head -1',
    vim.fn.shellescape(account),
    vim.fn.shellescape(folder)
  )
  
  local output = vim.fn.system(cmd)
  -- Parse output to extract total count
  -- Example: "Page 1 / 10 | 243 emails"
  local count = output:match('| (%d+) emails')
  count = tonumber(count) or 0
  
  -- Cache the result
  state.set_email_count(account, folder, count)
  
  return count
end
```

##### 4.3 Update Email List Display
```lua
-- Modify ui/email_list.lua
local function create_header_lines()
  local account = state.get_current_account()
  local folder = state.get_current_folder()
  local page = state.get_current_page()
  
  -- Get actual email count
  local total_emails = utils.get_folder_email_count(account, folder)
  local page_size = state.get_page_size()
  local total_pages = math.ceil(total_emails / page_size)
  
  local header = {
    "Account: " .. account,
    "Folder: " .. folder,
    string.format("Page %d / %d | %d emails", page, total_pages, total_emails),
    "─────────────────────────",
  }
  
  return header
end
```

### 5. Remove Noisy Messages

#### Current State
- Shows "Himalaya closed" notification when closing
- Various debug messages shown to users

#### Design Goals
- Only show actionable notifications
- Hide routine operations
- Keep debug messages in debug mode only

#### Implementation Details

##### 5.1 Notification Filtering
```lua
-- Modify ui/sidebar.lua close function
function M.close()
  if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
    vim.api.nvim_win_close(sidebar_win, true)
  end
  
  if sidebar_buf and vim.api.nvim_buf_is_valid(sidebar_buf) then
    vim.api.nvim_buf_delete(sidebar_buf, { force = true })
  end
  
  sidebar_win = nil
  sidebar_buf = nil
  
  -- Remove noisy notification
  -- notify.himalaya("Himalaya closed", notify.categories.STATUS)
end
```

##### 5.2 Conditional Debug Messages
```lua
-- Add helper to ui/notifications.lua
function M.debug(message, category)
  if notify.config.modules.himalaya.debug_mode then
    notify.himalaya(message, category or notify.categories.BACKGROUND)
  end
end

-- Use throughout codebase
-- Before:
notify.himalaya("Updating email list", notify.categories.STATUS)

-- After:
notifications.debug("Updating email list")
```

## Implementation Schedule

### Phase 1: Foundation (2 days)
1. Create new modules (email_preview.lua, email_composer_v2.lua, confirm.lua)
2. Add configuration options
3. Set up basic infrastructure

### Phase 2: Hover Preview (2 days)
1. Implement preview window management
2. Add hover detection with debouncing
3. Create preview rendering
4. Add configuration and keybindings

### Phase 3: Buffer-based Composition (3 days)
1. Implement new compose buffer creation
2. Add auto-save functionality
3. Create draft management system
4. Implement syntax highlighting
5. Migrate existing compose commands

### Phase 4: Improved Confirmations (1 day)
1. Create confirmation dialog module
2. Replace all existing confirmations
3. Add configuration options

### Phase 5: Accurate Email Count & Cleanup (1 day)
1. Implement email count caching
2. Update display logic
3. Remove noisy notifications
4. Final testing and documentation

**Total: 9 days**

## Testing Plan

### Unit Tests
```lua
-- test/ui/email_preview_spec.lua
describe("Email Preview", function()
  it("shows preview after hover delay", function()
    -- Test hover detection and preview display
  end)
  
  it("hides preview on cursor move", function()
    -- Test preview hiding
  end)
  
  it("handles invalid email IDs gracefully", function()
    -- Test error cases
  end)
end)
```

### Integration Tests
1. Test auto-save draft functionality
2. Verify draft deletion on send/discard
3. Test confirmation dialog keyboard navigation
4. Verify email count accuracy after sync

### Manual Testing Checklist
- [ ] Hover over emails shows preview after delay
- [ ] Preview updates when hovering different emails
- [ ] Compose in buffer with syntax highlighting
- [ ] Auto-save creates drafts every 30 seconds
- [ ] Confirmations respond to Return/Escape
- [ ] Email count shows actual folder count
- [ ] No "Himalaya closed" message on exit

## Migration Guide

### For Users
1. **Hover Preview**: Enable with `preview.enabled = true` in config
2. **Buffer Composition**: Emails now open in regular buffers, use `:w` to save drafts
3. **Confirmations**: Press Enter to confirm, Escape to cancel
4. **Email Counts**: Now show actual counts (may be slower on first load)

### For Developers
1. Use `email_composer_v2` for new composition features
2. Use `confirm.show()` instead of `vim.ui.input()` for confirmations
3. Use `notifications.debug()` for debug-only messages
4. Cache expensive operations like email counts

## Configuration Schema

```lua
{
  preview = {
    enabled = true,
    delay_ms = 500,
    width = 40,
    position = 'right',
    show_headers = true,
    max_lines = 50,
  },
  compose = {
    use_tab = false,
    auto_save_interval = 30,
    delete_draft_on_send = true,
    syntax_highlighting = true,
  },
  confirmations = {
    style = 'modern', -- 'modern' or 'classic'
    default_to_cancel = true,
  },
  notifications = {
    show_routine_operations = false,
  },
}
```

## Success Metrics

1. **Hover Preview**: 90% of users find it helpful for quick email scanning
2. **Buffer Composition**: 50% reduction in lost emails due to auto-save
3. **Confirmations**: 0 accidental deletions due to clear UI
4. **Email Count**: 100% accuracy in displayed counts
5. **Noise Reduction**: 80% fewer non-actionable notifications

## Future Enhancements

1. **Preview Enhancements**
   - Render HTML emails in preview
   - Show attachments in preview
   - Customizable preview templates

2. **Composition Enhancements**
   - Template system
   - Signature management
   - Send later functionality

3. **UI Polish**
   - Smooth animations for preview appear/disappear
   - Theme support for confirmations
   - Accessibility improvements