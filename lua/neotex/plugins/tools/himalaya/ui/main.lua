-- Himalaya Email Client UI
-- Main UI module that delegates to specialized components

local M = {}

-- Dependencies
local config = require('neotex.plugins.tools.himalaya.core.config')
local utils = require('neotex.plugins.tools.himalaya.utils')
local state = require('neotex.plugins.tools.himalaya.core.state')
local notifications = require('neotex.plugins.tools.himalaya.ui.notifications')
local email_list = require('neotex.plugins.tools.himalaya.ui.email_list')
local email_composer = require('neotex.plugins.tools.himalaya.ui.email_composer')
local email_preview = require('neotex.plugins.tools.himalaya.ui.email_preview')
local notify = require('neotex.util.notifications')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
local window_stack = require('neotex.plugins.tools.himalaya.ui.window_stack')

-- New modules
local coordinator = require('neotex.plugins.tools.himalaya.ui.coordinator')
local session = require('neotex.plugins.tools.himalaya.ui.session')

-- Initialize UI components
function M.init()
  -- Initialize coordinator which handles component initialization
  coordinator.init()
  
  -- Initialize session management
  session.init(config.config)
end

-- Buffer tracking (delegate to coordinator)
M.buffers = setmetatable({}, {
  __index = function(_, key)
    return coordinator.get_buffers()[key]
  end,
  __newindex = function(_, key, value)
    coordinator.set_buffer(key, value)
  end
})

-- Toggle email sidebar
function M.toggle_email_sidebar()
  return email_list.toggle_email_sidebar()
end

function M.show_email_list(args)
  return email_list.show_email_list(args)
end

-- Format email list for display (matching old UI exactly)
function M.format_email_list(emails)
  return email_list.format_email_list(emails)
end

-- Get sync status line for header
function M.get_sync_status_line()
  return email_list.get_sync_status_line()
end

-- Get sync status line for header with enhanced progress information (from old UI)
function M.get_sync_status_line_detailed()
  return email_list.get_sync_status_line_detailed()
end
-- Start sync status updates
function M.start_sync_status_updates()
  return email_list.start_sync_status_updates()
end

-- Stop sync status updates
function M.stop_sync_status_updates()
  return email_list.stop_sync_status_updates()
end

-- Update sidebar with current sync status
function M.update_sidebar_sync_status()
  return email_list.update_sidebar_sync_status()
end

-- Refresh just the sidebar header (without refetching emails)
function M.refresh_sidebar_header()
  return email_list.refresh_sidebar_header()
end

-- Compose new email (delegate to coordinator)
function M.compose_email(to_address)
  local buf = email_composer.create_compose_buffer({ to = to_address })
  return coordinator.open_compose_buffer_in_window(buf)
end

-- Open email window (delegate to coordinator)
function M.open_email_window(buf, title, parent_win)
  return coordinator.open_email_window(buf, title, parent_win)
end

-- Pagination functions
function M.reset_pagination()
  state.set_current_page(1)
end

function M.next_page()
  return email_list.next_page()
end

function M.prev_page()
  return email_list.prev_page()
end

-- Refresh current email list
function M.refresh_email_list(opts)
  return email_list.refresh_email_list(opts)
end

-- Send current email (from compose buffer)
function M.send_current_email()
  local buf = vim.api.nvim_get_current_buf()
  if email_composer.is_compose_buffer(buf) then
    return email_composer.send_email(buf)
  end
  notify.himalaya('Not in a compose buffer', notify.categories.ERROR)
end

-- Check if email buffer is open (for backward compatibility)
function M.is_email_buffer_open()
  return sidebar.is_open()
end

-- Close without saving (discard)
function M.close_without_saving()
  local buf = vim.api.nvim_get_current_buf()
  
  if email_composer.is_compose_buffer(buf) then
    return email_composer.discard_email(buf)
  end
  
  -- Original implementation for non-compose buffers
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
  
  -- Restore focus using coordinator
  coordinator.restore_focus(buf, parent_win, parent_buf)
  
  notify.himalaya('Draft discarded', notify.categories.STATUS)
end

-- Navigate to next field in compose buffer
function M.compose_next_field()
  return email_composer.compose_next_field()
end

-- Navigate to previous field in compose buffer
function M.compose_prev_field()
  return email_composer.compose_prev_field()
end

-- Close and save as draft
function M.close_and_save_draft()
  local buf = vim.api.nvim_get_current_buf()
  
  if email_composer.is_compose_buffer(buf) then
    -- Save the draft first
    email_composer.save_draft(buf)
    
    -- Then close the compose buffer after a short delay to ensure save completes
    vim.defer_fn(function()
      email_composer.close_compose_buffer(buf)
    end, 200)
    return
  end
  
  -- Original implementation for non-compose buffers
  local parent_win = vim.b[buf].himalaya_parent_win
  local parent_buf = vim.b[buf].himalaya_parent_buf
  
  -- Close the current window
  local current_win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_is_valid(current_win) then
    vim.api.nvim_win_close(current_win, true)
  end
  
  -- Restore focus using coordinator
  coordinator.restore_focus(buf, parent_win, parent_buf)
end


