-- Himalaya Email Client UI
-- Buffer and window management for email interface

local M = {}

local config = require('neotex.plugins.tools.himalaya.core.config')
local utils = require('neotex.plugins.tools.himalaya.utils')
local window_stack = require('neotex.plugins.tools.himalaya.ui.window_stack')
local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
local state = require('neotex.plugins.tools.himalaya.ui.state')
local notifications = require('neotex.plugins.tools.himalaya.ui.notifications')

-- Buffer tracking
M.buffers = {
  email_list = nil,
  email_read = nil,
  email_compose = nil,
}

-- Initialize UI components
function M.init()
  -- Initialize state management first
  state.init()
  
  -- Initialize sidebar with state
  sidebar.init()
  
  -- Sync state with sidebar configuration (non-intrusive)
  state.sync_with_sidebar()
  
  -- Note: Session restoration is now manual only
  -- Call M.restore_session() explicitly if needed
end

-- Toggle email sidebar
function M.toggle_email_sidebar()
  -- Check if we have an email list buffer open
  local email_list_buf = M.buffers.email_list
  if email_list_buf and vim.api.nvim_buf_is_valid(email_list_buf) then
    -- Find the window showing this buffer
    local win_found = false
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == email_list_buf then
        -- Close this window
        vim.api.nvim_win_close(win, true)
        win_found = true
        break
      end
    end
    
    if win_found then
      -- Clean up
      M.buffers.email_list = nil
      sidebar.state.is_open = false
      sidebar.state.win = nil
      sidebar.state.buf = nil
      notifications.show('Himalaya closed', 'info')
      return
    end
  end
  
  -- If we get here, sidebar is not open, so open it
  M.show_email_list({})
end

