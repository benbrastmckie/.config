-- Email Composer v2 - Refactored with new draft system
-- Simplified composition with unified draft management

local M = {}

-- Dependencies
local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_maildir')
local draft_notifications = require('neotex.plugins.tools.himalaya.core.draft_notifications')
-- draft_parser removed - we now save raw content without parsing
local state = require('neotex.plugins.tools.himalaya.core.state')
local config = require('neotex.plugins.tools.himalaya.core.config')
local utils = require('neotex.plugins.tools.himalaya.utils')
local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
local window_stack = require('neotex.plugins.tools.himalaya.ui.window_stack') -- Phase 6

-- Module state
local autosave_timers = {}

-- Configuration
M.config = {
  use_tab = true,
  auto_save_interval = 5,  -- Reduced from 30 to 5 seconds
  delete_draft_on_send = true,
  syntax_highlighting = true,
}

-- Initialize module
function M.setup(cfg)
  if cfg and cfg.compose then
    M.config = vim.tbl_extend('force', M.config, cfg.compose)
  end
  
  -- Initialize draft manager and local storage
  draft_manager.setup()
  local storage = require('neotex.plugins.tools.himalaya.core.local_storage')
  storage.setup()
end

-- Create email template lines
local function format_email_template(opts)
  opts = opts or {}
  
  local account_name = opts.account or state.get_current_account()
  local from = opts.from or config.get_formatted_from(account_name) or 
               draft_manager._get_default_from(account_name)
  
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
    local body_lines = vim.split(opts.body, '\n', { plain = true })
    vim.list_extend(lines, body_lines)
  else
    -- Add a blank line for the body to make it clear where to type
    table.insert(lines, '')
  end
  
  return lines
end

-- Setup autosave for a buffer
local function setup_autosave(buf)
  -- Clear any existing timer
  if autosave_timers[buf] then
    vim.loop.timer_stop(autosave_timers[buf])
    autosave_timers[buf] = nil
  end
  
  local timer = vim.loop.new_timer()
  autosave_timers[buf] = timer
  
  -- Auto-save every N seconds
  timer:start(
    M.config.auto_save_interval * 1000,
    M.config.auto_save_interval * 1000,
    vim.schedule_wrap(function()
      if not vim.api.nvim_buf_is_valid(buf) then
        timer:stop()
        autosave_timers[buf] = nil
        return
      end
      
      -- Check if buffer is modified
      if vim.api.nvim_buf_get_option(buf, 'modified') then
        M.save_draft(buf, 'autosave')
      end
    end)
  )
end

-- Parse headers only for display purposes
function M.parse_headers_for_display(lines)
  local headers = {}
  
  for _, line in ipairs(lines) do
    if line == '' then
      break  -- End of headers
    end
    local key, value = line:match('^([^:]+):%s*(.*)$')
    if key then
      headers[key:lower()] = value
    end
  end
  
  return {
    from = headers.from or '',
    to = headers.to or '',
    subject = headers.subject or '',
    cc = headers.cc or '',
    bcc = headers.bcc or ''
  }
end