-- Helper function to get current email ID
function M.get_current_email_id()
  -- Check if we have a preview_email_id set (from preview window actions)
  local preview_email_id = state.get('preview_email_id')
  if preview_email_id then
    -- Clear it after use
    state.set('preview_email_id', nil)
    return preview_email_id
  end
  
  -- Check if we're in preview window
  if vim.bo.filetype == 'himalaya-email' then
    local preview = require('neotex.plugins.tools.himalaya.ui.email_preview')
    local preview_state = preview.get_preview_state()
    if preview_state and preview_state.email_id then
      return preview_state.email_id
    end
  end
  
  if vim.bo.filetype ~= 'himalaya-list' then
    return nil
  end
  
  local line_num = vim.fn.line('.')
  local current_line = vim.fn.getline('.')
  
  -- Debug logging
  local logger = require('neotex.plugins.tools.himalaya.core.logger')
  logger.debug('get_current_email_id', {
    line_num = line_num,
    current_line = current_line,
    current_folder = state.get_current_folder()
  })
  
  -- Check if we're on a header line by content
  if current_line:match('^Himalaya%s*-') or current_line:match('^Page%s*%d+') or current_line:match('^[─]+$') then
    logger.debug('Cursor is on header/separator line')
    return nil
  end
  
  -- Use the line map from state
  local line_map = state.get('email_list.line_map')
  if line_map and line_map[line_num] then
    local metadata = line_map[line_num]
    logger.debug('Found metadata for line', {
      line_num = line_num,
      metadata = metadata
    })
    -- Handle both regular emails (email_id) and scheduled emails (id)
    local id = line_map[line_num].email_id or line_map[line_num].id
    logger.debug('Returning email ID from line_map', {
      id = id,
      id_type = type(id)
    })
    return id
  end
  
  -- Fallback to old method if line map not available
  local emails = state.get('email_list.emails')
  local email_start_line = state.get('email_list.email_start_line')
  
  logger.debug('Fallback method for get_current_email_id', {
    has_emails = emails ~= nil,
    email_count = emails and #emails or 0,
    email_start_line = email_start_line
  })
  
  if not emails or #emails == 0 then
    logger.debug('No emails found in state')
    return nil
  end
  
  -- Additional check: if we're on a header line, return nil
  if email_start_line and line_num < email_start_line then
    logger.debug('Cursor is on header line, not an email', {
      line_num = line_num,
      email_start_line = email_start_line
    })
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
    local email = emails[email_index]
    local id = email.id
    
    -- Extra validation to prevent folder names
    if type(id) == 'string' and (id == 'Drafts' or id == state.get_current_folder()) then
      logger.error('Email has folder name as ID', {
        email_index = email_index,
        id = id,
        email = email
      })
      return nil
    end
    
    logger.debug('Returning email ID from fallback method', {
      email_index = email_index,
      id = id,
      id_type = type(id)
    })
    return id
  end
  
  logger.debug('No email ID found for line', {
    line_num = line_num,
    email_index = email_index,
    emails_count = #emails,
    email_start_line = email_start_line
  })
  return nil
end

-- Close current view (delegate to coordinator)
function M.close_current_view()
  return coordinator.close_current_view()
end

-- Close Himalaya entirely (delegate to coordinator)
function M.close_himalaya()
  -- Save session before closing
  session.save_session()
  
  -- Delegate to coordinator for cleanup
  coordinator.close_himalaya()
end

-- Update email display without resetting pagination
function M.update_email_display()
  return email_list.update_email_display()
end

-- Refresh current view
function M.refresh_current_view()
  return email_list.refresh_current_view()
end

-- Reply to current email
function M.reply_current_email()
  -- Get current email ID (handles both sidebar and preview)
  local email_id = M.get_current_email_id()

  if not email_id then
    -- Provide detailed diagnostic message
    local filetype = vim.bo.filetype
    local line_num = vim.fn.line('.')
    local line_map = state.get('email_list.line_map')
    local emails = state.get('email_list.emails')

    logger.error('reply_current_email: No email ID found', {
      filetype = filetype,
      line_num = line_num,
      has_line_map = line_map ~= nil,
      line_map_count = line_map and vim.tbl_count(line_map) or 0,
      has_emails = emails ~= nil,
      emails_count = emails and #emails or 0,
      current_folder = state.get_current_folder()
    })

    local msg = 'No email to reply to'
    if filetype ~= 'himalaya-list' and filetype ~= 'himalaya-email' then
      msg = msg .. ' (not in email buffer: ' .. filetype .. ')'
    elseif not line_map or vim.tbl_count(line_map) == 0 then
      msg = msg .. ' (email list not loaded)'
    end
    notify.himalaya(msg, notify.categories.ERROR)
    return
  end

  local account = state.get_current_account()
  local folder = state.get_current_folder()
  local email = utils.get_email_by_id(account, folder, email_id)

  if not email then
    logger.error('reply_current_email: Email not found', {
      email_id = email_id,
      account = account,
      folder = folder
    })
    notify.himalaya('Email not found (ID: ' .. tostring(email_id) .. ')', notify.categories.ERROR)
    return
  end

  -- Debug: log what we got
  logger.debug('Reply email data', {
    id = email.id,
    has_body = email.body ~= nil,
    body_length = email.body and #email.body or 0
  })
  local buf = email_composer.reply_to_email(email, false)
  return coordinator.open_compose_buffer_in_window(buf, { position_to_body = true })
end

