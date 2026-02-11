-- Himalaya Email List UI Module
-- Handles email list display, formatting, and navigation

-- TODO: Add email search and filtering within the list
-- TODO: Implement email threading/conversation view
-- TODO: Add email sorting options (date, subject, sender, size)
-- TODO: Implement virtual scrolling for large email lists
-- TODO: Add email archiving with visual feedback

local M = {}

-- Dependencies
local config = require('neotex.plugins.tools.himalaya.core.config')
local utils = require('neotex.plugins.tools.himalaya.utils')
local state = require('neotex.plugins.tools.himalaya.core.state')
local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
local notifications = require('neotex.plugins.tools.himalaya.ui.notifications')
local window_stack = require('neotex.plugins.tools.himalaya.ui.window_stack')
local notify = require('neotex.util.notifications')
local email_preview = require('neotex.plugins.tools.himalaya.ui.email_preview')
local draft_manager = require("neotex.plugins.tools.himalaya.data.drafts")
local email_cache = require("neotex.plugins.tools.himalaya.data.cache")
local logger = require('neotex.plugins.tools.himalaya.core.logger')

-- Module state
local sync_status_timer = nil
local last_sync_progress = nil
local scheduled_timer = nil

-- Buffer tracking (reference to main module's buffers)
local buffers = nil

-- Initialize module
function M.init(main_buffers)
  -- Store reference to main module's buffers
  buffers = main_buffers
  
  -- Register event listener for email scheduled
  local events_bus = require('neotex.plugins.tools.himalaya.commands.orchestrator')
  local event_types = require('neotex.plugins.tools.himalaya.core.events')
  
  events_bus.on(event_types.EMAIL_SCHEDULED, function(data)
    -- Refresh sidebar if it's open
    if sidebar.is_open() then
      vim.schedule(function()
        M.refresh_email_list()
      end)
    end
  end)
  
  -- Also refresh on reschedule
  events_bus.on(event_types.EMAIL_RESCHEDULED, function(data)
    if sidebar.is_open() then
      vim.schedule(function()
        M.refresh_email_list()
      end)
    end
  end)
  
  -- And on cancel
  events_bus.on(event_types.EMAIL_CANCELLED, function(data)
    if sidebar.is_open() then
      vim.schedule(function()
        M.refresh_email_list()
      end)
    end
  end)
  
  -- And when email is sent
  events_bus.on(event_types.EMAIL_SENT, function(data)
    if sidebar.is_open() then
      vim.schedule(function()
        M.refresh_email_list()
      end)
    end
  end)
  
  -- And when email is paused
  events_bus.on(event_types.EMAIL_PAUSED, function(data)
    if sidebar.is_open() then
      vim.schedule(function()
        M.refresh_email_list()
      end)
    end
  end)
  
  -- And when email is resumed
  events_bus.on(event_types.EMAIL_RESUMED, function(data)
    if sidebar.is_open() then
      vim.schedule(function()
        M.refresh_email_list()
      end)
    end
  end)
  
  -- Listen to draft events for automatic refresh
  events_bus.on(event_types.DRAFT_CREATED, function(data)
    if sidebar.is_open() then
      local current_folder = state.get_current_folder()
      local draft_folder = utils.find_draft_folder(state.get_current_account())
      
      if current_folder == draft_folder then
        -- Already in drafts folder, just refresh
        vim.defer_fn(function()
          M.refresh_email_list()
        end, 100)
      else
        -- Don't navigate to drafts folder automatically
        -- This was changing the sidebar when replying/forwarding
        -- Users can manually navigate to drafts if they want to see them
      end
    end
  end)
  
  events_bus.on(event_types.DRAFT_SAVED, function(data)
    if sidebar.is_open() then
      local current_folder = state.get_current_folder()
      local draft_folder = utils.find_draft_folder(state.get_current_account())
      
      -- Always refresh if we're viewing the drafts folder
      if current_folder == draft_folder then
        -- Small delay to ensure filesystem write is complete
        vim.defer_fn(function()
          M.refresh_email_list()
        end, 200) -- Increased delay to 200ms
      end
    end
  end)
  
  events_bus.on(event_types.DRAFT_DELETED, function(data)
    if sidebar.is_open() then
      local current_folder = state.get_current_folder()
      local draft_folder = utils.find_draft_folder(state.get_current_account())
      -- Only refresh if we're viewing the drafts folder
      if current_folder == draft_folder then
        vim.schedule(function()
          M.refresh_email_list()
        end)
      end
    end
  end)
end

-- Toggle email sidebar
function M.toggle_email_sidebar()
  -- Check if sidebar is already open using sidebar module's state
  if sidebar.is_open() then
    -- Close the sidebar
    sidebar.close()
    -- Clean up our buffer tracking
    buffers.email_list = nil
    -- Stop countdown timer
    M.stop_scheduled_updates()
    return
  end
  
  -- If we get here, sidebar is not open, so open it
  -- Sync scheduled emails from other instances before opening
  local scheduler = require("neotex.plugins.tools.himalaya.data.scheduler")
  if scheduler.initialized then
    scheduler.sync_from_disk()
  end
  
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
    -- Try to initialize config with defaults if not done yet
    local init = require('neotex.plugins.tools.himalaya.init')
    if not init.loaded then
      init.setup({})
    end
    
    -- Check again after initialization attempt
    if not config.is_initialized() then
      notify.himalaya('Himalaya not configured. Run :HimalayaSetup to begin.', notify.categories.ERROR)
      return
    end
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
  -- No longer show count in header as it's shown in pagination
  
  local loading_lines = {
    string.format('󰊫 %s - %s', display_name, folder),
    '',
    '󰔟 Loading emails...',
    '',
    'Please wait while emails are being fetched from Himalaya.'
  }
  sidebar.update_content(loading_lines)
  
  -- Get email list from himalaya (async to prevent UI blocking)
  local account_name = config.get_current_account_name()
  
  -- Check if this is the drafts folder
  local draft_folder = utils.find_draft_folder(account_name)
  local is_drafts_folder = folder == draft_folder
  
  if is_drafts_folder then
    -- For drafts, bypass himalaya and use filesystem directly
    -- This ensures immediate updates and eliminates sync issues
    M.process_email_list_results(nil, 0, folder, account_name)
  else
    -- Use async loading for non-draft folders
    utils.get_emails_async(account_name, folder, state.get_current_page(), state.get_page_size(), function(emails, total_count, error)
        if error then
          local error_lines = {
            string.format('󰊫 %s - %s', config.get_account_display_name(account_name), folder),
            '',
            '󰅙 Failed to get email list',
            '',
            'Error: ' .. tostring(error),
            '',
            'Try:',
            '• Check network connection',
            '• Verify account configuration',
            '• :messages for details'
          }
          sidebar.update_content(error_lines)
          notify.himalaya('Failed to get email list: ' .. tostring(error), notify.categories.ERROR)
          return
        end

      -- Continue with original logic but inside the callback
      M.process_email_list_results(emails, total_count, folder, account_name)
    end)
  end
end

-- Process email list results (extracted from original show_email_list)
function M.process_email_list_results(emails, total_count, folder, account_name)
  local display_name = config.get_account_display_name(account_name)
  
  -- Handle errors or empty results
  local draft_folder = utils.find_draft_folder(account_name)
  local is_drafts = folder == draft_folder
  
  if not emails or (type(emails) == "table" and #emails == 0 and (total_count == 0 or total_count == nil)) then
    -- Skip empty maildir check for drafts folder (we'll add local drafts below)
    if is_drafts then
      emails = {}
      total_count = 0
    else
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
            string.format('󰊫 %s - %s', display_name, folder),
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
            string.format('󰊫 %s - %s', display_name, folder),
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
          string.format('󰊫 %s - %s', display_name, folder),
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
    end  -- Close the else block for non-drafts folders
  end
  
  -- Special handling for drafts: Use filesystem as single source of truth
  -- This bypasses himalaya's cache entirely for the drafts folder
  if is_drafts then
    -- Get all drafts directly from the filesystem
    local draft_manager = require("neotex.plugins.tools.himalaya.data.drafts")
    local draft_list = draft_manager.list(account_name)
    
    -- Convert draft list to email format for display
    emails = {}
    for _, draft in ipairs(draft_list) do
      local email = {
        id = draft.filename,  -- Use filename as stable ID
        subject = draft.subject or 'Untitled',
        from = draft.from or '',
        to = draft.to or '',
        date = os.date('%Y-%m-%d %H:%M:%S', draft.mtime or draft.timestamp),
        mtime = draft.mtime or draft.timestamp,
        draft_filepath = draft.filepath,  -- Store filepath for preview
        flags = { draft = true }
      }
      table.insert(emails, email)
    end
    
    -- Draft list from draft_manager is already sorted by mtime (newest first)
    -- so we don't need to sort again
    total_count = #emails
  end
  
  -- Store emails in cache
  if emails and #emails > 0 then
    email_cache.store_emails(account_name, folder, emails)
  end
  
  -- Store total count and folder count
  if total_count and total_count > 0 then
    state.set_total_emails(total_count)
    
    -- Only store as folder count if it's an exact count (not an estimate)
    -- We have an exact count when we get less than a full page
    local page_size = state.get_page_size()
    if emails and #emails < page_size then
      -- This is the exact total count, store it
      state.set_folder_count(account_name, folder, total_count)
    end
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
  
  -- Position cursor at first email or restore previous position
  local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
  local buf = sidebar.get_buf()
  if sidebar.get_win() and vim.api.nvim_win_is_valid(sidebar.get_win()) and buf then
    -- Get stored cursor position or default to first email
    local email_start_line = lines.email_start_line or 1
    local cursor_line = state.get('sidebar.cursor_line', email_start_line)
    
    -- Ensure cursor line is within valid range
    local line_count = vim.api.nvim_buf_line_count(buf)
    if cursor_line > line_count then
      cursor_line = email_start_line
    end
    
    -- Position cursor
    vim.api.nvim_win_set_cursor(sidebar.get_win(), {cursor_line, 0})
    
    -- Keep buffer references for backwards compatibility but only with simple data
    vim.b[buf].himalaya_account = state.get_current_account()
    vim.b[buf].himalaya_folder = folder
    -- Store lines object with metadata for draft detection
    vim.b[buf].himalaya_lines = { metadata = lines.metadata }
    
    -- Set up buffer keymaps for the sidebar
    config.setup_buffer_keymaps(buf)
    
    -- Set up hover preview
    M.setup_hover_preview(buf)
  end
  
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
  
  -- Don't auto-focus sidebar - let user control focus
  -- sidebar.focus()
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
  
  -- Get accurate email count from stored sync data
  local account = state.get_current_account()
  local folder = state.get_current_folder()
  local total_emails = state.get_folder_count(account, folder)
  
  -- Debug: show what we found
  local notify = require('neotex.util.notifications')
  if notify.config.modules.himalaya.debug_mode then
    if total_emails then
      notify.himalaya(string.format('Found stored count: %s/%s = %d', 
        account, folder, total_emails), notify.categories.BACKGROUND)
    else
      notify.himalaya(string.format('No stored count for: %s/%s', 
        account, folder), notify.categories.BACKGROUND)
    end
  end
  
  -- If no stored count, use what we got from the email list
  if not total_emails or total_emails == 0 then
    total_emails = state.get_total_emails()
    -- If still no count, check if we have a full page (might be more)
    if not total_emails or total_emails == 0 then
      local page_size = state.get_page_size()
      if #emails >= page_size then
        -- We have a full page, so there might be more
        total_emails = nil  -- Will show as "?" or "30+" etc
      else
        total_emails = #emails
      end
    end
  end
  
  local page_size = state.get_page_size()
  local current_page = state.get_current_page()
  
  local pagination_info
  if total_emails then
    -- We know the exact count
    local total_pages = math.max(1, math.ceil(total_emails / page_size))
    
    -- Format count display with optional age indicator
    local count_age = state.get_folder_count_age(account, folder)
    local count_display
    
    if count_age and count_age > 600 then  -- Show age if older than 10 minutes
      local age_str
      if count_age < 3600 then
        age_str = string.format('%dm ago', math.floor(count_age / 60))
      elseif count_age < 86400 then
        age_str = string.format('%dh ago', math.floor(count_age / 3600))
      else
        age_str = string.format('%dd ago', math.floor(count_age / 86400))
      end
      count_display = string.format('%d emails (%s)', total_emails, age_str)
    else
      count_display = string.format('%d emails', total_emails)
    end
    
    pagination_info = string.format('Page %d / %d | %s', 
      current_page, total_pages, count_display)
  else
    -- We don't know the exact count
    if #emails >= page_size then
      -- Full page, might be more
      pagination_info = string.format('Page %d / ? | %d+ emails', 
        current_page, current_page * page_size)
    else
      -- Less than a page, this is all
      pagination_info = string.format('Page %d / %d | %d emails', 
        current_page, current_page, #emails)
    end
  end
  
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
  -- Use a fixed width separator to prevent visual jumping
  local separator_width = 70  -- Reasonable width that accommodates most content
  table.insert(lines, string.rep('─', separator_width))
  
  -- Only add blank line when NOT syncing
  if not sync_status_line then
    table.insert(lines, '')
  end
  
  -- Store where emails start (before adding email lines)
  local email_start_line = #lines + 1
  
  -- Check if current folder is draft folder for draft detection
  local current_folder = state.get_current_folder()
  local current_account = state.get_current_account()
  local draft_folder = utils.find_draft_folder(current_account)
  local is_draft_folder = current_folder == draft_folder
  
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
      
      -- For drafts, show To field instead of From
      local display_field = 'Unknown'
      if is_draft_folder then
        -- Show To field for drafts
        if email.to then
          if type(email.to) == 'table' then
            -- Extract name from "Name <email@example.com>" format or just use the address
            if email.to.name then
              display_field = email.to.name
            elseif email.to.addr then
              display_field = email.to.addr
            else
              display_field = tostring(email.to)
            end
          elseif type(email.to) == 'string' then
            -- Parse "Name <email@example.com>" format
            local name = email.to:match('^([^<]+)%s*<')
            if name then
              display_field = name:gsub('^%s+', ''):gsub('%s+$', '') -- Trim whitespace
            else
              -- Just an email address or already a name
              display_field = email.to
            end
          else
            display_field = tostring(email.to)
          end
        end
      else
        -- Show From field for non-drafts
        if email.from then
          if type(email.from) == 'table' then
            display_field = email.from.name or email.from.addr or 'Unknown'
          elseif type(email.from) == 'string' then
            display_field = email.from
          else
            display_field = tostring(email.from)
          end
        end
      end
      
      local subject = email.subject or ''
      
      -- For drafts, the subject comes directly from filesystem
      -- No cache lookup needed - filesystem is the source of truth
      
      if subject == '' then
        subject = '(No subject)'
      end
      
      local date = email.date or ''
      
      -- Truncate long fields
      display_field = utils.truncate_string(display_field, 25)
      subject = utils.truncate_string(subject, 50)
      
      -- Add draft indicator if this is a draft
      local draft_indicator = is_draft_folder and '' or ''
      
      local line = string.format('%s%s%s | %s  %s', checkbox, draft_indicator, display_field, subject, date)
      table.insert(lines, line)
      
      -- Store email metadata for highlighting
      if not lines.metadata then lines.metadata = {} end
      
      -- Validate email_id before storing (allow local draft IDs and maildir filenames)
      if email_id and (tonumber(email_id) or tostring(email_id):match('^draft_') or 
                      (is_draft_folder and tostring(email_id):match('%..*,.*:2,'))) then
        lines.metadata[#lines] = {
          type = 'email',  -- Add type field for regular emails
          seen = seen,
          starred = starred,
          email_index = i,
          email_id = email_id,
          selected = is_selected,
          from_start = #checkbox + #draft_indicator + 1,  -- Start position of author/recipient field
          from_end = #checkbox + #draft_indicator + #display_field,  -- End position of author/recipient field
          is_draft = is_draft_folder,  -- Flag for draft detection
          draft_folder = is_draft_folder and draft_folder or nil,  -- Store draft folder for cleanup
          is_local = email.is_local  -- Store local flag
        }
      else
        -- Log invalid email ID
        logger.warn('Invalid email ID detected', {
          email_id = email_id,
          email_index = i,
          subject = email.subject,
          from = from
        })
      end
    else
      -- Log invalid email but continue
      local logger = require('neotex.plugins.tools.himalaya.core.logger')
      logger.warn('Invalid email structure at index ' .. i, { email = email })
    end
  end
  
  -- Store the email start line for easier access
  lines.email_start_line = email_start_line
  
  -- Add scheduled emails section
  local scheduler = require("neotex.plugins.tools.himalaya.data.scheduler")
  local scheduled_items = scheduler.get_scheduled_emails()
  
  if #scheduled_items > 0 then
    -- Add visual separator
    table.insert(lines, "")
    table.insert(lines, string.rep("─", 26) .. " Scheduled (" .. #scheduled_items .. ") " .. string.rep("─", 26))
    table.insert(lines, "")
    
    -- Store where scheduled emails start
    local scheduled_start_line = #lines + 1
    
    -- Add each scheduled email with countdown
    for i, item in ipairs(scheduled_items) do
      local line_num = #lines + 1
      local countdown
      
      if item.status == "paused" then
        countdown = " PAUSED"
      else
        local time_left = item.scheduled_for - os.time()
        countdown = scheduler.format_countdown(time_left)
      end
      
      -- Store metadata for navigation
      if not lines.metadata then lines.metadata = {} end
      lines.metadata[line_num] = {
        type = 'scheduled',
        id = item.id,
        email_data = item.email_data,
        scheduled_for = item.scheduled_for,
        email_index = i + #emails,  -- Continue index from regular emails
        status = item.status
      }
      
      -- Format: [countdown] [subject] to [recipient]
      local subject = item.email_data.subject or "No subject"
      if #subject > 30 then
        subject = subject:sub(1, 27) .. "..."
      end
      
      local to = item.email_data.to or ""
      if #to > 25 then
        to = to:sub(1, 22) .. "..."
      end
      
      table.insert(lines, string.format(" %s   %-30s to %s", 
        countdown, subject, to))
    end
    
    -- Store scheduled section info
    lines.scheduled_start_line = scheduled_start_line
    lines.scheduled_count = #scheduled_items
    
    -- Start countdown timer if not already running
    if not scheduled_timer then
      M.start_scheduled_updates()
    end
  end
  
  -- Footer with keymaps
  table.insert(lines, '')
  table.insert(lines, string.rep('─', 70))
  
  -- Check if cursor is on a scheduled email (for context-aware footer)
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local line_data = lines.metadata and lines.metadata[current_line]
  local is_on_scheduled = line_data and line_data.type == 'scheduled'
  
  -- Show compact help footer with new keymaps
  table.insert(lines, '<C-d>/<C-u>:page | n/p:select | F:refresh | <leader>m:actions | gH:help')
  
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
      message = message .. string.format(": %d/%d Folders", 
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
  
  -- Use adaptive refresh intervals based on sync status
  local function get_refresh_interval()
    local manager = require('neotex.plugins.tools.himalaya.sync.manager')
    local sync_info = manager.get_sync_info()
    
    -- If sync is running, use 10-second intervals to reduce UI churn during sync
    if sync_info.type and sync_info.status == 'running' then
      return 10000  -- 10 seconds during sync
    else
      return 5000   -- 5 seconds when idle
    end
  end
  
  -- Start new timer with adaptive intervals
  local function start_timer()
    local interval = get_refresh_interval()
    sync_status_timer = vim.fn.timer_start(interval, function()
      M.update_sidebar_sync_status()
      
      -- Restart timer with potentially new interval
      M.stop_sync_status_updates()
      start_timer()
    end)
  end
  
  start_timer()
end

-- Stop sync status updates
function M.stop_sync_status_updates()
  if sync_status_timer then
    vim.fn.timer_stop(sync_status_timer)
    sync_status_timer = nil
  end
end

-- Start scheduled email countdown updates
function M.start_scheduled_updates()
  -- Stop existing timer if any
  if scheduled_timer then
    vim.fn.timer_stop(scheduled_timer)
    scheduled_timer = nil
  end
  
  -- Update every second for smooth countdown
  scheduled_timer = vim.fn.timer_start(1000, function()
    vim.schedule(function()
      -- Only update if sidebar is open
      if not sidebar.is_open() then
        return
      end
      
      local scheduler = require("neotex.plugins.tools.himalaya.data.scheduler")
      local scheduled_items = scheduler.get_scheduled_emails()
      
      if #scheduled_items == 0 then
        -- No scheduled emails, stop timer
        vim.fn.timer_stop(scheduled_timer)
        scheduled_timer = nil
        return
      end
      
      -- Update only the scheduled section lines
      M.update_scheduled_section()
    end)
  end, { ['repeat'] = -1 })
end

-- Stop scheduled updates
function M.stop_scheduled_updates()
  if scheduled_timer then
    vim.fn.timer_stop(scheduled_timer)
    scheduled_timer = nil
  end
end

-- Efficient update of just the scheduled section
function M.update_scheduled_section()
  local buf = sidebar.get_buf()
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local metadata = state.get('email_list.line_map') or {}
  
  -- Find where scheduled section starts
  local scheduled_start = nil
  local scheduled_header_line = nil
  for i, line in ipairs(lines) do
    if line:match("─+ Scheduled %(") then
      scheduled_header_line = i
      scheduled_start = i + 2  -- Skip header and blank line
      break
    end
  end
  
  if not scheduled_start then 
    return 
  end
  
  -- Update header with current count
  local scheduler = require("neotex.plugins.tools.himalaya.data.scheduler")
  local scheduled_items = scheduler.get_scheduled_emails()
  
  if scheduled_header_line then
    local new_header = string.rep("─", 26) .. " Scheduled (" .. #scheduled_items .. ") " .. string.rep("─", 26)
    -- Make buffer modifiable temporarily
    local modifiable = vim.bo[buf].modifiable
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, scheduled_header_line - 1, scheduled_header_line, false, {new_header})
    vim.bo[buf].modifiable = modifiable
  end
  
  -- Update only the countdown timers in place
  for i, item in ipairs(scheduled_items) do
    local line_idx = scheduled_start + i - 1
    local countdown
    
    if item.status == "paused" then
      countdown = " PAUSED"
    else
      local time_left = item.scheduled_for - os.time()
      countdown = scheduler.format_countdown(time_left)
    end
    
    -- Get current line
    if line_idx <= #lines then
      local current_line = lines[line_idx]
      if current_line then
        -- Find the start of the subject (after countdown and 3 spaces)
        -- Format is: " [countdown]   [subject] to [recipient]"
        local subject_start = string.find(current_line, "   ", 2) -- Find "   " after countdown
        local updated_line
        if subject_start then
          local rest_of_line = current_line:sub(subject_start)
          updated_line = " " .. countdown .. rest_of_line
        else
          -- Fallback: just update countdown portion if pattern not found
          updated_line = " " .. countdown .. current_line:sub(string.len(countdown) + 2)
        end
        
        -- Make buffer modifiable temporarily
        local modifiable = vim.bo[buf].modifiable
        vim.bo[buf].modifiable = true
        vim.api.nvim_buf_set_lines(buf, line_idx - 1, line_idx, false, {updated_line})
        vim.bo[buf].modifiable = modifiable
      end
    end
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
  
  -- Get email count from stored sync data
  local total_emails = state.get_folder_count(account_name, folder_name)
  if not total_emails or total_emails == 0 then
    -- Fallback to stored total
    total_emails = state.get_total_emails()
    if not total_emails or total_emails == 0 then
      -- Last resort - show we don't know
      total_emails = nil
    end
  end
  
  local page_size = state.get_page_size()
  local current_page = state.get_current_page()
  
  local pagination_info
  if total_emails then
    -- We know the exact count
    local total_pages = math.max(1, math.ceil(total_emails / page_size))
    
    -- Format count display with optional age indicator
    local count_age = state.get_folder_count_age(account_name, folder_name)
    local count_display
    
    if count_age and count_age > 600 then  -- Show age if older than 10 minutes
      local age_str
      if count_age < 3600 then
        age_str = string.format('%dm ago', math.floor(count_age / 60))
      elseif count_age < 86400 then
        age_str = string.format('%dh ago', math.floor(count_age / 3600))
      else
        age_str = string.format('%dd ago', math.floor(count_age / 86400))
      end
      count_display = string.format('%d emails (%s)', total_emails, age_str)
    else
      count_display = string.format('%d emails', total_emails)
    end
    
    pagination_info = string.format('Page %d / %d | %s', 
      current_page, total_pages, count_display)
  else
    -- We don't know the exact count
    -- Get stored emails from state to check if we have a full page
    local stored_emails = state.get('email_list.emails')
    local email_count = stored_emails and #stored_emails or 0
    
    if email_count >= page_size then
      -- Full page, might be more
      pagination_info = string.format('Page %d / ? | %d+ emails', 
        current_page, current_page * page_size)
    else
      -- Less than a page, this is all
      pagination_info = string.format('Page %d / %d | %d emails', 
        current_page, current_page, email_count)
    end
  end
  
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
  -- Use a fixed width separator to prevent visual jumping
  local separator_width = 70  -- Reasonable width that accommodates most content
  table.insert(header_lines, string.rep('─', separator_width))
  
  -- Only add blank line when NOT syncing (must be included in header_lines)
  if not sync_status_line then
    table.insert(header_lines, '')
  end
  
  -- Use optimized header update
  sidebar.update_header_lines(header_lines)
end

-- Helper function to reset pagination
function M.reset_pagination()
  state.set_current_page(1)
end

-- Navigation functions
function M.next_page()
  local total_emails = state.get_total_emails()
  local current_page = state.get_current_page()
  local page_size = state.get_page_size()

  -- Allow pagination when total is unknown (0) or when there are more pages
  -- When total is 0, we don't know if there are more emails, so allow advancing
  if total_emails == 0 or total_emails == nil or current_page * page_size < total_emails then
    state.set_current_page(current_page + 1)
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
function M.refresh_email_list(opts)
  opts = opts or {}
  
  -- Sync scheduled emails from other instances before refresh
  local scheduler = require("neotex.plugins.tools.himalaya.data.scheduler")
  if scheduler.initialized then
    scheduler.sync_from_disk()
  end
  
  -- Save current window and mode to restore focus
  local current_win = vim.api.nvim_get_current_win()
  local current_buf = vim.api.nvim_get_current_buf()
  local current_mode = vim.api.nvim_get_mode().mode
  local was_insert_mode = (current_mode == 'i' or current_mode == 'ic' or current_mode == 'ix')
  local should_restore_insert = opts.restore_insert_mode ~= false and was_insert_mode
  local cursor_pos = vim.api.nvim_win_get_cursor(current_win)
  
  -- Check if we're in a compose buffer
  local email_composer = require('neotex.plugins.tools.himalaya.ui.email_composer')
  local is_compose_buffer = email_composer.is_compose_buffer(current_buf)
  
  -- Get current sidebar buffer
  local buf = sidebar.get_buf()
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    -- No sidebar open, don't open it
    return
  else
    -- Sidebar is open, do optimized refresh
    local account_name = config.get_current_account_name()
    if not account_name then
      return
    end
    
    local folder = state.get_current_folder()
    
    -- Check if this is drafts folder for special handling
    local draft_folder = utils.find_draft_folder(account_name)
    local is_drafts = folder == draft_folder
    
    if is_drafts then
      -- For drafts, use filesystem as single source of truth
      M.show_email_list({ folder })
      
      -- Restore focus for drafts folder too
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(current_win) and vim.api.nvim_buf_is_valid(current_buf) then
          -- Set focus back to original window
          vim.api.nvim_set_current_win(current_win)
          
          -- Restore cursor position if it was moved
          local ok, _ = pcall(vim.api.nvim_win_set_cursor, current_win, cursor_pos)
          if not ok then
            -- If cursor position is invalid, just go to line 1
            pcall(vim.api.nvim_win_set_cursor, current_win, {1, 0})
          end
          
          -- If we were in insert mode, restore it (unless in test mode)
          if should_restore_insert and not _G.HIMALAYA_TEST_MODE then
            vim.cmd('startinsert')
          end
        end
      end)
      return
    end
    
    -- Get email list from himalaya (async for responsiveness)
    utils.get_emails_async(account_name, folder, state.get_current_page(), state.get_page_size(), function(emails, total_count, error)
      if error then
        notify.himalaya('Failed to refresh email list: ' .. tostring(error), notify.categories.ERROR)
        return
      end
      
      if emails then
        -- Clear draft folder cache first to ensure fresh data
        local draft_folder = utils.find_draft_folder(account_name)
        if folder == draft_folder then
          logger.info('Clearing draft folder cache in refresh')
          email_cache.clear_folder(account_name, folder)
        end
        
        -- Store emails in cache
        email_cache.store_emails(account_name, folder, emails)
        
        -- Store total count
        if total_count and total_count > 0 then
          state.set_total_emails(total_count)
          
          -- Only store as folder count if it's an exact count
          local page_size = state.get_page_size()
          if emails and #emails < page_size then
            state.set_folder_count(account_name, folder, total_count)
          end
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
    end)
  end
  
  -- Restore focus to original window if it's still valid
  -- Use vim.schedule_wrap to ensure this happens after all other scheduled operations
  vim.schedule(function()
    if vim.api.nvim_win_is_valid(current_win) and vim.api.nvim_buf_is_valid(current_buf) then
      -- Set focus back to original window
      vim.api.nvim_set_current_win(current_win)
      
      -- Restore cursor position if it was moved
      local ok, _ = pcall(vim.api.nvim_win_set_cursor, current_win, cursor_pos)
      if not ok then
        -- If cursor position is invalid, just go to line 1
        pcall(vim.api.nvim_win_set_cursor, current_win, {1, 0})
      end
      
      -- If we were in insert mode, restore it (unless in test mode)
      if should_restore_insert and not _G.HIMALAYA_TEST_MODE then
        vim.cmd('startinsert')
      end
    end
  end)
end

-- Fast selection display update (no server calls)
function M.update_selection_display()
  -- Get current sidebar buffer
  local buf = sidebar.get_buf()
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  
  -- Get current email data from state
  local emails = state.get('email_list.emails')
  if not emails then
    return
  end
  
  -- Check if we're in drafts folder to preserve filesystem data
  local current_folder = state.get_current_folder()
  local account_name = state.get_current_account()
  local draft_folder = utils.find_draft_folder(account_name)
  local is_drafts = current_folder == draft_folder
  
  -- For drafts, ensure we have the filesystem data preserved
  if is_drafts and emails[1] and emails[1].draft_filepath then
    -- We have filesystem-based drafts, good to proceed
  end
  
  -- Format email list with current selections and update display
  local lines = M.format_email_list(emails)
  sidebar.update_content(lines)
  
  -- Update line mapping in state
  state.set('email_list.line_map', lines.metadata or {})
end

-- Update email display
function M.update_email_display()
  -- Get email list with smart page filling
  local emails, total_count, actual_page = utils.get_email_list_smart_fill(
    state.get_current_account(),
    state.get_current_folder(),
    state.get_current_page(),
    state.get_page_size()
  )
  if not emails then
    notify.himalaya('Failed to get email list', notify.categories.ERROR)
    return
  end
  
  -- Update page if it was adjusted during smart fill
  if actual_page and actual_page ~= state.get_current_page() then
    state.set_current_page(actual_page)
  end
  
  -- Update total count if available
  if total_count and total_count > 0 then
    state.set_total_emails(total_count)
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
  
  -- Don't auto-focus sidebar - let user control focus
  -- sidebar.focus()
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
  local STATES = email_preview.PREVIEW_STATE

  -- CursorMoved - update preview in SWITCH mode (immediate, for j/k navigation)
  vim.api.nvim_create_autocmd('CursorMoved', {
    buffer = buf,
    callback = function()
      -- Only update preview in SWITCH mode
      if not email_preview.is_mode(STATES.SWITCH) then
        return
      end

      local line = vim.api.nvim_win_get_cursor(0)[1]
      local email_id = M.get_email_id_from_line(line)

      if email_id then
        -- Check if this is a different email than currently previewed
        local current_preview_id = email_preview.get_current_preview_id()
        if tostring(email_id) ~= tostring(current_preview_id) then
          -- Get email type from metadata
          local metadata = state.get('email_list.line_map') or {}
          local line_data = metadata[line]
          local email_type = 'regular'
          local local_id = nil

          if line_data then
            if line_data.type == 'scheduled' then
              email_type = 'scheduled'
            elseif line_data.is_draft then
              email_type = 'draft'
              local_id = line_data.is_local and line_data.email_id or nil
            end
          end

          -- Update preview to show new email
          email_preview.show_preview(email_id, sidebar_win, email_type, local_id)
        end
      end
    end
  })

  -- CursorHold - show preview after delay (legacy behavior, for preview_mode compat)
  vim.api.nvim_create_autocmd('CursorHold', {
    buffer = buf,
    callback = function()
      if not email_preview.config.enabled then return end
      -- Only trigger on CursorHold if in legacy preview_mode
      if not email_preview.is_preview_mode() then return end
      -- Don't trigger if already in SWITCH or FOCUS mode (handled by CursorMoved)
      if email_preview.is_mode(STATES.SWITCH) or email_preview.is_mode(STATES.FOCUS) then
        return
      end

      local line = vim.api.nvim_win_get_cursor(0)[1]
      local email_id = M.get_email_id_from_line(line)

      if email_id then
        -- Check if this is a scheduled email
        local metadata = state.get('email_list.line_map') or {}
        local line_data = metadata[line]
        local email_type = line_data and line_data.type or 'regular'

        email_preview.show_preview(email_id, sidebar_win, email_type)
      end
    end
  })

  -- Preview updates are handled by config.lua mouse and cursor handlers
end

-- Helper function to get the current lines object with metadata
function M.get_current_lines()
  local buf = sidebar.get_buf()
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return nil
  end

  -- Try to get from buffer first
  local lines = vim.b[buf].himalaya_lines
  -- Handle vim.NIL case
  if lines == vim.NIL then
    lines = nil
  end
  if lines and type(lines) == 'table' and lines.metadata then
    return lines
  end

  -- Fallback to state
  local metadata = state.get('email_list.line_map')
  if not metadata or metadata == vim.NIL then
    return nil
  end

  -- Ensure metadata is a proper table
  if type(metadata) ~= 'table' then
    return nil
  end

  return {
    metadata = metadata
  }
end

-- Handle enter key press (implements 3-state progressive preview model)
-- OFF -> SWITCH (first CR): Opens preview, j/k switches emails
-- SWITCH -> FOCUS (second CR): Focuses preview, j/k scrolls content
-- FOCUS -> BUFFER_OPEN (third CR): Opens email in full buffer
function M.handle_enter()
  local current_mode = email_preview.get_mode()
  local STATES = email_preview.PREVIEW_STATE

  -- Get current line data
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  local email_id = M.get_email_id_from_line(line_num)

  -- Get line metadata for type detection
  local metadata = state.get('email_list.line_map') or {}
  local line_data = metadata[line_num]

  -- Handle scheduled emails specially
  if line_data and line_data.type == 'scheduled' then
    -- For scheduled emails, show preview with scheduled info
    local scheduler = require("neotex.plugins.tools.himalaya.data.scheduler")
    -- Show scheduled email in preview
    if current_mode == STATES.OFF then
      email_preview.enter_switch_mode(line_data.id, sidebar.get_win(), 'scheduled')
    elseif current_mode == STATES.SWITCH then
      email_preview.enter_focus_mode()
    elseif current_mode == STATES.FOCUS then
      -- For scheduled emails, maybe open edit dialog instead of buffer
      notify.himalaya('Scheduled email - use gE to edit schedule', notify.categories.STATUS)
    end
    return
  end

  -- Handle regular emails and drafts
  if current_mode == STATES.OFF then
    -- First CR: Enter SWITCH mode (show preview)
    if not email_id then
      notify.himalaya('No email on this line', notify.categories.STATUS)
      return
    end

    -- Determine email type
    local email_type = 'regular'
    local local_id = nil
    if line_data then
      if line_data.is_draft then
        email_type = 'draft'
        local_id = line_data.is_local and line_data.email_id or nil
      end
    end

    email_preview.enter_switch_mode(email_id, sidebar.get_win(), email_type, local_id)

  elseif current_mode == STATES.SWITCH then
    -- Second CR: Enter FOCUS mode (focus preview window)
    email_preview.enter_focus_mode()

  elseif current_mode == STATES.FOCUS then
    -- Third CR: Open email in full buffer
    email_preview.open_email_in_buffer()
  end
end

-- Toggle email selection
function M.toggle_selection()
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  local email_id = M.get_email_id_from_line(line_num)

  if not email_id then
    notify.himalaya('No email on this line', notify.categories.STATUS)
    return
  end

  -- Get email data from cache
  local emails = state.get('email_list.emails') or {}
  local email_data = nil

  -- Find the email in the list
  for _, email in ipairs(emails) do
    if tostring(email.id) == tostring(email_id) then
      email_data = email
      break
    end
  end

  if not email_data then
    logger.warn('Email not found in list', { email_id = email_id })
    return
  end

  -- Toggle selection in state
  state.toggle_email_selection(email_id, email_data)

  -- Update display to show new selection state
  M.update_selection_display()

  -- Provide feedback
  local is_selected = state.is_email_selected(email_id)
  local count = state.get_selection_count()
  if is_selected then
    notify.himalaya(string.format('Selected (%d total)', count), notify.categories.STATUS)
  else
    notify.himalaya(string.format('Deselected (%d total)', count), notify.categories.STATUS)
  end
end

-- Select email (add to selection)
function M.select_email()
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  local email_id = M.get_email_id_from_line(line_num)

  if not email_id then
    -- No email on this line, just move down anyway
    vim.cmd('normal! j')
    return
  end

  -- Get email data from cache
  local emails = state.get('email_list.emails') or {}
  local email_data = nil

  -- Find the email in the list
  for _, email in ipairs(emails) do
    if tostring(email.id) == tostring(email_id) then
      email_data = email
      break
    end
  end

  if not email_data then
    logger.warn('Email not found in list', { email_id = email_id })
    vim.cmd('normal! j')
    return
  end

  -- Toggle selection
  state.toggle_email_selection(email_id, email_data)

  -- Update display
  M.update_selection_display()

  -- Provide feedback
  local count = state.get_selection_count()
  local is_selected = state.is_email_selected(email_id)
  local action = is_selected and 'Selected' or 'Deselected'
  notify.himalaya(string.format('%s (%d total)', action, count), notify.categories.STATUS)

  -- Move cursor down for rapid multi-selection
  vim.cmd('normal! j')
end

-- Deselect email (toggle selection and move up)
function M.deselect_email()
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  local email_id = M.get_email_id_from_line(line_num)

  if not email_id then
    -- No email on this line, just move up anyway
    vim.cmd('normal! k')
    return
  end

  -- Get email data from cache
  local emails = state.get('email_list.emails') or {}
  local email_data = nil

  -- Find the email in the list
  for _, email in ipairs(emails) do
    if tostring(email.id) == tostring(email_id) then
      email_data = email
      break
    end
  end

  if not email_data then
    logger.warn('Email not found in list', { email_id = email_id })
    vim.cmd('normal! k')
    return
  end

  -- Toggle selection
  state.toggle_email_selection(email_id, email_data)

  -- Update display
  M.update_selection_display()

  -- Provide feedback
  local count = state.get_selection_count()
  local is_selected = state.is_email_selected(email_id)
  local action = is_selected and 'Selected' or 'Deselected'
  notify.himalaya(string.format('%s (%d total)', action, count), notify.categories.STATUS)

  -- Always move cursor up for navigation
  vim.cmd('normal! k')
end

return M
