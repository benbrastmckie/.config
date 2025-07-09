-- Robust Draft Content Parser
-- State-machine based parser that handles himalaya's various output formats
--
-- This module solves the fragile parsing issues that cause draft content loss
-- by implementing a proper state machine that can handle all edge cases.

local M = {}

-- Dependencies
local logger = require('neotex.plugins.tools.himalaya.core.logger')

-- Parser states
local STATES = {
  INITIAL = "initial",
  HEADERS = "headers",
  DISPLAY_DIVIDER = "display_divider",
  DISPLAY_HEADERS = "display_headers",
  BODY_SEPARATOR = "body_separator",
  BODY = "body",
  MULTIPART = "multipart"
}

-- Create a new parser instance
function M.new()
  local parser = {
    state = STATES.INITIAL,
    headers = {},
    body_lines = {},
    display_headers = {},
    errors = {},
    line_num = 0
  }
  
  -- Parse a single line
  function parser:parse_line(line)
    self.line_num = self.line_num + 1
    
    logger.debug('Parser: Processing line', {
      line_num = self.line_num,
      state = self.state,
      line = line
    })
    
    if self.state == STATES.INITIAL then
      -- Look for header format
      if line:match('^[A-Za-z%-]+:%s*') then
        self.state = STATES.HEADERS
        self:parse_header(line)
      elseif line == '' then
        -- Empty line at start, skip
      else
        -- Assume body if no headers
        self.state = STATES.BODY
        table.insert(self.body_lines, line)
      end
      
    elseif self.state == STATES.HEADERS then
      if line == '' then
        -- Empty line marks end of headers
        self.state = STATES.BODY_SEPARATOR
      elseif line:match('^%-%-%-+$') then
        -- Display divider
        self.state = STATES.DISPLAY_DIVIDER
      elseif line:match('^[A-Za-z%-]+:%s*') then
        -- Another header
        self:parse_header(line)
      else
        -- Continuation of previous header
        self:continue_header(line)
      end
      
    elseif self.state == STATES.DISPLAY_DIVIDER then
      -- After divider, expect display headers
      if line:match('^[A-Za-z%-]+:%s*') then
        self.state = STATES.DISPLAY_HEADERS
        self:parse_display_header(line)
      elseif line == '' then
        self.state = STATES.BODY
      else
        -- Unexpected content after divider
        self:add_error("Unexpected content after divider: " .. line)
        self.state = STATES.BODY
        table.insert(self.body_lines, line)
      end
      
    elseif self.state == STATES.DISPLAY_HEADERS then
      if line == '' then
        self.state = STATES.BODY
      elseif line:match('^[A-Za-z%-]+:%s*') then
        self:parse_display_header(line)
      else
        -- Body started without empty line
        self.state = STATES.BODY
        table.insert(self.body_lines, line)
      end
      
    elseif self.state == STATES.BODY_SEPARATOR then
      -- We're past the headers empty line, everything is body
      self.state = STATES.BODY
      if line ~= '' then -- Don't include the separator line itself
        table.insert(self.body_lines, line)
      end
      
    elseif self.state == STATES.BODY then
      -- Check for multipart markers
      if line:match('^<#part') then
        self.state = STATES.MULTIPART
      elseif line:match('^<#/part>') then
        -- End of multipart, continue body
      else
        table.insert(self.body_lines, line)
      end
      
    elseif self.state == STATES.MULTIPART then
      -- Skip multipart content until end marker
      if line:match('^<#/part>') then
        self.state = STATES.BODY
      end
      -- Don't include multipart markers in body
    end
  end
  
  -- Parse a header line
  function parser:parse_header(line)
    local header, value = line:match('^([A-Za-z%-]+):%s*(.*)$')
    if header and value then
      header = header:lower()
      self.headers[header] = value
      self.last_header = header
    end
  end
  
  -- Continue a multi-line header
  function parser:continue_header(line)
    if self.last_header and line:match('^%s+') then
      -- Continuation line starts with whitespace
      self.headers[self.last_header] = self.headers[self.last_header] .. ' ' .. line:match('^%s+(.*)$')
    else
      -- Not a continuation, treat as body
      self.state = STATES.BODY
      table.insert(self.body_lines, line)
    end
  end
  
  -- Parse display headers (after divider)
  function parser:parse_display_header(line)
    local header, value = line:match('^([A-Za-z%-]+):%s*(.*)$')
    if header and value then
      self.display_headers[header:lower()] = value
    end
  end
  
  -- Add an error
  function parser:add_error(error)
    table.insert(self.errors, {
      line_num = self.line_num,
      error = error
    })
  end
  
  -- Parse a complete email
  function parser:parse(lines)
    for _, line in ipairs(lines) do
      self:parse_line(line)
    end
    
    return self:get_result()
  end
  
  -- Get parsing result
  function parser:get_result()
    -- Clean up vim.NIL values
    local function clean_value(val)
      if val == vim.NIL or val == 'vim.NIL' then
        return ''
      end
      return val or ''
    end
    
    local result = {
      headers = {},
      from = clean_value(self.headers.from),
      to = clean_value(self.headers.to),
      cc = clean_value(self.headers.cc),
      bcc = clean_value(self.headers.bcc),
      subject = clean_value(self.headers.subject),
      date = clean_value(self.headers.date),
      body = table.concat(self.body_lines, '\n'),
      errors = self.errors,
      parser_state = self.state,
      line_count = self.line_num
    }
    
    -- Copy all headers
    for k, v in pairs(self.headers) do
      result.headers[k] = clean_value(v)
    end
    
    -- If display headers exist and have better data, use them
    if vim.tbl_count(self.display_headers) > 0 then
      for k, v in pairs(self.display_headers) do
        local clean_val = clean_value(v)
        if clean_val ~= '' then
          result.headers[k] = clean_val
          -- Update top-level fields
          if k == 'from' then result.from = clean_val
          elseif k == 'to' then result.to = clean_val
          elseif k == 'cc' then result.cc = clean_val
          elseif k == 'bcc' then result.bcc = clean_val
          elseif k == 'subject' then result.subject = clean_val
          elseif k == 'date' then result.date = clean_val
          end
        end
      end
    end
    
    logger.debug('Parser: Final result', {
      headers_count = vim.tbl_count(result.headers),
      body_lines = #self.body_lines,
      has_subject = result.subject ~= '',
      has_to = result.to ~= '',
      errors = #self.errors,
      final_state = self.state
    })
    
    return result
  end
  
  return parser
