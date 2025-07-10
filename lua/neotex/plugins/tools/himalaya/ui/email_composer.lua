-- Buffer-based email composition with auto-save
-- TODO: Add attachment support for composition
-- TODO: Implement address book integration and auto-completion
-- TODO: Add email templates and signatures management
-- TODO: Implement spell checking and grammar checking integration
-- TODO: Add email encryption support (PGP/GPG)

local M = {}

-- Dependencies
local state = require('neotex.plugins.tools.himalaya.core.state')
local config = require('neotex.plugins.tools.himalaya.core.config')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local utils = require('neotex.plugins.tools.himalaya.utils')
local notify = require('neotex.util.notifications')
local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager')
local id_validator = require('neotex.plugins.tools.himalaya.core.id_validator')
local draft_parser = require('neotex.plugins.tools.himalaya.core.draft_parser')
local draft_cache = require('neotex.plugins.tools.himalaya.core.draft_cache')
local performance = require('neotex.plugins.tools.himalaya.core.performance')
local draft_debug = require('neotex.plugins.tools.himalaya.core.draft_debug')
local draft_maildir = require('neotex.plugins.tools.himalaya.core.draft_maildir')
local local_draft_cache = require('neotex.plugins.tools.himalaya.core.local_draft_cache')
local draft_cache_manager = require('neotex.plugins.tools.himalaya.core.draft_cache_manager')

-- Module state
local composer_buffers = {}
local autosave_timers = {}
local draft_id_to_buffer = {}  -- Track which buffer owns which draft ID
local debounced_saves = {}  -- Track debounced save functions per buffer

-- Configuration
M.config = {
  use_tab = true,  -- Open in current window (false = vsplit)
  auto_save_interval = 30,
  delete_draft_on_send = true,
  syntax_highlighting = true,
  draft_dir = vim.fn.expand('~/.local/share/himalaya/drafts/'),
}

-- Initialize module
function M.setup(cfg)
  if cfg and cfg.compose then
    M.config = vim.tbl_extend('force', M.config, cfg.compose)
  end
  
  -- Ensure draft directory exists
  vim.fn.mkdir(M.config.draft_dir, 'p')
  
  -- Initialize draft debug module
  draft_debug.setup()
  
  logger.debug('Email composer v2 initialized', { config = M.config })
end

-- Parse email buffer content (now uses robust parser)
local function parse_email_buffer(lines)
  -- Use the robust parser
  local parsed = draft_parser.parse_email(lines)
  
  -- Log parsing result
  logger.info('Parsed email buffer using robust parser', {
    header_count = vim.tbl_count(parsed.headers),
    headers = parsed.headers,
    body_length = #parsed.body,
    body_content = parsed.body,  -- Show full body to debug
    total_lines = #lines,
    parse_errors = #(parsed.errors or {}),
    parser_state = parsed.parser_state
  })
  
  -- Ensure body is not nil
  if not parsed.body then
    parsed.body = ''
  end
  
  return parsed
end

-- Format email for display in buffer
local function format_email_template(opts)
  opts = opts or {}
  
  local account_name = state.get_current_account()
  local from = opts.from or config.get_formatted_from(account_name) or ''
  
  local lines = {
    'From: ' .. from,
    'To: ' .. (opts.to or ''),
    'Cc: ' .. (opts.cc or ''),
    'Bcc: ' .. (opts.bcc or ''),
    'Subject: ' .. (opts.subject or ''),
    '',  -- Empty line to separate headers from body
  }
  
  -- Add body content
  if opts.body and opts.body ~= '' then
    -- Handle body content line by line, preserving empty lines
    -- Use a different pattern that correctly handles empty lines
    local body_lines = vim.split(opts.body, '\n', { plain = true })
    for _, line in ipairs(body_lines) do
      table.insert(lines, line)
    end
  else
    -- Add at least one empty line for the body to ensure proper file format
    table.insert(lines, '')
    
    -- Add signature if configured
    local signature = config.get('compose.signature')
    if signature then
      table.insert(lines, '--')
      for line in signature:gmatch('[^\r\n]+') do
        table.insert(lines, line)
      end
    end
  end
  
  return lines
end