-- Reply all to current email
function M.reply_all_current_email()
  -- Get current email ID (handles both sidebar and preview)
  local email_id = M.get_current_email_id()

  if not email_id then
    -- Provide detailed diagnostic message
    local filetype = vim.bo.filetype
    local line_num = vim.fn.line('.')
    local line_map = state.get('email_list.line_map')
    local emails = state.get('email_list.emails')

    logger.error('reply_all_current_email: No email ID found', {
      filetype = filetype,
      line_num = line_num,
      has_line_map = line_map ~= nil,
      line_map_count = line_map and vim.tbl_count(line_map) or 0,
      has_emails = emails ~= nil,
      emails_count = emails and #emails or 0,
      current_folder = state.get_current_folder()
    })

    local msg = 'No email to reply to'
    if filetype ~= 'himalaya-list' and filetype ~= 'himalaya-email' then
      msg = msg .. ' (not in email buffer: ' .. filetype .. ')'
    elseif not line_map or vim.tbl_count(line_map) == 0 then
      msg = msg .. ' (email list not loaded)'
    end
    notify.himalaya(msg, notify.categories.ERROR)
    return
  end

  local account = state.get_current_account()
  local folder = state.get_current_folder()
  local email = utils.get_email_by_id(account, folder, email_id)

  if not email then
    logger.error('reply_all_current_email: Email not found', {
      email_id = email_id,
      account = account,
      folder = folder
    })
    notify.himalaya('Email not found (ID: ' .. tostring(email_id) .. ')', notify.categories.ERROR)
    return
  end

  -- Debug: log what we got
  logger.debug('Reply all email data', {
    id = email.id,
    has_body = email.body ~= nil,
    body_length = email.body and #email.body or 0
  })
  local buf = email_composer.reply_to_email(email, true)
  return coordinator.open_compose_buffer_in_window(buf, { position_to_body = true })
end

-- Reply to email
function M.reply_email(email_id, reply_all)
  local account = state.get_current_account()
  local folder = state.get_current_folder()
  local email = utils.get_email_by_id(account, folder, email_id)
  if email then
    local buf = email_composer.reply_to_email(email, reply_all)
    return coordinator.open_compose_buffer_in_window(buf, { position_to_body = true })
  end
  notify.himalaya('Email not found', notify.categories.ERROR)
end

-- Parse email content for reply operations
function M.parse_email_for_reply(email_content)
  return email_composer.parse_email_for_reply(email_content)
end

-- Forward current email
function M.forward_current_email()
  -- Get current email ID (handles both sidebar and preview)
  local email_id = M.get_current_email_id()

  if not email_id then
    -- Provide detailed diagnostic message
    local filetype = vim.bo.filetype
    local line_num = vim.fn.line('.')
    local line_map = state.get('email_list.line_map')
    local emails = state.get('email_list.emails')

    logger.error('forward_current_email: No email ID found', {
      filetype = filetype,
      line_num = line_num,
      has_line_map = line_map ~= nil,
      line_map_count = line_map and vim.tbl_count(line_map) or 0,
      has_emails = emails ~= nil,
      emails_count = emails and #emails or 0,
      current_folder = state.get_current_folder()
    })

    local msg = 'No email to forward'
    if filetype ~= 'himalaya-list' and filetype ~= 'himalaya-email' then
      msg = msg .. ' (not in email buffer: ' .. filetype .. ')'
    elseif not line_map or vim.tbl_count(line_map) == 0 then
      msg = msg .. ' (email list not loaded)'
    end
    notify.himalaya(msg, notify.categories.ERROR)
    return
  end

  local account = state.get_current_account()
  local folder = state.get_current_folder()
  local email = utils.get_email_by_id(account, folder, email_id)

  if not email then
    logger.error('forward_current_email: Email not found', {
      email_id = email_id,
      account = account,
      folder = folder
    })
    notify.himalaya('Email not found (ID: ' .. tostring(email_id) .. ')', notify.categories.ERROR)
    return
  end

  local buf = email_composer.forward_email(email)
  return coordinator.open_compose_buffer_in_window(buf)
end

-- Shared sync implementation that handles OAuth refresh
function M._perform_sync(mbsync_target, display_name, callback)
  -- Use sync manager for consistent state management
  local sync_manager = require('neotex.plugins.tools.himalaya.sync.manager')
  local mbsync = require('neotex.plugins.tools.himalaya.sync.mbsync')
  
  notify.himalaya('Starting sync for ' .. display_name .. '...', notify.categories.STATUS)
  
  -- Start sync through manager
  sync_manager.start_sync('full', {
    channel = mbsync_target,
    account = state.get_current_account()
  })
  
  -- Start sidebar refresh timer
  local refresh_timer = nil
  if M.is_email_buffer_open() then
    refresh_timer = vim.fn.timer_start(5000, function()
      -- Refresh the entire sidebar to show updated sync progress
      local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
      if sidebar.is_open() then
        M.refresh_email_list()
      end
    end, { ['repeat'] = -1 })
  end
  
  -- Run mbsync with OAuth auto-refresh enabled
  mbsync.sync(mbsync_target, {
    auto_refresh = true,  -- Enable OAuth auto-refresh
    on_progress = function(progress)
      -- Update progress through manager
      sync_manager.update_progress(progress)
      
      if notifications and notifications.show_sync_progress then
        notifications.show_sync_progress(progress)
      end
    end,
    callback = function(success, error)
      -- Stop the refresh timer
      if refresh_timer then
        vim.fn.timer_stop(refresh_timer)
      end
      
      -- Complete sync through manager
      sync_manager.complete_sync('full', {
        success = success,
        error = error
      })
      
      if not success then
        notifications.handle_sync_error(error)
        -- Log error details in debug mode
        if notify.config.modules.himalaya.debug_mode and error then
          notify.himalaya('Sync error details: ' .. error, notify.categories.BACKGROUND)
        end
      else
        -- Clear cache
        utils.clear_email_cache()
        
        notify.himalaya('Sync completed for ' .. display_name, notify.categories.USER_ACTION)
        
        -- Count update is now handled by sync manager
        
        if M.is_email_buffer_open() then
          M.refresh_email_list()
        end
      end
      
      -- Final sidebar refresh
      if M.is_email_buffer_open() then
        M.refresh_email_list()
      end
      
      -- Call custom callback if provided
      if callback then
        callback(success)
      end
    end
  })
end

