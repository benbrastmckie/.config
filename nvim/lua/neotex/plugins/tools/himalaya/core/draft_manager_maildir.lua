-- Maildir-based Draft Manager
-- Simplified draft management using Maildir format

local M = {}

-- Dependencies
local notify = require('neotex.util.notifications')
local utils = require('neotex.plugins.tools.himalaya.utils')
local state = require('neotex.plugins.tools.himalaya.core.state')
local events_bus = require('neotex.plugins.tools.himalaya.orchestration.events')
local event_types = require('neotex.plugins.tools.himalaya.core.events')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local maildir = require('neotex.plugins.tools.himalaya.core.maildir')

-- Draft notification helper
local function notify_draft(message, category, context)
  context = vim.tbl_extend('force', context or {}, {
    module = 'himalaya',
    feature = 'drafts'
  })
  notify.himalaya(message, category, context)
end

-- Draft states (simplified)
M.states = {
  ACTIVE = 'active',    -- Draft is being edited
  SAVED = 'saved'       -- Draft is saved to Maildir
}

-- Buffer to draft path mapping
M.buffer_drafts = {}  -- buffer -> filepath

-- Get Maildir path for account
local function get_drafts_maildir(account)
  local config = require('neotex.plugins.tools.himalaya.core.config').config
  
  -- Use configured maildir path or default
  local base_path = config.sync.maildir_root or (vim.fn.expand('~') .. '/Mail')
  
  -- Map account to maildir folder - handle case sensitivity
  local account_name = account or 'Gmail'
  if account == 'default' and config.accounts and #config.accounts > 0 then
    account_name = config.accounts[1].name
  elseif account == 'gmail' then
    -- Map lowercase 'gmail' to 'Gmail' (mbsync folder name)
    account_name = 'Gmail'
  end
  
  return base_path .. '/' .. account_name .. '/.Drafts'
end

-- Initialize draft manager
function M.setup()
  -- Create autocmd group for cleanup
  local group = vim.api.nvim_create_augroup('HimalayaDraftManagerMaildir', { clear = true })
  
  -- Clean up drafts when buffers are deleted
  vim.api.nvim_create_autocmd('BufDelete', {
    group = group,
    callback = function(args)
      M.cleanup_draft(args.buf)
    end,
    desc = 'Clean up draft when buffer is deleted'
  })
  
  -- Auto-save drafts on buffer write
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = group,
    pattern = '*.eml',
    callback = function(args)
      if M.buffer_drafts[args.buf] then
        M.save(args.buf)
      end
    end,
    desc = 'Auto-save draft on buffer write'
  })
end

-- Create a new draft
-- @param account string Account name
-- @param metadata table Draft metadata (from, to, subject, etc)
-- @return number|nil buffer Buffer number or nil on error
-- @return string|nil error Error message if failed
function M.create(account, metadata)
  metadata = metadata or {}
  
  -- Get Maildir path
  local drafts_dir = get_drafts_maildir(account)
  
  -- Ensure Maildir exists
  if not maildir.is_maildir(drafts_dir) then
    local ok, err = maildir.create_maildir(drafts_dir)
    if not ok then
      return nil, 'Failed to create drafts Maildir: ' .. err
    end
  end
  
  -- Generate Maildir filename with Draft flag
  local filename = maildir.generate_filename({'D'})
  local filepath = drafts_dir .. '/new/' .. filename
  
  -- Create email content
  local headers = {
    string.format('From: %s', metadata.from or ''),
    string.format('To: %s', metadata.to or ''),
    string.format('Cc: %s', metadata.cc or ''),
    string.format('Bcc: %s', metadata.bcc or ''),
    string.format('Subject: %s', metadata.subject or ''),
    string.format('Date: %s', os.date('!%a, %d %b %Y %H:%M:%S +0000')),
    string.format('X-Himalaya-Account: %s', account),
    'Content-Type: text/plain; charset=utf-8',
    'MIME-Version: 1.0'
  }
  
  local content = table.concat(headers, '\n') .. '\n\n' .. (metadata.body or '')
  
  -- Write to Maildir
  local tmp_dir = drafts_dir .. '/tmp'
  local ok, err = maildir.atomic_write(tmp_dir, filepath, content)
  if not ok then
    return nil, err
  end
  
  -- Update size in filename
  maildir.update_size(filepath)
  
  -- Create buffer
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, filepath)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, '\n'))
  vim.api.nvim_buf_set_option(buf, 'filetype', 'mail')
  vim.api.nvim_buf_set_option(buf, 'buftype', '')
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  
  -- Track buffer
  M.buffer_drafts[buf] = filepath
  
  -- Emit event
  events_bus.emit(event_types.DRAFT_CREATED, {
    account = account,
    filepath = filepath,
    buffer = buf
  })
  
  logger.info('Created draft in Maildir', {
    account = account,
    filepath = filepath
  })
  
  return buf
end