-- Sync draft to maildir
local function sync_draft_to_maildir(draft_file, account, existing_draft_id)
  -- Use provided account or fallback to current account
  account = account or state.get_current_account()
  
  if not account then
    logger.warn('No account specified for draft sync')
    return nil
  end
  
  logger.info('Draft lifecycle: Starting sync to maildir', {
    draft_file = draft_file,
    account = account,
    existing_draft_id = existing_draft_id
  })
  
  local draft_folder = utils.find_draft_folder(account)
  
  if not draft_folder then
    logger.warn('No draft folder found for account', { account = account })
    return nil
  end
  
  -- Read draft content
  local content = vim.fn.readfile(draft_file)
  
  -- Debug: log raw file content
  logger.info('Draft file raw content', {
    file = draft_file,
    line_count = #content,
    first_lines = vim.list_slice(content, 1, 10),
    all_lines = content  -- Log all lines to see the complete content
  })
  
  -- Add draft debug tracking
  draft_debug.debug_draft_content('file_read', draft_file, content)
  draft_debug.debug_lifecycle_event('sync_start', nil, existing_draft_id, {
    account = account,
    draft_folder = draft_folder,
    file = draft_file
  })
  
  -- Extra debug: Check for subject in raw content
  local subject_line = nil
  for _, line in ipairs(content) do
    if line:match('^Subject:') then
      subject_line = line
      break
    end
  end
  logger.info('Subject line in raw content', {
    subject_line = subject_line,
    has_subject = subject_line ~= nil
  })
  
  -- If the file is empty or has no content, add basic headers
  if not content or #content == 0 then
    logger.warn('Draft file is empty', { file = draft_file })
    content = { 
      'From: ' .. config.get_formatted_from(account),
      'To: ',
      'Subject: ',
      '',
      ''
    }
  end
  
  local email = parse_email_buffer(content)
  
  -- Debug parsed content
  draft_debug.debug_draft_content('after_parse', draft_file, email)
  
  -- Make sure we have all the required fields
  if not email.from or email.from == '' then
    -- Try to get from account config
    email.from = config.get_formatted_from(account)
  end
  
  -- Validate email content before saving
  local is_valid, validation_errors = draft_parser.validate_email(email)
  
  -- Debug logging - ALWAYS show this info
  logger.info('Parsed email for draft sync', {
    file = draft_file,
    account = account,
    folder = draft_folder,
    has_body = email.body ~= nil and email.body ~= '',
    body_length = email.body and #email.body or 0,
    body_content = email.body,  -- Show actual body content
    subject = email.subject,
    subject_empty = email.subject == nil or email.subject == '',
    from = email.from,
    to = email.to,
    headers = email.headers,
    is_valid = is_valid,
    validation_errors = validation_errors
  })
  
  -- Error recovery: ensure minimum required fields
  if not email.from or email.from == '' then
    logger.warn('Draft missing From address, using account default')
    email.from = config.get_formatted_from(account)
  end
  
  -- Ensure body is not nil
  if not email.body then
    email.body = ''
  end
  
  -- Enhanced empty draft detection and handling (NEW for Phase 6)
  local is_effectively_empty = (
    (not email.to or email.to == '') and
    (not email.subject or email.subject == '') and
    (not email.body or email.body:match('^%s*$'))
  )
  
  -- For empty drafts, ensure minimal but valid structure
  if is_effectively_empty then
    email.subject = ''  -- Explicitly empty, not nil
    email.body = ''     -- Explicitly empty, not nil
    
    -- Add metadata to track empty state
    email.headers = email.headers or {}
    email.headers['X-Draft-State'] = 'empty'
    email.headers['X-Draft-Created'] = os.date('!%Y-%m-%dT%H:%M:%SZ')
    
    logger.info('Empty draft detected - adding state metadata', {
      draft_file = draft_file,
      account = account,
      state_header = email.headers['X-Draft-State'],
      created_header = email.headers['X-Draft-Created']
    })
  else
    -- Remove empty state marker if content added
    if email.headers and email.headers['X-Draft-State'] then
      email.headers['X-Draft-State'] = nil
      logger.info('Draft has content - removing empty state marker', {
        draft_file = draft_file,
        account = account
      })
    end
  end
  
  -- If we have an existing draft ID, we should update that draft
  -- However, himalaya doesn't support update, so we need to delete and recreate
  if existing_draft_id and existing_draft_id ~= '' then
    logger.debug('Updating existing draft', {
      existing_draft_id = existing_draft_id,
      account = account,
      folder = draft_folder
    })
    -- Note: We're not deleting the old draft here anymore to prevent duplicates
    -- The himalaya CLI should handle this internally
  end
  
  -- Save to maildir using himalaya
  local ok, result = pcall(utils.save_draft, account, draft_folder, email)
  if ok and result then
    logger.info('Draft lifecycle: Successfully synced to maildir', { 
      file = draft_file,
      draft_id = result.id,
      account = account,
      folder = draft_folder
    })
    
    -- Use enhanced caching that reads draft back while body is available
    draft_cache_manager.cache_draft_after_save(account, draft_folder, result.id, email)
    
    -- Update draft manager content for preview refresh
    local buf = draft_manager.find_buffer_for_draft(result.id)
    if not buf then
      -- Try to find by existing draft ID if this is an update
      if existing_draft_id then
        buf = draft_manager.find_buffer_for_draft(existing_draft_id)
      end
    end
    
    if buf then
      draft_manager.update_content(buf, email)
      -- Also update the draft ID if it changed
      if existing_draft_id and existing_draft_id ~= result.id then
        draft_manager.set_draft_id(buf, result.id)
      end
    else
      logger.warn('Could not find buffer for draft to update content', {
        draft_id = result.id,
        existing_draft_id = existing_draft_id
      })
    end
    
    -- Refresh sidebar if we're in drafts folder and sidebar is open
    local current_folder = state.get_current_folder()
    local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
    if current_folder and current_folder == draft_folder and sidebar.is_open() then
      vim.defer_fn(function()
        local email_list = require('neotex.plugins.tools.himalaya.ui.email_list')
        email_list.refresh_email_list()
      end, 100)
    end
    
    -- Also cache in email_cache for compatibility
    local email_cache = require('neotex.plugins.tools.himalaya.core.email_cache')
    email_cache.clear_email(account, draft_folder, result.id)
    
    local cached_email = {
      id = result.id,
      from = email.from,
      to = email.to,
      subject = email.subject,
      body = email.body,
      date = os.date('%Y-%m-%d %H:%M:%S'),
      flags = { 'Draft' },
      _is_draft = true
    }
    logger.info('Caching draft email data', {
      draft_id = result.id,
      subject = email.subject,
      subject_length = email.subject and #email.subject or 0,
      account = account,
      folder = draft_folder
    })
    email_cache.store_email(account, draft_folder, cached_email)
    
    -- Show success notification in debug mode
    if notify.config.modules.himalaya.debug_mode then
      notify.himalaya('Draft synced to ' .. draft_folder, notify.categories.BACKGROUND)
    end
    
    -- Update draft manager with the himalaya ID
    local buffer_id = vim.fn.bufnr(draft_file)
    if buffer_id ~= -1 then
      draft_manager.set_draft_id(buffer_id, result.id)
      draft_manager.update_content(buffer_id, {
        from = email.from,
        to = email.to,
        cc = email.cc,
        bcc = email.bcc,
        subject = email.subject,
        body = email.body
      })
    end
    
    -- Refresh the email list if we're in the drafts folder AND the sidebar is open
    local current_folder = state.get_current_folder()
    local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
    if current_folder and current_folder:lower():match('draft') and sidebar.is_open() then
      vim.defer_fn(function()
        -- Double-check sidebar is still open before refreshing
        if sidebar.is_open() then
          local email_list = require('neotex.plugins.tools.himalaya.ui.email_list')
          email_list.refresh_email_list()
        end
      end, 500)
    end
    
    return result.id
  else
    local error_msg = result or 'Unknown error'
    logger.error('Draft lifecycle: Failed to sync draft', { 
      file = draft_file,
      error = error_msg,
      email = email,
      account = account,
      folder = draft_folder
    })
    -- Show user-friendly notification about draft sync failure
    if not email.from or email.from == '' then
      notify.himalaya('Draft saved locally but not synced: Missing From address', notify.categories.WARNING)
    else
      notify.himalaya('Draft saved locally but sync failed: ' .. tostring(error_msg), notify.categories.WARNING)
    end
    return nil
  end
end

-- Delete draft from maildir
local function delete_draft_from_maildir(account, draft_id)
  if not draft_id then 
    logger.warn('delete_draft_from_maildir: No draft_id provided')
    return 
  end
  
  -- Validate draft_id is not a folder name
  if type(draft_id) == 'string' and (draft_id == 'Drafts' or draft_id:match('^[A-Za-z]+$') and not tonumber(draft_id)) then
    logger.error('delete_draft_from_maildir: Invalid draft_id (folder name)', {
      draft_id = draft_id,
      account = account
    })
    return
  end
  
  local draft_folder = utils.find_draft_folder(account)
  if not draft_folder then return end
  
  logger.info('Deleting draft from maildir', {
    account = account,
    folder = draft_folder,
    draft_id = draft_id
  })
  
  local ok, err = pcall(utils.delete_email, account, draft_folder, draft_id)
  if not ok then
    logger.error('Failed to delete draft from maildir', {
      draft_id = draft_id,
      error = err
    })
  else
    logger.info('Draft deleted successfully', { draft_id = draft_id })
  end
end