function M.show_email_list(args)
  args = args or {}
  
  -- Ensure UI is initialized
  if not state.is_initialized() then
    M.init()
  end
  
  -- Check if config is properly initialized
  if not config.is_initialized() then
    notifications.show('Himalaya not configured. Run :HimalayaSetup to begin.', 'error')
    return
  end
  
  -- Check if maildir exists and set up if needed
  -- For now, we'll skip this check since the wizard module doesn't have ensure_maildir_exists
  -- TODO: Implement maildir check in wizard module or create a separate maildir module
  
  -- Parse arguments
  local folder = args[1] or state.get_current_folder() or 'INBOX'
  local account = nil
  for i, arg in ipairs(args) do
    if arg:match('^--account=') then
      account = arg:gsub('^--account=', '')
    end
  end
  
  -- Switch account if specified
  if account then
    if not config.switch_account(account) then
      notifications.show('Unknown account: ' .. account, 'error')
      return
    end
  elseif account and account ~= config.get_current_account_name() then
    M.reset_pagination()  -- Reset pagination when changing accounts
  end
  
  -- Switch folder if different (only reset pagination if actually changing folders)
  if folder ~= state.get_current_folder() then
    state.set_current_folder(folder)  -- Set folder directly without resetting page
    M.reset_pagination()  -- Reset pagination when changing folders
  end
  
  -- Update state
  state.set_current_account(config.get_current_account_name())
  state.set_current_folder(folder)
  
  -- Open sidebar immediately with loading message
  local win = sidebar.open()
  local buf = sidebar.get_buf()
  M.buffers.email_list = buf
  
  -- Show loading content immediately for responsiveness
  local account_name = config.get_current_account_name()
  -- Capitalize common account names for display
  local display_name = account_name
  if display_name == 'gmail' then
    display_name = 'Gmail'
  end
  local loading_lines = {
    string.format('󰊫 %s (%s)', display_name, folder),
    '',
    '󰔟 Loading emails...',
    '',
    'Please wait while emails are being fetched from Himalaya.'
  }
  sidebar.update_content(loading_lines)
  
  -- Load emails asynchronously to avoid blocking UI
  vim.defer_fn(function()
    local account_name = config.get_current_account_name()
    local emails, total_count = utils.get_email_list(account_name, folder, state.get_current_page(), state.get_page_size())
    if not emails or (type(emails) == "table" and #emails == 0 and (total_count == 0 or total_count == nil)) then
      -- Check if this is a fresh/empty maildir
      local account = config.get_current_account()
      if account then
        local maildir = vim.fn.expand(account.maildir_path)
        if vim.fn.isdirectory(maildir) == 1 then
          -- Check if INBOX has any emails
          local inbox_cur = maildir .. '/INBOX/cur'
          local inbox_new = maildir .. '/INBOX/new'
          local has_emails = false
          
          if vim.fn.isdirectory(inbox_cur) == 1 then
            local cur_files = vim.fn.readdir(inbox_cur)
            if #cur_files > 0 then has_emails = true end
          end
          
          if not has_emails and vim.fn.isdirectory(inbox_new) == 1 then
            local new_files = vim.fn.readdir(inbox_new)
            if #new_files > 0 then has_emails = true end
          end
          
          if not has_emails then
            -- Fresh maildir with no emails
            local empty_lines = {
              string.format('󰊫 %s (%s)', display_name, folder),
              '',
              '󰇯 Maildir is empty',
              '',
              'Run :HimalayaSyncInbox to sync emails',
              'or :HimalayaSyncFull for all folders'
            }
            sidebar.update_content(empty_lines)
            notifications.show('Maildir is empty. Run :HimalayaSyncInbox to sync emails.', 'info')
            -- Continue with empty list
            emails = {}
            total_count = 0
          else
            local error_lines = {
              string.format('󰊫 %s (%s)', display_name, folder),
              '',
              '󰅙 Failed to get email list',
              '',
              'This could be due to:',
              '• Invalid Himalaya configuration',
              '• JSON parsing error',
              '• Network connectivity issues',
              '',
              'Try:',
              '• :HimalayaDebugJson - Test JSON parsing',
              '• :HimalayaRawTest - Test raw output',
              '• :messages - Check error details'
            }
            sidebar.update_content(error_lines)
            notifications.show('Failed to get email list - run :HimalayaDebugJson for details', 'error')
            return
          end
        else
          local error_lines = {
            string.format('󰊫 %s (%s)', display_name, folder),
            '',
            '󰅙 Mail directory not found',
            '',
            'Run :HimalayaSetup to configure'
          }
          sidebar.update_content(error_lines)
          notifications.show('Mail directory not found. Run :HimalayaSetup', 'error')
          return
        end
      else
        local error_lines = {
          '󰊫 No account configured',
          '',
          'Run :HimalayaSetup to configure'
        }
        sidebar.update_content(error_lines)
        notifications.show('No account configured', 'error')
        return
      end
    end
    
    -- Store total count
    if total_count then
      state.set_total_emails(total_count)
    end
    
    -- Format and display email list
    local lines = M.format_email_list(emails)
    sidebar.update_content(lines)
    
    -- Store email data for reference in sidebar buffer
    vim.b[buf].himalaya_emails = emails
    vim.b[buf].himalaya_account = state.get_current_account()
    vim.b[buf].himalaya_folder = folder
    vim.b[buf].himalaya_line_map = lines.metadata -- Store line-to-email mapping
    vim.b[buf].himalaya_email_start_line = lines.email_start_line -- Store where emails start
    
    -- Set up buffer keymaps for the sidebar
    config.setup_buffer_keymaps(buf)
    
    -- Check for running sync and start status updates
    local mbsync = require('neotex.plugins.tools.himalaya.sync.mbsync')
    local status = mbsync.get_status()
    
    -- Start sync status updates if sync is running
    if status.sync_running then
      M.start_sync_status_updates()
      -- Force refresh header immediately to show current status
      M.refresh_sidebar_header()
    end
    
    -- Save current view to state
    state.save()
    
    -- Remove repetitive message - too noisy
  end, 10) -- Very short delay to ensure sidebar opens immediately
  
  -- Set up buffer keymaps immediately (before emails load)
  config.setup_buffer_keymaps(buf)
  
  -- Focus the sidebar immediately
  sidebar.focus()
  return win
end

-- Format email list for display (matching old UI exactly)
function M.format_email_list(emails)
  local lines = {}
  
  -- Header with pagination info (matching old format)
  local account = config.get_current_account()
  local email_display = 'Empty'
  
  -- Try to get email from account config
  if account and account.email then
    email_display = account.email
  elseif account and account.name then
    email_display = account.name
  else
    -- Try to get from account name (often is the email for gmail)
    local account_name = config.get_current_account_name()
    if account_name and account_name ~= 'gmail' then
      email_display = account_name
    elseif emails and #emails > 0 then
      -- If we have emails, we have a working config, so show account name
      email_display = account_name or 'gmail'
    end
  end
  
  -- Capitalize common account names for display
  if email_display == 'gmail' then
    email_display = 'Gmail'
  end
  
  local header = string.format('Himalaya - %s - %s', email_display, state.get_current_folder())
  local pagination_info = string.format('Page %d | %d emails', 
    state.get_current_page(), state.get_total_emails())
  
  -- Remove selection info display
  
  -- Add sync status if running
  local sync_status_line = M.get_sync_status_line()
  
  -- Debug the sync status
  local notify = require('neotex.util.notifications')
  if notify.config.modules.himalaya.debug_mode then
    notify.himalaya('format_email_list: sync_status_line = ' .. tostring(sync_status_line), notify.categories.BACKGROUND)
  end
  
  table.insert(lines, header)
  table.insert(lines, pagination_info)
  if sync_status_line then
    table.insert(lines, sync_status_line)
  end
  table.insert(lines, string.rep('─', math.max(#header, #pagination_info, 
    sync_status_line and #sync_status_line or 0)))
  
  -- Only add blank line when NOT syncing
  if not sync_status_line then
    table.insert(lines, '')
  end
  
  -- Store where emails start (before adding email lines)
  local email_start_line = #lines + 1
  
  -- Email entries
  for i, email in ipairs(emails) do
    -- Validate email structure
    if email and type(email) == 'table' then
      -- Parse flags (they're in an array)
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
      local status = seen and ' ' or '*'
      
      -- Selection checkbox (always shown)
      local email_id = email.id or tostring(i)
      local is_selected = state.is_email_selected(email_id)
      local checkbox = is_selected and '[x] ' or '[ ] '
      
      -- Parse from field (it's an object with name and addr)
      local from = 'Unknown'
      if email.from then
        if type(email.from) == 'table' then
          from = email.from.name or email.from.addr or 'Unknown'
        elseif type(email.from) == 'string' then
          from = email.from
        else
          from = tostring(email.from)
        end
      end
      
      local subject = email.subject or '(No subject)'
      local date = email.date or ''
      
      -- Truncate long fields
      from = utils.truncate_string(from, 25)
      subject = utils.truncate_string(subject, 50)
      
      local line = string.format('%s%s | %s  %s', checkbox, from, subject, date)
      table.insert(lines, line)
      
      -- Store email metadata for highlighting
      if not lines.metadata then lines.metadata = {} end
      lines.metadata[#lines] = {
        seen = seen,
        starred = starred,
        email_index = i,
        email_id = email_id,
        selected = is_selected,
        from_start = #checkbox + 1,  -- Start position of author field
        from_end = #checkbox + #from  -- End position of author field
      }
    else
      -- Log invalid email but continue
      local logger = require('neotex.plugins.tools.himalaya.core.logger')
      logger.warn('Invalid email structure at index ' .. i, { email = email })
    end
  end
  
  -- Store the email start line for easier access
  lines.email_start_line = email_start_line
  
  -- Footer with keymaps
  table.insert(lines, '')
  table.insert(lines, string.rep('─', 70))
  
  -- Show different footer based on whether emails are selected
  local selected_count = state.get_selection_count()
  if selected_count > 0 then
    table.insert(lines, string.format('%d selected: gD:delete gA:archive gS:spam n/N:select', selected_count))
  else
    table.insert(lines, 'r:refresh gn:next-page gp:prev-page n/N:select')
  end
  table.insert(lines, 'gm:folder ga:account gw:write c:compose')
  
  return lines
end

-- Get sync status line for header
function M.get_sync_status_line()
  -- Debug logging
  local state = require('neotex.plugins.tools.himalaya.core.state')
  local sync_checking = state.get('sync.checking', false)
  local notify = require('neotex.util.notifications')
  if notify.config.modules.himalaya.debug_mode then
    notify.himalaya('get_sync_status_line called, sync.checking = ' .. tostring(sync_checking), notify.categories.BACKGROUND)
  end
  
  -- Use the detailed version that shows progress ratios
  local status = M.get_sync_status_line_detailed()
  if status and notify.config.modules.himalaya.debug_mode then
    notify.himalaya('get_sync_status_line returning: ' .. status, notify.categories.BACKGROUND)
  end
  
  return status
end

-- Get sync status line for header with enhanced progress information (from old UI)
function M.get_sync_status_line_detailed()
  local sync_manager = require('neotex.plugins.tools.himalaya.sync.manager')
  local notify = require('neotex.util.notifications')
  
  -- Get current sync info from unified manager
  local sync_info = sync_manager.get_sync_info()
  
  if notify.config.modules.himalaya.debug_mode then
    notify.himalaya('get_sync_status_line_detailed called', notify.categories.BACKGROUND)
    notify.himalaya('  sync type = ' .. tostring(sync_info.type), notify.categories.BACKGROUND)
    notify.himalaya('  sync status = ' .. tostring(sync_info.status), notify.categories.BACKGROUND)
    notify.himalaya('  sync message = ' .. tostring(sync_info.message), notify.categories.BACKGROUND)
  end
  
  -- Not syncing
  if not sync_info.type or sync_info.status ~= 'running' then
    return nil
  end
  
  -- Get base message
  local message = sync_info.message
  if not message then
    return nil
  end
  
  -- Add elapsed time
  if sync_info.start_time then
    local elapsed = os.time() - sync_info.start_time
    local elapsed_str
    if elapsed >= 60 then
      local minutes = math.floor(elapsed / 60)
      local seconds = elapsed % 60
      elapsed_str = string.format(" (%dm %ds)", minutes, seconds)
    else
      elapsed_str = string.format(" (%ds)", elapsed)
    end
    message = message .. elapsed_str
  end
  
  -- Add type-specific details
  if sync_info.type == 'full' and sync_info.progress then
    local progress = sync_info.progress
    
    -- Add folder progress
    if progress.current_folder then
      message = message .. ": " .. progress.current_folder
      if progress.folders_total and progress.folders_total > 0 then
        message = message .. string.format(" %d/%d", 
          progress.folders_done or 0, progress.folders_total)
      end
    elseif progress.folders_total and progress.folders_total > 0 then
      message = message .. string.format(": %d/%d folders", 
        progress.folders_done or 0, progress.folders_total)
    end
    
    -- Add operation details
    if progress.messages_total and progress.messages_total > 0 then
      local op_name = progress.current_operation or "Processing"
      -- Capitalize common operations for consistency
      if op_name == "Downloading" then
        op_name = "Downloaded"
      elseif op_name == "Uploading" then
        op_name = "Uploaded"
      elseif op_name == "Synchronizing" then
        op_name = "Synced"
      end
      message = message .. string.format(" - %s %d/%d", op_name,
        progress.messages_processed or 0, progress.messages_total)
    elseif progress.current_operation then
      message = message .. " - " .. progress.current_operation
    end
  end
  
  return message
end
-- Timer for sync status updates
local sync_status_timer = nil

-- Start sync status updates
function M.start_sync_status_updates()
  -- Stop existing timer
  M.stop_sync_status_updates()
  
  -- Start new timer to update every 5 seconds for real-time progress (5000ms)
  sync_status_timer = vim.fn.timer_start(5000, function()
    M.update_sidebar_sync_status()
  end, { ['repeat'] = -1 })
end

-- Stop sync status updates
function M.stop_sync_status_updates()
  if sync_status_timer then
    vim.fn.timer_stop(sync_status_timer)
    sync_status_timer = nil
  end
end

-- Track last known sync progress to avoid unnecessary updates
local last_sync_progress = nil

-- Update sidebar with current sync status
function M.update_sidebar_sync_status()
  local mbsync = require('neotex.plugins.tools.himalaya.sync.mbsync')
  local status = mbsync.get_status()
  
  -- Only update if sidebar is actually open
  if not sidebar.is_open() then
    return
  end
  
  -- Stop timer if sync is no longer running
  if not status.sync_running then
    M.stop_sync_status_updates()
    -- Clear last progress
    last_sync_progress = nil
    -- Refresh entire sidebar one final time to remove sync status
    M.refresh_email_list()
    return
  end
  
  -- Check if progress has actually changed
  local progress_changed = false
  if status.progress then
    local current_progress = vim.inspect(status.progress)
    if current_progress ~= last_sync_progress then
      progress_changed = true
      last_sync_progress = current_progress
    end
  end
  
  -- Only update if something meaningful changed
  if progress_changed then
    -- Just update the header for smoother experience
    M.refresh_sidebar_header()
  else
    -- Only update header if we need to refresh elapsed time
    -- This happens less frequently
    M.refresh_sidebar_header()
  end
end

-- Refresh just the sidebar header (without refetching emails)
function M.refresh_sidebar_header()
  local notify = require('neotex.util.notifications')
  if notify.config.modules.himalaya.debug_mode then
    notify.himalaya('refresh_sidebar_header called', notify.categories.BACKGROUND)
  end
  
  local buf = sidebar.get_buf()
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    if notify.config.modules.himalaya.debug_mode then
      notify.himalaya('refresh_sidebar_header: no valid buffer', notify.categories.BACKGROUND)
    end
    return
  end
  
  -- Debug buffer info
  if notify.config.modules.himalaya.debug_mode then
    local filetype = vim.bo[buf].filetype
    notify.himalaya('refresh_sidebar_header: buffer filetype = ' .. tostring(filetype), notify.categories.BACKGROUND)
  end
  
  -- Don't require emails to be loaded - we can still update the header
  local emails = vim.b[buf].himalaya_emails
  
  -- Build just the header lines
  local account_name = config.get_current_account_name() or 'gmail'
  local folder_name = state.get_current_folder() or 'INBOX'
  
  -- Capitalize account name for display
  local account_display = account_name:sub(1,1):upper() .. account_name:sub(2):lower()
  
  local header = string.format('Himalaya - %s - %s', account_display, folder_name)
  local pagination_info = string.format('Page %d | %d emails', 
    state.get_current_page(), state.get_total_emails())
  
  -- Add sync status if running
  local sync_status_line = M.get_sync_status_line()
  
  -- Debug: log if we have a sync status
  if notify.config.modules.himalaya.debug_mode then
    if sync_status_line then
      notify.himalaya('refresh_sidebar_header: sync_status_line = ' .. sync_status_line, notify.categories.BACKGROUND)
    else
      notify.himalaya('refresh_sidebar_header: no sync status line', notify.categories.BACKGROUND)
    end
  end
  
  local header_lines = {header, pagination_info}
  if sync_status_line then
    table.insert(header_lines, sync_status_line)
  end
  table.insert(header_lines, string.rep('─', math.max(#header, #pagination_info, sync_status_line and #sync_status_line or 0)))
  
  -- Use optimized header update
  sidebar.update_header_lines(header_lines)
end

-- Read specific email
function M.read_email(email_id)
  local email_content = utils.get_email_content(state.get_current_account(), email_id, state.get_current_folder())
  if not email_content then
    notifications.show('Failed to read email', 'error')
    return
  end
  
  -- Create or reuse buffer
  local buf = M.buffers.email_read
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    buf = vim.api.nvim_create_buf(false, true)
    M.buffers.email_read = buf
  end
  
  -- Configure buffer
  vim.api.nvim_buf_set_option(buf, 'filetype', 'himalaya-email')
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  
  -- Format email content
  local lines, urls = M.format_email_content(email_content)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  -- Store email data
  vim.b[buf].himalaya_email_id = email_id
  vim.b[buf].himalaya_email = email_content
  vim.b[buf].himalaya_urls = urls
  
  -- Update selected email in state
  state.set_selected_email(email_id)
  
  -- Explicitly ensure keymaps are set up for this buffer
  config.setup_buffer_keymaps(buf)
  
  -- Open in window
  M.open_email_window(buf, 'Email - ' .. (email_content.subject or 'No Subject'))
end

-- Format email content for display
function M.format_email_content(email_content)
  local lines = {}
  local urls = {}  -- Track URLs for easy access
  
  -- Parse the raw email content if it's a string
  if type(email_content) == 'string' then
    local email_lines = vim.split(email_content, '\n')
    local in_headers = true
    local headers = {}
    local body_lines = {}
    
    for _, line in ipairs(email_lines) do
      if in_headers then
        if line == '' then
          in_headers = false
        elseif line:match('^[%w-]+:') then
          local header, value = line:match('^([%w-]+):%s*(.*)$')
          if header then
            headers[header:lower()] = value
          end
        end
      else
        table.insert(body_lines, line)
      end
    end
    
    -- Format headers
    table.insert(lines, 'From: ' .. (headers.from or 'Unknown'))
    table.insert(lines, 'To: ' .. (headers.to or 'Unknown'))
    if headers.cc then
      table.insert(lines, 'CC: ' .. headers.cc)
    end
    table.insert(lines, 'Subject: ' .. (headers.subject or '(No subject)'))
    table.insert(lines, 'Date: ' .. (headers.date or 'Unknown'))
    
    table.insert(lines, string.rep('─', 70))
    table.insert(lines, '')
    
    -- Process body and extract URLs
    local processed_body = M.process_email_body(body_lines, urls)
    vim.list_extend(lines, processed_body)
  else
    -- Fallback for structured data (shouldn't happen with current Himalaya)
    table.insert(lines, 'From: ' .. (email_content.from or 'Unknown'))
    table.insert(lines, 'To: ' .. (email_content.to or 'Unknown'))
    if email_content.cc then
      table.insert(lines, 'CC: ' .. email_content.cc)
    end
    table.insert(lines, 'Subject: ' .. (email_content.subject or '(No subject)'))
    table.insert(lines, 'Date: ' .. (email_content.date or 'Unknown'))
    
    table.insert(lines, string.rep('─', 70))
    table.insert(lines, '')
    
    -- Body
    if email_content.body then
      local body_lines = vim.split(email_content.body, '\n')
      local processed_body = M.process_email_body(body_lines, urls)
      vim.list_extend(lines, processed_body)
    end
  end
  
  -- Add URLs section if any were found
  if #urls > 0 then
    table.insert(lines, '')
    table.insert(lines, string.rep('─', 70))
    table.insert(lines, 'LINKS:')
    for i, url in ipairs(urls) do
      -- Truncate long URLs for display but keep them ctrl+clickable
      local display_url = utils.truncate_string(url, 60)
      table.insert(lines, string.format('[%d] %s', i, display_url))
    end
  end
  
  -- Footer
  table.insert(lines, '')
  table.insert(lines, string.rep('─', 70))
  if #urls > 0 then
    table.insert(lines, 'gl:go-to-link gr:reply gR:reply-all gf:forward gD:delete q:back')
  else
    table.insert(lines, 'gr:reply gR:reply-all gf:forward gD:delete q:back')
  end
  
  return lines, urls
end

-- Process email body text and extract URLs
function M.process_email_body(body_lines, urls)
  local processed_lines = {}
  
  for _, line in ipairs(body_lines) do
    -- Extract URLs from angle brackets and replace with numbered references
    local processed_line = line:gsub('<(https?://[^>]+)>', function(url)
      table.insert(urls, url)
      return string.format('[%d]', #urls)
    end)
    
    -- Also extract bare URLs (not in angle brackets)
    processed_line = processed_line:gsub('(https?://[%S]+)', function(url)
      -- Don't double-process URLs that were already in angle brackets
      if not line:match('<' .. url:gsub('[%(%)%.%+%-%*%?%[%]%^%$%%]', '%%%1') .. '>') then
        table.insert(urls, url)
        return string.format('[%d]', #urls)
      end
      return url
    end)
    
    table.insert(processed_lines, processed_line)
  end
  
  return processed_lines
end

-- Compose new email
function M.compose_email(to_address)
  -- Capture parent window before creating compose buffer
  local parent_win = vim.api.nvim_get_current_win()
  local parent_buf = vim.api.nvim_win_get_buf(parent_win)
  
  -- Create compose buffer
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Configure buffer
  vim.api.nvim_buf_set_option(buf, 'filetype', 'himalaya-compose')
  vim.api.nvim_buf_set_option(buf, 'buftype', 'acwrite')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  
  -- Email template
  local account = config.get_current_account()
  
  -- Get email address using auto-detection
  local from_email = config.get_account_email()
  
  -- Error if no email address found
  if not from_email then
    notifications.show('Cannot compose email: No email address configured for account', 'error')
    return
  end
  
  local lines = {
    'From: ' .. from_email,
    'To: ' .. (to_address or ''),
    'Subject: ',
    '',
    '',
    '',
    '--',
    account.name or from_email,
    '',
    string.rep('─', 70),
  }
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Store compose data
  vim.b[buf].himalaya_compose = true
  vim.b[buf].himalaya_account = state.get_current_account()
  
  -- Store parent window info for restoration
  vim.b[buf].himalaya_parent_win = parent_win
  vim.b[buf].himalaya_parent_buf = parent_buf
  
  -- Set up autocommand to handle window close and focus restoration
  vim.api.nvim_create_autocmd({'BufWipeout', 'BufDelete'}, {
    buffer = buf,
    once = true,
    callback = function()
      -- Restore focus to parent window if it's still valid
      vim.defer_fn(function()
        if vim.api.nvim_win_is_valid(parent_win) then
          vim.api.nvim_set_current_win(parent_win)
        elseif vim.api.nvim_buf_is_valid(parent_buf) then
          -- Parent window was closed, try to find a window showing the parent buffer
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_get_buf(win) == parent_buf then
              vim.api.nvim_set_current_win(win)
              break
            end
          end
        end
      end, 50)
    end
  })
  
  -- Set up buffer keymaps
  config.setup_buffer_keymaps(buf)
  
  -- Open in window
  M.open_email_window(buf, 'Compose Email', parent_win)
  
  -- Position cursor on To: line after "To: "
  vim.api.nvim_win_set_cursor(0, {2, 4})
  -- Start in insert mode
  vim.cmd('startinsert!')
end

-- Open email window (floating)
function M.open_email_window(buf, title, parent_win)
  -- Calculate window size
  local ui = vim.api.nvim_list_uis()[1]
  local width = math.floor(ui.width * 0.8)
  local height = math.floor(ui.height * 0.8)
  local row = math.floor((ui.height - height) / 2)
  local col = math.floor((ui.width - width) / 2)
  
  -- Create floating window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = title,
    title_pos = 'center',
  })
  
  -- Window settings
  vim.api.nvim_win_set_option(win, 'wrap', true)
  vim.api.nvim_win_set_option(win, 'linebreak', true)
  vim.api.nvim_win_set_option(win, 'cursorline', true)
  
  -- Track window in stack for proper focus restoration
  -- Use provided parent window or current window as fallback
  window_stack.push(win, parent_win or vim.api.nvim_get_current_win())
  
  return win
end

-- Pagination functions
function M.reset_pagination()
  state.set_current_page(1)
end

function M.next_page()
  if state.get_current_page() * state.get_page_size() < state.get_total_emails() then
    state.set_current_page(state.get_current_page() + 1)
    M.refresh_email_list()
  else
    notifications.show('Already on last page', 'info')
  end
end

function M.prev_page()
  if state.get_current_page() > 1 then
    state.set_current_page(state.get_current_page() - 1)
    M.refresh_email_list()
  else
    notifications.show('Already on first page', 'info')
  end
end

-- Refresh current email list
function M.refresh_email_list()
  -- Save current window to restore focus
  local current_win = vim.api.nvim_get_current_win()
  
  -- Get current sidebar buffer
  local buf = sidebar.get_buf()
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    -- No sidebar open, do full show
    M.show_email_list({state.get_current_folder()})
  else
    -- Sidebar is open, do optimized refresh
    local account_name = config.get_current_account_name()
    if not account_name then
      return
    end
    
    local folder = state.get_current_folder()
    
    -- Get updated email list
    local emails, total_count = utils.get_email_list(
      account_name,
      folder,
      state.get_current_page(),
      state.get_page_size()
    )
    
    if emails then
      -- Store total count
      if total_count then
        state.set_total_emails(total_count)
      end
      
      -- Update stored email data
      vim.b[buf].himalaya_emails = emails
      
      -- Format and update display with optimized rendering
      local lines = M.format_email_list(emails)
      sidebar.update_content(lines)
      
      -- Update line mapping data
      vim.b[buf].himalaya_line_map = lines.metadata
      vim.b[buf].himalaya_email_start_line = lines.email_start_line
    end
  end
  
  -- Restore focus to original window if it's still valid
  if vim.api.nvim_win_is_valid(current_win) then
    vim.api.nvim_set_current_win(current_win)
  end
end

-- Send current email (from compose buffer)
function M.send_current_email()
  local buf = vim.api.nvim_get_current_buf()
  if not vim.b[buf].himalaya_compose then
    notifications.show('Not in compose buffer', 'warn')
    return
  end
  
  -- Get buffer content
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  
  -- Parse email headers and body
  local headers = {}
  local body_start = nil
  
  for i, line in ipairs(lines) do
    if line == '' and not body_start then
      body_start = i + 1
      break
    elseif line:match('^[%w-]+:') then
      local header, value = line:match('^([%w-]+):%s*(.*)$')
      if header then
        headers[header:lower()] = value
      end
    end
  end
  
  -- Validate required fields
  if not headers.to or headers.to == '' then
    notifications.show('To: field is required', 'error')
    return
  end
  
  if not headers.subject or headers.subject == '' then
    notifications.show('Subject: field is required', 'error')
    return
  end
  
  -- Get body content (skip footer)
  local body_lines = {}
  for i = body_start or 1, #lines do
    if lines[i]:match('^─+$') then
      break
    end
    table.insert(body_lines, lines[i])
  end
  
  local body = table.concat(body_lines, '\n')
  
  -- Send email
  local email_data = {
    from = headers.from,
    to = headers.to,
    subject = headers.subject,
    body = body
  }
  local result = utils.send_email(state.get_current_account(), email_data)
  
  if result then
    notifications.show('Email sent successfully', 'info', { user_action = true })
    
    -- Get parent window info from buffer variables
    local parent_win = vim.b[buf].himalaya_parent_win
    local parent_buf = vim.b[buf].himalaya_parent_buf
    
    -- Close compose window and restore focus to parent
    local current_win = vim.api.nvim_get_current_win()
    
    -- Close the compose window
    if vim.api.nvim_win_is_valid(current_win) then
      vim.api.nvim_win_close(current_win, true)
    end
    
    -- Explicitly restore focus to email reading window
    vim.defer_fn(function()
      -- First try the stored email reading window (most reliable for replies)
      if M._email_reading_win and vim.api.nvim_win_is_valid(M._email_reading_win) then
        vim.api.nvim_set_current_win(M._email_reading_win)
        M._email_reading_win = nil  -- Clear it after use
      elseif parent_win and vim.api.nvim_win_is_valid(parent_win) then
        vim.api.nvim_set_current_win(parent_win)
      elseif parent_buf and vim.api.nvim_buf_is_valid(parent_buf) then
        -- Parent window was closed, try to find a window showing the parent buffer
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_get_buf(win) == parent_buf then
            vim.api.nvim_set_current_win(win)
            break
          end
        end
      end
    end, 50)
  else
    notifications.show('Failed to send email', 'error')
  end
end

-- Check if email buffer is open (for backward compatibility)
function M.is_email_buffer_open()
  return sidebar.is_open()
end

-- Close without saving (discard)
function M.close_without_saving()
  local buf = vim.api.nvim_get_current_buf()
  
  -- Get parent window info from buffer variables
  local parent_win = vim.b[buf].himalaya_parent_win
  local parent_buf = vim.b[buf].himalaya_parent_buf
  
  -- Close the current window
  local current_win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_is_valid(current_win) then
    vim.api.nvim_win_close(current_win, true)
  end
  
  -- Delete the buffer
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
  
  -- Explicitly restore focus to email reading window
  vim.defer_fn(function()
    -- First try the stored email reading window (most reliable for replies)
    if M._email_reading_win and vim.api.nvim_win_is_valid(M._email_reading_win) then
      vim.api.nvim_set_current_win(M._email_reading_win)
      M._email_reading_win = nil  -- Clear it after use
    elseif parent_win and vim.api.nvim_win_is_valid(parent_win) then
      vim.api.nvim_set_current_win(parent_win)
    elseif parent_buf and vim.api.nvim_buf_is_valid(parent_buf) then
      -- Parent window was closed, try to find a window showing the parent buffer
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == parent_buf then
          vim.api.nvim_set_current_win(win)
          break
        end
      end
    end
  end, 50)
  
  notifications.show('Draft discarded', 'info')
end

-- Navigate to next field in compose buffer
function M.compose_next_field()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1]
  local col = cursor[2]
  
  -- Field positions:
  -- Line 2: To:
  -- Line 3: Subject:
  -- Line 5+: Body (first empty line after headers)
  
  if row < 2 then
    -- Move to To: field
    vim.api.nvim_win_set_cursor(0, {2, 4})
    vim.cmd('startinsert!')
  elseif row == 2 then
    -- Move to Subject: field
    vim.api.nvim_win_set_cursor(0, {3, 9})
    vim.cmd('startinsert!')
  elseif row == 3 then
    -- Move to body (first empty line after subject)
    vim.api.nvim_win_set_cursor(0, {5, 0})
    vim.cmd('startinsert')
  else
    -- In body, go back to To:
    vim.api.nvim_win_set_cursor(0, {2, 4})
    vim.cmd('startinsert!')
  end
end

-- Navigate to previous field in compose buffer
function M.compose_prev_field()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1]
  
  if row <= 2 then
    -- At To: or above, go to body
    vim.api.nvim_win_set_cursor(0, {5, 0})
    vim.cmd('startinsert')
  elseif row == 3 then
    -- At Subject:, go to To:
    vim.api.nvim_win_set_cursor(0, {2, 4})
    vim.cmd('startinsert!')
  else
    -- In body, go to Subject:
    vim.api.nvim_win_set_cursor(0, {3, 9})
    vim.cmd('startinsert!')
  end
end

-- Close and save as draft
function M.close_and_save_draft()
  local buf = vim.api.nvim_get_current_buf()
  
  -- Get parent window info from buffer variables
  local parent_win = vim.b[buf].himalaya_parent_win
  local parent_buf = vim.b[buf].himalaya_parent_buf
  
  if vim.b[buf].himalaya_compose then
    -- TODO: Implement draft saving with Himalaya CLI
    -- For now, just close and notify
    notifications.show('Draft saved (not yet implemented)', 'warn')
  end
  
  -- Close the current window
  local current_win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_is_valid(current_win) then
    vim.api.nvim_win_close(current_win, true)
  end
  
  -- Explicitly restore focus to email reading window
  vim.defer_fn(function()
    -- First try the stored email reading window (most reliable for replies)
    if M._email_reading_win and vim.api.nvim_win_is_valid(M._email_reading_win) then
      vim.api.nvim_set_current_win(M._email_reading_win)
      M._email_reading_win = nil  -- Clear it after use
    elseif parent_win and vim.api.nvim_win_is_valid(parent_win) then
      vim.api.nvim_set_current_win(parent_win)
    elseif parent_buf and vim.api.nvim_buf_is_valid(parent_buf) then
      -- Parent window was closed, try to find a window showing the parent buffer
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == parent_buf then
          vim.api.nvim_set_current_win(win)
          break
        end
      end
    end
  end, 50)
end

-- Read current email (from email list buffer)
function M.read_current_email()
  local email_id = M.get_current_email_id()
  if email_id then
    M.read_email(email_id)
  else
    notifications.show('No email selected', 'warn')
  end
end

-- Helper function to get current email ID
function M.get_current_email_id()
  if vim.bo.filetype ~= 'himalaya-list' then
    return nil
  end
  
  local line_num = vim.fn.line('.')
  local emails = vim.b.himalaya_emails
  local email_start_line = vim.b.himalaya_email_start_line
  
  if not emails or #emails == 0 then
    return nil
  end
  
  -- Use stored email start line if available
  if not email_start_line then
    -- Fallback: Find where emails actually start by looking for the pattern of the first email
    email_start_line = 0
    for i = 1, 15 do  -- Check first 15 lines
      local line = vim.fn.getline(i)
      -- Look for email lines which have the status indicator pattern [*] or [ ]
      -- In selection mode, lines start with checkbox [ ] or [x] followed by status [*] or [ ]
      -- Without selection mode, lines start directly with status [*] or [ ]
      if line and (line:match('^%[[ *]%] [^ ]') or line:match('^%[[ x]%] %[[ *]%]')) then
        email_start_line = i
        break
      end
    end
    
    -- Fallback: count header lines by finding the separator line
    if email_start_line == 0 then
      for i = 1, 10 do  -- Check first 10 lines
        local line = vim.fn.getline(i)
        if line and line:match('^[─]+$') then  -- Found separator line
          email_start_line = i + 2  -- Emails start after separator + empty line
          break
        end
      end
    end
    
    -- Final fallback if nothing found
    if email_start_line == 0 then
      email_start_line = 6 -- Default
    end
  end
  
  local email_index = line_num - email_start_line + 1
  
  if email_index > 0 and email_index <= #emails and emails[email_index] then
    return emails[email_index].id
  end
  
  return nil
end

-- Close current view using window stack
function M.close_current_view()
  local current_win = vim.api.nvim_get_current_win()
  local current_buf = vim.api.nvim_get_current_buf()
  
  -- Check if we're closing an email reading buffer
  local is_email_buffer = vim.b[current_buf].himalaya_email_id ~= nil
  
  -- Try to close using window stack first
  if not window_stack.close_current() then
    -- If not in stack, close normally
    vim.cmd('close')
  end
  
  -- Refresh email list after closing email reading view
  if is_email_buffer then
    vim.defer_fn(function()
      M.refresh_email_list()
    end, 100)
  end
end

-- Close Himalaya entirely (all buffers and sidebar)
function M.close_himalaya()
  -- Save state before closing
  state.save()
  
  -- Close and cleanup sidebar (including buffer)
  sidebar.close_and_cleanup()
  
  -- Close all tracked Himalaya buffers
  local closed_buffers = 0
  for name, buf in pairs(M.buffers) do
    if buf and vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
      closed_buffers = closed_buffers + 1
    end
  end
  
  -- Find and close any remaining Himalaya buffers by filetype
  local all_buffers = vim.api.nvim_list_bufs()
  for _, buf in ipairs(all_buffers) do
    if vim.api.nvim_buf_is_valid(buf) then
      local ok, filetype = pcall(vim.api.nvim_buf_get_option, buf, 'filetype')
      if ok and filetype and filetype:match('^himalaya%-') then
        vim.api.nvim_buf_delete(buf, { force = true })
        closed_buffers = closed_buffers + 1
      end
    end
  end
  
  -- Clear window stack
  window_stack.clear()
  
  -- Reset buffer tracking
  M.buffers = {
    email_list = nil,
    email_read = nil,
    email_compose = nil,
  }
  
  notifications.show('Himalaya closed', 'info', { buffers_cleaned = closed_buffers })
end

-- Update email display without resetting pagination
function M.update_email_display()
  -- Get email list with current pagination settings
  local emails = utils.get_email_list(
    state.get_current_account(),
    state.get_current_folder(),
    state.get_current_page(),
    state.get_page_size()
  )
  if not emails then
    notifications.show('Failed to get email list', 'error')
    return
  end
  
  -- Get existing sidebar buffer or create new one
  local win = sidebar.open()
  local buf = sidebar.get_buf()
  
  -- Update buffer tracking
  M.buffers.email_list = buf
  
  -- Format email list content
  local lines = M.format_email_list(emails)
  sidebar.update_content(lines)
  
  -- Store email data for reference in sidebar buffer
  vim.api.nvim_buf_set_var(buf, 'himalaya_emails', emails)
  vim.api.nvim_buf_set_var(buf, 'himalaya_account', state.get_current_account())
  vim.api.nvim_buf_set_var(buf, 'himalaya_folder', state.get_current_folder())
  
  -- Save current view to state
  state.save()
  
  -- Focus the sidebar
  sidebar.focus()
end

-- Refresh current view
function M.refresh_current_view()
  local buf = vim.api.nvim_get_current_buf()
  if vim.b[buf].himalaya_emails then
    M.refresh_email_list()
  end
end

-- Reply to current email
function M.reply_current_email()
  local buf = vim.api.nvim_get_current_buf()
  local email_id = vim.b[buf].himalaya_email_id
  if email_id then
    -- Store the current window (email reading window) globally for restoration
    M._email_reading_win = vim.api.nvim_get_current_win()
    M.reply_email(email_id, false)
  else
    notifications.show('No email to reply to', 'warn')
  end
end

-- Reply all to current email
function M.reply_all_current_email()
  local buf = vim.api.nvim_get_current_buf()
  local email_id = vim.b[buf].himalaya_email_id
  if email_id then
    -- Store the current window (email reading window) globally for restoration
    M._email_reading_win = vim.api.nvim_get_current_win()
    M.reply_email(email_id, true)
  else
    notifications.show('No email to reply to', 'warn')
  end
end

-- Reply to email
function M.reply_email(email_id, reply_all)
  -- Capture parent window before creating new window
  local parent_win = vim.api.nvim_get_current_win()
  
  -- Store the parent window in a more reliable way
  local parent_buf = vim.api.nvim_win_get_buf(parent_win)
  local is_email_reading_buffer = vim.b[parent_buf].himalaya_email_id ~= nil
  
  local email_content = utils.get_email_content(state.get_current_account(), email_id)
  if not email_content then
    notifications.show('Failed to get email for reply', 'error')
    return
  end
  
  -- Parse email content if it's raw text
  local parsed_email = M.parse_email_for_reply(email_content)
  
  -- Create compose buffer
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Configure buffer
  vim.api.nvim_buf_set_option(buf, 'filetype', 'himalaya-compose')
  vim.api.nvim_buf_set_option(buf, 'buftype', 'acwrite')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  
  -- Reply template
  local account = config.get_current_account()
  
  -- Get email address using auto-detection
  local from_email = config.get_account_email()
  
  -- Error if no email address found
  if not from_email then
    notifications.show('Cannot reply: No email address configured for account', 'error')
    return
  end
  
  local to_field = parsed_email.from or ''
  if reply_all then
    local cc_field = parsed_email.cc or ''
    if cc_field ~= '' then
      to_field = to_field .. ', ' .. cc_field
    end
    -- Also include other recipients from To field if reply_all
    local original_to = parsed_email.to or ''
    if original_to ~= '' and original_to ~= from_email then
      to_field = to_field .. ', ' .. original_to
    end
  end
  
  local subject = parsed_email.subject or ''
  if not subject:match('^Re:%s') then
    subject = 'Re: ' .. subject
  end
  
  local lines = {
    'From: ' .. from_email,
    'To: ' .. to_field,
    'Subject: ' .. subject,
    '',
    '',
    '> ' .. (parsed_email.from or 'Unknown') .. ' wrote:',
  }
  
  -- Add quoted original content
  if parsed_email.body then
    local original_lines = vim.split(parsed_email.body, '\n')
    for _, line in ipairs(original_lines) do
      table.insert(lines, '> ' .. line)
    end
  end
  
  table.insert(lines, '')
  table.insert(lines, '--')
  table.insert(lines, account.name or from_email)
  table.insert(lines, '')
  table.insert(lines, string.rep('─', 70))
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Store compose data
  vim.b[buf].himalaya_compose = true
  vim.b[buf].himalaya_account = state.get_current_account()
  vim.b[buf].himalaya_reply_to = email_id
  
  -- Store parent window info in compose buffer for reliable restoration
  vim.b[buf].himalaya_parent_win = parent_win
  vim.b[buf].himalaya_parent_buf = parent_buf
  vim.b[buf].himalaya_parent_is_email = is_email_reading_buffer
  
  -- Set up autocommand to handle window close and focus restoration
  vim.api.nvim_create_autocmd({'BufWipeout', 'BufDelete'}, {
    buffer = buf,
    once = true,
    callback = function()
      -- Restore focus to parent window if it's still valid
      vim.defer_fn(function()
        if vim.api.nvim_win_is_valid(parent_win) then
          vim.api.nvim_set_current_win(parent_win)
        elseif vim.api.nvim_buf_is_valid(parent_buf) then
          -- Parent window was closed, try to find a window showing the parent buffer
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_get_buf(win) == parent_buf then
              vim.api.nvim_set_current_win(win)
              break
            end
          end
        end
      end, 50)
    end
  })
  
  -- Open in window with proper parent tracking
  M.open_email_window(buf, 'Reply - ' .. subject, parent_win)
  
  -- Position cursor before quoted content
  vim.api.nvim_win_set_cursor(0, {5, 0})
  vim.cmd('startinsert!')
end

-- Parse email content for reply operations
function M.parse_email_for_reply(email_content)
  local parsed = {}
  
  if type(email_content) == 'string' then
    -- Parse raw email string
    local email_lines = vim.split(email_content, '\n')
    local in_headers = true
    local body_lines = {}
    
    for _, line in ipairs(email_lines) do
      if in_headers then
        if line == '' or line:match('^──+$') then
          in_headers = false
        elseif line:match('^From:%s*(.+)') then
          parsed.from = line:match('^From:%s*(.+)')
        elseif line:match('^To:%s*(.+)') then
          parsed.to = line:match('^To:%s*(.+)')
        elseif line:match('^CC:%s*(.+)') then
          parsed.cc = line:match('^CC:%s*(.+)')
        elseif line:match('^Subject:%s*(.+)') then
          parsed.subject = line:match('^Subject:%s*(.+)')
        elseif line:match('^Date:%s*(.+)') then
          parsed.date = line:match('^Date:%s*(.+)')
        end
      else
        -- Skip separator lines
        if not line:match('^──+$') then
          table.insert(body_lines, line)
        end
      end
    end
    
    parsed.body = table.concat(body_lines, '\n')
  else
    -- Already structured data
    parsed = email_content
  end
  
  return parsed
end

-- Forward current email
function M.forward_current_email()
  local buf = vim.api.nvim_get_current_buf()
  local email_id = vim.b[buf].himalaya_email_id
  if email_id then
    -- Store the current window (email reading window) globally for restoration
    M._email_reading_win = vim.api.nvim_get_current_win()
    M.forward_email(email_id)
  else
    notifications.show('No email to forward', 'warn')
  end
end

-- Forward email
function M.forward_email(email_id)
  -- Capture parent window before creating new window
  local parent_win = vim.api.nvim_get_current_win()
  
  -- Store the parent window in a more reliable way
  local parent_buf = vim.api.nvim_win_get_buf(parent_win)
  local is_email_reading_buffer = vim.b[parent_buf].himalaya_email_id ~= nil
  
  local email_content = utils.get_email_content(state.get_current_account(), email_id)
  if not email_content then
    notifications.show('Failed to get email for forwarding', 'error')
    return
  end
  
  -- Parse email content
  local parsed_email = M.parse_email_for_reply(email_content)
  
  -- Create compose buffer similar to reply but with forward template
  local buf = vim.api.nvim_create_buf(false, true)
  
  vim.api.nvim_buf_set_option(buf, 'filetype', 'himalaya-compose')
  vim.api.nvim_buf_set_option(buf, 'buftype', 'acwrite')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  
  local account = config.get_current_account()
  local subject = parsed_email.subject or ''
  if not subject:match('^Fwd:%s') then
    subject = 'Fwd: ' .. subject
  end
  
  -- Get email address using auto-detection
  local from_email = config.get_account_email()
  
  -- Error if no email address found
  if not from_email then
    notifications.show('Cannot forward: No email address configured for account', 'error')
    return
  end
  
  local lines = {
    'From: ' .. from_email,
    'To: ',
    'Subject: ' .. subject,
    '',
    '---------- Forwarded message ---------',
    'From: ' .. (parsed_email.from or 'Unknown'),
    'Date: ' .. (parsed_email.date or 'Unknown'),
    'Subject: ' .. (parsed_email.subject or '(No subject)'),
    'To: ' .. (parsed_email.to or 'Unknown'),
    '',
  }
  
  -- Add CC if present
  if parsed_email.cc then
    table.insert(lines, 10, 'CC: ' .. parsed_email.cc)
    table.insert(lines, 11, '')
  end
  
  -- Add original content
  if parsed_email.body then
    local original_lines = vim.split(parsed_email.body, '\n')
    vim.list_extend(lines, original_lines)
  end
  
  table.insert(lines, '')
  table.insert(lines, '--')
  table.insert(lines, account.name or from_email)
  table.insert(lines, '')
  table.insert(lines, string.rep('─', 70))
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  vim.b[buf].himalaya_compose = true
  vim.b[buf].himalaya_account = state.get_current_account()
  vim.b[buf].himalaya_forward = email_id
  
  -- Store parent window info in compose buffer for reliable restoration
  vim.b[buf].himalaya_parent_win = parent_win
  vim.b[buf].himalaya_parent_buf = parent_buf
  vim.b[buf].himalaya_parent_is_email = is_email_reading_buffer
  
  -- Set up autocommand to handle window close and focus restoration
  vim.api.nvim_create_autocmd({'BufWipeout', 'BufDelete'}, {
    buffer = buf,
    once = true,
    callback = function()
      -- Restore focus to parent window if it's still valid
      vim.defer_fn(function()
        if vim.api.nvim_win_is_valid(parent_win) then
          vim.api.nvim_set_current_win(parent_win)
        elseif vim.api.nvim_buf_is_valid(parent_buf) then
          -- Parent window was closed, try to find a window showing the parent buffer
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_get_buf(win) == parent_buf then
              vim.api.nvim_set_current_win(win)
              break
            end
          end
        end
      end, 50)
    end
  })
  
  M.open_email_window(buf, 'Forward - ' .. subject, parent_win)
  
  -- Position cursor on To: line
  vim.api.nvim_win_set_cursor(0, {2, #lines[2]})
  vim.cmd('startinsert!')
end

-- Delete current email
function M.delete_current_email()
  local buf = vim.api.nvim_get_current_buf()
  local email_id = vim.b[buf].himalaya_email_id
  
  -- If no email_id in buffer variable, try to get it from cursor position (sidebar)
  if not email_id then
    email_id = M.get_current_email_id()
  end
  
  if not email_id then
    notifications.show('No email to delete', 'warn')
    return
  end
  
  local success, error_type, extra = utils.smart_delete_email(state.get_current_account(), email_id)
  
  if success then
    notifications.show('Email deleted successfully', 'info')
    
    -- Only close view if we're in an email reading buffer, not the sidebar
    local current_buf = vim.api.nvim_get_current_buf()
    local is_email_buffer = vim.b[current_buf].himalaya_email_id ~= nil
    local is_sidebar = vim.bo[current_buf].filetype == 'himalaya-list'
    
    if is_email_buffer and not is_sidebar then
      M.close_current_view()
    end
    
    -- Always refresh the list to show the deletion
    vim.defer_fn(function()
      M.refresh_email_list()
    end, 100)
  elseif error_type == 'missing_trash' then
    -- Trash folder doesn't exist, offer alternatives
    M.handle_missing_trash_folder(email_id, extra)
  else
    notifications.show('Failed to delete email', 'error', { error = extra or 'Unknown error' })
  end
end

-- Handle missing trash folder scenario
function M.handle_missing_trash_folder(email_id, suggested_folders)
  -- Check if we're in headless mode
  local is_headless = vim.fn.argc(-1) == 0 and vim.fn.has('gui_running') == 0
  
  if is_headless then
    -- In headless mode, just permanently delete
    notifications.show('Permanently deleting email (trash folder not found)', 'info')
    M.permanent_delete_email(email_id)
    return
  end
  
  local options = {'Permanently delete (cannot be undone)'}
  
  -- Add suggested trash folders
  if suggested_folders and #suggested_folders > 0 then
    for _, folder in ipairs(suggested_folders) do
      table.insert(options, 'Move to ' .. folder)
    end
  end
  
  -- Add option to move to a custom folder
  table.insert(options, 'Move to custom folder...')
  table.insert(options, 'Cancel')
  
  vim.ui.select(options, {
    prompt = 'Trash folder not found. How would you like to delete this email?',
  }, function(choice)
    if not choice or choice == 'Cancel' then
      return
    end
    
    if choice == 'Permanently delete (cannot be undone)' then
      M.permanent_delete_email(email_id)
    elseif choice:match('^Move to ') then
      local folder = choice:gsub('^Move to ', '')
      M.move_email_to_folder(email_id, folder)
    elseif choice == 'Move to custom folder...' then
      M.prompt_custom_folder_move(email_id)
    end
  end)
end

-- Permanently delete email
function M.permanent_delete_email(email_id)
  local success = utils.delete_email(state.get_current_account(), email_id, state.get_current_folder())
  if success then
    notifications.show('Email permanently deleted', 'info')
    M.close_current_view()
    vim.defer_fn(function()
      M.refresh_email_list()
    end, 100)
  else
    notifications.show('Failed to permanently delete email', 'error')
  end
end

-- Move email to specific folder
function M.move_email_to_folder(email_id, folder)
  local success = utils.move_email(email_id, folder)
  if success then
    M.close_current_view()
    -- Refresh is handled by the autocmd from utils.move_email
  end
end

-- Prompt for custom folder name
function M.prompt_custom_folder_move(email_id)
  -- Check if we're in headless mode
  local is_headless = vim.fn.argc(-1) == 0 and vim.fn.has('gui_running') == 0
  
  if is_headless then
    -- In headless mode, use a default folder
    notifications.show('Moving email to Archive folder', 'info')
    M.move_email_to_folder(email_id, 'Archive')
    return
  end
  
  vim.ui.input({
    prompt = 'Enter folder name: ',
    completion = 'custom,folder',
  }, function(folder)
    if folder and folder ~= '' then
      M.move_email_to_folder(email_id, folder)
    end
  end)
end

-- Archive current email (from email list)
function M.archive_current_email()
  local email_id = nil
  local current_buf = vim.api.nvim_get_current_buf()
  
  -- Try to get email ID based on current buffer type
  if vim.bo[current_buf].filetype == 'himalaya-list' then
    email_id = M.get_current_email_id()
  elseif vim.b[current_buf].himalaya_email_id then
    -- We're in email reading buffer
    email_id = vim.b[current_buf].himalaya_email_id
  end
  
  if email_id then
    -- Try different archive folder names that might exist
    local archive_folders = {'All_Mail', 'Archive', 'All Mail', 'ARCHIVE', 'Archived'}
    local folders = utils.get_folders(state.get_current_account())
    local archive_folder = nil
    
    if folders then
      -- Find the first existing archive folder
      for _, folder in ipairs(folders) do
        for _, archive_name in ipairs(archive_folders) do
          -- Check exact match first, then case-insensitive match
          if folder == archive_name or folder:lower() == archive_name:lower() then
            archive_folder = folder
            break
          end
        end
        if archive_folder then break end
      end
    end
    
    if archive_folder then
      local success = utils.move_email(email_id, archive_folder)
      if success then
        notifications.show('Email archived', 'info', { folder = archive_folder })
        
        -- Close email view if we're reading the email
        local current_buf = vim.api.nvim_get_current_buf()
        local is_email_buffer = vim.b[current_buf].himalaya_email_id ~= nil
        local is_sidebar = vim.bo[current_buf].filetype == 'himalaya-list'
        
        if is_email_buffer and not is_sidebar then
          M.close_current_view()
        end
        
        -- Always refresh the sidebar to show the change
        vim.defer_fn(function()
          M.refresh_email_list()
        end, 100)
      end
    else
      -- If no archive folder found, offer alternatives
      vim.ui.select({
        'Move to All_Mail',
        'Create Archive folder',
        'Move to custom folder...',
        'Cancel'
      }, {
        prompt = 'No archive folder found. How would you like to archive this email?',
      }, function(choice)
        if choice == 'Move to All_Mail' then
          utils.move_email(email_id, 'All_Mail')
        elseif choice == 'Create Archive folder' then
          utils.move_email(email_id, '[Gmail].All Mail')
        elseif choice == 'Move to custom folder...' then
          vim.ui.input({
            prompt = 'Enter folder name: ',
          }, function(folder)
            if folder and folder ~= '' then
              utils.move_email(email_id, folder)
            end
          end)
        end
      end)
    end
  else
    notifications.show('No email selected', 'warn')
  end
end

-- Mark current email as spam and move to spam folder
function M.spam_current_email()
  local email_id = M.get_current_email_id()
  if email_id then
    -- Try different spam folder names that might exist
    local spam_folders = {'Spam', 'Junk', 'SPAM', 'JUNK'}
    local folders = utils.get_folders(state.get_current_account())
    local spam_folder = nil
    
    if folders then
      -- Find the first existing spam folder
      for _, folder in ipairs(folders) do
        for _, spam_name in ipairs(spam_folders) do
          -- Check exact match first, then case-insensitive match
          if folder == spam_name or folder:lower() == spam_name:lower() then
            spam_folder = folder
            break
          end
        end
        if spam_folder then break end
      end
    end
    
    if spam_folder then
      local success = utils.move_email(email_id, spam_folder)
      if success then
        notifications.show('Email marked as spam', 'info', { folder = spam_folder })
        
        -- Close email view if we're reading the email
        local current_buf = vim.api.nvim_get_current_buf()
        local is_email_buffer = vim.b[current_buf].himalaya_email_id ~= nil
        local is_sidebar = vim.bo[current_buf].filetype == 'himalaya-list'
        
        if is_email_buffer and not is_sidebar then
          M.close_current_view()
        end
        
        -- Always refresh the sidebar to show the change
        vim.defer_fn(function()
          M.refresh_email_list()
        end, 100)
      end
    else
      -- If no spam folder found, ask user what to do
      vim.ui.select({
        'Move to Junk folder',
        'Move to Spam folder', 
        'Delete permanently',
        'Cancel'
      }, {
        prompt = 'No spam folder found. How would you like to handle this email?',
      }, function(choice)
        if choice == 'Move to Junk folder' then
          utils.move_email(email_id, 'Junk')
        elseif choice == 'Move to Spam folder' then
          utils.move_email(email_id, 'Spam')
        elseif choice == 'Delete permanently' then
          M.delete_current_email()
        end
      end)
    end
  else
    notifications.show('No email selected', 'warn')
  end
end

-- Search emails
function M.search_emails(query)
  -- Update search state
  state.set_last_query(query)
  
  local results = utils.search_emails(state.get_current_account(), query)
  if results then
    -- Save search results to state
    state.set_search_results(results)
    -- Display search results in email list format
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'filetype', 'himalaya-list')
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'swapfile', false)
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    
    local lines = M.format_email_list(results)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    
    vim.b[buf].himalaya_emails = results
    vim.b[buf].himalaya_account = state.get_current_account()
    vim.b[buf].himalaya_search = query
    
    M.open_email_window(buf, 'Search Results: ' .. query)
  else
    notifications.show('Search failed', 'error')
  end
end

-- Show attachments
function M.show_attachments(email_id)
  local attachments = utils.get_email_attachments(state.get_current_account(), email_id)
  if not attachments or #attachments == 0 then
    notifications.show('No attachments found', 'info')
    return
  end
  
  -- Create attachment list buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'himalaya-attachments')
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  
  local lines = {'Email Attachments', string.rep('─', 50), ''}
  for i, attachment in ipairs(attachments) do
    table.insert(lines, string.format('%d. %s (%s)', i, attachment.name, attachment.size or 'unknown size'))
  end
  table.insert(lines, '')
  table.insert(lines, string.rep('─', 50))
  table.insert(lines, '<CR>:download  q:close')
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  vim.b[buf].himalaya_attachments = attachments
  vim.b[buf].himalaya_email_id = email_id
  
  M.open_email_window(buf, 'Attachments')
end

-- Open link under cursor
function M.open_link_under_cursor()
  local buf = vim.api.nvim_get_current_buf()
  local urls = vim.b[buf].himalaya_urls
  
  if not urls or #urls == 0 then
    notifications.show('No links found in this email', 'info')
    return
  end
  
  -- Get current line
  local line = vim.api.nvim_get_current_line()
  
  -- Check if cursor is on a link line
  local link_number = line:match('^%[(%d+)%]')
  if link_number then
    local index = tonumber(link_number)
    if index and urls[index] then
      M.open_url(urls[index])
      return
    end
  end
  
  -- If not on a link line, show picker
  if #urls == 1 then
    M.open_url(urls[1])
  else
    local choices = {}
    for i, url in ipairs(urls) do
      table.insert(choices, string.format('%d. %s', i, url))
    end
    
    vim.ui.select(choices, {
      prompt = 'Select link to open:',
      format_item = function(item)
        return item
      end,
    }, function(choice)
      if choice then
        local index = tonumber(choice:match('^(%d+)%.'))
        if index and urls[index] then
          M.open_url(urls[index])
        end
      end
    end)
  end
end

-- Open URL using system default browser
function M.open_url(url)
  local cmd
  if vim.fn.has('mac') == 1 then
    cmd = { 'open', url }
  elseif vim.fn.has('unix') == 1 then
    cmd = { 'xdg-open', url }
  elseif vim.fn.has('win32') == 1 then
    cmd = { 'cmd', '/c', 'start', url }
  else
    notifications.show('Unsupported platform for opening URLs', 'error')
    return
  end
  
  vim.fn.jobstart(cmd, {
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        notifications.show('URL opened', 'info', { url = url })
      else
        notifications.show('Failed to open URL', 'error')
      end
    end
  })
end

-- Session restoration functions
function M.can_restore_session()
  if not state.is_state_fresh() then
    return false, "No recent session found (older than 24 hours)"
  end
  
  local current_account = state.get_current_account()
  local current_folder = state.get_current_folder()
  
  if not current_account or not current_folder then
    return false, "No previous email session found"
  end
  
  return true, string.format("Session available: %s/%s", current_account, current_folder)
end

-- Restore session from state (manual only)
function M.restore_session()
  local can_restore, message = M.can_restore_session()
  
  if not can_restore then
    notifications.show('Cannot restore session', 'warn', { error = message })
    return false
  end
  
  local current_account = state.get_current_account()
  local current_folder = state.get_current_folder()
  local selected_email = state.get_selected_email()
  
  vim.defer_fn(function()
    -- Show the email list for the saved folder/account
    M.show_email_list({current_folder, '--account=' .. current_account})
    
    -- Check if we're in headless mode
    local is_headless = vim.fn.argc(-1) == 0 and vim.fn.has('gui_running') == 0
    
    -- Ask user if they want to restore the selected email (skip in headless)
    if selected_email and not is_headless then
      vim.ui.select({'Open previous email', 'Just show email list'}, {
        prompt = 'Restore previous email session:',
      }, function(choice)
        if choice == 'Open previous email' then
          vim.defer_fn(function()
            M.read_email(selected_email)
          end, 200)
        end
      end)
    elseif selected_email and is_headless then
      -- In headless mode, just restore the email directly
      vim.defer_fn(function()
        M.read_email(selected_email)
      end, 200)
    end
    
    -- Restore search results if available
    local last_query = state.get_last_query()
    local search_results = state.get_search_results()
    if last_query and search_results then
      notifications.show('Previous search available', 'info', { query = last_query })
    end
    
    notifications.show('Email session restored', 'info')
  end, 100)
  
  return true
end

-- Show session restoration prompt (called manually)
function M.prompt_session_restore()
  local can_restore, message = M.can_restore_session()
  
  if not can_restore then
    notifications.show(message, 'info')
    return
  end
  
  -- Check if we're in headless mode
  local is_headless = vim.fn.argc(-1) == 0 and vim.fn.has('gui_running') == 0
  
  if is_headless then
    -- In headless mode, just restore directly
    notifications.show(message, 'info')
    M.restore_session()
  else
    vim.ui.select({'Restore previous session', 'Start fresh'}, {
      prompt = message .. ' - Restore?',
    }, function(choice)
      if choice == 'Restore previous session' then
        M.restore_session()
      end
    end)
  end
end

-- Show folder picker
function M.pick_folder()
  local account_name = config.get_current_account_name()
  if not account_name then
    notifications.show('No account selected', 'error')
    return
  end
  
  local folders = utils.get_folders(account_name)
  if not folders or #folders == 0 then
    notifications.show('No folders found', 'error')
    return
  end
  
  -- Add current folder indicator
  local current_folder = state.get_current_folder()
  local options = {}
  for _, folder in ipairs(folders) do
    if folder == current_folder then
      table.insert(options, folder .. ' (current)')
    else
      table.insert(options, folder)
    end
  end
  
  vim.ui.select(options, {
    prompt = 'Select folder:',
  }, function(choice)
    if not choice then
      return
    end
    
    -- Remove the " (current)" suffix if present
    local folder = choice:gsub(' %(current%)$', '')
    
    if folder ~= current_folder then
      state.set_current_folder(folder)
      state.set_current_page(1)  -- Reset to first page
      M.show_email_list({ folder })
    end
  end)
end

-- Show account picker
function M.pick_account()
  -- Get available accounts from config
  local accounts = {}
  local current_account = config.get_current_account_name()
  
  for name, _ in pairs(config.config.accounts) do
    if name == current_account then
      table.insert(accounts, name .. ' (current)')
    else
      table.insert(accounts, name)
    end
  end
  
  if #accounts == 0 then
    notifications.show('No accounts configured', 'error')
    return
  end
  
  vim.ui.select(accounts, {
    prompt = 'Select account:',
  }, function(choice)
    if not choice then
      return
    end
    
    -- Remove the " (current)" suffix if present
    local account = choice:gsub(' %(current%)$', '')
    
    if account ~= current_account then
      if config.switch_account(account) then
        state.set_current_account(account)
        state.set_current_folder('INBOX')  -- Reset to INBOX
        state.set_current_page(1)  -- Reset to first page
        M.show_email_list({ 'INBOX' })
      else
        notifications.show('Failed to switch account', 'error')
      end
    end
  end)
end

-- Batch Operations

-- Batch delete operation
function M.delete_selected_emails()
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
      
      -- Show progress notification for large batches
      if #selected > 5 then
        notifications.show(string.format('Deleting %d emails...', #selected), 'info')
      end
      
      for i, email in ipairs(selected) do
        local success, error_type = utils.smart_delete_email(state.get_current_account(), email.id)
        if success then
          success_count = success_count + 1
        else
          error_count = error_count + 1
          -- Log specific error for debugging
          notify.himalaya(string.format('Failed to delete email %s: %s', 
            email.subject or email.id, error_type or 'unknown error'), notify.categories.BACKGROUND)
        end
        
        -- Update progress for large batches
        if #selected > 10 and i % 10 == 0 then
          notify.himalaya(string.format('Progress: %d/%d', i, #selected), notify.categories.STATUS)
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
      
      -- Find archive folder
      local archive_folders = {'Archive', 'All Mail', 'All_Mail', '[Gmail]/All Mail'}
      local folders = utils.get_folders(state.get_current_account())
      local archive_folder = nil
      
      if folders then
        for _, folder in ipairs(folders) do
          for _, archive_name in ipairs(archive_folders) do
            if folder == archive_name or folder:match(archive_name) then
              archive_folder = folder
              break
            end
          end
          if archive_folder then break end
        end
      end
      
      if not archive_folder then
        archive_folder = 'All_Mail' -- Default fallback
      end
      
      -- Show progress notification for large batches
      if #selected > 5 then
        notifications.show(string.format('Archiving %d emails to %s...', #selected, archive_folder), 'info')
      end
      
      for i, email in ipairs(selected) do
        local success = utils.move_email(email.id, archive_folder)
        if success then
          success_count = success_count + 1
        else
          error_count = error_count + 1
          notify.himalaya(string.format('Failed to archive email %s', 
            email.subject or email.id), notify.categories.BACKGROUND)
        end
        
        -- Update progress for large batches
        if #selected > 10 and i % 10 == 0 then
          notify.himalaya(string.format('Progress: %d/%d', i, #selected), notify.categories.STATUS)
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
      
      -- Find spam folder
      local spam_folders = {'Spam', 'Junk', 'SPAM', 'JUNK', '[Gmail]/Spam'}
      local folders = utils.get_folders(state.get_current_account())
      local spam_folder = nil
      
      if folders then
        for _, folder in ipairs(folders) do
          for _, spam_name in ipairs(spam_folders) do
            if folder == spam_name or folder:lower() == spam_name:lower() then
              spam_folder = folder
              break
            end
          end
          if spam_folder then break end
        end
      end
      
      if not spam_folder then
        spam_folder = 'Spam' -- Default fallback
      end
      
      -- Show progress notification for large batches
      if #selected > 5 then
        notifications.show(string.format('Moving %d emails to spam...', #selected), 'info')
      end
      
      for i, email in ipairs(selected) do
        local success = utils.move_email(email.id, spam_folder)
        if success then
          success_count = success_count + 1
        else
          error_count = error_count + 1
          notify.himalaya(string.format('Failed to mark email as spam: %s', 
            email.subject or email.id), notify.categories.BACKGROUND)
        end
        
        -- Update progress for large batches
        if #selected > 10 and i % 10 == 0 then
          notify.himalaya(string.format('Progress: %d/%d', i, #selected), notify.categories.STATUS)
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

-- Close compose buffer and save as draft
function M.close_and_save_draft()
  local buf = vim.api.nvim_get_current_buf()
  if not vim.b[buf].himalaya_compose then
    notifications.show('Not in compose buffer', 'warn')
    return
  end
  
  -- Get buffer content
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  
  -- Parse email content
  local email_data = utils.parse_email_content(lines)
  
  -- Save to drafts folder
  local account = state.get_current_account()
  local drafts_folders = {'Drafts', 'DRAFTS', '[Gmail]/Drafts', 'Draft'}
  local folders = utils.get_folders(account)
  local drafts_folder = nil
  
  if folders then
    for _, folder in ipairs(folders) do
      for _, draft_name in ipairs(drafts_folders) do
        if folder == draft_name or folder:lower() == draft_name:lower() then
          drafts_folder = folder
          break
        end
      end
      if drafts_folder then break end
    end
  end
  
  if not drafts_folder then
    drafts_folder = 'Drafts' -- Default fallback
  end
  
  -- Save draft using utility function
  local success = utils.save_draft(account, email_data, drafts_folder)
  
  if success then
    notifications.show('Draft saved to ' .. drafts_folder, 'info')
    M.close_current_view()
  else
    notifications.show('Failed to save draft', 'error')
  end
end

-- Close compose buffer without saving
function M.close_without_saving()
  local buf = vim.api.nvim_get_current_buf()
  if not vim.b[buf].himalaya_compose then
    notifications.show('Not in compose buffer', 'warn')
    return
  end
  
  -- Check if buffer has been modified
  if vim.bo[buf].modified then
    vim.ui.input({
      prompt = 'Discard unsaved changes? (y/n): '
    }, function(input)
      if input and input:lower() == 'y' then
        -- Force close without saving
        vim.bo[buf].modified = false
        M.close_current_view()
        notifications.show('Email discarded', 'info')
      end
    end)
  else
    -- Buffer not modified, just close
    M.close_current_view()
    notifications.show('Email discarded', 'info')
  end
end

return M