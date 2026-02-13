-- Maildir-based Draft Manager
-- Simplified draft management using Maildir format

local M = {}

-- Dependencies
local notify = require('neotex.util.notifications')
local utils = require('neotex.plugins.tools.himalaya.utils')
local state = require('neotex.plugins.tools.himalaya.core.state')
local events_bus = require('neotex.plugins.tools.himalaya.commands.orchestrator')
local event_types = require('neotex.plugins.tools.himalaya.core.events')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local maildir = require("neotex.plugins.tools.himalaya.data.maildir")

-- Draft notification helper
local function notify_draft(message, category, context)
  -- Suppress notifications in test mode unless they're errors
  if _G.HIMALAYA_TEST_MODE and category ~= notify.categories.ERROR then
    return
  end
  
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
  
  -- Note: Auto-save is handled by email_composer.lua via BufWriteCmd
  -- No need for BufWritePost autocmd as it would create duplicate saves/notifications
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
  -- Write directly to cur/ folder - no need for new/ folder for drafts
  local filepath = drafts_dir .. '/cur/' .. filename
  
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
  
  -- Note: We intentionally do NOT update the size in the filename
  -- This avoids file renames that can cause duplicate drafts and confusion
  -- The size in Maildir filenames is optional and not updating it is fine
  
  -- Check if a buffer with this name already exists
  local existing_buf = nil
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(b) and vim.api.nvim_buf_get_name(b) == filepath then
      existing_buf = b
      break
    end
  end
  
  -- Create or reuse buffer
  local buf
  if existing_buf then
    -- Clean up buffer tracking before deleting
    M.buffer_drafts[existing_buf] = nil
    -- Delete the existing buffer to avoid conflicts
    pcall(vim.api.nvim_buf_delete, existing_buf, { force = true })
  end
  
  -- Create new buffer with editable format
  buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(buf, filepath)
  
  -- Format for editing (show all key headers)
  local edit_lines = {}
  table.insert(edit_lines, 'From: ' .. (metadata.from or ''))
  table.insert(edit_lines, 'To: ' .. (metadata.to or ''))
  table.insert(edit_lines, 'Cc: ' .. (metadata.cc or ''))
  table.insert(edit_lines, 'Bcc: ' .. (metadata.bcc or ''))
  table.insert(edit_lines, 'Subject: ' .. (metadata.subject or ''))
  table.insert(edit_lines, '') -- Empty line between headers and body
  if metadata.body and metadata.body ~= '' then
    -- Split body into lines if it contains newlines
    local body_lines = vim.split(metadata.body, '\n', { plain = true })
    for _, line in ipairs(body_lines) do
      table.insert(edit_lines, line)
    end
  end
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, edit_lines)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'mail')
  vim.api.nvim_buf_set_option(buf, 'buftype', '')
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_option(buf, 'modified', false)
  vim.bo[buf].autoread = false

  -- Store original headers for reconstruction on save
  local all_headers = {}
  for _, header in ipairs(headers) do
    local key, value = header:match("^([^:]+):%s*(.*)$")
    if key then
      all_headers[key:lower()] = value
    end
  end
  vim.api.nvim_buf_set_var(buf, 'himalaya_original_headers', all_headers)
  vim.api.nvim_buf_set_var(buf, 'himalaya_is_multipart', false) -- New drafts are not multipart
  
  -- Ensure date is always preserved
  if not all_headers['date'] then
    all_headers['date'] = os.date('!%a, %d %b %Y %H:%M:%S +0000')
  end
  
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