-- Save draft buffer to Maildir
-- @param buffer number Buffer number
-- @return boolean success
-- @return string|nil error
function M.save(buffer)
  local filepath = M.buffer_drafts[buffer]
  if not filepath then
    return false, 'No draft associated with buffer'
  end
  
  -- Get buffer content
  local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
  local content = table.concat(lines, '\n')
  
  -- Check if we need to move from new/ to cur/
  local dir = vim.fn.fnamemodify(filepath, ':h:t')
  if dir == 'new' then
    -- Move to cur/ on first save
    local filename = vim.fn.fnamemodify(filepath, ':t')
    local drafts_dir = vim.fn.fnamemodify(filepath, ':h:h')
    local new_filepath = drafts_dir .. '/cur/' .. filename
    
    -- Write to new location
    local ok = vim.fn.writefile(lines, new_filepath) == 0
    if ok then
      -- Delete old file
      vim.fn.delete(filepath)
      -- Update tracking
      M.buffer_drafts[buffer] = new_filepath
      filepath = new_filepath
      -- Update buffer name
      vim.api.nvim_buf_set_name(buffer, new_filepath)
    end
  else
    -- Save in place
    vim.cmd('silent write!')
  end
  
  -- Update size in filename
  maildir.update_size(filepath)
  
  -- Mark buffer as unmodified
  vim.api.nvim_buf_set_option(buffer, 'modified', false)
  
  -- Emit event
  events_bus.emit(event_types.DRAFT_SAVED, {
    filepath = filepath,
    buffer = buffer
  })
  
  notify_draft(
    'Draft saved',
    notify.categories.USER_ACTION,
    { filepath = filepath }
  )
  
  return true
end

-- Find or create a suitable window for editing (not sidebar/preview)
local function find_or_create_edit_window()
  local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
  local sidebar_win = sidebar.get_win()
  
  -- Look for a non-sidebar, non-preview window
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if win ~= sidebar_win then
      local buf = vim.api.nvim_win_get_buf(win)
      local buftype = vim.api.nvim_buf_get_option(buf, 'buftype')
      local filetype = vim.api.nvim_buf_get_option(buf, 'filetype')
      
      -- Skip special buffers (preview, floating, etc)
      if buftype == '' and filetype ~= 'himalaya-preview' then
        return win
      end
    end
  end
  
  -- No suitable window found, need to create one
  -- Save current window
  local original_win = vim.api.nvim_get_current_win()
  
  -- Focus sidebar to ensure split is created in the right place
  if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
    vim.api.nvim_set_current_win(sidebar_win)
    -- Move to the right and create a split there
    vim.cmd('wincmd l')
    -- If we're still in sidebar, we need to create a new split
    if vim.api.nvim_get_current_win() == sidebar_win then
      vim.cmd('rightbelow vsplit')
    else
      -- We moved to an existing window, use it
      local existing_win = vim.api.nvim_get_current_win()
      -- Return to sidebar
      vim.api.nvim_set_current_win(sidebar_win)
      return existing_win
    end
  else
    -- No sidebar, just create a new split
    vim.cmd('vsplit')
  end
  
  local new_win = vim.api.nvim_get_current_win()
  
  -- Return to original window
  if original_win and vim.api.nvim_win_is_valid(original_win) then
    vim.api.nvim_set_current_win(original_win)
  end
  
  return new_win
end

-- Open an existing draft from Maildir
-- @param filepath string Path to draft file
-- @return number|nil buffer Buffer number or nil on error
-- @return string|nil error Error message if failed
function M.open(filepath)
  local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
  local sidebar_win = sidebar.get_win()
  local original_win = vim.api.nvim_get_current_win()
  
  -- Check if already open
  for buf, path in pairs(M.buffer_drafts) do
    if path == filepath and vim.api.nvim_buf_is_valid(buf) then
      -- Find suitable window and show buffer there
      local target_win = find_or_create_edit_window()
      
      -- Switch to target window temporarily to load buffer
      local saved_win = vim.api.nvim_get_current_win()
      vim.api.nvim_set_current_win(target_win)
      vim.cmd('buffer ' .. buf)
      
      -- Focus the target window where we opened the draft
      vim.api.nvim_set_current_win(target_win)
      return buf
    end
  end
  
  -- Find or create suitable window for editing
  local target_win = find_or_create_edit_window()
  
  -- Switch to target window temporarily to open file
  local saved_win = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(target_win)
  vim.cmd('edit ' .. vim.fn.fnameescape(filepath))
  local buf = vim.api.nvim_get_current_buf()
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'filetype', 'mail')
  vim.api.nvim_buf_set_option(buf, 'buftype', '')
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  
  -- Track buffer
  M.buffer_drafts[buf] = filepath
  
  -- Focus the target window where we opened the draft
  vim.api.nvim_set_current_win(target_win)
  
  return buf
end

