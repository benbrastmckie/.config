-- Himalaya Email List UI Module
-- Handles email list display, formatting, and navigation

local M = {}

-- Dependencies
local config = require('neotex.plugins.tools.himalaya.core.config')
local utils = require('neotex.plugins.tools.himalaya.utils')
local state = require('neotex.plugins.tools.himalaya.core.state')
local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
local notifications = require('neotex.plugins.tools.himalaya.ui.notifications')
local window_stack = require('neotex.plugins.tools.himalaya.ui.window_stack')
local notify = require('neotex.util.notifications')
local email_preview = require('neotex.plugins.tools.himalaya.ui.email_preview_v2')
local email_cache = require('neotex.plugins.tools.himalaya.core.email_cache')

-- Module state
local sync_status_timer = nil
local last_sync_progress = nil

-- Buffer tracking (reference to main module's buffers)
local buffers = nil

-- Initialize module
function M.init(main_buffers)
  -- Store reference to main module's buffers
  buffers = main_buffers
end

-- Toggle email sidebar
function M.toggle_email_sidebar()
  -- Check if we have an email list buffer open
  local email_list_buf = buffers.email_list
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
      buffers.email_list = nil
      sidebar.state.is_open = false
      sidebar.state.win = nil
      sidebar.state.buf = nil
      notify.himalaya('Himalaya closed', notify.categories.STATUS)
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
    -- Initialize state management first
    state.init()
    
    -- Initialize sidebar with state
    sidebar.init()
    
    -- Sync state with sidebar configuration (non-intrusive)
    state.sync_with_sidebar()
  end
  
  -- Check if config is properly initialized
  if not config.is_initialized() then
    notify.himalaya('Himalaya not configured. Run :HimalayaSetup to begin.', notify.categories.ERROR)
    return
  end
  
  -- Check if maildir exists and set up if needed
  -- For now, we'll skip this check since the wizard module doesn't have ensure_maildir_exists
  -- TODO: Implement maildir check in wizard module
  
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
      notify.himalaya('Unknown account: ' .. account, notify.categories.ERROR)
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
  buffers.email_list = buf
  
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
            notify.himalaya('Maildir is empty. Run :HimalayaSyncInbox to sync emails.', notify.categories.STATUS)
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
            notify.himalaya('Failed to get email list - run :HimalayaDebugJson for details', notify.categories.ERROR)
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
          notify.himalaya('Mail directory not found. Run :HimalayaSetup', notify.categories.ERROR)
          return
        end
      else
        local error_lines = {
          '󰊫 No account configured',
          '',
          'Run :HimalayaSetup to configure'
        }
        sidebar.update_content(error_lines)
        notify.himalaya('No account configured', notify.categories.ERROR)
        return
      end
    end
    
    -- Store emails in cache
    if emails and #emails > 0 then
      email_cache.store_emails(account_name, folder, emails)
    end
    
    -- Store total count
    if total_count then
      state.set_total_emails(total_count)
      -- Update cached count
      local account = state.get_current_account()
      local folder = state.get_current_folder()
      state.set('email_counts.' .. account .. '.' .. folder, total_count)
    end
    
    -- Format and display email list
    local lines = M.format_email_list(emails)
    sidebar.update_content(lines)
    
    -- Store email data in state instead of buffer variables to avoid userdata issues
    state.set('email_list.emails', emails)
    state.set('email_list.account', state.get_current_account())
    state.set('email_list.folder', folder)
    
    -- Store metadata in state
    state.set('email_list.line_map', lines.metadata or {})
    state.set('email_list.email_start_line', lines.email_start_line or 1)
    
    -- Keep buffer references for backwards compatibility but only with simple data
    vim.b[buf].himalaya_account = state.get_current_account()
    vim.b[buf].himalaya_folder = folder
    
    -- Set up buffer keymaps for the sidebar
    config.setup_buffer_keymaps(buf)
    
    -- Set up hover preview
    M.setup_hover_preview(buf)
    
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
  
  -- Get accurate email count
  local account = state.get_current_account()
  local folder = state.get_current_folder()
  local total_emails = state.get('email_counts.' .. account .. '.' .. folder)
  
  -- If no cached count, get it
  if not total_emails then
    total_emails = utils.get_folder_email_count(account, folder)
    -- Only cache if we got a valid count
    if total_emails and total_emails > 0 then
      state.set('email_counts.' .. account .. '.' .. folder, total_emails)
    else
      -- If we couldn't get the count, use the number of emails we have
      total_emails = #emails
    end
  end
  
  local page_size = state.get_page_size()
  local current_page = state.get_current_page()
  local total_pages = math.max(1, math.ceil(total_emails / page_size))
  
  local pagination_info = string.format('Page %d / %d | %d emails', 
    current_page, total_pages, total_emails)
  
  -- Remove selection info display
  
  -- Add sync status if running
  local sync_status_line = M.get_sync_status_line()
  
  -- Debug the sync status
  notifications.debug('format_email_list: sync_status_line = ' .. tostring(sync_status_line))
  
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
    table.insert(lines, 'gs:sync gn:next-page gp:prev-page n/N:select')
  end
  table.insert(lines, 'return:preview/focus gm:folder ga:account gw:write')
  
  return lines
end

-- Get sync status line for header
function M.get_sync_status_line()
  -- Use the detailed version that shows progress ratios
  local status = M.get_sync_status_line_detailed()
  local notify = require('neotex.util.notifications')
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

-- Helper function to reset pagination
function M.reset_pagination()
  state.set_current_page(1)
end

-- Navigation functions
function M.next_page()
  if state.get_current_page() * state.get_page_size() < state.get_total_emails() then
    state.set_current_page(state.get_current_page() + 1)
    M.refresh_email_list()
  else
    notify.himalaya('Already on last page', notify.categories.STATUS)
  end
end

function M.prev_page()
  if state.get_current_page() > 1 then
    state.set_current_page(state.get_current_page() - 1)
    M.refresh_email_list()
  else
    notify.himalaya('Already on first page', notify.categories.STATUS)
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
      -- Store emails in cache
      email_cache.store_emails(account_name, folder, emails)
      
      -- Store total count
      if total_count then
        state.set_total_emails(total_count)
      end
      
      -- Update stored email data in state instead of buffer variables
      state.set('email_list.emails', emails)
      
      -- Format and update display with optimized rendering
      local lines = M.format_email_list(emails)
      sidebar.update_content(lines)
      
      -- Update line mapping data in state
      state.set('email_list.line_map', lines.metadata or {})
      state.set('email_list.email_start_line', lines.email_start_line or 1)
    end
  end
  
  -- Restore focus to original window if it's still valid
  if vim.api.nvim_win_is_valid(current_win) then
    vim.api.nvim_set_current_win(current_win)
  end
end

-- Update email display
function M.update_email_display()
  -- Get email list with current pagination settings
  local emails = utils.get_email_list(
    state.get_current_account(),
    state.get_current_folder(),
    state.get_current_page(),
    state.get_page_size()
  )
  if not emails then
    notify.himalaya('Failed to get email list', notify.categories.ERROR)
    return
  end
  
  -- Get existing sidebar buffer or create new one
  local win = sidebar.open()
  local buf = sidebar.get_buf()
  
  -- Update buffer tracking
  buffers.email_list = buf
  
  -- Format email list content
  local lines = M.format_email_list(emails)
  sidebar.update_content(lines)
  
  -- Store email data in state instead of buffer variables
  state.set('email_list.emails', emails)
  state.set('email_list.account', state.get_current_account())
  state.set('email_list.folder', state.get_current_folder())
  
  -- Keep simple buffer variables for identification
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
  if vim.bo[buf].filetype == 'himalaya-list' then
    M.refresh_email_list()
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
    
    -- Store search results in state
    state.set('search.results', results)
    state.set('search.account', state.get_current_account())
    state.set('search.query', query)
    
    -- Keep simple buffer variables for identification
    vim.b[buf].himalaya_account = state.get_current_account()
    vim.b[buf].himalaya_search = query
    
    -- Note: M.open_email_window needs to be provided by main module
    require('neotex.plugins.tools.himalaya.ui.main').open_email_window(buf, 'Search Results: ' .. query)
  else
    notify.himalaya('Search failed', notify.categories.ERROR)
  end
end

-- Show folder picker
function M.pick_folder()
  local account_name = config.get_current_account_name()
  if not account_name then
    notify.himalaya('No account selected', notify.categories.ERROR)
    return
  end
  
  local folders = utils.get_folders(account_name)
  if not folders or #folders == 0 then
    notify.himalaya('No folders found', notify.categories.ERROR)
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
    notify.himalaya('No accounts configured', notify.categories.ERROR)
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
        notify.himalaya('Failed to switch account', notify.categories.ERROR)
      end
    end
  end)