-- Reconstruct MIME email from edited content
local function reconstruct_mime_email(buffer)
  -- Get edited lines
  local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
  
  -- Get stored original headers
  local ok, orig_headers = pcall(vim.api.nvim_buf_get_var, buffer, 'himalaya_original_headers')
  if not ok then
    orig_headers = {}
  end
  
  local ok2, was_multipart = pcall(vim.api.nvim_buf_get_var, buffer, 'himalaya_is_multipart')
  if not ok2 then
    was_multipart = false
  end
  
  -- Parse edited content back into headers and body
  local edited_headers = {}
  local body_lines = {}
  local in_body = false
  
  for _, line in ipairs(lines) do
    if in_body then
      table.insert(body_lines, line)
    elseif line == "" then
      in_body = true
    else
      local key, value = line:match("^([^:]+):%s*(.*)$")
      if key then
        edited_headers[key:lower()] = value
      end
    end
  end
  
  local body = table.concat(body_lines, '\n')
  
  -- Merge edited headers with original headers (preserve technical headers)
  local final_headers = vim.tbl_deep_extend('force', orig_headers, edited_headers)
  
  -- Always update Date header to current time for proper sorting
  -- This ensures drafts are sorted by when they were last modified
  final_headers['date'] = os.date('!%a, %d %b %Y %H:%M:%S +0000')
  
  -- Build the email content
  local email_lines = {}
  
  -- Add MIME-Version if not present
  if not final_headers['mime-version'] then
    table.insert(email_lines, 'MIME-Version: 1.0')
  end
  
  -- Add headers (preserving some original headers)
  local header_order = {
    'received', 'mime-version', 'date', 'message-id', 
    'from', 'to', 'cc', 'bcc', 'subject', 'reply-to', 'in-reply-to', 'references',
    'content-type', 'x-himalaya-account', 'x-tuid'
  }
  
  local added = {}
  for _, key in ipairs(header_order) do
    if final_headers[key] and not added[key] then
      local display_key = key:gsub("^%l", string.upper):gsub("%-(%l)", function(c) return "-" .. c:upper() end)
      table.insert(email_lines, display_key .. ": " .. final_headers[key])
      added[key] = true
    end
  end
  
  -- Add any remaining headers
  for key, value in pairs(final_headers) do
    if not added[key] and value ~= "" then
      local display_key = key:gsub("^%l", string.upper):gsub("%-(%l)", function(c) return "-" .. c:upper() end)
      table.insert(email_lines, display_key .. ": " .. value)
    end
  end
  
  -- Add blank line between headers and body
  table.insert(email_lines, "")
  
  -- For multipart emails, reconstruct the MIME structure
  if was_multipart and final_headers['content-type'] and final_headers['content-type']:match('multipart') then
    local boundary = final_headers['content-type']:match('boundary="?([^"]+)"?')
    if not boundary then
      boundary = final_headers['content-type']:match("boundary=([^%s;]+)")
    end
    
    if boundary then
      -- Add text/plain part
      table.insert(email_lines, "--" .. boundary)
      table.insert(email_lines, "Content-Type: text/plain; charset=UTF-8")
      table.insert(email_lines, "")
      table.insert(email_lines, body)
      table.insert(email_lines, "")
      
      -- Add HTML part (convert plain text to simple HTML)
      table.insert(email_lines, "--" .. boundary)
      table.insert(email_lines, "Content-Type: text/html; charset=UTF-8")
      table.insert(email_lines, "Content-Transfer-Encoding: quoted-printable")
      table.insert(email_lines, "")
      
      -- Simple text to HTML conversion
      local html = '<div dir="ltr">' .. body:gsub('\n\n', '</div><div><br></div><div>'):gsub('\n', '<br>') .. '</div>'
      table.insert(email_lines, html)
      table.insert(email_lines, "")
      table.insert(email_lines, "--" .. boundary .. "--")
    else
      -- Fallback to plain text if boundary not found
      table.insert(email_lines, body)
    end
  else
    -- Single part email
    table.insert(email_lines, body)
  end
  
  return table.concat(email_lines, '\n')
end

