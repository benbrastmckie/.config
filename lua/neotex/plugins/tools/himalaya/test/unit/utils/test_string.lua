-- Unit tests for string utilities

local test_framework = require('neotex.plugins.tools.himalaya.test.utils.test_framework')
local assert = test_framework.assert
local string_utils = require('neotex.plugins.tools.himalaya.utils.string')

local M = {}

-- Test metadata
M.test_metadata = {
  name = "String Utility Tests",
  description = "Tests for string manipulation utilities",
  count = 10,
  category = "unit",
  tags = {"utils", "string", "formatting"},
  estimated_duration_ms = 200
}

function M.test_truncate()
  -- Test normal truncation
  assert.equals(
    string_utils.truncate('very long string', 10),
    'very lo...',
    'Should truncate long strings'
  )
  
  -- Test short string preservation
  assert.equals(
    string_utils.truncate('short', 10),
    'short',
    'Should preserve short strings'
  )
  
  -- Test nil handling
  assert.equals(
    string_utils.truncate(nil, 10),
    '',
    'Should handle nil input'
  )
  
  -- Test vim.NIL handling
  assert.equals(
    string_utils.truncate(vim.NIL, 10),
    '',
    'Should handle vim.NIL input'
  )
  
  -- Test custom ellipsis
  assert.equals(
    string_utils.truncate('very long string', 10, '…'),
    'very long…',
    'Should use custom ellipsis'
  )
end

function M.test_format_date()
  -- Test timestamp formatting
  local timestamp = os.time({year=2024, month=1, day=15})
  assert.equals(
    string_utils.format_date(timestamp),
    'Jan 15',
    'Should format timestamp correctly'
  )
  
  -- Test string date parsing
  assert.equals(
    string_utils.format_date('January 15'),
    'Jan 15',
    'Should parse string dates'
  )
  
  -- Test nil handling
  assert.equals(
    string_utils.format_date(nil),
    'Unknown',
    'Should handle nil date'
  )
end

function M.test_format_from()
  -- Test email extraction
  assert.equals(
    string_utils.format_from('John Doe <john@example.com>'),
    'John Doe',
    'Should extract name from email'
  )
  
  -- Test quoted name
  assert.equals(
    string_utils.format_from('"Doe, John" <john@example.com>'),
    'Doe, John',
    'Should handle quoted names'
  )
  
  -- Test plain email
  assert.equals(
    string_utils.format_from('john@example.com'),
    'john',
    'Should extract username from plain email'
  )
  
  -- Test truncation
  local long_name = 'Very Long Name That Should Be Truncated'
  assert.equals(
    #string_utils.format_from(long_name),
    20,
    'Should truncate to 20 characters'
  )
end

function M.test_format_size()
  -- Test bytes
  assert.equals(
    string_utils.format_size(100),
    '100B',
    'Should format bytes'
  )
  
  -- Test KB
  assert.equals(
    string_utils.format_size(1536),
    '1.5KB',
    'Should format kilobytes'
  )
  
  -- Test MB
  assert.equals(
    string_utils.format_size(1048576),
    '1.0MB',
    'Should format megabytes'
  )
  
  -- Test nil/zero
  assert.equals(
    string_utils.format_size(nil),
    '0B',
    'Should handle nil size'
  )
  
  assert.equals(
    string_utils.format_size(0),
    '0B',
    'Should handle zero size'
  )
end

function M.test_time_ago()
  local now = os.time()
  
  -- Test just now
  assert.equals(
    string_utils.time_ago(now - 30),
    'just now',
    'Should show just now for recent times'
  )
  
  -- Test minutes
  assert.equals(
    string_utils.time_ago(now - 120),
    '2 minutes ago',
    'Should show minutes ago'
  )
  
  -- Test singular minute
  assert.equals(
    string_utils.time_ago(now - 60),
    '1 minute ago',
    'Should show singular minute'
  )
  
  -- Test hours
  assert.equals(
    string_utils.time_ago(now - 7200),
    '2 hours ago',
    'Should show hours ago'
  )
  
  -- Test days
  assert.equals(
    string_utils.time_ago(now - 172800),
    '2 days ago',
    'Should show days ago'
  )
end

function M.test_split()
  -- Test default comma split
  local result = string_utils.split('a,b,c')
  assert.equals(#result, 3, 'Should split into 3 parts')
  assert.equals(result[1], 'a', 'First part should be a')
  assert.equals(result[2], 'b', 'Second part should be b')
  assert.equals(result[3], 'c', 'Third part should be c')
  
  -- Test custom delimiter
  result = string_utils.split('a|b|c', '|')
  assert.equals(#result, 3, 'Should split with custom delimiter')
end

function M.test_join()
  -- Test default join
  assert.equals(
    string_utils.join({'a', 'b', 'c'}),
    'a, b, c',
    'Should join with default delimiter'
  )
  
  -- Test custom delimiter
  assert.equals(
    string_utils.join({'a', 'b', 'c'}, '|'),
    'a|b|c',
    'Should join with custom delimiter'
  )
end

function M.test_trim()
  -- Test leading/trailing spaces
  assert.equals(
    string_utils.trim('  test  '),
    'test',
    'Should trim whitespace'
  )
  
  -- Test tabs and newlines
  assert.equals(
    string_utils.trim('\t\ntest\n\t'),
    'test',
    'Should trim tabs and newlines'
  )
  
  -- Test nil
  assert.equals(
    string_utils.trim(nil),
    '',
    'Should handle nil'
  )
end

function M.test_capitalize()
  assert.equals(
    string_utils.capitalize('hello'),
    'Hello',
    'Should capitalize first letter'
  )
  
  assert.equals(
    string_utils.capitalize('HELLO'),
    'HELLO',
    'Should preserve uppercase'
  )
  
  assert.equals(
    string_utils.capitalize(''),
    '',
    'Should handle empty string'
  )
end

function M.test_title_case()
  assert.equals(
    string_utils.title_case('hello world'),
    'Hello World',
    'Should convert to title case'
  )
  
  assert.equals(
    string_utils.title_case('hello_world'),
    'Hello_World',
    'Should handle underscores'
  )
end

-- Add standardized interface

return M