-- Setup auto-save for a buffer
local function setup_autosave(buf, draft_file)
  -- Clear any existing timer
  if autosave_timers[buf] then
    vim.loop.timer_stop(autosave_timers[buf])
    autosave_timers[buf] = nil
  end
  
  local timer = vim.loop.new_timer()
  autosave_timers[buf] = timer
  
  -- Auto-save every N seconds
  timer:start(M.config.auto_save_interval * 1000, M.config.auto_save_interval * 1000, 
    vim.schedule_wrap(function()
      if not vim.api.nvim_buf_is_valid(buf) then
        timer:stop()
        autosave_timers[buf] = nil
        return
      end
      
      if vim.api.nvim_buf_get_option(buf, 'modified') then
        -- Save to file
        vim.api.nvim_buf_call(buf, function()
          vim.cmd('silent write!')
        end)
        
        -- Sync to maildir
        local draft_info = composer_buffers[buf]
        if draft_info and draft_info.file then
          -- Check if this is the first save for a new draft
          if draft_info.needs_initial_sync and not draft_info.draft_id then
            -- Initial sync for new drafts
            logger.debug('Auto-save: initial draft sync', {
              buf = buf,
              file = draft_info.file
            })
            
            local new_id = sync_draft_to_maildir(draft_info.file, draft_info.account, nil)
            if new_id then
              -- Track which buffer owns this draft ID
              if draft_id_to_buffer[new_id] and draft_id_to_buffer[new_id] ~= buf then
                logger.warn('Draft ID already assigned to another buffer', {
                  draft_id = new_id,
                  existing_buf = draft_id_to_buffer[new_id],
                  new_buf = buf
                })
              end
              draft_id_to_buffer[new_id] = buf
              
              draft_info.draft_id = new_id
              draft_info.draft_synced = true
              draft_info.needs_initial_sync = false
              composer_buffers[buf] = draft_info
              state.set('compose.drafts.' .. buf, draft_info)
              vim.api.nvim_buf_set_var(buf, 'himalaya_draft_info', draft_info)
              
              -- Update draft manager with the new ID
              draft_manager.set_draft_id(buf, new_id)
              
              logger.info('Draft created on first save', {
                draft_id = new_id,
                buf = buf
              })
            end
          elseif draft_info.draft_id and draft_info.draft_synced then
            -- Update existing draft
            local current_id = draft_info.draft_id
            
            logger.debug('Auto-save: updating existing draft', {
              current_id = current_id,
              original_draft_id = draft_info.original_draft_id,
              buf = buf
            })
            
            -- Save the new version (update existing draft)
            local new_id = sync_draft_to_maildir(draft_info.file, draft_info.account, current_id)
            if new_id then
              -- Only update if we got a different ID
              if new_id ~= current_id then
                draft_info.draft_id = new_id
                composer_buffers[buf] = draft_info
                state.set('compose.drafts.' .. buf, draft_info)
                vim.api.nvim_buf_set_var(buf, 'himalaya_draft_info', draft_info)
                logger.debug('Auto-save: draft ID changed', {
                  old_id = current_id,
                  new_id = new_id,
                  buf = buf
                })
              end
            end
          else
            -- Draft in inconsistent state - log for debugging
            logger.warn('Auto-save: draft in unexpected state', {
              has_draft_id = draft_info.draft_id ~= nil,
              draft_synced = draft_info.draft_synced,
              needs_initial_sync = draft_info.needs_initial_sync,
              buf = buf
            })
          end
        end
        
        -- Notify in debug mode
        if notify.config.modules.himalaya.debug_mode then
          notify.himalaya('Draft auto-saved', notify.categories.BACKGROUND)
        end
      end
    end)
  )
end