end

-- Parse email content (convenience function)
function M.parse_email(lines)
  local parser = M.new()
  return parser:parse(lines)
end

-- Parse himalaya draft output specifically
function M.parse_himalaya_draft(content)
  local lines
  
  -- Handle string vs table input
  if type(content) == 'string' then
    lines = vim.split(content, '\n', { plain = true })
  elseif type(content) == 'table' then
    lines = content
  else
    logger.error('Invalid content type for parsing', { type = type(content) })
    return {
      headers = {},
      from = '',
      to = '',
      subject = '',
      body = '',
      errors = { { error = 'Invalid content type: ' .. type(content) } }
    }
  end
  
  -- Parse with state machine
  local result = M.parse_email(lines)
  
  -- Post-processing for himalaya quirks
  if result.body then
    -- Remove any remaining multipart markers
    result.body = result.body:gsub('<#part[^>]*>', '')
    result.body = result.body:gsub('<#/part>', '')
    
    -- Trim excessive blank lines at start/end
    result.body = result.body:gsub('^%s*\n', '')
    result.body = result.body:gsub('\n%s*$', '')
  end
  
  return result
end

-- Validate parsed email
function M.validate_email(email)
  local issues = {}
  
  if not email.from or email.from == '' then
    table.insert(issues, "Missing 'From' address")
  end
  
  if not email.to or email.to == '' then
    table.insert(issues, "Missing 'To' address")
  end
  
  if not email.subject or email.subject == '' then
    table.insert(issues, "Missing subject")
  end
  
  -- Check for parsing errors
  if email.errors and #email.errors > 0 then
    for _, err in ipairs(email.errors) do
      table.insert(issues, string.format("Parse error at line %d: %s", err.line_num, err.error))
    end
  end
  
  return #issues == 0, issues
end

-- Debug: Test parser
function M.debug_test_parser()
  print("=== Draft Parser Test ===")
  
  local test_cases = {
    {
      name = "Simple email",
      input = {
        "From: test@example.com",
        "To: recipient@example.com",
        "Subject: Test Subject",
        "",
        "This is the body."
      }
    },
    {
      name = "With display headers",
      input = {
        "From: test@example.com",
        "To: vim.NIL",
        "Subject: ",
        "---",
        "From: Test User <test@example.com>",
        "To: recipient@example.com",
        "Subject: Real Subject",
        "",
        "Body content here."
      }
    },
    {
      name = "Multipart content",
      input = {
        "From: test@example.com",
        "To: recipient@example.com",
        "Subject: Test",
        "",
        "Text before multipart",
        "<#part type=text/html>",
        "<html>content</html>",
        "<#/part>",
        "Text after multipart"
      }
    }
  }
  
  for _, test in ipairs(test_cases) do
    print("\nTest: " .. test.name)
    local result = M.parse_email(test.input)
    print("  From: " .. result.from)
    print("  To: " .. result.to)
    print("  Subject: " .. result.subject)
    print("  Body lines: " .. vim.tbl_count(vim.split(result.body, '\n')))
    print("  Errors: " .. #result.errors)
  end
end

-- Register debug command
vim.api.nvim_create_user_command('DebugDraftParser', M.debug_test_parser, {})

return M