-- Sync current folder (for 'gs' keybinding)
function M.sync_current_folder()
  local account = state.get_current_account()
  local folder = state.get_current_folder()
  
  if not account or not folder then
    notify.himalaya('No folder selected', notify.categories.ERROR)
    return
  end
  
  -- Special handling for Drafts folder
  if folder == 'Drafts' or folder:lower():match('draft') then
    M.sync_drafts_folder(account, folder)
    return
  end
  
  -- Get account configuration
  local account_config = config.get_account(account)
  if not account_config then
    notify.himalaya('Account configuration not found', notify.categories.ERROR)
    return
  end
  
  -- Determine the mbsync channel/target
  local mbsync_target
  local display_name = folder
  if account:lower() == 'gmail' then
    -- Map folder to specific mbsync channels
    local folder_channels = {
      ['INBOX'] = 'gmail-inbox',
      ['Drafts'] = 'gmail-drafts',
      ['Sent'] = 'gmail-sent',
      ['Trash'] = 'gmail-trash',
      ['Spam'] = 'gmail-spam',
      ['All_Mail'] = 'gmail-all',
      ['Starred'] = 'gmail-starred',
      ['Important'] = 'gmail-important'
    }
    
    mbsync_target = folder_channels[folder]
    
    if not mbsync_target then
      -- Fallback to general sync if no specific channel
      mbsync_target = 'gmail'
      display_name = 'all folders'
      if notify.config.modules.himalaya.debug_mode then
        notify.himalaya('Note: No specific channel for ' .. folder .. ', syncing all folders', notify.categories.INFO)
      end
    end
  else
    -- For non-Gmail accounts, use account:folder format
    mbsync_target = string.format('%s:%s', account, folder)
  end
  
  -- Use shared sync implementation
  M._perform_sync(mbsync_target, display_name)
end

-- Sync inbox only (for <leader>ms keybinding)
function M.sync_inbox()
  local account = state.get_current_account()
  if not account then
    notify.himalaya('No email account configured', notify.categories.ERROR)
    return
  end

  local account_config = config.get_account(account)
  if not account_config then
    notify.himalaya('Account configuration not found', notify.categories.ERROR)
    return
  end

  -- Always use inbox channel
  local channel = account_config.mbsync and account_config.mbsync.inbox_channel or 'gmail-inbox'

  -- Use shared sync implementation
  M._perform_sync(channel, 'inbox')
end

-- Sync all folders (for <leader>mS and HimalayaSyncFull command)
function M.sync_all()
  local account = state.get_current_account()
  if not account then
    notify.himalaya('No email account configured', notify.categories.ERROR)
    return
  end

  local account_config = config.get_account(account)
  if not account_config then
    notify.himalaya('Account configuration not found', notify.categories.ERROR)
    return
  end

  -- Use the account name as mbsync target for full sync
  local mbsync_target = account:lower()

  -- Use shared sync implementation
  M._perform_sync(mbsync_target, 'all folders')
end

-- Sync drafts folder (handles local drafts)
function M.sync_drafts_folder(account, folder)
  -- Use mbsync like other folders for proper sync
  local mbsync_target
  if account:lower() == 'gmail' then
    mbsync_target = 'gmail-drafts'
  else
    mbsync_target = account .. ':Drafts'
  end
  
  -- Use shared sync implementation (mbsync) with special callback for drafts
  M._perform_sync(mbsync_target, 'drafts', function(success)
    if success then
      -- For drafts, ensure we continue using filesystem-based display
      -- The email_list module will detect we're in drafts folder and use filesystem
      vim.defer_fn(function()
        M.refresh_email_list()
      end, 100)
    end
  end)
end

-- Forward email
function M.forward_email(email_id)
  local account = state.get_current_account()
  local folder = state.get_current_folder()
  local email = utils.get_email_by_id(account, folder, email_id)
  if email then
    return email_composer.forward_email(email)
  end
  notify.himalaya('Email not found', notify.categories.ERROR)
end

-- Delete current email
function M.delete_current_email()
  local email_id = M.get_current_email_id()
  
  if not email_id then
    notify.himalaya('No email to delete', notify.categories.STATUS)
    return
  end
  
  -- Check if this is a draft
  local folder = state.get_current_folder()
  local draft_folder = require('neotex.plugins.tools.himalaya.utils').find_draft_folder(state.get_current_account())
  local is_draft = folder == draft_folder
  
  -- For filesystem-based drafts, we need to handle deletion differently
  local draft_filepath = nil
  if is_draft then
    -- Get the draft filepath from the email data
    local line_num = vim.fn.line('.')
    local line_map = state.get('email_list.line_map')
    local emails = state.get('email_list.emails')
    
    if line_map and line_map[line_num] and line_map[line_num].email_index then
      local email = emails[line_map[line_num].email_index]
      if email and email.draft_filepath then
        draft_filepath = email.draft_filepath
      end
    end
    
    -- Debug logging
    logger.debug('Draft deletion check', {
      is_draft = is_draft,
      has_draft_filepath = draft_filepath ~= nil,
      draft_filepath = draft_filepath,
      email_id = email_id,
      line_num = line_num
    })
  end
  
  -- Confirm deletion
  local prompt = is_draft and "Delete draft?" or "Delete current email?"
  vim.ui.select({"Yes", "No"}, {
    prompt = prompt,
    kind = "confirmation",
    format_item = function(item)
      if item == "Yes" then
        return " " .. item  -- Check mark
      else
        return " " .. item  -- X mark
      end
    end,
  }, function(choice)
    if choice ~= "Yes" then
      return
    end
    
    if is_draft then
      -- All drafts in the drafts folder should use filesystem deletion
      if draft_filepath then
        -- Delete filesystem-based draft
        local success = vim.fn.delete(draft_filepath) == 0
        
        if success then
          notify.himalaya('Draft deleted', notify.categories.STATUS)
          vim.defer_fn(function()
            M.refresh_email_list({ restore_insert_mode = false })
          end, 100)
        else
          notify.himalaya('Failed to delete draft', notify.categories.ERROR)
        end
      else
        -- Draft without filepath - this shouldn't happen with our filesystem approach
        notify.himalaya('Draft filepath not found. Cannot delete.', notify.categories.ERROR)
        logger.error('Draft without filepath', {
          email_id = email_id,
          line_num = vim.fn.line('.'),
          emails = state.get('email_list.emails')
        })
      end
    else
      -- Delete regular email (non-draft)
      local success, error_type, extra = utils.smart_delete_email(state.get_current_account(), email_id)
      
      if success then
        notify.himalaya('Email deleted successfully', notify.categories.STATUS)
        
        -- Since emails are only viewed in preview now, no need to close any buffers
        
        -- Always refresh the list to show the deletion
        vim.defer_fn(function()
          M.refresh_email_list({ restore_insert_mode = false })
        end, 100)
      elseif error_type == 'missing_trash' then
        -- Trash folder doesn't exist, offer alternatives
        M.handle_missing_trash_folder(email_id, extra)
      else
        notify.himalaya('Failed to delete email', notify.categories.STATUS)
      end
    end
  end)
