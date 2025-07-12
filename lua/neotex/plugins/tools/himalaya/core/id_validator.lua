-- ID Validation System
-- Centralized validation and generation for draft and email IDs
--
-- This module prevents the "Drafts" folder name from being used as an ID
-- and ensures all IDs conform to expected formats.

local M = {}

-- Dependencies
local logger = require('neotex.plugins.tools.himalaya.core.logger')

-- Known folder names that should never be used as IDs
local FOLDER_NAMES = {
  'INBOX', 'Inbox', 'inbox',
  'Drafts', 'drafts', 'DRAFTS',
  'Sent', 'sent', 'SENT',
  'Trash', 'trash', 'TRASH',
  'Spam', 'spam', 'SPAM',
  'Junk', 'junk', 'JUNK',
  'Archive', 'archive', 'ARCHIVE',
  'All Mail', 'All mail', 'all mail'
}

-- Create a lookup table for faster checking
local FOLDER_NAME_SET = {}
for _, name in ipairs(FOLDER_NAMES) do
  FOLDER_NAME_SET[name] = true
end

-- Validate himalaya ID format
function M.is_valid_id(id)
  -- Basic type and existence check
  if not id or type(id) ~= 'string' or id == '' then
    logger.debug('ID validation failed: invalid type or empty', { id = id, type = type(id) })
    return false
  end
  
  -- Check if it's a known folder name
  if FOLDER_NAME_SET[id] then
    logger.warn('ID validation failed: folder name used as ID', { id = id })
    return false
  end
  
  -- Check if it starts with uppercase (likely a folder name)
  if id:match('^[A-Z]') and #id > 1 and id:match('^[A-Za-z]+$') then
    logger.warn('ID validation failed: likely folder name', { id = id })
    return false
  end
  
  -- Check if it's a local draft ID (draft_timestamp_uniqueid)
  if id:match('^draft_%d+_') then
    logger.debug('ID validation: local draft ID', { id = id })
    return true  -- Local draft IDs are valid
  end
  
  -- Valid himalaya IDs should be numeric strings
  if not id:match('^%d+$') then
    logger.debug('ID validation failed: non-numeric ID', { id = id })
    return false
  end
  
  return true
end

-- Generate temporary local ID for drafts
function M.generate_local_id()
  local timestamp = os.time()
  local random = math.random(10000, 99999)
  return string.format('draft_%d_%d', timestamp, random)
end

-- Generate a unique message ID for emails
function M.generate_message_id()
  local timestamp = os.time()
  local random = math.random(100000, 999999)
  local hostname = vim.fn.hostname() or 'localhost'
  return string.format('<%d.%d@%s>', timestamp, random, hostname)
end

-- Sanitize ID before use (throws error if invalid)
function M.sanitize_id(id)
  if not M.is_valid_id(id) then
    local error_msg = string.format("Invalid ID: '%s'", tostring(id))
    logger.error('ID sanitization failed', { id = id })
    error(error_msg)
  end
  return id
end

-- Safe ID validation (returns nil if invalid, doesn't throw)
function M.safe_validate_id(id)
  if M.is_valid_id(id) then
    return id
  end
  return nil
end

-- Check if string looks like a folder name
function M.is_folder_name(str)
  if not str or type(str) ~= 'string' then
    return false
  end
  
  -- Check known folder names
  if FOLDER_NAME_SET[str] then
    return true
  end
  
  -- Check patterns that suggest folder names
  -- Starts with capital letter and contains only letters/spaces
  if str:match('^[A-Z][A-Za-z%s]+$') then
    return true
  end
  
  return false
end

-- Extract ID from mixed input (e.g., "Draft 12345" -> "12345")
function M.extract_id(input)
  if not input or type(input) ~= 'string' then
    return nil
  end
  
  -- Try to extract numeric ID
  local id = input:match('(%d+)')
  if id and M.is_valid_id(id) then
    return id
  end
  
  -- If the whole string is a valid ID, return it
  if M.is_valid_id(input) then
    return input
  end
  
  return nil
end

-- Validate command arguments to prevent folder names in ID positions
function M.validate_command_args(command, args)
  -- Commands that expect an ID as first argument after command
  local id_commands = {
    'read', 'delete', 'move', 'copy', 'flag', 'unflag',
    'mark', 'unmark', 'download', 'forward', 'reply'
  }
  
  -- Find the command in args
  local command_index = nil
  for i, arg in ipairs(args) do
    if arg == command then
      command_index = i
      break
    end
  end
  
  if not command_index then
    return true -- Command not found, let it pass
  end
  
  -- Check if this command expects an ID
  local needs_id = false
  for _, cmd in ipairs(id_commands) do
    if command == cmd or command == 'message ' .. cmd or command == 'envelope ' .. cmd then
      needs_id = true
      break
    end
  end
  
  if not needs_id then
    return true
  end
  
  -- Get the ID argument (next argument after command)
  local id_index = command_index + 1
  if id_index <= #args then
    local potential_id = args[id_index]
    
    -- Check if it looks like a folder name
    if M.is_folder_name(potential_id) then
      logger.error('Folder name used where ID expected', {
        command = command,
        invalid_id = potential_id,
        args = args
      })
      return false, string.format("Invalid ID '%s' for command '%s'", potential_id, command)
    end
    
    -- For strict validation, could also check is_valid_id
    -- but that might be too restrictive for some himalaya commands
  end
  
  return true
end

-- Create a validated ID wrapper for safer usage
function M.create_id(value)
  if not M.is_valid_id(value) then
    return nil, string.format("Invalid ID: %s", tostring(value))
  end
  
  return {
    value = value,
    type = 'email_id',
    is_valid = true,
    
    -- Method to get the ID value
    get = function(self)
      return self.value
    end,
    
    -- Method to convert to string
    tostring = function(self)
      return self.value
    end
  }
end

-- Debug: Test ID validation
function M.debug_test_validation()
  local test_cases = {
    -- Valid IDs
    { id = "12345", expected = true },
    { id = "1", expected = true },
    { id = "999999999", expected = true },
    
    -- Invalid IDs
    { id = "Drafts", expected = false },
    { id = "INBOX", expected = false },
    { id = "Sent", expected = false },
    { id = "abc123", expected = false },
    { id = "123abc", expected = false },
    { id = "", expected = false },
    { id = nil, expected = false },
    { id = "All Mail", expected = false },
    { id = "draft_123", expected = false },
  }
  
  print("=== ID Validator Test ===")
  local passed = 0
  local failed = 0
  
  for _, test in ipairs(test_cases) do
    local result = M.is_valid_id(test.id)
    local status = (result == test.expected) and "PASS" or "FAIL"
    
    if result == test.expected then
      passed = passed + 1
    else
      failed = failed + 1
    end
    
    print(string.format("%s: id='%s', expected=%s, got=%s",
      status, tostring(test.id), tostring(test.expected), tostring(result)))
  end
  
  print(string.format("\nTotal: %d, Passed: %d, Failed: %d",
    passed + failed, passed, failed))
end

-- Register debug command
vim.api.nvim_create_user_command('DebugIDValidator', M.debug_test_validation, {})

return M