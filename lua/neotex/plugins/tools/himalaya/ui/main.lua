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
  if sidebar.is_open() then
    sidebar.close()
    notifications.show('Himalaya closed', 'info')
  else
    M.show_email_list({})
  end
end

function M.show_email_list(args)
  args = args or {}
  
  -- Ensure UI is initialized
  if not state.is_initialized() then
    M.init()
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
  local loading_lines = {
    string.format('󰊫 %s (%s)', account_name, folder),
    '',
    '󰔟 Loading emails...',
    '',
    'Please wait while emails are being fetched from Himalaya.'
  }
  sidebar.update_content(loading_lines)
  
  -- Load emails asynchronously to avoid blocking UI
  vim.defer_fn(function()
    local account_name = config.get_current_account_name()
    local emails = utils.get_email_list(account_name, folder, state.get_current_page(), state.get_page_size())
    if not emails then
      local error_lines = {
        string.format('󰊫 %s (%s)', account_name, folder),
        '',
        '󰅙 Failed to get email list',
        '',
        'Check your Himalaya configuration and try again.'
      }
      sidebar.update_content(error_lines)
      notifications.show('Failed to get email list', 'error')
      return
    end
    
    -- Store total count if available
    if emails and #emails > 0 then
      state.set_total_emails(#emails)
    end
    
    -- Format and display email list
    local lines = M.format_email_list(emails)
    sidebar.update_content(lines)
    
    -- Store email data for reference in sidebar buffer
    vim.b[buf].himalaya_emails = emails
    vim.b[buf].himalaya_account = state.get_current_account()
    vim.b[buf].himalaya_folder = folder
    
    -- Set up buffer keymaps for the sidebar
    -- TODO: Implement keymap setup
    -- config.setup_buffer_keymaps(buf)
    
    -- Check for running sync and start status updates
    local mbsync = require('neotex.plugins.tools.himalaya.sync.mbsync')
    local status = mbsync.get_status()
    
    -- Start sync status updates if sync is running (either locally or externally)
    if status.sync_running or status.external_sync_running then
      M.start_sync_status_updates()
      -- Force refresh header immediately to show current status
      M.refresh_sidebar_header()
    end
    
    -- Save current view to state
    state.save()
    
    notifications.show('Email list loaded in sidebar', 'info')
  end, 10) -- Very short delay to ensure sidebar opens immediately
  
  -- Set up buffer keymaps immediately (before emails load)
  -- TODO: Implement keymap setup
  -- config.setup_buffer_keymaps(buf)
  
  -- Focus the sidebar immediately
  sidebar.focus()
  return win
end

-- Format email list for display (matching old UI exactly)
function M.format_email_list(emails)
  local lines = {}
  
  -- Header with account info and folder
  local account = config.get_current_account()
  local header = string.format('󰊫 %s (%s)', account.email or account.name or 'Unknown', state.get_current_folder())
  
  -- Sync status
  local sync_status_line = M.get_sync_status_line()
  
  -- Add header sections
  table.insert(lines, header)
  if sync_status_line then
    table.insert(lines, sync_status_line)
  end
  table.insert(lines, '')
  
  -- Column headers with nice formatting
  table.insert(lines, '  📧 Emails')
  table.insert(lines, '  ' .. string.rep('─', 60))
  
  -- Email entries with better formatting
  if emails and #emails > 0 then
    for _, email in ipairs(emails) do
      -- Parse flags
      local seen = false
      local flagged = false
      if email.flags then
        if type(email.flags) == 'table' then
          for _, flag in ipairs(email.flags) do
            if flag == 'Seen' or flag == '\\Seen' or flag == 'R' then
              seen = true
            elseif flag == 'Flagged' or flag == '\\Flagged' or flag == '*' then
              flagged = true
            end
          end
        elseif type(email.flags) == 'string' then
          seen = email.flags:match('R') ~= nil
          flagged = email.flags:match('*') ~= nil
        end
      end
      
      -- Status icon
      local status_icon = '●'  -- Unread (filled circle)
      if seen then
        status_icon = '○'      -- Read (empty circle)
      end
      if flagged then
        status_icon = '★'      -- Flagged (star)
      end
      
      -- Parse from field
      local from = 'Unknown'
      if email.from then
        if type(email.from) == 'table' then
          -- Prefer name over email address
          from = email.from.name or email.from.addr or 'Unknown'
          -- Handle vim.NIL values
          if from == vim.NIL then
            from = email.from.addr or 'Unknown'
          end
          if from == vim.NIL then
            from = 'Unknown'
          end
        else
          from = tostring(email.from)
        end
      end
      
      -- Format date nicely
      local date_str = ''
      if email.date then
        -- Try to parse and format the date
        local date = email.date
        if type(date) == 'string' then
          -- Extract just the date part if it has timezone info
          local simple_date = date:match('(%d%d%d%d%-%d%d%-%d%d)')
          if simple_date then
            date_str = simple_date
          else
            -- Try to extract time
            local time = date:match('(%d%d:%d%d)')
            if time then
              date_str = time
            else
              date_str = date:sub(1, 10)
            end
          end
        end
      end
      
      local subject = email.subject or '(No subject)'
      
      -- Calculate field widths for alignment
      local status_width = 2
      local from_width = 20
      local subject_width = 35
      local date_width = 10
      
      -- Truncate and pad fields
      from = utils.truncate_string(from, from_width)
      from = from .. string.rep(' ', from_width - vim.fn.strdisplaywidth(from))
      
      subject = utils.truncate_string(subject, subject_width)
      subject = subject .. string.rep(' ', subject_width - vim.fn.strdisplaywidth(subject))
      
      date_str = utils.truncate_string(date_str, date_width)
      
      -- Format the line with better spacing
      local line = string.format('  %s %s │ %s │ %s', 
        status_icon, 
        from, 
        subject, 
        date_str
      )
      
      table.insert(lines, line)
    end
  else
    table.insert(lines, '')
    table.insert(lines, '  No emails to display')
    table.insert(lines, '')
    table.insert(lines, '  Press <leader>ms to sync inbox')
  end
  
  -- Footer with pagination
  table.insert(lines, '')
  table.insert(lines, '  ' .. string.rep('─', 60))
  local page_info = string.format('  Page %d of %d (%d emails)', 
    state.get_current_page(),
    math.max(1, math.ceil(state.get_total_emails() / state.get_page_size())),
    #emails
  )
  table.insert(lines, page_info)
  
  -- Quick help
  table.insert(lines, '')
  table.insert(lines, '  Quick Keys:')
  table.insert(lines, '  <CR> Read  │ c Compose │ r Refresh')
  table.insert(lines, '  j/k Navigate │ n/p Page │ q Close')
  
  return lines
end

-- Get sync status line for header
function M.get_sync_status_line()
  local mbsync = require('neotex.plugins.tools.himalaya.sync.mbsync')
  local status = mbsync.get_status()
  
  if not status.running then
    return nil
  end
  
  return "  🔄 Syncing..."
end

-- Get sync status line for header with enhanced progress information (from old UI)
function M.get_sync_status_line_detailed()
  local mbsync = require('neotex.plugins.tools.himalaya.sync.mbsync')
  local status = mbsync.get_status()
  
  -- Check for external sync first (higher priority in display)
  if status.external_sync_running then
    -- External sync is running - show simple status
    return "🔄 Syncing: External (1 process)"
  end
  
  -- Check for local sync
  if not status.sync_running then
    return nil
  end
  
  local status_text = "🔄 Syncing"
  local progress_info = {}
  
  if status.progress then
    -- Priority 1: Show message ratio if available (15/98 emails)
    if status.progress.current_message and status.progress.total_messages and 
       status.progress.total_messages > 0 then
      status_text = status_text .. string.format(": %d/%d emails", 
        status.progress.current_message, status.progress.total_messages)
    
    -- Priority 2: Show detailed progress from mbsync counters
    elseif (status.progress.messages_added_total and status.progress.messages_added_total > 0) or
           (status.progress.messages_updated_total and status.progress.messages_updated_total > 0) then
      local progress_parts = {}
      
      if status.progress.messages_added_total and status.progress.messages_added_total > 0 then
        table.insert(progress_parts, string.format("%d/%d new", 
          status.progress.messages_added or 0, status.progress.messages_added_total))
      end
      
      if status.progress.messages_updated_total and status.progress.messages_updated_total > 0 then
        table.insert(progress_parts, string.format("%d/%d updated", 
          status.progress.messages_updated or 0, status.progress.messages_updated_total))
      end
      
      if #progress_parts > 0 then
        status_text = status_text .. ": " .. table.concat(progress_parts, ", ")
      elseif status.progress.current_operation then
        status_text = status_text .. ": " .. status.progress.current_operation
      end
    
    -- Priority 3: Show calculated difference if we have far/near totals
    elseif status.progress.far_total and status.progress.near_total then
      local new_msgs = math.max(0, status.progress.far_total - status.progress.near_total)
      local to_upload = math.max(0, status.progress.near_total - status.progress.far_total)
      local recent = status.progress.far_recent or 0
      
      -- Show what's happening based on the difference
      if new_msgs > 0 then
        status_text = status_text .. string.format(": %d new to download", new_msgs)
      elseif to_upload > 0 then
        status_text = status_text .. string.format(": %d to upload", to_upload)
      elseif recent > 0 then
        status_text = status_text .. string.format(": %d recent to check", recent)
      else
        -- Show the totals for reference
        status_text = status_text .. string.format(": %d/%d synced", 
          status.progress.near_total, status.progress.far_total)
      end
      
      -- Add operation if different from default
      if status.progress.current_operation and 
         status.progress.current_operation ~= "Synchronizing emails" then
        status_text = status_text .. " - " .. status.progress.current_operation
      end
    
    -- Priority 4: Show operation status
    elseif status.progress.current_operation then
      status_text = status_text .. ": " .. status.progress.current_operation
    end
    
    -- Add mailbox progress if available (nil-safe)
    if status.progress.mailboxes_total and status.progress.mailboxes_total > 0 then
      table.insert(progress_info, string.format("%d/%d mailboxes", 
        status.progress.mailboxes_done or 0, status.progress.mailboxes_total))
    end
    
    -- Add message processing info if available (nil-safe)
    if status.progress.messages_processed and status.progress.messages_processed > 0 then
      local msg_details = {}
      if status.progress.messages_added and status.progress.messages_added > 0 then
        table.insert(msg_details, status.progress.messages_added .. " added")
      end
      if status.progress.messages_updated and status.progress.messages_updated > 0 then
        table.insert(msg_details, status.progress.messages_updated .. " updated")
      end
      
      if #msg_details > 0 then
        table.insert(progress_info, table.concat(msg_details, ", "))
      else
        table.insert(progress_info, status.progress.messages_processed .. " msgs")
      end
    end
    
    -- Add elapsed time
    if status.progress.start_time then
      local elapsed = os.time() - status.progress.start_time
      local elapsed_str
      if elapsed >= 60 then
        local minutes = math.floor(elapsed / 60)
        local seconds = elapsed % 60
        elapsed_str = string.format("%dm %ds", minutes, seconds)
      else
        elapsed_str = string.format("%ds", elapsed)
      end
      table.insert(progress_info, elapsed_str)
    end
    
    -- Combine progress info with separator
    if #progress_info > 0 then
      status_text = status_text .. " | " .. table.concat(progress_info, " | ")
    end
  end
  
  -- Fallback to process count if no detailed progress
  if #progress_info == 0 then
    -- Try to get mbsync command line to show what's syncing
    local handle = io.popen('pgrep -a mbsync 2>/dev/null | head -1')
    if handle then
      local mbsync_info = handle:read('*a')
      handle:close()
      
      if mbsync_info and mbsync_info ~= "" then
        -- Extract account or channel from command line
        local account = mbsync_info:match('mbsync%s+(%S+)')
        if account and account ~= '-V' and account ~= '-a' then
          status_text = status_text .. ": " .. account
        else
          -- Count processes as fallback
          local count_handle = io.popen('pgrep mbsync 2>/dev/null | wc -l')
          if count_handle then
            local process_count = tonumber(count_handle:read('*a')) or 0
            count_handle:close()
            if process_count > 0 then
              status_text = status_text .. string.format(" (%d process%s)", 
                process_count, process_count == 1 and "" or "es")
            end
          end
        end
      else
        status_text = status_text .. "..."
      end
    end
  end
  
  return status_text
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

-- Update sidebar with current sync status
function M.update_sidebar_sync_status()
  local mbsync = require('neotex.plugins.tools.himalaya.sync.mbsync')
  local status = mbsync.get_status()
  
  -- Only update if sidebar is actually open
  if not sidebar.is_open() then
    return
  end
  
  -- Stop timer if sync is no longer running (neither local nor external)
  if not status.sync_running and not status.external_sync_running then
    M.stop_sync_status_updates()
    -- Refresh sidebar one final time to remove sync status
    M.refresh_sidebar_header()
    return
  end
  
  -- Update sidebar header with current sync status
  M.refresh_sidebar_header()
end

-- Refresh just the sidebar header (without refetching emails)
function M.refresh_sidebar_header()
  local buf = sidebar.get_buf()
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  
  local emails = vim.b[buf].himalaya_emails
  if not emails then
    return
  end
  
  -- Get current cursor position
  local cursor_pos = vim.api.nvim_win_get_cursor(sidebar.get_win())
  
  -- Regenerate content with updated sync status
  local lines = M.format_email_list(emails)
  
  -- Update buffer content
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  -- Restore cursor position
  pcall(vim.api.nvim_win_set_cursor, sidebar.get_win(), cursor_pos)
end

-- Read specific email
function M.read_email(email_id)
  local email_content = utils.get_email_content(state.get_current_account(), email_id)
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
  -- TODO: Implement keymap setup
  -- config.setup_buffer_keymaps(buf)
  
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
  -- Create compose buffer
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Configure buffer
  vim.api.nvim_buf_set_option(buf, 'filetype', 'himalaya-compose')
  vim.api.nvim_buf_set_option(buf, 'buftype', 'acwrite')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  
  -- Email template
  local account = config.get_current_account()
  local lines = {
    'From: ' .. account.email,
    'To: ' .. (to_address or ''),
    'Subject: ',
    '',
    '',
    '',
    '--',
    account.name or account.email,
    '',
    string.rep('─', 70),
    'gs:send q:save-draft Q:discard',
  }
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Store compose data
  vim.b[buf].himalaya_compose = true
  vim.b[buf].himalaya_account = state.get_current_account()
  
  -- Set up buffer keymaps
  -- TODO: Implement keymap setup
  -- config.setup_buffer_keymaps(buf)
  
  -- Open in window
  M.open_email_window(buf, 'Compose Email')
  
  -- Position cursor on To: line if empty, otherwise Subject line
  vim.api.nvim_win_set_cursor(0, to_address and {3, 9} or {2, 4})
end

-- Open email window (floating)
function M.open_email_window(buf, title)
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
  window_stack.push(win, sidebar.get_win())
  
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
  M.show_email_list({state.get_current_folder()})
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
  local result = utils.send_email(state.get_current_account(), headers.to, headers.subject, body)
  
  if result then
    notifications.show('Email sent successfully', 'info')
    -- Close compose window
    window_stack.close_current()
  else
    notifications.show('Failed to send email', 'error')
  end
end

-- Check if email buffer is open (for backward compatibility)
function M.is_email_buffer_open()
  return sidebar.is_open()
end

return M