end

-- Handle missing trash folder scenario
function M.handle_missing_trash_folder(email_id, suggested_folders)
  -- Check if we're in headless mode
  local is_headless = vim.fn.argc(-1) == 0 and vim.fn.has('gui_running') == 0
  
  if is_headless then
    -- In headless mode, just permanently delete
    notify.himalaya('Permanently deleting email (trash folder not found)', notify.categories.STATUS)
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
    prompt = 'Trash Folder Not Found - How would you like to delete this email?',
    format_item = function(item)
      if item:match('Permanently delete') then
        return ' ' .. item  -- Trash icon
      elseif item:match('^Move to ') then
        return ' ' .. item  -- Move icon
      elseif item == 'Cancel' then
        return ' ' .. item  -- Cancel icon
      else
        return item
      end
    end,
  }, function(selected_option, idx)
    if not selected_option then
      return
    end
    if selected_option == 'Permanently delete (cannot be undone)' then
      M.permanent_delete_email(email_id)
    elseif selected_option:match('^Move to ') then
      local folder = selected_option:gsub('^Move to ', '')
      M.move_email_to_folder(email_id, folder)
    elseif selected_option == 'Move to custom folder...' then
      M.prompt_custom_folder_move(email_id)
    end
  end)
end

-- Permanently delete email
function M.permanent_delete_email(email_id)
  local success = utils.delete_email(state.get_current_account(), email_id, state.get_current_folder())
  if success then
    notify.himalaya('Email permanently deleted', notify.categories.STATUS)
    M.close_current_view()
    vim.defer_fn(function()
      M.refresh_email_list()
    end, 100)
  else
    notify.himalaya('Failed to permanently delete email', notify.categories.ERROR)
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
    notify.himalaya('Moving email to Archive folder', notify.categories.STATUS)
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
  
  -- First try get_current_email_id which handles preview_email_id
  email_id = M.get_current_email_id()
  
  if not email_id then
    return
  end
  
  -- Show confirmation dialog
  local prompt = "Archive current email?"
  vim.ui.select({"Yes", "No"}, {
    prompt = prompt,
    kind = "confirmation",
    format_item = function(item)
      if item == "Yes" then
        return " " .. item  -- Check mark
      else
        return " " .. item  -- X mark
      end
    end,
  }, function(choice)
    if choice ~= "Yes" then
      return
    end
    
    -- User confirmed, proceed with archiving
    M.do_archive_current_email(email_id)
  end)
end

-- Internal function to perform the actual archiving
function M.do_archive_current_email(email_id)
  if email_id then
    -- Try different archive folder names that might exist
    local archive_folders = {'All_Mail', 'Archive', 'All Mail', 'ARCHIVE', 'Archived'}
    local folders = utils.get_folders(state.get_current_account())
    local archive_folder = nil
    
    if folders then
      -- Find the first existing archive folder
      for _, folder in ipairs(folders) do
        -- Extract folder name if it's a table with {name, path} structure
        local folder_name = type(folder) == "table" and folder.name or folder
        if folder_name and type(folder_name) == "string" then
          for _, archive_name in ipairs(archive_folders) do
            -- Check exact match first, then case-insensitive match
            if folder_name == archive_name or folder_name:lower() == archive_name:lower() then
              archive_folder = folder_name
              break
            end
          end
          if archive_folder then break end
        end
      end
    end
    
    if archive_folder then
      local success = utils.move_email(email_id, archive_folder)
      if success then
        notify.himalaya('Email archived', notify.categories.STATUS)
        
        -- Close email view if we're reading the email
        local current_buf = vim.api.nvim_get_current_buf()
        -- Since emails are only viewed in preview now, no need to close any buffers
        
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
        format_item = function(item)
          if item == 'Move to All_Mail' then
            return ' ' .. item  -- Move/archive icon
          elseif item == 'Create Archive folder' then
            return ' ' .. item  -- Create/plus icon
          elseif item:match('Move to custom') then
            return ' ' .. item  -- Folder icon
          elseif item == 'Cancel' then
            return ' ' .. item  -- Cancel icon
          else
            return item
          end
        end,
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
    notify.himalaya('No email selected', notify.categories.STATUS)
  end
end