-- Save draft (manual or auto)
function M.save_draft(buf, trigger)
  local draft = draft_manager.get_by_buffer(buf)
  if not draft then
    return false, "No draft associated with buffer"
  end
  
  -- Get the ENTIRE buffer content as-is
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local content = table.concat(lines, '\n')
  
  -- Save to .eml file (for :w behavior)
  vim.api.nvim_buf_call(buf, function()
    vim.cmd('silent write!')
  end)
  
  -- Save complete content to draft storage
  local storage = require('neotex.plugins.tools.himalaya.core.local_storage')
  local ok, err = storage.save(draft.local_id, {
    content = content,  -- Save ENTIRE content, don't parse yet
    account = draft.account,
    remote_id = draft.remote_id,
    -- Parse metadata only for display purposes
    metadata = M.parse_headers_for_display(lines),
    created_at = draft.created_at,
    updated_at = os.time()
  })
  
  if not ok then
    draft_notifications.draft_save_failed(draft.local_id, err)
    return false, err
  end
  
  -- Mark buffer as unmodified
  vim.api.nvim_buf_set_option(buf, 'modified', false)
  
  -- Update draft object with latest metadata for UI
  draft.metadata = M.parse_headers_for_display(lines)
  
  -- Queue remote sync only if draft has meaningful content
  -- Check if body has content (not just headers)
  local has_body = false
  local in_body = false
  for _, line in ipairs(lines) do
    if in_body and line:match('%S') then  -- Non-whitespace in body
      has_body = true
      break
    elseif line == '' then  -- Empty line marks start of body
      in_body = true
    end
  end
  
  -- Don't auto-sync to remote - keep everything local until manual sync
  draft_notifications.debug_lifecycle('local_save_only', draft.local_id, {
    trigger = trigger,
    has_body = has_body
  })
  
  -- Update UI to show local draft
  M.update_ui_after_save(draft)
  
  return true
end

-- Sync draft to remote using himalaya template save
function M.sync_draft_to_remote(draft, content)
  -- Check if content has actual body content before attempting sync
  local lines = vim.split(content, '\n')
  local has_body = false
  local in_body = false
  for _, line in ipairs(lines) do
    if in_body and line:match('%S') then
      has_body = true
      break
    elseif line == '' then
      in_body = true
    end
  end
  
  if not has_body then
    draft_notifications.debug_lifecycle('sync_skipped', draft.local_id, {
      reason = 'no_body_content_in_sync'
    })
    -- Still update UI to show local draft
    M.update_ui_after_save(draft)
    return
  end
  
  -- Create temp file with content
  local tmpfile = vim.fn.tempname()
  vim.fn.writefile(vim.split(content, '\n'), tmpfile)
  
  -- Build himalaya command using shell to handle redirection
  local cmd_str = string.format(
    'himalaya template save --account %s --folder Drafts < %s',
    vim.fn.shellescape(draft.account),
    vim.fn.shellescape(tmpfile)
  )
  
  -- Use shell to execute the command with proper redirection
  vim.fn.jobstart({'sh', '-c', cmd_str}, {
    on_stdout = function(_, data)
      -- Capture any output for debugging
      if data and #data > 0 then
        for _, line in ipairs(data) do
          if line ~= '' then
            draft_notifications.debug_lifecycle('sync_output', draft.local_id, { output = line })
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        -- Filter out empty lines and combine error messages
        local error_lines = {}
        for _, line in ipairs(data) do
          if line ~= '' and not line:match('^%s*$') then
            table.insert(error_lines, line)
          end
        end
        if #error_lines > 0 then
          -- Extract the main error message
          local error_msg = error_lines[1]
          for _, line in ipairs(error_lines) do
            if line:match('cannot parse MML message') or line:match('empty body') then
              error_msg = 'Draft needs content before syncing'
              break
            end
          end
          -- Store error but don't notify if it's just empty body
          draft.sync_error = error_msg
          if not error_msg:match('needs content') then
            draft_notifications.draft_sync_failed(draft.local_id, error_msg)
          end
        end
      end
    end,
    on_exit = function(_, exit_code)
      vim.fn.delete(tmpfile)
      if exit_code == 0 then
        -- Success - update sync status
        draft.state = draft_manager.states.SYNCED
        draft.last_sync = os.time()
        draft_notifications.draft_synced(draft.local_id)
        
        -- After successful sync, refresh the sidebar if showing drafts
        vim.schedule(function()
          M.update_ui_after_save(draft)
        end)
        
        -- If this was first sync, we need to get the remote_id
        if not draft.remote_id then
          -- Schedule a refresh to get the new remote_id
          vim.defer_fn(function()
            M.fetch_remote_id_for_draft(draft)
          end, 500)  -- Reduced from 1000ms to 500ms for faster update
        end
      else
        -- Sync failed - check if we already reported error
        if not draft.sync_error or not draft.sync_error:match('needs content') then
          draft.state = draft_manager.states.ERROR
          draft.sync_error = draft.sync_error or 'Failed to sync to remote'
          draft_notifications.draft_sync_failed(draft.local_id, draft.sync_error)
        end
      end
    end
  })