-- Save draft buffer to Maildir
-- @param buffer number Buffer number
-- @param silent boolean Don't show notification
-- @return boolean success
-- @return string|nil error
function M.save(buffer, silent)
  local filepath = M.buffer_drafts[buffer]
  if not filepath then
    return false, 'No draft associated with buffer'
  end
  
  -- Reconstruct the MIME email
  local content = reconstruct_mime_email(buffer)
  
  -- Save directly to file (always in cur/ folder now)
  local file = io.open(filepath, 'w')
  if file then
    file:write(content)
    file:close()
  else
    return false, 'Failed to write file'
  end
  
  -- Note: We intentionally do NOT update the size in the filename
  -- This avoids file renames that can cause duplicate drafts and confusion
  -- The size in Maildir filenames is optional and not updating it is fine
  
  -- Touch the file to update modification time
  -- This helps ensure proper sorting by modification time
  vim.loop.fs_utime(filepath, os.time(), os.time())
  
  -- Mark buffer as unmodified
  vim.api.nvim_buf_set_option(buffer, 'modified', false)
  
  -- Emit event
  events_bus.emit(event_types.DRAFT_SAVED, {
    filepath = filepath,
    buffer = buffer
  })
  
  -- Only show notification if not silent
  if not silent then
    notify_draft(
      'Draft saved',
      notify.categories.USER_ACTION,
      { filepath = filepath }
    )
  end
  
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

-- Parse MIME email content to extract headers and body
local function parse_email_content(content)
  local headers = {}
  local body = ""
  local in_headers = true
  local in_body = false
  local multipart_boundary = nil
  local in_text_part = false
  
  -- Split content into lines
  local lines = vim.split(content, '\n', { plain = true })
  local i = 1
  
  -- Parse headers
  while i <= #lines and in_headers do
    local line = lines[i]
    
    if line == "" then
      -- Empty line marks end of headers
      in_headers = false
      i = i + 1
      break
    elseif line:match("^%s") and i > 1 then
      -- Continuation of previous header
      local last_key = nil
      for k, _ in pairs(headers) do
        last_key = k
      end
      if last_key then
        headers[last_key] = headers[last_key] .. " " .. line:gsub("^%s+", "")
      end
    else
      -- New header
      local key, value = line:match("^([^:]+):%s*(.*)$")
      if key then
        headers[key:lower()] = value
        
        -- Check for multipart boundary
        if key:lower() == "content-type" and value:match("multipart") then
          multipart_boundary = value:match('boundary="?([^"]+)"?')
          if not multipart_boundary then
            multipart_boundary = value:match("boundary=([^%s;]+)")
          end
        end
      end
    end
    
    i = i + 1
  end
  
  -- If multipart, extract text/plain part
  if multipart_boundary then
    local boundary_pattern = "--" .. multipart_boundary
    local in_plain_text = false
    
    while i <= #lines do
      local line = lines[i]
      
      if line == boundary_pattern or line == boundary_pattern .. "--" then
        if in_plain_text then
          -- End of text part
          break
        end
        in_plain_text = false
        -- Look ahead for Content-Type
        local j = i + 1
        while j <= #lines and lines[j] ~= "" do
          if lines[j]:lower():match("^content%-type:%s*text/plain") then
            in_plain_text = true
            -- Skip to empty line after part headers
            while j <= #lines and lines[j] ~= "" do
              j = j + 1
            end
            i = j
            break
          end
          j = j + 1
        end
      elseif in_plain_text and line ~= boundary_pattern .. "--" then
        if body ~= "" then body = body .. "\n" end
        body = body .. line
      end
      
      i = i + 1
    end
  else
    -- Single part email, rest is body
    while i <= #lines do
      if body ~= "" then body = body .. "\n" end
      body = body .. lines[i]
      i = i + 1
    end
  end
  
  return headers, body
end