-- Mark current email as spam and move to spam folder
function M.spam_current_email()
  local email_id = M.get_current_email_id()
  
  if not email_id then
    notify.himalaya('No email selected', notify.categories.STATUS)
    return
  end
  
  -- Show confirmation dialog
  local prompt = "Mark current email as spam?"
  vim.ui.select({"Yes", "No"}, {
    prompt = prompt,
    kind = "confirmation",
    format_item = function(item)
      if item == "Yes" then
        return " " .. item  -- Check mark
      else
        return " " .. item  -- X mark
      end
    end,
  }, function(choice)
    if choice ~= "Yes" then
      return
    end
    
    -- User confirmed, proceed with spam marking
    M.do_spam_current_email(email_id)
  end)
end

-- Internal function to perform the actual spam marking
function M.do_spam_current_email(email_id)
  if email_id then
    -- Try different spam folder names that might exist
    local spam_folders = {'Spam', 'Junk', 'SPAM', 'JUNK'}
    local folders = utils.get_folders(state.get_current_account())
    local spam_folder = nil
    
    if folders then
      -- Find the first existing spam folder
      for _, folder in ipairs(folders) do
        -- Extract folder name if it's a table with {name, path} structure
        local folder_name = type(folder) == "table" and folder.name or folder
        if folder_name and type(folder_name) == "string" then
          for _, spam_name in ipairs(spam_folders) do
            -- Check exact match first, then case-insensitive match
            if folder_name == spam_name or folder_name:lower() == spam_name:lower() then
              spam_folder = folder_name
              break
            end
          end
          if spam_folder then break end
        end
      end
    end
    
    if spam_folder then
      local success = utils.move_email(email_id, spam_folder)
      if success then
        notify.himalaya('Email marked as spam', notify.categories.STATUS)
        
        -- Since emails are only viewed in preview now, no need to close any buffers
        
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
        format_item = function(item)
          if item:match('Move to') then
            return ' ' .. item  -- Move/folder icon
          elseif item == 'Delete permanently' then
            return ' ' .. item  -- Trash icon
          elseif item == 'Cancel' then
            return ' ' .. item  -- Cancel icon
          else
            return item
          end
        end,
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
    notify.himalaya('No email selected', notify.categories.STATUS)
  end
end

-- Search emails
function M.search_emails(query)
  return email_list.search_emails(query)
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
    notify.himalaya('Cannot restore session', notify.categories.STATUS)
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
        format_item = function(item)
          if item == 'Open previous email' then
            return ' ' .. item  -- Email/envelope icon
          elseif item == 'Just show email list' then
            return ' ' .. item  -- List icon
          else
            return item
          end
        end,
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
      notify.himalaya('Previous search available', notify.categories.STATUS)
    end
    
    notify.himalaya('Email session restored', notify.categories.STATUS)
  end, 100)
  
  return true
end

-- Show session restoration prompt (called manually)
function M.prompt_session_restore()
  local can_restore, message = M.can_restore_session()
  
  if not can_restore then
    notify.himalaya(message, notify.categories.STATUS)
    return
  end
  
  -- Check if we're in headless mode
  local is_headless = vim.fn.argc(-1) == 0 and vim.fn.has('gui_running') == 0
  
  if is_headless then
    -- In headless mode, just restore directly
    notify.himalaya(message, notify.categories.STATUS)
    M.restore_session()
  else
    vim.ui.select({'Restore previous session', 'Start fresh'}, {
      prompt = message .. ' - Restore?',
      format_item = function(item)
        if item == 'Restore previous session' then
          return ' ' .. item  -- Restore icon
        elseif item == 'Start fresh' then
          return ' ' .. item  -- New/plus icon
        else
          return item
        end
      end,
    }, function(choice)
      if choice == 'Restore previous session' then
        M.restore_session()
      end
    end)
  end
end

-- Show folder picker
function M.pick_folder()
  return email_list.pick_folder()
end

-- Show account picker
function M.pick_account()
  return email_list.pick_account()
end

-- Alias for account picker (used by commands)
function M.show_account_picker()
  return M.pick_account()
end

-- Switch to a specific account by name
function M.switch_account(account_name)
  local accounts_config = require('neotex.plugins.tools.himalaya.config.accounts')

  if not accounts_config.has_account(account_name) then
    notify.himalaya('Account not found: ' .. account_name, notify.categories.ERROR)
    return false
  end

  local success = accounts_config.switch_account(account_name)
  if success then
    state.set_current_account(account_name)
    state.set_current_folder('INBOX')
    state.set_current_page(1)
    notify.himalaya('Switched to account: ' .. account_name, notify.categories.STATUS)

    -- Refresh email list if sidebar is open
    if M.is_email_buffer_open() then
      M.show_email_list({ 'INBOX' })
    end
    return true
  else
    notify.himalaya('Failed to switch account', notify.categories.ERROR)
    return false
  end
end

-- Batch Operations

