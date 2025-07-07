-- Custom Headers Support
-- Manages custom email headers for advanced email operations

local M = {}

local config = require('neotex.plugins.tools.himalaya.core.config')
local state = require('neotex.plugins.tools.himalaya.core.state')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local api = require('neotex.plugins.tools.himalaya.core.api')
local utils = require('neotex.plugins.tools.himalaya.utils')

-- Common custom headers
M.common_headers = {
  -- Priority headers
  ['X-Priority'] = { values = {'1', '2', '3', '4', '5'}, description = 'Email priority (1=highest, 5=lowest)' },
  ['Importance'] = { values = {'high', 'normal', 'low'}, description = 'Email importance' },
  
  -- Tracking headers
  ['X-Mailer'] = { description = 'Email client identifier' },
  ['X-Originating-IP'] = { description = 'Sender IP address' },
  
  -- Organization headers
  ['Organization'] = { description = 'Sender organization' },
  ['X-Organization'] = { description = 'Alternative organization header' },
  
  -- Reply handling
  ['Reply-To'] = { description = 'Alternative reply address' },
  ['Return-Path'] = { description = 'Return path for bounces' },
  
  -- List headers
  ['List-Id'] = { description = 'Mailing list identifier' },
  ['List-Unsubscribe'] = { description = 'Unsubscribe URL' },
  
  -- Custom tracking
  ['X-Custom-Tag'] = { description = 'Custom tag for filtering' },
  ['X-Project'] = { description = 'Project identifier' },
  ['X-Client-Id'] = { description = 'Client identifier' }
}

-- Get all headers for an email
function M.get_headers(email_id)
  local cmd_args = {'message', 'read', email_id, '--headers'}
  local result = utils.execute_himalaya(cmd_args)
  
  if not result.success then
    return api.error("Failed to get headers: " .. result.error, "HEADERS_FETCH_FAILED")
  end
  
  -- Parse headers
  local headers = M.parse_headers(result.output)
  
  return api.success(headers)
end

-- Parse raw headers
function M.parse_headers(raw_headers)
  local headers = {}
  local current_header = nil
  
  for line in raw_headers:gmatch("[^\r\n]+") do
    if line:match("^%s") then
      -- Continuation of previous header
      if current_header then
        headers[current_header] = headers[current_header] .. " " .. line:gsub("^%s+", "")
      end
    else
      -- New header
      local name, value = line:match("^([^:]+):%s*(.*)$")
      if name then
        current_header = name
        headers[name] = value
      end
    end
  end
  
  return headers
end

-- Add custom headers to draft
function M.add_to_draft(draft_id, custom_headers)
  -- Validate headers
  for name, value in pairs(custom_headers) do
    if not M.validate_header(name, value) then
      return api.error("Invalid header: " .. name, "INVALID_HEADER")
    end
  end
  
  -- Store in draft state
  local current_headers = state.get('drafts.' .. draft_id .. '.custom_headers', {})
  for name, value in pairs(custom_headers) do
    current_headers[name] = value
  end
  
  state.set('drafts.' .. draft_id .. '.custom_headers', current_headers)
  
  logger.info("Added " .. vim.tbl_count(custom_headers) .. " custom headers to draft")
  
  return api.success(current_headers)
end

-- Remove header from draft
function M.remove_from_draft(draft_id, header_name)
  local headers = state.get('drafts.' .. draft_id .. '.custom_headers', {})
  headers[header_name] = nil
  
  state.set('drafts.' .. draft_id .. '.custom_headers', headers)
  
  return api.success({ removed = header_name, remaining = headers })
end

-- Get suggested headers based on context
function M.get_suggestions(context)
  context = context or {}
  local suggestions = {}
  
  -- Priority for important emails
  if context.important then
    table.insert(suggestions, {
      name = 'X-Priority',
      value = '1',
      reason = 'Mark as high priority'
    })
    table.insert(suggestions, {
      name = 'Importance',
      value = 'high',
      reason = 'Mark as important'
    })
  end
  
  -- Reply-To for different reply address
  if context.reply_to and context.reply_to ~= context.from then
    table.insert(suggestions, {
      name = 'Reply-To',
      value = context.reply_to,
      reason = 'Set alternative reply address'
    })
  end
  
  -- Organization header
  local org = config.get('user.organization')
  if org then
    table.insert(suggestions, {
      name = 'Organization',
      value = org,
      reason = 'Add organization information'
    })
  end
  
  -- Project tracking
  if context.project then
    table.insert(suggestions, {
      name = 'X-Project',
      value = context.project,
      reason = 'Track project emails'
    })
  end
  
  return suggestions