end

-- Update UI after saving draft
function M.update_ui_after_save(draft)
  -- Don't refresh the sidebar automatically - it's disruptive
  -- Users can manually refresh with 'gs' if needed
  
  -- Update preview if showing this draft
  local preview = require('neotex.plugins.tools.himalaya.ui.email_preview')
  if preview.is_preview_visible() then
    if preview.get_current_preview_id() == (draft.remote_id or draft.local_id) then
      -- Re-render the preview with updated content
      preview.hide_preview()
      preview.show_preview(draft.remote_id or draft.local_id, nil, 'draft')
    end
  end
end

-- Fetch remote ID for a newly synced draft
function M.fetch_remote_id_for_draft(draft)
  -- Get the most recent draft from the server
  local cmd = {
    'himalaya', 'envelope', 'list',
    '--account', draft.account,
    '--folder', 'Drafts',
    '--page', '1',
    '--page-size', '10',
    '-o', 'json'
  }
  
  local output = {}
  vim.fn.jobstart(cmd, {
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= '' then
            table.insert(output, line)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        for _, line in ipairs(data) do
          if line ~= '' then
            draft_notifications.debug_lifecycle('fetch_remote_id_error', draft.local_id, {
              error = line
            })
          end
        end
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code == 0 and #output > 0 then
        -- Parse JSON output
        local ok, result = pcall(vim.json.decode, table.concat(output, '\n'))
        if ok and type(result) == 'table' then
          -- Look for our draft by matching subject or find the most recent
          for _, envelope in ipairs(result) do
            if envelope.id and envelope.subject == draft.metadata.subject then
              draft.remote_id = tostring(envelope.id)
              -- Update storage with remote_id
              local storage = require('neotex.plugins.tools.himalaya.core.local_storage')
              local stored = storage.load(draft.local_id)
              if stored then
                stored.remote_id = draft.remote_id
                storage.save(draft.local_id, stored)
              end
              
              draft_notifications.debug_lifecycle('remote_id_found', draft.local_id, {
                remote_id = draft.remote_id
              })
              
              -- Update UI now that we have the remote ID
              vim.schedule(function()
                M.update_ui_after_save(draft)
              end)
              break
            end
          end
        end
      else
        draft_notifications.debug_lifecycle('fetch_remote_id_failed', draft.local_id, {
          exit_code = exit_code,
          output_lines = #output
        })
      end
    end
  })
end