-- Batch delete operation
function M.delete_selected_emails()
  local selected = state.get_selected_emails()
  
  if #selected == 0 then
    notify.himalaya('No emails selected', notify.categories.STATUS)
    return
  end
  
  -- Confirm batch operation
  local prompt = string.format(' Delete %d selected emails?', #selected)
  vim.ui.select({"Yes", "No"}, {
    prompt = prompt,
    kind = "confirmation",
    format_item = function(item)
      if item == "Yes" then
        return " " .. item  -- Check mark
      else
        return " " .. item  -- X mark
      end
    end,
  }, function(choice)
    if choice == "Yes" then
      local success_count = 0
      local error_count = 0
      
      -- Show progress notification for large batches
      if #selected > 5 then
        notify.himalaya(string.format('Deleting %d emails...', #selected), notify.categories.STATUS)
      end
      
      -- Check if we're in drafts folder
      local current_folder = state.get_current_folder()
      local draft_folder = utils.find_draft_folder(state.get_current_account())
      local is_drafts_folder = current_folder == draft_folder
      
      for i, email in ipairs(selected) do
        if is_drafts_folder and email.draft_filepath then
          -- Delete filesystem-based draft
          local success = vim.fn.delete(email.draft_filepath) == 0
          if success then
            success_count = success_count + 1
          else
            error_count = error_count + 1
            notify.himalaya(string.format('Failed to delete draft %s', email.subject or email.id), notify.categories.BACKGROUND)
          end
        else
          -- Delete regular email
          local success, error_type = utils.smart_delete_email(state.get_current_account(), email.id)
          if success then
            success_count = success_count + 1
          else
            error_count = error_count + 1
            -- Log specific error for debugging
            notify.himalaya(string.format('Failed to delete email %s: %s', email.subject or email.id, error_type or 'unknown error'), notify.categories.BACKGROUND)
          end
        end
        
        -- Update progress for large batches
        if #selected > 10 and i % 10 == 0 then
          notify.himalaya(string.format('Progress: %d/%d', i, #selected), notify.categories.STATUS)
        end
      end
      
      state.clear_selection()
      state.toggle_selection_mode() -- Exit selection mode
      
      notify.himalaya(string.format('Deleted %d emails (%d errors)', success_count, error_count),
        error_count > 0 and notify.categories.WARNING or notify.categories.USER_ACTION
      )
      
      -- With Maildir, no need to refresh local storage
      -- Drafts are handled the same as regular emails
      
      M.refresh_email_list({ restore_insert_mode = false })
    end
  end)
end

-- Batch archive operation
function M.archive_selected_emails()
  local selected = state.get_selected_emails()
  
  if #selected == 0 then
    notify.himalaya('No emails selected', notify.categories.STATUS)
    return
  end
  
  local prompt = string.format(' Archive %d selected emails?', #selected)
  vim.ui.select({"Yes", "No"}, {
    prompt = prompt,
    kind = "confirmation",
    format_item = function(item)
      if item == "Yes" then
        return " " .. item  -- Check mark
      else
        return " " .. item  -- X mark
      end
    end,
  }, function(choice)
    if choice == "Yes" then
      local success_count = 0
      local error_count = 0
      
      -- Find archive folder
      local archive_folders = {'Archive', 'All Mail', 'All_Mail', '[Gmail]/All Mail'}
      local folders = utils.get_folders(state.get_current_account())
      local archive_folder = nil

      if folders then
        for _, folder in ipairs(folders) do
          -- Extract folder name if it's a table with {name, path} structure
          local folder_name = type(folder) == "table" and folder.name or folder
          if folder_name and type(folder_name) == "string" then
            for _, archive_name in ipairs(archive_folders) do
              if folder_name == archive_name or folder_name:match(archive_name) then
                archive_folder = folder_name
                break
              end
            end
            if archive_folder then break end
          end
        end
      end
      
      if not archive_folder then
        archive_folder = 'All_Mail' -- Default fallback
      end
      
      -- Show progress notification for large batches
      if #selected > 5 then
        notify.himalaya(string.format('Archiving %d emails to %s...', #selected, archive_folder), notify.categories.STATUS)
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
      
      notify.himalaya(string.format('Archived %d emails (%d errors)', success_count, error_count),
        error_count > 0 and notify.categories.WARNING or notify.categories.USER_ACTION
      )
      
      M.refresh_email_list()
    end
  end)
end

-- Batch spam operation
function M.spam_selected_emails()
  local selected = state.get_selected_emails()
  
  if #selected == 0 then
    notify.himalaya('No emails selected', notify.categories.STATUS)
    return
  end
  
  local prompt = string.format(' Mark %d selected emails as spam?', #selected)
  vim.ui.select({"Yes", "No"}, {
    prompt = prompt,
    kind = "confirmation",
    format_item = function(item)
      if item == "Yes" then
        return " " .. item  -- Check mark
      else
        return " " .. item  -- X mark
      end
    end,
  }, function(choice)
    if choice == "Yes" then
      local success_count = 0
      local error_count = 0
      
      -- Find spam folder
      local spam_folders = {'Spam', 'Junk', 'SPAM', 'JUNK', '[Gmail]/Spam'}
      local folders = utils.get_folders(state.get_current_account())
      local spam_folder = nil

      if folders then
        for _, folder in ipairs(folders) do
          -- Extract folder name if it's a table with {name, path} structure
          local folder_name = type(folder) == "table" and folder.name or folder
          if folder_name and type(folder_name) == "string" then
            for _, spam_name in ipairs(spam_folders) do
              if folder_name == spam_name or folder_name:lower() == spam_name:lower() then
                spam_folder = folder_name
                break
              end
            end
            if spam_folder then break end
          end
        end
      end
      
      if not spam_folder then
        spam_folder = 'Spam' -- Default fallback
      end
      
      -- Show progress notification for large batches
      if #selected > 5 then
        notify.himalaya(string.format('Moving %d emails to spam...', #selected), notify.categories.STATUS)
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
      
      notify.himalaya(string.format('Marked %d emails as spam (%d errors)', success_count, error_count),
        error_count > 0 and notify.categories.WARNING or notify.categories.USER_ACTION
      )
      
      M.refresh_email_list()
    end
  end)
end

-- Move current email to another folder
function M.move_current_email()
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local metadata = state.get('email_list.line_map') or {}
  local line_data = metadata[current_line]
  
  -- Debug logging
  local logger = require('neotex.plugins.tools.himalaya.core.logger')
  logger.debug('move_current_email', {
    current_line = current_line,
    has_metadata = metadata ~= nil,
    has_line_data = line_data ~= nil,
    line_data_type = line_data and line_data.type,
    line_data = line_data
  })
  
  if not line_data or line_data.type ~= 'email' then
    notify.himalaya('No email on current line', notify.categories.STATUS)
    return
  end
  
  -- Get list of folders
  local account = state.get_current_account()
  if not account then
    notify.himalaya('No account selected', notify.categories.ERROR)
    return
  end
  
  local folders = utils.get_folders(account)
  if not folders or #folders == 0 then
    notify.himalaya('No folders available', notify.categories.ERROR)
    return
  end
  
  -- Filter out current folder
  local current_folder = state.get_current_folder()
  local available_folders = {}
  for _, folder in ipairs(folders) do
    local folder_name = type(folder) == "table" and folder.name or folder
    if folder_name ~= current_folder then
      table.insert(available_folders, folder)
    end
  end

  -- Show folder picker
  vim.ui.select(available_folders, {
    prompt = ' Move email to folder:',
    format_item = function(folder)
      local name = type(folder) == "table" and folder.name or folder
      if not name or type(name) ~= "string" then
        return "(invalid)"
      end
      -- Add icon for special folders
      if name:lower():match('inbox') then
        return '📥 ' .. name
      elseif name:lower():match('sent') then
        return '📤 ' .. name
      elseif name:lower():match('draft') then
        return '📝 ' .. name
      elseif name:lower():match('trash') then
        return '🗑️ ' .. name
      elseif name:lower():match('spam') or name:lower():match('junk') then
        return '⚠️ ' .. name
      elseif name:lower():match('archive') or name:lower():match('all.mail') then
        return '📦 ' .. name
      else
        return '📁 ' .. name
      end
    end
  }, function(choice)
    if choice then
      local target_folder = type(choice) == "table" and choice.name or choice
      local success = utils.move_email(line_data.email_id or line_data.id, target_folder)
      if success then
        notify.himalaya(string.format('Email moved to %s', target_folder), notify.categories.USER_ACTION)
        -- Refresh to show the email is gone
        vim.defer_fn(function()
          M.refresh_email_list({ restore_insert_mode = false })
        end, 100)
      else
        notify.himalaya('Failed to move email', notify.categories.ERROR)
      end
    end
  end)
end

-- Move selected emails to another folder
function M.move_selected_emails()
  local selected = state.get_selected_emails()
  
  if #selected == 0 then
    notify.himalaya('No emails selected', notify.categories.STATUS)
    return
  end
  
  -- Get list of folders
  local account = state.get_current_account()
  if not account then
    notify.himalaya('No account selected', notify.categories.ERROR)
    return
  end
  
  local folders = utils.get_folders(account)
  if not folders or #folders == 0 then
    notify.himalaya('No folders available', notify.categories.ERROR)
    return
  end
  
  -- Filter out current folder
  local current_folder = state.get_current_folder()
  local available_folders = {}
  for _, folder in ipairs(folders) do
    local folder_name = type(folder) == "table" and folder.name or folder
    if folder_name ~= current_folder then
      table.insert(available_folders, folder)
    end
  end

  -- Show folder picker
  vim.ui.select(available_folders, {
    prompt = string.format(' Move %d emails to folder:', #selected),
    format_item = function(folder)
      local name = type(folder) == "table" and folder.name or folder
      if not name or type(name) ~= "string" then
        return "(invalid)"
      end
      -- Add icon for special folders
      if name:lower():match('inbox') then
        return '📥 ' .. name
      elseif name:lower():match('sent') then
        return '📤 ' .. name
      elseif name:lower():match('draft') then
        return '📝 ' .. name
      elseif name:lower():match('trash') then
        return '🗑️ ' .. name
      elseif name:lower():match('spam') or name:lower():match('junk') then
        return '⚠️ ' .. name
      elseif name:lower():match('archive') or name:lower():match('all.mail') then
        return '📦 ' .. name
      else
        return '📁 ' .. name
      end
    end
  }, function(choice)
    if choice then
      local target_folder = type(choice) == "table" and choice.name or choice
      local success_count = 0
      local error_count = 0

      -- Show progress notification for large batches
      if #selected > 5 then
        notify.himalaya(string.format('Moving %d emails to %s...', #selected, target_folder), notify.categories.STATUS)
      end

      for i, email in ipairs(selected) do
        -- Debug logging
        local logger = require('neotex.plugins.tools.himalaya.core.logger')
        logger.debug('Processing selected email for move', {
          index = i,
          email_id = email.id,
          email_id_type = type(email.id),
          email_subject = email.subject,
          target_folder = target_folder,
          email_keys = vim.tbl_keys(email)
        })

        if not email.id then
          notify.himalaya(string.format('Email missing ID: %s', vim.inspect(email)), notify.categories.ERROR)
          error_count = error_count + 1
        else
          local success = utils.move_email(email.id, target_folder)
          if success then
            success_count = success_count + 1
          else
            error_count = error_count + 1
            notify.himalaya(string.format('Failed to move email %s (ID: %s)',
              email.subject or 'unknown', tostring(email.id)), notify.categories.BACKGROUND)
          end
        end
      end

      -- Clear selection mode
      state.toggle_selection_mode() -- Exit selection mode

      notify.himalaya(string.format('Moved %d emails to %s (%d errors)',
        success_count, target_folder, error_count),
        error_count > 0 and notify.categories.WARNING or notify.categories.USER_ACTION
      )
      
      M.refresh_email_list({ restore_insert_mode = false })
    end
  end)
end

-- Session management functions (delegate to session module)
function M.save_session()
  return session.save_session()
end

function M.restore_session()
  return session.restore_session()
end

function M.clear_session()
  return session.clear_session()
end

function M.get_session_info()
  return session.get_session_info()
end

return M