-- Setup buffer keymaps and autocmds
local function setup_buffer_mappings(buf)
  local opts = { buffer = buf, noremap = true, silent = true }
  
  -- Only set up Tab navigation helper for insert mode, other keymaps are in which-key
  vim.keymap.set('i', '<Tab>', function()
    -- Jump to next header field or body
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    
    -- Find next field
    for i = line + 1, #lines do
      if lines[i] == '' then
        -- Jump to body and stay in insert mode
        vim.api.nvim_win_set_cursor(0, { i + 1, 0 })
        return
      elseif lines[i]:match('^[^:]+:%s*$') or lines[i]:match('^[^:]+:%s*$') then
        -- Jump to end of header line and stay in insert mode
        vim.api.nvim_win_set_cursor(0, { i, #lines[i] })
        return
      end
    end
  end, opts)
  
  -- Cleanup on buffer unload
  vim.api.nvim_create_autocmd('BufUnload', {
    buffer = buf,
    callback = function()
      -- Stop autosave timer
      if autosave_timers[buf] then
        vim.loop.timer_stop(autosave_timers[buf])
        autosave_timers[buf] = nil
      end
      
      -- Get draft info before cleanup
      local draft_info = composer_buffers[buf]
      
      -- Clean up draft ID tracking
      if draft_info and draft_info.draft_id then
        if draft_id_to_buffer[draft_info.draft_id] == buf then
          draft_id_to_buffer[draft_info.draft_id] = nil
          logger.debug('Cleaned up draft ID tracking', {
            draft_id = draft_info.draft_id,
            buf = buf
          })
        end
      end
      
      -- If this was a draft, invalidate its cache to ensure fresh preview
      if draft_info and (draft_info.draft_id or draft_info.original_draft_id) then
        local email_cache = require('neotex.plugins.tools.himalaya.core.email_cache')
        local account = draft_info.account or state.get_current_account()
        local folder = utils.find_draft_folder(account)
        if folder then
          -- Clear cache for this draft
          local draft_id = draft_info.draft_id or draft_info.original_draft_id
          email_cache.clear_email(account, folder, draft_id)
        end
        
        -- Refresh the email list if we're in the drafts folder AND the sidebar is open
        local current_folder = state.get_current_folder()
        local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
        if current_folder and current_folder:lower():match('draft') and sidebar.is_open() then
          vim.defer_fn(function()
            -- Double-check sidebar is still open before refreshing
            if sidebar.is_open() then
              local email_list = require('neotex.plugins.tools.himalaya.ui.email_list')
              email_list.refresh_email_list()
            end
          end, 100)
        end
      end
      
      -- Cleanup state
      composer_buffers[buf] = nil
      debounced_saves[buf] = nil
      state.set('compose.drafts.' .. buf, nil)
    end,
  })
end

-- Setup content change tracking for empty draft handling (NEW for Phase 6)
local function setup_content_tracking(buf)
  -- Track when user makes actual changes
  vim.api.nvim_create_autocmd({'TextChanged', 'TextChangedI'}, {
    buffer = buf,
    callback = function()
      local draft_state = draft_manager.get_draft(buf)
      if draft_state then
        -- Update tracking fields
        local updates = {
          user_touched = true,
          last_modified = os.time()
        }
        
        -- Check if content is still effectively empty
        updates.is_empty = draft_manager.is_draft_empty(buf)
        
        draft_manager.update_draft_state(buf, updates)
        
        logger.debug('Content tracking update', {
          buffer_id = buf,
          local_id = draft_state.local_id,
          user_touched = true,
          is_empty = updates.is_empty,
          last_modified = updates.last_modified
        })
      end
    end
  })
end

-- Create email composition buffer
function M.compose_email(opts)
  opts = opts or {}
  
  -- If no template specified and no content, offer template selection
  if not opts.template_id and not opts.to and not opts.subject and not opts.body then
    local templates = require('neotex.plugins.tools.himalaya.core.templates')
    local template_list = templates.get_templates()
    
    if vim.tbl_count(template_list) > 0 then
      vim.ui.select({"Start from template", "Start blank"}, {
        prompt = "How would you like to compose this email?",
        format_item = function(item)
          if item == "Start from template" then
            return "📧 " .. item
          else
            return "📝 " .. item
          end
        end
      }, function(choice)
        if choice == "Start from template" then
          templates.pick_template(function(template_id, variables)
            local result = templates.apply_template(template_id, variables)
            if result then
              opts.to = result.to
              opts.cc = result.cc
              opts.bcc = result.bcc
              opts.subject = result.subject
              opts.body = result.body
              opts.template_id = template_id
              M.create_compose_buffer(opts)
            end
          end)
          return
        else
          M.create_compose_buffer(opts)
        end
      end)
      return
    end
  end
  
  M.create_compose_buffer(opts)
end

-- Create email composition buffer (internal function)
function M.create_compose_buffer(opts)
  opts = opts or {}
  
  -- Use existing draft file if reopening, otherwise create new
  local draft_file
  if opts.is_draft_reopen and opts.existing_draft_file then
    draft_file = opts.existing_draft_file
  else
    -- Generate new draft filename
    local timestamp = os.date('%Y%m%d_%H%M%S')
    draft_file = M.config.draft_dir .. 'draft_' .. timestamp .. '.eml'
  end
  
  -- Create buffer
  local buf = vim.api.nvim_create_buf(true, false)
  
  -- Check if a buffer with this name already exists
  local existing_buf = vim.fn.bufnr(draft_file)
  if existing_buf ~= -1 and vim.api.nvim_buf_is_valid(existing_buf) then
    -- Use the existing buffer instead
    buf = existing_buf
    logger.debug('Using existing buffer for draft file', { file = draft_file, buf = buf })
  else
    vim.api.nvim_buf_set_name(buf, draft_file)
  end
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'filetype', 'mail')
  vim.api.nvim_buf_set_option(buf, 'buftype', '')
  vim.api.nvim_buf_set_option(buf, 'fileformat', 'dos')  -- Use DOS line endings for RFC compliance
  vim.api.nvim_buf_set_option(buf, 'endofline', true)  -- Ensure EOL at end of file
  
  -- Open buffer in appropriate window
  if M.config.use_tab then
    -- Check if we're in the sidebar or preview
    local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
    local preview = require('neotex.plugins.tools.himalaya.ui.email_preview')
    local sidebar_win = sidebar.get_win()
    local current_win = vim.api.nvim_get_current_win()
    
    -- Store if we're in preview to maintain it
    local preview_win = preview.ensure_preview_window()
    local in_preview = preview_win and current_win == preview_win
    
    -- If in sidebar or preview, move to main window
    if sidebar_win and (current_win == sidebar_win or in_preview) then
      -- Find a non-sidebar, non-preview window
      local found_main = false
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if win ~= sidebar_win and win ~= preview_win then
          vim.api.nvim_set_current_win(win)
          found_main = true
          break
        end
      end
      
      -- If no main window found, create one
      if not found_main then
        vim.cmd('wincmd w')
      end
    end
    
    -- Now edit the buffer in the current window
    vim.cmd('buffer ' .. buf)
  else
    -- Use vertical split for wider editing area
    vim.cmd('vsplit')
    vim.api.nvim_win_set_buf(0, buf)
  end
  
  -- Initialize content
  local lines = format_email_template(opts)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Ensure buffer always has the empty line separator
  -- This is critical for proper email format
  local buf_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local has_separator = false
  for i, line in ipairs(buf_lines) do
    if line == '' then
      has_separator = true
      break
    end
  end
  if not has_separator then
    -- Add empty line after headers if missing
    table.insert(buf_lines, 6, '')  -- After the 5 header lines
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, buf_lines)
  end
  
  -- Debug: Log initial buffer content - ALWAYS show this
  logger.info('Initial buffer content after setup', {
    line_count = vim.api.nvim_buf_line_count(buf),
    lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false),
    has_empty_line = has_separator,
    format_email_template_result = lines
  })
  
  -- Position cursor in To: field if empty
  local line_count = vim.api.nvim_buf_line_count(buf)
  if not opts.to or opts.to == '' then
    vim.api.nvim_win_set_cursor(0, { math.min(2, line_count), 4 })  -- After "To: "
  elseif not opts.subject or opts.subject == '' then
    vim.api.nvim_win_set_cursor(0, { math.min(5, line_count), 9 })  -- After "Subject: "
  else
    -- Position cursor at beginning of body (after empty line)
    -- Find the empty line that separates headers from body
    local body_line = 7  -- Default position
    local buf_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    for i = 1, line_count do
      if i <= #buf_lines and buf_lines[i] == '' then
        body_line = i + 1
        break
      end
    end
    vim.api.nvim_win_set_cursor(0, { math.min(body_line, line_count), 0 })
  end
  
  -- Setup syntax highlighting
  if M.config.syntax_highlighting then
    vim.api.nvim_buf_call(buf, function()
      vim.cmd('syntax match mailHeader "^\\\\(From\\\\|To\\\\|Cc\\\\|Bcc\\\\|Subject\\\\|Date\\\\|Reply-To\\\\):"')
      vim.cmd('syntax match mailEmail "<[^>]\\\\+@[^>]\\\\+>"')
      vim.cmd('syntax match mailEmail "[a-zA-Z0-9._%+-]\\\\+@[a-zA-Z0-9.-]\\\\+\\\\.[a-zA-Z]\\\\{2,}"')
      vim.cmd('syntax region mailQuoted start="^>" end="$" contains=mailQuoted')
      vim.cmd('hi link mailHeader Keyword')
      vim.cmd('hi link mailEmail Underlined')
      vim.cmd('hi link mailQuoted Comment')
    end)
  end
  
  -- Store buffer info
  local current_account = state.get_current_account() or config.get_current_account_name() or 'gmail'
  local draft_folder = utils.find_draft_folder(current_account) or 'Drafts'
  
  -- Register draft with draft manager
  local draft_state = draft_manager.register_draft(buf, current_account, draft_folder)
  
  -- Update draft content from options
  draft_manager.update_content(buf, {
    from = opts.from or config.get_account_email(current_account),
    to = opts.to or '',
    cc = opts.cc or '',
    bcc = opts.bcc or '',
    subject = opts.subject or '',
    body = opts.body or ''
  })
  
  -- If reopening a draft, set the draft ID
  if opts.draft_id and id_validator.is_valid_id(opts.draft_id) then
    draft_manager.set_draft_id(buf, opts.draft_id)
  end
  
  local draft_info = {
    file = draft_file,
    created = os.time(),
    account = current_account,
    reply_to = opts.reply_to,
    forward_from = opts.forward_from,
    template_id = opts.template_id,
    draft_id = opts.draft_id,  -- Preserve draft ID if reopening
    original_draft_id = opts.original_draft_id,
    draft_synced = opts.is_draft_reopen,  -- Mark reopened drafts as already synced
  }
  
  composer_buffers[buf] = draft_info
  state.set('compose.drafts.' .. buf, draft_info)
  
  -- Also set as buffer variable for easier access
  vim.api.nvim_buf_set_var(buf, 'himalaya_draft_info', draft_info)
  
  logger.info('Draft lifecycle: Buffer created', {
    buffer_id = buf,
    local_id = draft_state.local_id,
    draft_id = opts.draft_id,
    is_reopen = opts.is_draft_reopen,
    account = current_account,
    has_subject = (opts.subject ~= nil and opts.subject ~= ''),
    has_to = (opts.to ~= nil and opts.to ~= '')
  })
  
  -- Setup mappings and auto-save
  setup_buffer_mappings(buf)
  setup_content_tracking(buf)  -- NEW for Phase 6
  setup_autosave(buf, draft_file)
  
  -- Initial save
  vim.api.nvim_buf_call(buf, function()
    -- Ensure DOS line endings for RFC compliance
    vim.bo.fileformat = 'dos'
    vim.cmd('silent write!')
  end)
  
  -- Debug: Check what was saved initially
  local initial_saved = vim.fn.readfile(draft_file)
  logger.info('Initial draft file saved', {
    file = draft_file,
    line_count = #initial_saved,
    content = initial_saved
  })
  
  -- Skip initial sync for new drafts - wait for user to save
  -- This prevents creating empty drafts that cause duplicates
  if not opts.is_draft_reopen then
    -- Don't sync immediately - wait for first save
    logger.info('New draft created - will sync on first save', {
      file = draft_file,
      account = draft_info.account
    })
    
    -- Mark that we haven't synced yet
    draft_info.draft_synced = false
    draft_info.needs_initial_sync = true
    composer_buffers[buf] = draft_info
    state.set('compose.drafts.' .. buf, draft_info)
  else
    -- For reopened drafts, mark as already synced
    logger.info('Reopened draft - already synced', {
      draft_id = draft_info.draft_id,
      original_draft_id = draft_info.original_draft_id
    })
  end
  
  local message = 'Composing email (auto-save enabled)'
  if opts.template_id then
    local templates = require('neotex.plugins.tools.himalaya.core.templates')
    local template = templates.get_template(opts.template_id)
    if template then
      message = string.format('Composing from template: %s', template.name)
    end
  end
  
  notify.himalaya(message, notify.categories.STATUS)
  
  return buf
