-- Email Utilities for Himalaya
-- Email formatting, validation, and parsing utilities

local M = {}

local string_utils = require('neotex.plugins.tools.himalaya.utils.string')

-- Format email flags
function M.format_flags(flags)
  if not flags then return '  ' end
  
  local flag_chars = ''
  if flags.seen then flag_chars = flag_chars .. 'R' else flag_chars = flag_chars .. ' ' end
  if flags.answered then flag_chars = flag_chars .. 'A' else flag_chars = flag_chars .. ' ' end
  if flags.flagged then flag_chars = flag_chars .. '*' else flag_chars = flag_chars .. ' ' end
  if flags.draft then flag_chars = flag_chars .. 'D' else flag_chars = flag_chars .. ' ' end
  
  return flag_chars
end

-- Format email for sending
function M.format_email_for_sending(email_data)
  local config = require('neotex.plugins.tools.himalaya.core.config')
  local headers = {}
  
  -- Add account email as From if not provided
  if not email_data.from then
    local account = config.get_current_account()
    if account and account.email then
      email_data.from = account.email
    end
  end
  
  -- Required headers
  if email_data.from then
    table.insert(headers, 'From: ' .. email_data.from)
  end
  
  if email_data.to then
    table.insert(headers, 'To: ' .. email_data.to)
  end
  
  -- Optional headers
  if email_data.cc then
    table.insert(headers, 'Cc: ' .. email_data.cc)
  end
  
  if email_data.bcc then
    table.insert(headers, 'Bcc: ' .. email_data.bcc)
  end
  
  if email_data.subject then
    table.insert(headers, 'Subject: ' .. email_data.subject)
  end
  
  if email_data.reply_to then
    table.insert(headers, 'Reply-To: ' .. email_data.reply_to)
  end
  
  if email_data.in_reply_to then
    table.insert(headers, 'In-Reply-To: ' .. email_data.in_reply_to)
  end
  
  if email_data.references then
    table.insert(headers, 'References: ' .. email_data.references)
  end
  
  -- Add custom headers
  if email_data.headers then
    for header, value in pairs(email_data.headers) do
      table.insert(headers, header .. ': ' .. value)
    end
  end
  
  -- Add empty line between headers and body
  table.insert(headers, '')
  
  -- Add body
  if email_data.body then
    for _, line in ipairs(vim.split(email_data.body, '\n')) do
      table.insert(headers, line)
    end
  end
  
  return table.concat(headers, '\n')
end

-- Parse email content from buffer lines
function M.parse_email_content(lines)
  local email = {
    headers = {},
    body = {}
  }
  
  local in_body = false
  local current_header = nil
  
  for _, line in ipairs(lines) do
    if not in_body then
      if line == '' then
        -- Empty line marks end of headers
        in_body = true
      elseif line:match('^%s') and current_header then
        -- Continuation of previous header
        email.headers[current_header] = email.headers[current_header] .. ' ' .. line:gsub('^%s+', '')
      else
        -- New header
        local header, value = line:match('^([^:]+):%s*(.*)$')
        if header then
          current_header = header:lower():gsub('-', '_')
          email.headers[current_header] = value
        end
      end
    else
      table.insert(email.body, line)
    end
  end
  
  -- Join body lines
  email.body = table.concat(email.body, '\n')
  
  return email
end

-- Validate email address
function M.validate_email(email)
  if not email then return false end
  -- Basic email validation pattern
  return email:match("^[%w._%+-]+@[%w.-]+%.[%w]+$") ~= nil
end

-- Extract email addresses from a string
function M.extract_emails(str)
  if not str then return {} end
  local emails = {}
  
  -- Pattern to match email addresses
  for email in str:gmatch("[%w._%+-]+@[%w.-]+%.[%w]+") do
    table.insert(emails, email)
  end
  
  return emails
end

-- Parse email address (name and email)
function M.parse_address(address)
  if not address then return nil end
  
  -- Try to match "Name <email@domain.com>" format
  local name, email = address:match('^"?([^"<]+)"?%s*<([^>]+)>')
  if name and email then
    return {
      name = string_utils.trim(name),
      email = string_utils.trim(email),
      display = address
    }
  end
  
  -- Try to match plain email
  if M.validate_email(address) then
    return {
      name = nil,
      email = address,
      display = address
    }
  end
  
  -- Return as-is if no pattern matches
  return {
    name = address,
    email = nil,
    display = address
  }
end

-- Format address for display
function M.format_address(address)
  local parsed = M.parse_address(address)
  if not parsed then return 'Unknown' end
  
  if parsed.name then
    return parsed.name
  elseif parsed.email then
    return parsed.email
  else
    return parsed.display
  end
end

-- Create a reply to an email
function M.create_reply(original_email, reply_all)
  local reply = {
    headers = {},
    body = ''
  }
  
  -- Set From to original To
  if original_email.headers.to then
    reply.headers.from = original_email.headers.to
  end
  
  -- Set To to original From
  if original_email.headers.from then
    reply.headers.to = original_email.headers.from
  end
  
  -- Handle Reply-All
  if reply_all then
    -- Add CC recipients
    local cc_list = {}
    
    -- Add original CC
    if original_email.headers.cc then
      for _, addr in ipairs(M.extract_emails(original_email.headers.cc)) do
        table.insert(cc_list, addr)
      end
    end
    
    -- Add original To (except ourselves)
    if original_email.headers.to and reply.headers.from then
      for _, addr in ipairs(M.extract_emails(original_email.headers.to)) do
        if addr ~= reply.headers.from then
          table.insert(cc_list, addr)
        end
      end
    end
    
    if #cc_list > 0 then
      reply.headers.cc = table.concat(cc_list, ', ')
    end
  end
  
  -- Set subject
  if original_email.headers.subject then
    local subject = original_email.headers.subject
    if not subject:match('^Re:%s*') then
      subject = 'Re: ' .. subject
    end
    reply.headers.subject = subject
  end
  
  -- Set In-Reply-To
  if original_email.headers.message_id then
    reply.headers['in-reply-to'] = original_email.headers.message_id
  end
  
  -- Set References
  local references = {}
  if original_email.headers.references then
    references = vim.split(original_email.headers.references, '%s+')
  end
  if original_email.headers.message_id then
    table.insert(references, original_email.headers.message_id)
  end
  if #references > 0 then
    reply.headers.references = table.concat(references, ' ')
  end
  
  -- Quote original message
  local quote_lines = {}
  table.insert(quote_lines, '')
  table.insert(quote_lines, string.format('On %s, %s wrote:', 
    original_email.headers.date or 'Unknown date',
    M.format_address(original_email.headers.from)))
  
  -- Quote body
  for line in original_email.body:gmatch('[^\n]+') do
    table.insert(quote_lines, '> ' .. line)
  end
  
  reply.body = table.concat(quote_lines, '\n')
  
  return reply
end

-- Generate Message-ID
function M.generate_message_id()
  local random = math.random(1000000, 9999999)
  local timestamp = os.time()
  local hostname = vim.fn.hostname()
  
  return string.format("<%s.%s@%s>", timestamp, random, hostname)
end

-- Check if email has attachments
function M.has_attachments(email_content)
  if not email_content then return false end
  
  -- Simple check for multipart content
  return email_content:match('Content%-Type:%s*multipart') ~= nil
end

return M