end

-- Get email ID from current line
function M.get_email_id_from_line(line_num)
  local line_map = state.get('email_list.line_map')
  local email_start_line = state.get('email_list.email_start_line')
  
  if not line_map or not email_start_line then
    return nil
  end
  
  -- Get metadata for this line
  local metadata = line_map[line_num]
  if metadata and metadata.email_id then
    return metadata.email_id
  end
  
  return nil
end

-- Setup hover preview for email list
function M.setup_hover_preview(buf)
  if not config.get('preview.enabled', true) then
    return
  end
  
  -- Store sidebar window for preview positioning
  local sidebar_win = sidebar.get_win()
  
  -- CursorHold - show preview after delay (only in preview mode)
  vim.api.nvim_create_autocmd('CursorHold', {
    buffer = buf,
    callback = function()
      if not email_preview.config.enabled then return end
      if not email_preview.is_preview_mode() then return end
      
      local line = vim.api.nvim_win_get_cursor(0)[1]
      local email_id = M.get_email_id_from_line(line)
      
      if email_id then
        email_preview.queue_preview(email_id, sidebar_win, 'keyboard')
      end
    end
  })
  
  -- CursorMoved - handled by config.lua for preview updates
  -- We don't hide preview on cursor move anymore as it conflicts with
  -- the preview update mechanism in config.lua
  
  -- Don't hide preview on BufLeave - let the user control when to close it
  -- This prevents the preview from being destroyed when clicking on it
  
  -- Mouse support is handled by the CursorMoved autocmd in config.lua
end

return M
