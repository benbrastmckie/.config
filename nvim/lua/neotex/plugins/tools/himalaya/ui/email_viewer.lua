-- Himalaya Email Viewer UI Module
-- Handles reading, displaying, and formatting individual emails

local M = {}

-- Dependencies
local config = require('neotex.plugins.tools.himalaya.core.config')
local utils = require('neotex.plugins.tools.himalaya.utils')
local state = require('neotex.plugins.tools.himalaya.ui.state')
local notifications = require('neotex.plugins.tools.himalaya.ui.notifications')

-- Module state
local buffers = nil  -- Reference to main module's buffers
local main = nil     -- Reference to main module for window functions

-- Initialize module
function M.init(main_buffers, main_module)
  buffers = main_buffers
  main = main_module
end

-- Read and display email content
function M.read_email(email_id)
  local email_content = utils.get_email_content(state.get_current_account(), email_id, state.get_current_folder())
  if not email_content then
    notifications.show('Failed to read email', 'error')
    return
  end
  
  -- Create or reuse buffer
  local buf = buffers.email_read
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    buf = vim.api.nvim_create_buf(false, true)
    buffers.email_read = buf
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
  main.open_email_window(buf, 'Email - ' .. (email_content.subject or 'No Subject'))
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

-- Process email body to extract and replace URLs
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

-- Read current email (from list view)
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

-- Show email attachments
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
  
  main.open_email_window(buf, 'Attachments')
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

return M