end

-- Reply to email
function M.reply_email(email, reply_all)
  -- Format the quoted body
  local quoted_body = ''
  if email.body then
    -- Split body into lines and prefix each with "> "
    for line in email.body:gmatch("[^\r\n]*") do
      quoted_body = quoted_body .. '> ' .. line .. '\n'
    end
  else
    quoted_body = '> [No content]\n'
  end
  
  -- Start with empty lines for user to type their reply
  local reply_body = '\n\n\n' .. string.rep('-', 40) .. '\n' ..
                     'On ' .. (email.date or 'Unknown date') .. ', ' .. 
                     (email.from or 'Unknown') .. ' wrote:\n\n' ..
                     quoted_body
  
  local opts = {
    to = email.from,
    subject = 'Re: ' .. (email.subject or ''),
    body = reply_body,
    reply_to = email.id,
  }
  
  if reply_all and email.cc then
    opts.cc = email.cc
  end
  
  return M.compose_email(opts)
end

-- Forward email
function M.forward_email(email)
  local opts = {
    subject = 'Fwd: ' .. (email.subject or ''),
    body = '\n\n' .. string.rep('-', 40) .. '\n' ..
           '---------- Forwarded message ----------\n' ..
           'From: ' .. (email.from or 'Unknown') .. '\n' ..
           'Date: ' .. (email.date or 'Unknown date') .. '\n' ..
           'Subject: ' .. (email.subject or '') .. '\n' ..
           'To: ' .. (email.to or '') .. '\n\n' ..
           (email.body or ''),
    forward_from = email.id,
  }
  
  return M.compose_email(opts)
end

-- Save draft manually
-- Create debounced save function for buffer
local function get_debounced_save(buf)
  if not debounced_saves[buf] then
    debounced_saves[buf] = performance.debounce(function()
      M.save_draft_immediate(buf)
    end, 1000)  -- 1 second debounce
  end
  return debounced_saves[buf]
end

-- Save draft to maildir (debounced version)
function M.save_draft(buf)
  local debounced = get_debounced_save(buf)
  debounced()
end