end

-- Format headers for sending
function M.format_headers(headers)
  local formatted = {}
  
  for name, value in pairs(headers) do
    -- Ensure proper formatting
    name = M.normalize_header_name(name)
    value = M.sanitize_header_value(value)
    
    table.insert(formatted, string.format("%s: %s", name, value))
  end
  
  return table.concat(formatted, "\r\n")
end

-- Apply headers to email before sending
function M.apply_to_email(email_content, custom_headers)
  if vim.tbl_isempty(custom_headers) then
    return email_content
  end
  
  -- Find the end of existing headers
  local header_end = email_content:find("\r?\n\r?\n")
  if not header_end then
    -- No body, just headers
    header_end = #email_content
  end
  
  -- Insert custom headers before the empty line
  local headers_str = M.format_headers(custom_headers)
  local new_content = email_content:sub(1, header_end - 1) .. 
                     "\r\n" .. headers_str .. 
                     email_content:sub(header_end)
  
  return new_content
end

-- Validate header name and value
function M.validate_header(name, value)
  -- Check header name format
  if not name:match("^[%w%-]+$") then
    return false, "Invalid header name format"
  end
  
  -- Check for forbidden headers
  local forbidden = {
    'From', 'To', 'Subject', 'Date', 'Message-ID',
    'Content-Type', 'Content-Transfer-Encoding'
  }
  
  for _, forbidden_name in ipairs(forbidden) do
    if name:lower() == forbidden_name:lower() then
      return false, "Cannot modify system header: " .. name
    end
  end
  
  -- Validate value
  if value:match("[\r\n]") then
    return false, "Header value cannot contain line breaks"
  end
  
  -- Check specific header constraints
  local header_info = M.common_headers[name]
  if header_info and header_info.values then
    local valid = false
    for _, allowed in ipairs(header_info.values) do
      if value == allowed then
        valid = true
        break
      end
    end
    if not valid then
      return false, "Invalid value for " .. name .. ". Allowed: " .. table.concat(header_info.values, ", ")
    end
  end
  
  return true
end

-- Normalize header name (proper capitalization)
function M.normalize_header_name(name)
  return name:gsub("(%w)([%w%-]*)", function(first, rest)
    return first:upper() .. rest:lower()
  end)
end

-- Sanitize header value
function M.sanitize_header_value(value)
  -- Remove line breaks
  value = value:gsub("[\r\n]+", " ")
  
  -- Trim whitespace
  value = value:gsub("^%s+", ""):gsub("%s+$", "")
  
  -- Fold long lines (RFC 2822)
  if #value > 78 then
    local folded = ""
    local line = ""
    
    for word in value:gmatch("%S+") do
      if #line + #word + 1 > 78 then
        folded = folded .. line .. "\r\n "
        line = word
      else
        line = line .. (line == "" and "" or " ") .. word
      end
    end
    
    value = folded .. line
  end
  
  return value
end

-- Get header presets
function M.get_presets()
  local presets = config.get('headers.presets', {})
  
  -- Add default presets
  if not presets.urgent then
    presets.urgent = {
      ['X-Priority'] = '1',
      ['Importance'] = 'high'
    }
  end
  
  if not presets.bulk then
    presets.bulk = {
      ['X-Priority'] = '5',
      ['Precedence'] = 'bulk'
    }
  end
  
  return presets
end

-- Apply preset headers
function M.apply_preset(draft_id, preset_name)
  local presets = M.get_presets()
  local preset = presets[preset_name]
  
  if not preset then
    return api.error("Preset not found: " .. preset_name, "PRESET_NOT_FOUND")
  end
  
  return M.add_to_draft(draft_id, preset)
end

-- Extract tracking headers from received email
function M.extract_tracking_headers(headers)
  local tracking = {}
  
  -- Common tracking patterns
  local tracking_patterns = {
    'X-.*-ID',
    'X-.*-Tracking',
    'X-Campaign.*',
    'X-Mailer',
    'List-.*'
  }
  
  for name, value in pairs(headers) do
    for _, pattern in ipairs(tracking_patterns) do
      if name:match(pattern) then
        tracking[name] = value
        break
      end
    end
  end
  
  return tracking
end

return M