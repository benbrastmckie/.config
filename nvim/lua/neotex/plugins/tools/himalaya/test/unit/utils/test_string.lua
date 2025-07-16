-- Unit tests for string utilities

local test_framework = require('neotex.plugins.tools.himalaya.test.utils.test_framework')
local string_utils = require('neotex.plugins.tools.himalaya.utils.string')

local M = {}

function M.test_truncate()
  -- Test normal truncation
  test_framework.assert_equals(
    string_utils.truncate('very long string', 10),
    'very lo...',
    'Should truncate long strings'
  )
  
  -- Test short string preservation
  test_framework.assert_equals(
    string_utils.truncate('short', 10),
    'short',
    'Should preserve short strings'
  )
  
  -- Test nil handling
  test_framework.assert_equals(
    string_utils.truncate(nil, 10),
    '',
    'Should handle nil input'
  )
  
  -- Test vim.NIL handling
  test_framework.assert_equals(
    string_utils.truncate(vim.NIL, 10),
    '',
    'Should handle vim.NIL input'
  )
  
  -- Test custom ellipsis
  test_framework.assert_equals(
    string_utils.truncate('very long string', 10, '…'),
    'very long…',
    'Should use custom ellipsis'
  )
end

function M.test_format_date()
  -- Test timestamp formatting
  local timestamp = os.time({year=2024, month=1, day=15})
  test_framework.assert_equals(
    string_utils.format_date(timestamp),
    'Jan 15',
    'Should format timestamp correctly'
  )
  
  -- Test string date parsing
  test_framework.assert_equals(
    string_utils.format_date('January 15'),
    'Jan 15',
    'Should parse string dates'
  )
  
  -- Test nil handling
  test_framework.assert_equals(
    string_utils.format_date(nil),
    'Unknown',
    'Should handle nil date'
  )
end

function M.test_format_from()
  -- Test email extraction
  test_framework.assert_equals(
    string_utils.format_from('John Doe <john@example.com>'),
    'John Doe',
    'Should extract name from email'
  )
  
  -- Test quoted name
  test_framework.assert_equals(
    string_utils.format_from('"Doe, John" <john@example.com>'),
    'Doe, John',
    'Should handle quoted names'
  )
  
  -- Test plain email
  test_framework.assert_equals(
    string_utils.format_from('john@example.com'),
    'john',
    'Should extract username from plain email'
  )
  
  -- Test truncation
  local long_name = 'Very Long Name That Should Be Truncated'
  test_framework.assert_equals(
    #string_utils.format_from(long_name),
    20,
    'Should truncate to 20 characters'
  )
end

function M.test_format_size()
  -- Test bytes
  test_framework.assert_equals(
    string_utils.format_size(100),
    '100B',
    'Should format bytes'
  )
  
  -- Test KB
  test_framework.assert_equals(
    string_utils.format_size(1536),
    '1.5KB',
    'Should format kilobytes'
  )
  
  -- Test MB
  test_framework.assert_equals(
    string_utils.format_size(1048576),
    '1.0MB',
    'Should format megabytes'
  )
  
  -- Test nil/zero
  test_framework.assert_equals(
    string_utils.format_size(nil),
    '0B',
    'Should handle nil size'
  )
  
  test_framework.assert_equals(
    string_utils.format_size(0),
    '0B',
    'Should handle zero size'
  )
end

function M.test_time_ago()
  local now = os.time()
  
  -- Test just now
  test_framework.assert_equals(
    string_utils.time_ago(now - 30),
    'just now',
    'Should show just now for recent times'
  )
  
  -- Test minutes
  test_framework.assert_equals(
    string_utils.time_ago(now - 120),
    '2 minutes ago',
    'Should show minutes ago'
  )
  
  -- Test singular minute
  test_framework.assert_equals(
    string_utils.time_ago(now - 60),
    '1 minute ago',
    'Should show singular minute'
  )
  
  -- Test hours
  test_framework.assert_equals(
    string_utils.time_ago(now - 7200),
    '2 hours ago',
    'Should show hours ago'
  )
  
  -- Test days
  test_framework.assert_equals(
    string_utils.time_ago(now - 172800),
    '2 days ago',
    'Should show days ago'
  )
end

function M.test_split()
  -- Test default comma split
  local result = string_utils.split('a,b,c')
  test_framework.assert_equals(#result, 3, 'Should split into 3 parts')
  test_framework.assert_equals(result[1], 'a', 'First part should be a')
  test_framework.assert_equals(result[2], 'b', 'Second part should be b')
  test_framework.assert_equals(result[3], 'c', 'Third part should be c')
  
  -- Test custom delimiter
  result = string_utils.split('a|b|c', '|')
  test_framework.assert_equals(#result, 3, 'Should split with custom delimiter')
end

function M.test_join()
  -- Test default join
  test_framework.assert_equals(
    string_utils.join({'a', 'b', 'c'}),
    'a, b, c',
    'Should join with default delimiter'
  )
  
  -- Test custom delimiter
  test_framework.assert_equals(
    string_utils.join({'a', 'b', 'c'}, '|'),
    'a|b|c',
    'Should join with custom delimiter'
  )
end

function M.test_trim()
  -- Test leading/trailing spaces
  test_framework.assert_equals(
    string_utils.trim('  test  '),
    'test',
    'Should trim whitespace'
  )
  
  -- Test tabs and newlines
  test_framework.assert_equals(
    string_utils.trim('\t\ntest\n\t'),
    'test',
    'Should trim tabs and newlines'
  )
  
  -- Test nil
  test_framework.assert_equals(
    string_utils.trim(nil),
    '',
    'Should handle nil'
  )
end

function M.test_capitalize()
  test_framework.assert_equals(
    string_utils.capitalize('hello'),
    'Hello',
    'Should capitalize first letter'
  )
  
  test_framework.assert_equals(
    string_utils.capitalize('HELLO'),
    'HELLO',
    'Should preserve uppercase'
  )
  
  test_framework.assert_equals(
    string_utils.capitalize(''),
    '',
    'Should handle empty string'
  )
end

function M.test_title_case()
  test_framework.assert_equals(
    string_utils.title_case('hello world'),
    'Hello World',
    'Should convert to title case'
  )
  
  test_framework.assert_equals(
    string_utils.title_case('hello_world'),
    'Hello_World',
    'Should handle underscores'
  )
end

return M