-- Delete a draft
-- @param buffer number Buffer number
-- @return boolean success
-- @return string|nil error
function M.delete(buffer)
  local filepath = M.buffer_drafts[buffer]
  if not filepath then
    return false, 'No draft associated with buffer'
  end
  
  -- Delete file
  local ok = vim.fn.delete(filepath) == 0
  if not ok then
    return false, 'Failed to delete draft file'
  end
  
  -- Clean up tracking
  M.buffer_drafts[buffer] = nil
  
  -- Delete buffer
  if vim.api.nvim_buf_is_valid(buffer) then
    vim.api.nvim_buf_delete(buffer, { force = true })
  end
  
  -- Emit event
  events_bus.emit(event_types.DRAFT_DELETED, {
    filepath = filepath
  })
  
  notify_draft(
    'Draft deleted',
    notify.categories.USER_ACTION,
    { filepath = filepath }
  )
  
  return true
end

-- Send draft as email
-- @param buffer number Buffer number  
-- @return boolean success
-- @return string|nil error
function M.send(buffer)
  local filepath = M.buffer_drafts[buffer]
  if not filepath then
    return false, 'No draft associated with buffer'
  end
  
  -- Save current state
  M.save(buffer)
  
  -- Read headers to get account
  local headers = maildir.read_headers(filepath)
  if not headers then
    return false, 'Failed to read draft headers'
  end
  
  local account = headers['x-himalaya-account'] or 'default'
  
  -- Use himalaya to send
  local himalaya = require('neotex.plugins.tools.himalaya.core.himalaya_wrapper')
  local result = himalaya.email.send({
    account = account,
    filepath = filepath
  })
  
  if not result.success then
    return false, result.error or 'Failed to send email'
  end
  
  -- Delete draft after successful send
  M.delete(buffer)
  
  notify_draft(
    'Email sent successfully',
    notify.categories.USER_ACTION,
    { subject = headers.subject }
  )
  
  return true
end

-- List all drafts
-- @param account string|nil Optional account filter
-- @return table Array of draft info
function M.list(account)
  local drafts = {}
  local config = require('neotex.plugins.tools.himalaya.core.config').config
  
  -- Get accounts to check
  local accounts = {}
  if account then
    table.insert(accounts, account)
  elseif config.accounts then
    for _, acc in ipairs(config.accounts) do
      table.insert(accounts, acc.name)
    end
  end
  
  -- Check each account's Maildir
  for _, acc_name in ipairs(accounts) do
    local drafts_dir = get_drafts_maildir(acc_name)
    
    if maildir.is_maildir(drafts_dir) then
      -- List all messages in drafts folder (they don't have D flag when synced via mbsync)
      local messages = maildir.list_messages(drafts_dir)
      
      for _, msg in ipairs(messages) do
        -- Read headers for metadata
        local headers = maildir.read_headers(msg.path)
        if headers then
          table.insert(drafts, {
            filepath = msg.path,
            filename = msg.filename,
            account = acc_name,
            subject = headers.subject or 'Untitled',
            from = headers.from,
            to = headers.to,
            timestamp = msg.timestamp,
            size = msg.size
          })
        end
      end
    end
  end
  
  -- Sort by timestamp (newest first)
  table.sort(drafts, function(a, b)
    return a.timestamp > b.timestamp
  end)
  
  return drafts
end

-- Get draft info by buffer
-- @param buffer number Buffer number
-- @return table|nil Draft info or nil if not found
function M.get_by_buffer(buffer)
  local filepath = M.buffer_drafts[buffer]
  if not filepath then
    return nil
  end
  
  -- Parse filename for metadata
  local filename = vim.fn.fnamemodify(filepath, ':t')
  local metadata = maildir.parse_filename(filename)
  if not metadata then
    return nil
  end
  
  -- Read headers
  local headers = maildir.read_headers(filepath)
  if not headers then
    return nil
  end
  
  return {
    buffer = buffer,
    filepath = filepath,
    filename = filename,
    account = headers['x-himalaya-account'] or 'default',
    subject = headers.subject or 'Untitled',
    from = headers.from,
    to = headers.to,
    cc = headers.cc,
    bcc = headers.bcc,
    timestamp = metadata.timestamp,
    size = metadata.size,
    flags = metadata.flags,
    state = M.states.SAVED
  }
end

-- Cleanup draft when buffer is deleted
-- @param buffer number Buffer number
function M.cleanup_draft(buffer)
  M.buffer_drafts[buffer] = nil
end

-- Get all active drafts
-- @return table Array of draft info
function M.get_all()
  local drafts = {}
  
  for buffer, _ in pairs(M.buffer_drafts) do
    if vim.api.nvim_buf_is_valid(buffer) then
      local draft = M.get_by_buffer(buffer)
      if draft then
        table.insert(drafts, draft)
      end
    else
      -- Clean up invalid buffer
      M.buffer_drafts[buffer] = nil
    end
  end
  
  return drafts
end

-- Check if buffer is a draft
-- @param buffer number Buffer number
-- @return boolean is_draft
function M.is_draft(buffer)
  return M.buffer_drafts[buffer] ~= nil
end

-- Recover drafts from previous session
function M.recover_session()
  -- This is now a no-op since drafts are persisted in Maildir
  -- The sidebar will show all drafts from Maildir
  logger.info('Draft recovery not needed with Maildir storage')
end

return M