-- Format email for editing (simplified view)
local function format_for_editing(headers, body)
  local lines = {}
  
  -- Add main headers in standard order
  local header_order = {"from", "to", "cc", "bcc", "subject", "reply-to", "in-reply-to"}
  for _, key in ipairs(header_order) do
    if headers[key] and headers[key] ~= "" then
      table.insert(lines, key:gsub("^%l", string.upper):gsub("%-(%l)", function(c) return "-" .. c:upper() end) .. ": " .. headers[key])
    end
  end
  
  -- Add blank line between headers and body
  table.insert(lines, "")
  
  -- Add body
  if body and body ~= "" then
    -- Split body and add lines
    for _, line in ipairs(vim.split(body, '\n', { plain = true })) do
      table.insert(lines, line)
    end
  end
  
  return lines
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
  
  -- Read and parse the draft file
  local file = io.open(filepath, 'r')
  if not file then
    return nil, "Failed to open draft file: " .. filepath
  end
  
  local content = file:read('*a')
  file:close()
  
  -- Parse the email content
  local headers, body = parse_email_content(content)
  
  -- Format for editing
  local edit_lines = format_for_editing(headers, body)
  
  -- Find or create suitable window for editing
  local target_win = find_or_create_edit_window()
  
  -- Create new buffer for editing
  vim.api.nvim_set_current_win(target_win)
  local buf = vim.api.nvim_create_buf(true, false)
  
  -- Set buffer content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, edit_lines)
  
  -- Set buffer name to the file path (for saving)
  vim.api.nvim_buf_set_name(buf, filepath)
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'filetype', 'mail')
  vim.api.nvim_buf_set_option(buf, 'buftype', '')
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_option(buf, 'modified', false)
  vim.bo[buf].autoread = false

  -- Show buffer in window
  vim.api.nvim_win_set_buf(target_win, buf)
  
  -- Track buffer with original filepath
  M.buffer_drafts[buf] = filepath
  
  -- Store original headers for reconstruction on save
  vim.api.nvim_buf_set_var(buf, 'himalaya_original_headers', headers)
  vim.api.nvim_buf_set_var(buf, 'himalaya_is_multipart', headers['content-type'] and headers['content-type']:match('multipart') ~= nil)
  
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
  
  -- Save current state (silently)
  M.save(buffer, true)
  
  -- Read headers to get account
  local headers = maildir.read_headers(filepath)
  if not headers then
    return false, 'Failed to read draft headers'
  end
  
  -- Get account from header or use current account
  local state = require('neotex.plugins.tools.himalaya.core.state')
  local config = require('neotex.plugins.tools.himalaya.core.config')
  local account = headers['x-himalaya-account'] or config.get_current_account_name() or 'gmail'
  
  -- Read the full email content to get the body
  local file = io.open(filepath, 'r')
  if not file then
    return false, 'Failed to open draft file'
  end
  
  local content = file:read('*all')
  file:close()
  
  -- Split headers and body
  local body = ''
  local header_end = content:find('\n\n')
  if header_end then
    body = content:sub(header_end + 2)
  end
  
  -- Parse email data from the file for sending
  local email_data = {
    from = headers['from'],
    to = headers['to'],
    cc = headers['cc'],
    bcc = headers['bcc'],
    subject = headers['subject'],
    body = body
  }
  
  -- Use utils to send email
  local utils = require('neotex.plugins.tools.himalaya.utils')
  local logger = require('neotex.plugins.tools.himalaya.core.logger')
  
  logger.debug('Sending email', {
    account = account,
    to = email_data.to,
    subject = email_data.subject,
    has_body = email_data.body ~= nil,
    body_length = email_data.body and #email_data.body or 0
  })
  
  local success = utils.send_email(account, email_data)
  
  if not success then
    logger.error('Failed to send email via utils', {
      account = account,
      email_data = email_data
    })
    return false, 'Failed to send email'
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
          -- Get file modification time for proper sorting
          local stat = vim.loop.fs_stat(msg.path)
          local mtime = stat and stat.mtime.sec or msg.timestamp
          
          table.insert(drafts, {
            filepath = msg.path,
            filename = msg.filename,
            account = acc_name,
            subject = headers.subject or 'Untitled',
            from = headers.from,
            to = headers.to,
            timestamp = msg.timestamp,
            mtime = mtime,  -- Modification time for sorting
            size = msg.size
          })
        end
      end
    end
  end
  
  -- Sort by modification time (newest first)
  table.sort(drafts, function(a, b)
    return (a.mtime or a.timestamp) > (b.mtime or b.timestamp)
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