-- Setup buffer keymaps and autocmds
local function setup_buffer_mappings(buf)
  local opts = { buffer = buf, noremap = true, silent = true }
  
  -- Tab navigation in insert mode
  vim.keymap.set('i', '<Tab>', function()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    
    -- Find next field or body
    for i = line + 1, #lines do
      if lines[i] == '' then
        -- Found empty line (header/body separator)
        -- Make sure we have a line after it for the body
        if i == #lines then
          -- Add a new line for the body
          vim.api.nvim_buf_set_lines(buf, -1, -1, false, {''})
          lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        end
        -- Jump to body (line after the empty line)
        local body_line = math.min(i + 1, #lines)
        vim.api.nvim_win_set_cursor(0, { body_line, 0 })
        -- Exit insert mode and re-enter to position cursor properly (unless in test mode)
        vim.cmd('stopinsert')
        if not _G.HIMALAYA_TEST_MODE then
          vim.schedule(function()
            vim.cmd('startinsert')
          end)
        end
        return
      elseif lines[i]:match('^[^:]+:%s*$') then
        -- Jump to end of header line
        vim.api.nvim_win_set_cursor(0, { i, #lines[i] })
        return
      end
    end
    
    -- If we're at the end and no empty line found, we're likely in the body already
    -- Just insert a tab
    vim.api.nvim_feedkeys('\t', 'n', false)
  end, opts)
  
  -- Shift-Tab to go to previous field in insert mode
  vim.keymap.set('i', '<S-Tab>', function()
    local pos = vim.api.nvim_win_get_cursor(0)
    local line = pos[1]
    local col = pos[2]
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    
    -- If we're in the body (after empty line), go back to last header
    local empty_line = 0
    for i = 1, #lines do
      if lines[i] == '' then
        empty_line = i
        break
      end
    end
    
    if line > empty_line and empty_line > 0 then
      -- We're in body, go to Subject line
      for i = empty_line - 1, 1, -1 do
        if lines[i]:match('^Subject:') then
          vim.api.nvim_win_set_cursor(0, { i, #lines[i] })
          return
        end
      end
    else
      -- Find previous field
      for i = line - 1, 1, -1 do
        if lines[i]:match('^[^:]+:%s*') then
          vim.api.nvim_win_set_cursor(0, { i, #lines[i] })
          return
        end
      end
    end
  end, opts)
  
  -- Manual save
  vim.keymap.set('n', '<C-s>', function()
    M.save_draft(buf, 'manual')
  end, opts)
  
  -- Override default write behavior to use our save
  vim.api.nvim_create_autocmd('BufWriteCmd', {
    buffer = buf,
    callback = function()
      M.save_draft(buf, 'write_cmd')
      -- Prevent default write behavior
      return true
    end,
    desc = 'Handle :w for draft buffer'
  })
  
  -- NOTE: Leader mappings are now defined in which-key.lua
  -- The following mappings have been moved:
  -- <leader>q - Close compose buffer -> Moved to <leader>mq in which-key
  -- <leader>s - Send and close -> Conflicts with surround, use <leader>me instead
  
  -- Note: Removed "save on first change" autocmd to prevent creating drafts with incomplete content
  -- The autosave timer (every 5 seconds) will handle saving once the user has added meaningful content
  
  -- Save draft before unload
  vim.api.nvim_create_autocmd('BufUnload', {
    buffer = buf,
    callback = function()
      -- Save draft if modified
      if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_option(buf, 'modified') then
        M.save_draft(buf, 'before_unload')
      end
      
      -- Stop autosave timer
      if autosave_timers[buf] then
        vim.loop.timer_stop(autosave_timers[buf])
        autosave_timers[buf] = nil
      end
      
      -- Draft manager handles cleanup automatically via autocmd
    end
  })
  
  -- Handle buffer deletion to avoid [No Name] buffers
  vim.api.nvim_create_autocmd('BufWipeout', {
    buffer = buf,
    callback = function()
      -- Save draft state before wipeout
      local should_close_tab = false
      if M.config.use_tab then
        local tabpage = vim.api.nvim_get_current_tabpage()
        local wins = vim.api.nvim_tabpage_list_wins(tabpage)
        should_close_tab = #wins <= 1 and vim.fn.tabpagenr('$') > 1
      end
      
      -- Clean up after buffer is wiped
      vim.schedule(function()
        if should_close_tab then
          -- Find and close the tab that had the draft
          for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
            local tab_wins = vim.api.nvim_tabpage_list_wins(tab)
            local all_unnamed = true
            for _, win in ipairs(tab_wins) do
              if vim.api.nvim_win_is_valid(win) then
                local win_buf = vim.api.nvim_win_get_buf(win)
                if vim.api.nvim_buf_get_name(win_buf) ~= '' then
                  all_unnamed = false
                  break
                end
              end
            end
            if all_unnamed and #tab_wins > 0 then
              vim.cmd('tabclose ' .. vim.api.nvim_tabpage_get_number(tab))
              break
            end
          end
        end
      end)
    end
  })
  
  -- Handle window close for window stack (Phase 6)
  vim.api.nvim_create_autocmd('BufWinLeave', {
    buffer = buf,
    once = true,
    callback = function()
      if config.get('draft.integration.use_window_stack', false) then
        window_stack.close_current()
      end
    end
  })
  
  -- Set filetype for syntax highlighting
  if M.config.syntax_highlighting then
    vim.api.nvim_buf_set_option(buf, 'filetype', 'mail')
  end
  
  -- Setup status line
  local compose_status = require('neotex.plugins.tools.himalaya.ui.compose_status')
  compose_status.setup_statusline(buf)
  
  -- Create buffer-local commands
  vim.api.nvim_buf_create_user_command(buf, 'HimalayaSend', function()
    M.send_and_close(buf)
  end, { desc = 'Send email and close buffer' })
  
  vim.api.nvim_buf_create_user_command(buf, 'HimalayaClose', function()
    M.close_compose_buffer(buf)
  end, { desc = 'Close compose buffer properly' })
  
  vim.api.nvim_buf_create_user_command(buf, 'HimalayaSave', function()
    M.save_draft(buf, 'manual')
  end, { desc = 'Save draft' })
end

-- Export this function so compose_status can hook into it
M.setup_buffer_mappings = setup_buffer_mappings

-- Create compose buffer
function M.create_compose_buffer(opts)
  opts = opts or {}
  
  -- Generate unique filename with microsecond precision
  local timestamp = os.date('%Y%m%d_%H%M%S')
  local unique_id = vim.loop.hrtime()
  local draft_file = string.format('%s/draft_%s_%s.eml', 
    vim.fn.stdpath('data') .. '/himalaya/drafts', timestamp, unique_id)
  
  -- Ensure directory exists
  vim.fn.mkdir(vim.fn.fnamemodify(draft_file, ':h'), 'p')
  
  -- Create buffer
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, draft_file)
  
  -- Set initial content
  local lines = format_email_template(opts)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Create draft in manager
  local account = opts.account or state.get_current_account()
  local draft = draft_manager.create(buf, account, {
    subject = opts.subject,
    to = opts.to,
    from = opts.from,
    cc = opts.cc,
    bcc = opts.bcc,
    reply_to = opts.reply_to,
    compose_type = opts.compose_type or 'new'
  })
  
  -- Debug notification
  draft_notifications.debug_lifecycle('compose_buffer_created', draft.local_id, {
    buffer = buf,
    compose_type = opts.compose_type,
    account = account
  })
  
  -- Setup buffer
  setup_buffer_mappings(buf)
  setup_autosave(buf)
  
  -- Open buffer like a normal file
  local parent_win = vim.api.nvim_get_current_win()
  local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
  local sidebar_win = sidebar.get_win()
  
  -- If we're in the sidebar, find or create a window to the right
  if parent_win == sidebar_win then
    local wins = vim.api.nvim_tabpage_list_wins(0)
    local target_win = nil
    
    -- Find a non-sidebar window
    for _, win in ipairs(wins) do
      if win ~= sidebar_win and vim.api.nvim_win_is_valid(win) then
        target_win = win
        break
      end
    end
    
    if target_win then
      -- Use existing window
      vim.api.nvim_set_current_win(target_win)
      vim.api.nvim_win_set_buf(target_win, buf)
    else
      -- Create a new window to the right of sidebar
      vim.cmd('wincmd l')  -- Try to move right
      if vim.api.nvim_get_current_win() == sidebar_win then
        -- Still in sidebar, create a new window
        vim.cmd('vsplit')
      end
      vim.api.nvim_win_set_buf(0, buf)
    end
  else
    -- Not in sidebar, just open in current window (like :edit)
    vim.api.nvim_win_set_buf(parent_win, buf)
  end
  
  -- Track window in stack if enabled (Phase 6)
  if config.get('draft.integration.use_window_stack', false) then
    local win_id = vim.api.nvim_get_current_win()
    window_stack.push_draft(win_id, draft.local_id, parent_win)
  end
  
  -- Position cursor on To: field if empty
  if not opts.to or opts.to == '' then
    vim.api.nvim_win_set_cursor(0, { 2, 4 })
  else
    -- Position in body (after empty line separator)
    vim.api.nvim_win_set_cursor(0, { 7, 0 })
  end
  
  -- Start in insert mode (unless in test mode)
  if not _G.HIMALAYA_TEST_MODE then
    vim.cmd('startinsert!')
  end
  
  -- Don't save immediately - wait for actual content
  -- The autosave timer will handle the first save when content is added
  
  return buf
end

-- Open local draft by local_id
function M.open_local_draft(local_id, account)
  -- Validate local_id
  if not local_id or local_id == "" or local_id == "nil" then
    draft_notifications.draft_load_failed(local_id or "nil", "Invalid local draft ID")
    return nil
  end
  
  local storage = require('neotex.plugins.tools.himalaya.core.local_storage')
  local draft_data = storage.load(local_id)
  
  if not draft_data or not draft_data.content then
    draft_notifications.draft_load_failed(local_id, "Local draft not found")
    return nil
  end
  
  -- Create buffer and set content
  local buf = vim.api.nvim_create_buf(true, false)
  local draft_file = string.format('%s/%s.eml',
    vim.fn.stdpath('data') .. '/himalaya/drafts', local_id)
  vim.api.nvim_buf_set_name(buf, draft_file)
  
  -- Set content without parsing
  local lines = vim.split(draft_data.content, '\n')
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Parse headers for metadata
  local metadata = M.parse_headers_for_display(lines)
  
  -- Create draft in manager
  local draft = draft_manager.create(buf, account, {
    local_id = local_id,
    subject = metadata.subject,
    to = metadata.to,
    from = metadata.from,
    cc = metadata.cc,
    bcc = metadata.bcc,
    compose_type = 'edit'
  })
  
  -- Set remote ID if available
  if draft_data.remote_id then
    draft.remote_id = draft_data.remote_id
    draft.state = draft_manager.states.SYNCED
  end
  
  -- Setup buffer
  setup_buffer_mappings(buf)
  setup_autosave(buf)
  
  -- Open buffer like a normal file
  local parent_win = vim.api.nvim_get_current_win()
  local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
  local sidebar_win = sidebar.get_win()
  
  -- If we're in the sidebar, find or create a window to the right
  if parent_win == sidebar_win then
    local wins = vim.api.nvim_tabpage_list_wins(0)
    local target_win = nil
    
    -- Find a non-sidebar window
    for _, win in ipairs(wins) do
      if win ~= sidebar_win and vim.api.nvim_win_is_valid(win) then
        target_win = win
        break
      end
    end
    
    if target_win then
      -- Use existing window
      vim.api.nvim_set_current_win(target_win)
      vim.api.nvim_win_set_buf(target_win, buf)
    else
      -- Create a new window to the right of sidebar
      vim.cmd('wincmd l')  -- Try to move right
      if vim.api.nvim_get_current_win() == sidebar_win then
        -- Still in sidebar, create a new window
        vim.cmd('vsplit')
      end
      vim.api.nvim_win_set_buf(0, buf)
    end
  else
    -- Not in sidebar, just open in current window (like :edit)
    vim.api.nvim_win_set_buf(parent_win, buf)
  end
  
  -- Track window in stack if enabled
  if config.get('draft.integration.use_window_stack', false) then
    local win_id = vim.api.nvim_get_current_win()
    window_stack.push_draft(win_id, draft.local_id, parent_win)
  end
  
  return buf
end

-- Open existing draft
function M.open_draft(draft_id, account)
  -- Check if draft already exists locally
  local storage = require('neotex.plugins.tools.himalaya.core.local_storage')
  local existing = storage.find_by_remote_id(draft_id, account)
  
  local content = nil
  local local_id = nil
  
  if existing then
    -- Load from local storage
    content = existing.content
    local_id = existing.local_id
  else
    -- Try to load from himalaya
    local ok, result = pcall(utils.execute_himalaya, 
      { 'message', 'read', tostring(draft_id) },
      { account = account, folder = 'Drafts' }
    )
    
    if ok and result then
      content = result
      local_id = 'draft_' .. draft_id .. '_' .. os.time()
    else
      draft_notifications.draft_load_failed(draft_id, result or "Failed to load draft")
      return nil
    end
  end
  
  -- Validate local_id to prevent nil.eml
  if not local_id or local_id == "" then
    local_id = 'draft_' .. tostring(draft_id) .. '_' .. os.time()
    draft_notifications.debug_lifecycle('generated_local_id', nil, {
      draft_id = draft_id,
      local_id = local_id
    })
  end
  
  -- Create buffer and set content as-is
  local buf = vim.api.nvim_create_buf(true, false)
  local draft_file = string.format('%s/%s.eml',
    vim.fn.stdpath('data') .. '/himalaya/drafts', local_id)
  vim.api.nvim_buf_set_name(buf, draft_file)
  
  -- Set content without parsing
  local lines = vim.split(content, '\n')
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Parse headers for metadata
  local metadata = M.parse_headers_for_display(lines)
  
  -- Create draft in manager with explicit local_id
  local draft = draft_manager.create(buf, account, {
    local_id = local_id,  -- Pass explicit local_id
    subject = metadata.subject,
    to = metadata.to,
    from = metadata.from,
    cc = metadata.cc,
    bcc = metadata.bcc,
    compose_type = 'edit'
  })
  
  -- Set remote ID
  draft.remote_id = tostring(draft_id)
  draft.state = draft_manager.states.SYNCED
  
  -- Debug notification
  draft_notifications.debug_lifecycle('draft_opened', draft.local_id, {
    remote_id = draft_id,
    buffer = buf
  })
  
  -- Setup buffer
  setup_buffer_mappings(buf)
  setup_autosave(buf)
  
  -- Open buffer like a normal file
  local parent_win = vim.api.nvim_get_current_win()
  local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
  local sidebar_win = sidebar.get_win()
  
  -- If we're in the sidebar, find or create a window to the right
  if parent_win == sidebar_win then
    local wins = vim.api.nvim_tabpage_list_wins(0)
    local target_win = nil
    
    -- Find a non-sidebar window
    for _, win in ipairs(wins) do
      if win ~= sidebar_win and vim.api.nvim_win_is_valid(win) then
        target_win = win
        break
      end
    end
    
    if target_win then
      -- Use existing window
      vim.api.nvim_set_current_win(target_win)
      vim.api.nvim_win_set_buf(target_win, buf)
    else
      -- Create a new window to the right of sidebar
      vim.cmd('wincmd l')  -- Try to move right
      if vim.api.nvim_get_current_win() == sidebar_win then
        -- Still in sidebar, create a new window
        vim.cmd('vsplit')
      end
      vim.api.nvim_win_set_buf(0, buf)
    end
  else
    -- Not in sidebar, just open in current window (like :edit)
    vim.api.nvim_win_set_buf(parent_win, buf)
  end
  
  -- Track window in stack if enabled (Phase 6)
  if config.get('draft.integration.use_window_stack', false) then
    local win_id = vim.api.nvim_get_current_win()
    window_stack.push_draft(win_id, draft.local_id, parent_win)
  end
  
  return buf
end

-- Send email and close buffer
function M.send_and_close(buf)
  local draft = draft_manager.get_by_buffer(buf)
  if not draft then
    return false, "No draft associated with buffer"
  end
  
  -- Get current buffer content
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local metadata = M.parse_headers_for_display(lines)
  
  -- Extract body
  local body_start = 1
  for i, line in ipairs(lines) do
    if line == '' then
      body_start = i + 1
      break
    end
  end
  
  local body = ''
  if body_start <= #lines then
    local body_lines = {}
    for i = body_start, #lines do
      table.insert(body_lines, lines[i])
    end
    body = table.concat(body_lines, '\n')
  end
  
  -- Schedule email
  local schedule_time = os.time() + 60 -- 1 minute from now
  local scheduled_id = scheduler.schedule_email({
    account = draft.account,
    email = {
      to = metadata.to,
      from = metadata.from,
      cc = metadata.cc,
      bcc = metadata.bcc,
      subject = metadata.subject,
      body = body
    }
  }, schedule_time)
  
  if scheduled_id then
    -- Delete draft if configured
    if M.config.delete_draft_on_send and draft.remote_id then
      draft_manager.delete(buf)
    end
    
    -- User notification
    draft_notifications.draft_sent(email.subject, email.to)
    
    -- Close buffer
    M.close_compose_buffer(buf)
    
    return true
  else
    return false, "Failed to schedule email"
  end
end

-- Close compose buffer
function M.close_compose_buffer(buf)
  -- Save any unsaved changes before closing
  if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_option(buf, 'modified') then
    M.save_draft(buf, 'before_close')
    -- Wait a bit for save to complete
    vim.wait(200)
  end
  
  -- Stop autosave
  if autosave_timers[buf] then
    vim.loop.timer_stop(autosave_timers[buf])
    autosave_timers[buf] = nil
  end
  
  -- Get all windows showing this buffer
  local wins = vim.fn.win_findbuf(buf)
  
  -- Check if we should close the tab
  local close_tab = false
  if M.config.use_tab then
    -- Check if this is the only window in the current tab
    local tabpage = vim.api.nvim_get_current_tabpage()
    local tab_wins = vim.api.nvim_tabpage_list_wins(tabpage)
    if #tab_wins == 1 and vim.tbl_contains(wins, tab_wins[1]) then
      close_tab = true
    end
  end
  
  -- Handle tab/buffer closing
  if vim.api.nvim_buf_is_valid(buf) then
    if close_tab and vim.fn.tabpagenr('$') > 1 then
      -- We're in a tab that needs to close
      -- First switch to another tab to avoid [No Name] buffer
      local current_tab = vim.fn.tabpagenr()
      if current_tab > 1 then
        vim.cmd('tabprevious')
      else
        vim.cmd('tabnext')
      end
      -- Now close the tab with the draft
      vim.cmd('tabclose ' .. current_tab)
    else
      -- Just delete the buffer
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
end

-- Check if buffer is a compose buffer
function M.is_compose_buffer(buf)
  return draft_manager.is_draft(buf)
end

-- Get all compose buffers
function M.get_compose_buffers()
  local buffers = {}
  local all_drafts = draft_manager.get_all()
  
  for _, draft in ipairs(all_drafts) do
    if vim.api.nvim_buf_is_valid(draft.buffer) then
      table.insert(buffers, draft.buffer)
    end
  end
  
  return buffers
end

-- Force cleanup (for testing)
function M.force_cleanup_compose_buffer(buf)
  -- First switch to a different buffer
  local buffers = vim.api.nvim_list_bufs()
  for _, b in ipairs(buffers) do
    if b ~= buf and vim.api.nvim_buf_is_valid(b) and
       vim.api.nvim_buf_get_option(b, 'buflisted') then
      -- Switch to this buffer in all windows showing the compose buffer
      local wins = vim.fn.win_findbuf(buf)
      for _, win in ipairs(wins) do
        vim.api.nvim_win_set_buf(win, b)
      end
      break
    end
  end
  
  -- Now close the compose buffer
  M.close_compose_buffer(buf)
end

return M