-- Save draft to maildir immediately
function M.save_draft_immediate(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  
  local draft_info = composer_buffers[buf]
  if not draft_info then
    notify.himalaya('Not a compose buffer', notify.categories.ERROR)
    return
  end
  
  -- Force save to file to ensure latest content is written
  vim.api.nvim_buf_call(buf, function()
    -- Get buffer content before saving
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    logger.debug('Buffer content before save', {
      line_count = #lines,
      lines = lines
    })
    
    -- Make sure we have DOS line endings for RFC compliance
    vim.bo.fileformat = 'dos'
    
    -- Mark as modified to force write even if vim thinks it's not
    vim.bo.modified = true
    vim.cmd('write!')
  end)
  
  -- Wait a moment to ensure file is written
  vim.wait(100)
  
  -- Debug: Check what was actually saved
  local saved_content = vim.fn.readfile(draft_info.file)
  logger.debug('Draft file content after save', {
    file = draft_info.file,
    line_count = #saved_content,
    first_10_lines = vim.list_slice(saved_content, 1, 10),
    has_empty_line = vim.tbl_contains(saved_content, ''),
    empty_line_position = vim.fn.index(saved_content, '')
  })
  
  -- Sync to maildir (update existing or create new)
  local new_draft_id = sync_draft_to_maildir(draft_info.file, draft_info.account, draft_info.draft_id)
  
  -- Only update draft_id if we got a new one
  if new_draft_id and new_draft_id ~= draft_info.draft_id then
    -- Clean up old tracking
    if draft_info.draft_id and draft_id_to_buffer[draft_info.draft_id] == buf then
      draft_id_to_buffer[draft_info.draft_id] = nil
    end
    
    -- Track new ID
    draft_id_to_buffer[new_draft_id] = buf
    draft_info.draft_id = new_draft_id
  end
  
  -- Update stored draft info
  if draft_info.draft_id then
    composer_buffers[buf] = draft_info
    state.set('compose.drafts.' .. buf, draft_info)
  end
  
  notify.himalaya('Draft saved', notify.categories.USER_ACTION)
end

-- Send email with scheduling (no immediate send)
function M.send_email(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  
  local draft_info = composer_buffers[buf]
  if not draft_info then
    notify.himalaya('Not a compose buffer', notify.categories.ERROR)
    return
  end
  
  -- Ensure draft is synced before sending
  if not draft_info.draft_id and draft_info.file then
    logger.warn('Draft not synced before send, syncing now')
    draft_info.draft_id = sync_draft_to_maildir(draft_info.file, draft_info.account, nil)
    if draft_info.draft_id then
      draft_info.draft_synced = true
      composer_buffers[buf] = draft_info
      state.set('compose.drafts.' .. buf, draft_info)
    end
  end
  
  logger.info('send_email: draft_info after sync check', {
    draft_id = draft_info.draft_id,
    original_draft_id = draft_info.original_draft_id,
    draft_synced = draft_info.draft_synced,
    file = draft_info.file
  })
  
  -- Always show this info for debugging
  notify.himalaya(string.format('Sending email with draft ID: %s', 
    tostring(draft_info.draft_id or 'none')), notify.categories.INFO)
  
  -- Save current content
  vim.api.nvim_buf_call(buf, function()
    vim.cmd('write!')
  end)
  
  -- Parse email
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local email = parse_email_buffer(lines)
  
  -- Validate required fields
  if not email.to or email.to == '' then
    notify.himalaya('Please specify a recipient', notify.categories.ERROR)
    return
  end
  
  -- Show scheduling options (no immediate send)
  M.show_scheduling_options(buf, draft_info, email)
end

-- Send email immediately (original behavior)
function M.send_immediate(buf, draft_info, email)
  notify.himalaya('Sending email...', notify.categories.STATUS)
  
  local ok, result = pcall(utils.send_email, draft_info.account, email)
  
  if ok and result then
    notify.himalaya('✅ Email sent immediately', notify.categories.USER_ACTION)
    M.cleanup_after_send(buf, draft_info)
  else
    notify.himalaya('❌ Failed to send email: ' .. tostring(result), notify.categories.ERROR)
  end
end

-- Send email with undo capability (60-second delay)
function M.send_with_undo(buf, draft_info, email)
  local send_queue = require('neotex.plugins.tools.himalaya.core.send_queue')
  
  -- Queue email for delayed send
  local queue_id = send_queue.queue_email(email, draft_info.account)
  
  if queue_id then
    -- Set up callback for successful send
    local original_queue = send_queue.queue[queue_id]
    if original_queue then
      -- Store cleanup info for when email is actually sent
      original_queue.composer_cleanup = {
        buf = buf,
        draft_info = draft_info
      }
    end
    
    -- Show queue status option
    notify.himalaya(
      "📨 Email queued with undo option. Use :HimalayaSendQueue to manage",
      notify.categories.USER_ACTION
    )
    
    -- Close composition buffer after queuing
    M.cleanup_after_send(buf, draft_info)
  else
    notify.himalaya('❌ Failed to queue email', notify.categories.ERROR)
  end
end

-- Scheduling options (no immediate send)
function M.show_scheduling_options(buf, draft_info, email)
  local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
  
  local options = {
    "1 minute (default)",
    "5 minutes",
    "30 minutes",
    "1 hour",
    "2 hours",
    "Tomorrow morning (9 AM)",
    "Custom time...",
    "Cancel"
  }
  
  vim.ui.select(options, {
    prompt = " When to send?",
    format_item = function(item)
      if item:match("Cancel") then
        return " " .. item
      else
        return " " .. item
      end
    end
  }, function(choice, idx)
    if not choice or choice == "Cancel" then
      return
    end
    
    local delay
    if idx == 1 then
      delay = 60        -- 1 minute
    elseif idx == 2 then
      delay = 300       -- 5 minutes
    elseif idx == 3 then
      delay = 1800      -- 30 minutes
    elseif idx == 4 then
      delay = 3600      -- 1 hour
    elseif idx == 5 then
      delay = 7200      -- 2 hours
    elseif idx == 6 then
      -- Tomorrow morning
      delay = M.calculate_delay_until_tomorrow(9, 0)
    elseif idx == 7 then
      -- Custom time picker
      M.show_custom_schedule_picker(buf, draft_info, email)
      return
    end
    
    -- Schedule the email
    -- Get draft folder for cleanup
    local draft_folder = utils.find_draft_folder(draft_info.account)
    
    logger.info('Scheduling email with draft metadata', {
      draft_file = draft_info.file,
      draft_id = draft_info.draft_id,
      draft_account = draft_info.account,
      draft_folder = draft_folder,
      original_draft_id = draft_info.original_draft_id,
      delay = delay
    })
    local queue_id = scheduler.schedule_email(email, draft_info.account, {
      delay = delay,
      metadata = {
        draft_file = draft_info.file,
        draft_id = draft_info.draft_id,
        draft_account = draft_info.account,
        draft_folder = draft_folder
      }
    })
    
    if queue_id then
      -- Clean up composer (notification is handled by scheduler)
      M.cleanup_after_queue(buf, draft_info)
    end
  end)
end

-- Calculate delay until tomorrow at specific time
function M.calculate_delay_until_tomorrow(hour, minute)
  local now = os.time()
  local tomorrow = now + 86400
  local date = os.date("*t", tomorrow)
  date.hour = hour
  date.min = minute
  date.sec = 0
  
  local target = os.time(date)
  return target - now
end

-- Custom time picker (placeholder for Phase 2)
function M.show_custom_schedule_picker(buf, draft_info, email)
  local current = os.date("%Y-%m-%d %H:%M", os.time() + 3600) -- Default to 1 hour from now
  
  vim.ui.input({
    prompt = "Send time (YYYY-MM-DD HH:MM): ",
    default = current,
  }, function(input)
    if not input then return end
    
    local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
    local new_time = M.parse_time_input(input)
    if new_time then
      local delay = new_time - os.time()
      if delay > 0 then
        local queue_id = scheduler.schedule_email(email, draft_info.account, {
          delay = delay,
          metadata = {
            draft_file = draft_info.file,
            draft_id = draft_info.draft_id,
            draft_account = draft_info.account
          }
        })
        
        if queue_id then
          M.cleanup_after_queue(buf, draft_info)
        end
      else
        notify.himalaya("Time must be in the future", notify.categories.ERROR)
      end
    else
      notify.himalaya("Invalid time format", notify.categories.ERROR, {
        input = input,
        expected_format = "YYYY-MM-DD HH:MM"
      })
    end
  end)
end

-- Parse time input
function M.parse_time_input(input)
  local year, month, day, hour, min = input:match("(%d+)-(%d+)-(%d+) (%d+):(%d+)")
  if year and month and day and hour and min then
    return os.time({
      year = tonumber(year),
      month = tonumber(month),
      day = tonumber(day),
      hour = tonumber(hour),
      min = tonumber(min),
      sec = 0
    })
  end
  return nil
end

-- Common cleanup after queuing
function M.cleanup_after_queue(buf, draft_info)
  -- DO NOT delete draft here - let the scheduler handle it after sending
  -- The scheduler needs the draft to remain until the email is actually sent
  
  -- Switch to alternate buffer before deleting (like :bd behavior)
  -- This prevents the sidebar from going full screen
  M.switch_to_normal_buffer(buf)
  
  -- Close compose buffer safely
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end

-- Discard email with modern confirmation dialog
function M.discard_email(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  
  local draft_info = composer_buffers[buf]
  if not draft_info then
    notify.himalaya('Not a compose buffer', notify.categories.ERROR)
    return
  end
  
  -- Use async confirmation prompt
  local modified = vim.api.nvim_buf_get_option(buf, 'modified')
  local message = modified and 'unsaved email draft' or 'email draft'
  local prompt = string.format(" Discard %s?", message)
  
  vim.ui.select({"No", "Yes"}, {
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
      -- User cancelled
      return
    end
    
    -- User selected Yes, proceed with discard
    -- Stop autosave
    if autosave_timers[buf] then
      vim.loop.timer_stop(autosave_timers[buf])
      autosave_timers[buf] = nil
    end
    
    -- Delete draft file
    vim.fn.delete(draft_info.file)
    
    -- Delete from maildir
    if draft_info.draft_id then
      delete_draft_from_maildir(draft_info.account, draft_info.draft_id)
    end
    
    -- Switch to alternate buffer before deleting (like :bd behavior)
    -- This prevents the sidebar from going full screen
    M.switch_to_normal_buffer(buf)
    
    -- Now delete the draft buffer
    vim.api.nvim_buf_delete(buf, { force = true })
  
    notify.himalaya('Email discarded', notify.categories.STATUS)
  end)
end

-- Check if buffer is a compose buffer
function M.is_compose_buffer(buf)
  return composer_buffers[buf] ~= nil
end

-- Get all active compose buffers
function M.get_compose_buffers()
  local buffers = {}
  for buf, info in pairs(composer_buffers) do
    if vim.api.nvim_buf_is_valid(buf) then
      table.insert(buffers, { buffer = buf, info = info })
    else
      -- Cleanup invalid buffer
      composer_buffers[buf] = nil
      if autosave_timers[buf] then
        vim.loop.timer_stop(autosave_timers[buf])
        autosave_timers[buf] = nil
      end
    end
  end
  return buffers
end

-- Force cleanup a compose buffer (for tests and edge cases)
-- This bypasses confirmation but uses proper buffer switching
function M.force_cleanup_compose_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  
  local draft_info = composer_buffers[buf]
  if not draft_info then
    -- Not a compose buffer, just delete it
    vim.api.nvim_buf_delete(buf, { force = true })
    return
  end
  
  -- Stop autosave
  if autosave_timers[buf] then
    vim.loop.timer_stop(autosave_timers[buf])
    autosave_timers[buf] = nil
  end
  
  -- Switch to normal buffer before cleanup
  M.switch_to_normal_buffer(buf)
  
  -- Clean up state
  composer_buffers[buf] = nil
  state.set('compose.drafts.' .. buf, nil)
  
  -- Delete the buffer
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_set_option(buf, 'modified', false)
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end

-- Close compose buffer properly
function M.close_compose_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  
  -- Switch to a normal buffer first
  M.switch_to_normal_buffer(buf)
  
  -- Clean up the compose buffer
  local draft_info = composer_buffers[buf]
  if draft_info then
    -- Stop autosave timer
    if autosave_timers[buf] then
      vim.loop.timer_stop(autosave_timers[buf])
      autosave_timers[buf] = nil
    end
    
    -- Clean up state
    composer_buffers[buf] = nil
    state.set('compose.drafts.' .. buf, nil)
  end
  
  -- Delete the buffer
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_set_option(buf, 'modified', false)
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end)
end

-- Switch to a normal buffer before closing a compose buffer
-- This prevents the sidebar from expanding to full screen
function M.switch_to_normal_buffer(closing_buf)
  local current_win = vim.api.nvim_get_current_win()
  
  -- Debug logging
  logger.debug('switch_to_normal_buffer called', {
    closing_buf = closing_buf,
    current_win = current_win,
    win_count = #vim.api.nvim_list_wins()
  })
  
  -- Check if we're in a special window (sidebar, preview, etc.)
  local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
  local sidebar_win = sidebar.get_win()
  
  if sidebar_win and current_win == sidebar_win then
    -- If we're in the sidebar, don't switch - let it handle itself
    logger.debug('Currently in sidebar window, skipping switch')
    return
  end
  
  -- Get list of all buffers and find a suitable normal buffer
  local buffers = vim.api.nvim_list_bufs()
  local alternate_buf = nil
  
  -- First pass: look for existing normal buffers
  for _, b in ipairs(buffers) do
    if b ~= closing_buf and vim.api.nvim_buf_is_valid(b) and vim.api.nvim_buf_is_loaded(b) then
      local buftype = vim.api.nvim_buf_get_option(b, 'buftype')
      local filetype = vim.api.nvim_buf_get_option(b, 'filetype')
      local name = vim.api.nvim_buf_get_name(b)
      
      -- Look for normal file buffers (not special buffers)
      if buftype == '' and 
         not filetype:match('^himalaya%-') and
         not name:match('draft_.*%.eml$') and  -- Skip other draft files
         not name:match('^%[.*%]$') then       -- Skip [No Name] type buffers
        alternate_buf = b
        break
      end
    end
  end
  
  -- Second pass: look for any non-special buffer
  if not alternate_buf then
    for _, b in ipairs(buffers) do
      if b ~= closing_buf and vim.api.nvim_buf_is_valid(b) and vim.api.nvim_buf_is_loaded(b) then
        local buftype = vim.api.nvim_buf_get_option(b, 'buftype')
        local filetype = vim.api.nvim_buf_get_option(b, 'filetype')
        
        -- Any normal buffer will do
        if buftype == '' and not filetype:match('^himalaya%-') then
          alternate_buf = b
          break
        end
      end
    end
  end
  
  -- If still no suitable buffer found, create a new scratch buffer
  if not alternate_buf then
    alternate_buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(alternate_buf, '[Scratch]')
    -- Set some basic options
    vim.api.nvim_buf_set_option(alternate_buf, 'buftype', '')
    vim.api.nvim_buf_set_option(alternate_buf, 'filetype', 'text')
  end
  
  -- Switch to the alternate buffer
  if vim.api.nvim_win_is_valid(current_win) and alternate_buf then
    logger.debug('Switching to alternate buffer', {
      current_win = current_win,
      alternate_buf = alternate_buf,
      buf_name = vim.api.nvim_buf_get_name(alternate_buf)
    })
    vim.api.nvim_win_set_buf(current_win, alternate_buf)
  else
    logger.warn('Could not switch to alternate buffer', {
      win_valid = vim.api.nvim_win_is_valid(current_win),
      alternate_buf = alternate_buf
    })
  end
end

-- Reopen existing draft for editing
function M.reopen_draft(provided_email_id)
  -- Check if we already have this draft open
  for buf, info in pairs(composer_buffers) do
    if vim.api.nvim_buf_is_valid(buf) and 
       (info.original_draft_id == provided_email_id or info.draft_id == provided_email_id) then
      -- Draft is already open, just switch to it
      local win = vim.fn.bufwinid(buf)
      if win ~= -1 then
        vim.api.nvim_set_current_win(win)
      else
        vim.cmd('buffer ' .. buf)
      end
      notify.himalaya('Draft already open', notify.categories.STATUS)
      return buf
    end
  end
  
  local email_id = provided_email_id
  
  -- If no email_id provided, try to get it from current position
  if not email_id then
    local main = require('neotex.plugins.tools.himalaya.ui.main')
    email_id = main.get_current_email_id()
  end
  
  -- Debug: Log what email_id we got
  logger.debug('reopen_draft: email_id', {
    email_id = email_id,
    email_id_type = type(email_id),
    provided = provided_email_id ~= nil,
    current_line = vim.fn.getline('.'),
    line_num = vim.fn.line('.'),
    current_folder = state.get_current_folder(),
    stack_trace = debug.traceback()
  })
  
  if not email_id then
    notify.himalaya('No draft selected', notify.categories.ERROR)
    return
  end
  
  -- Extra validation to catch the "Drafts" issue
  if type(email_id) == 'string' and email_id == state.get_current_folder() then
    logger.error('Email ID is same as folder name - this is a bug!', {
      email_id = email_id,
      folder = state.get_current_folder()
    })
    notify.himalaya('Error: Invalid draft selection (got folder name instead of ID)', notify.categories.ERROR)
    return
  end
  
  -- Validate email_id is a number or numeric string
  local numeric_id = tonumber(email_id)
  if not numeric_id then
    logger.error('Invalid email ID for draft', {
      email_id = email_id,
      type = type(email_id)
    })
    notify.himalaya('Invalid draft ID: ' .. tostring(email_id), notify.categories.ERROR)
    return
  end
  
  -- Additional safeguard: ensure it's not a folder name
  if tostring(email_id) == 'Drafts' or tostring(email_id):match('^[A-Za-z]+$') then
    logger.error('Email ID looks like a folder name', {
      email_id = email_id
    })
    notify.himalaya('Invalid draft selection', notify.categories.ERROR)
    return
  end
  
  -- Fetch draft content from current folder (we're already in drafts)
  local account = state.get_current_account()
  local current_folder = state.get_current_folder()
  
  if not current_folder then
    notify.himalaya('No current folder', notify.categories.ERROR)
    return
  end
  
  -- Invalidate the draft cache to ensure preview shows fresh content when we return
  local email_cache = require('neotex.plugins.tools.himalaya.core.email_cache')
  email_cache.store_email_body(account, current_folder, email_id, nil)
  
  -- Debug: Log the email ID we're trying to read
  logger.debug('Reopening draft', {
    email_id = email_id,
    numeric_id = numeric_id,
    account = account,
    folder = current_folder
  })
  
  -- Add draft debug tracking
  draft_debug.debug_lifecycle_event('reopen_attempt', nil, email_id, {
    account = account,
    folder = current_folder,
    numeric_id = numeric_id
  })
  
  -- Always use himalaya to get the correct draft by ID
  -- Don't use local files as they don't have a mapping to draft IDs
  local draft_content_found = false
  local email = {}
  
  if true then  -- Always use himalaya
    logger.debug('No local draft found, trying himalaya')
    
    -- Use utils.execute_himalaya for consistent command execution
    -- Note: Don't include --preview as it's added by execute_himalaya if needed
    local args = { 'message', 'read', tostring(numeric_id) }
    
    logger.debug('Calling execute_himalaya', {
      args = args,
      account = account,
      folder = current_folder
    })
    
    local result = utils.execute_himalaya(args, { 
      account = account, 
      folder = current_folder 
    })
    
    if not result then
      notify.himalaya('Failed to load draft content', notify.categories.ERROR)
      return
    end
    
    -- Debug: log what we got back
    logger.debug('Draft read result', {
      result_type = type(result),
      result_length = type(result) == 'string' and #result or nil,
      result_preview = type(result) == 'string' and result:sub(1, 500) or vim.inspect(result)
    })
    
    -- Handle both string output (plain text) and table output (JSON)
    local output
    if type(result) == 'string' then
      output = result
    elseif type(result) == 'table' then
      -- If it's JSON, we need to extract the body
      output = result.body or vim.json.encode(result)
    else
      output = tostring(result)
    end
  
  -- Parse the draft content using our robust parser
  local email
  if type(result) == 'table' then
    -- JSON response - convert to email format
    email = {
      from = result.from or '',
      to = result.to or '',
      cc = result.cc or '',
      bcc = result.bcc or '',
      subject = result.subject or '',
      body = result.body or '',
      headers = result.headers or {}
    }
  else
    -- Text response - use robust parser
    email = draft_parser.parse_himalaya_draft(result)
    
    -- Validate the parsed email
    local is_valid, validation_errors = draft_parser.validate_email(email)
    if not is_valid then
      logger.warn('Draft validation issues', {
        draft_id = numeric_id,
        errors = validation_errors
      })
    end
  end
  
  logger.info('Draft lifecycle: Parsed draft content', {
    draft_id = numeric_id,
    has_from = email.from ~= '',
    has_to = email.to ~= '',
    has_subject = email.subject ~= '',
    body_length = #(email.body or ''),
    parse_errors = #(email.errors or {})
  })
  
  -- Debug parsed draft
  draft_debug.debug_draft_content('reopen_parsed', 'draft_' .. numeric_id, email)
  draft_debug.debug_lifecycle_event('reopen_parsed', nil, numeric_id, {
    parsed_email = email
  })
  
  -- Check for multipart markers and extract content
  if email.body then
    -- Handle <#part type=application/octet-stream> markers
    local content_match = email.body:match('<#part type=application/octet%-stream>\n?(.-)\n?<#')
    if content_match then
      email.body = content_match
      logger.debug('Extracted content from multipart markers', { 
        extracted_length = #content_match 
      })
    end
    
    -- Also handle the case where the markers are at the beginning/end
    email.body = email.body:gsub('^<#part type=application/octet%-stream>\n?', '')
    email.body = email.body:gsub('\n?<#!part.->\n?<#!/part>\n?$', '')
    email.body = email.body:gsub('<#!/part>\n?$', '')  -- Sometimes just the end marker
  end
  
  -- If we still have no body, try maildir fallback
  if not email.body or email.body == '' then
    logger.warn('Draft appears to have no body content, trying maildir fallback', {
      email_id = email_id,
      parsed_headers = {
        from = email.from,
        to = email.to,
        subject = email.subject
      },
      raw_output_length = #output,
      raw_output_preview = output:sub(1, 200)
    })
    
    -- Try to read directly from maildir (known himalaya bug workaround)
    local maildir_content = draft_maildir.read_draft_from_maildir(account, numeric_id)
    if maildir_content then
      logger.info('Using maildir fallback for draft content')
      -- Parse the maildir content
      local maildir_email = draft_parser.parse_himalaya_draft(maildir_content)
      
      -- Merge with what we got from himalaya (prefer maildir body, himalaya headers)
      if maildir_email.body and maildir_email.body ~= '' then
        email.body = maildir_email.body
        logger.info('Successfully recovered draft body from maildir', {
          body_length = #email.body
        })
      end
      
      -- Also update other fields if they were missing
      if (not email.subject or email.subject == '') and maildir_email.subject then
        email.subject = maildir_email.subject
      end
      if (not email.to or email.to == '') and maildir_email.to then
        email.to = maildir_email.to
      end
    else
      logger.warn('Maildir fallback failed - trying local cache')
      
      -- Try local cache as final fallback
      local local_content = local_draft_cache.load_draft_content(account, numeric_id)
      if local_content then
        logger.info('Using local cache fallback for draft content')
        -- Parse the cached content
        local cached_email = draft_parser.parse_himalaya_draft(local_content)
        
        -- Merge with what we got from himalaya
        if cached_email.body and cached_email.body ~= '' then
          email.body = cached_email.body
          logger.info('Successfully recovered draft body from local cache', {
            body_length = #email.body
          })
        end
        
        -- Also update other fields if they were missing
        if (not email.subject or email.subject == '') and cached_email.subject then
          email.subject = cached_email.subject
        end
        if (not email.to or email.to == '') and cached_email.to then
          email.to = cached_email.to
        end
      else
        logger.error('All fallbacks failed - draft content lost')
      end
    end
  end
  
    -- Create compose buffer with existing content
    -- For reopened drafts, we should create a new local file since we don't know
    -- which local file corresponds to this maildir draft
    local opts = {
      to = email.to,
      cc = email.cc,
      bcc = email.bcc,
      subject = email.subject,
      body = email.body,
      is_draft_reopen = true,
      original_draft_id = email_id,
      -- Don't pass existing_draft_file - let it create a new local file
    }
    
    local buf = M.create_compose_buffer(opts)
    
    -- Store the draft ID to prevent duplicates
    vim.defer_fn(function()
      local draft_info = composer_buffers[buf]
      if draft_info then
        -- Don't delete the original - just track it
        draft_info.draft_id = email_id
        draft_info.original_draft_id = email_id
        draft_info.draft_synced = true  -- Mark as already synced
        composer_buffers[buf] = draft_info
        state.set('compose.drafts.' .. buf, draft_info)
        logger.info('Reopened draft from himalaya', {
          buf = buf,
          draft_id = email_id
        })
      end
    end, 100)
    
    notify.himalaya('Draft reopened for editing', notify.categories.STATUS)
    
    return buf
  end  -- End of 'if not draft_content_found then'
end

return M