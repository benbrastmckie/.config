-- Draft System Refactor Test Suite
-- Tests all components of the comprehensive draft refactor

local framework = require('neotex.plugins.tools.himalaya.scripts.utils.test_framework')
local assert = framework.assert
local helpers = framework.helpers
local mock = framework.mock

-- Test modules
local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager')
local id_validator = require('neotex.plugins.tools.himalaya.core.id_validator')
local draft_parser = require('neotex.plugins.tools.himalaya.core.draft_parser')
local draft_cache = require('neotex.plugins.tools.himalaya.core.draft_cache')
local retry_handler = require('neotex.plugins.tools.himalaya.core.retry_handler')

-- Test suite
local tests = {}

-- Phase 1 Tests: Draft Manager
table.insert(tests, framework.create_test('draft_manager_registration', function()
  -- Clear any existing drafts
  draft_manager.drafts = {}
  
  -- Register a new draft
  local buffer_id = 42
  local draft_state = draft_manager.register_draft(buffer_id, 'test@example.com', 'Drafts')
  
  assert.truthy(draft_state, "Should create draft state")
  assert.equals(draft_state.buffer_id, buffer_id, "Should have correct buffer ID")
  assert.equals(draft_state.account, 'test@example.com', "Should have correct account")
  assert.equals(draft_state.folder, 'Drafts', "Should have correct folder")
  assert.truthy(draft_state.local_id, "Should generate local ID")
  assert.equals(draft_state.state, 'new', "Should start in 'new' state")
end))

table.insert(tests, framework.create_test('draft_manager_lookups', function()
  -- Clear and register a draft
  draft_manager.drafts = {}
  local buffer_id = 42
  local draft_state = draft_manager.register_draft(buffer_id, 'test@example.com', 'Drafts')
  
  -- Update with himalaya ID
  draft_manager.set_draft_id(buffer_id, '12345')
  
  -- Test lookups
  local by_buffer = draft_manager.get_draft(buffer_id)
  assert.truthy(by_buffer, "Should find draft by buffer ID")
  assert.equals(by_buffer.draft_id, '12345', "Should have updated draft ID")
  
  local by_draft_id = draft_manager.get_draft_by_id('12345')
  assert.truthy(by_draft_id, "Should find draft by draft ID")
  assert.equals(by_draft_id.buffer_id, buffer_id, "Should be same draft")
  
  local by_local_id = draft_manager.get_draft_by_local_id(draft_state.local_id)
  assert.truthy(by_local_id, "Should find draft by local ID")
  assert.equals(by_local_id.buffer_id, buffer_id, "Should be same draft")
end))

table.insert(tests, framework.create_test('draft_manager_content_update', function()
  -- Clear and register a draft
  draft_manager.drafts = {}
  local buffer_id = 42
  draft_manager.register_draft(buffer_id, 'test@example.com', 'Drafts')
  
  -- Update content
  local content = {
    from = 'sender@test.com',
    to = 'recipient@test.com',
    subject = 'Test Subject',
    body = 'Test body content'
  }
  draft_manager.update_content(buffer_id, content)
  
  -- Verify update
  local draft = draft_manager.get_draft(buffer_id)
  assert.truthy(draft.content, "Should have content")
  assert.equals(draft.content.subject, 'Test Subject', "Should update subject")
  assert.equals(draft.content.body, 'Test body content', "Should update body")
  assert.truthy(draft.last_saved, "Should update last_saved timestamp")
end))

-- Phase 1 Tests: ID Validator
table.insert(tests, framework.create_test('id_validator_valid_ids', function()
  -- Test valid IDs
  assert.truthy(id_validator.is_valid_id('12345'), "Numeric string should be valid")
  assert.truthy(id_validator.is_valid_id('999'), "Short numeric should be valid")
  assert.truthy(id_validator.is_valid_id('0'), "Zero should be valid")
end))

table.insert(tests, framework.create_test('id_validator_invalid_ids', function()
  -- Test invalid IDs
  assert.falsy(id_validator.is_valid_id('Drafts'), "Folder name should be invalid")
  assert.falsy(id_validator.is_valid_id('INBOX'), "INBOX should be invalid")
  assert.falsy(id_validator.is_valid_id('Sent'), "Sent should be invalid")
  assert.falsy(id_validator.is_valid_id('abc123'), "Mixed alphanumeric should be invalid")
  assert.falsy(id_validator.is_valid_id(''), "Empty string should be invalid")
  assert.falsy(id_validator.is_valid_id(nil), "Nil should be invalid")
  assert.falsy(id_validator.is_valid_id(vim.NIL), "vim.NIL should be invalid")
end))

table.insert(tests, framework.create_test('id_validator_sanitize', function()
  -- Test sanitization
  assert.no_error(function()
    id_validator.sanitize_id('12345')
  end, "Valid ID should not error")
  
  assert.error(function()
    id_validator.sanitize_id('Drafts')
  end, "Invalid ID:", "Invalid ID should error")
end))

-- Phase 2 Tests: Draft Parser
table.insert(tests, framework.create_test('draft_parser_basic_email', function()
  local email_lines = {
    'From: sender@test.com',
    'To: recipient@test.com',
    'Subject: Test Email',
    '',
    'This is the body.',
    'Second line of body.'
  }
  
  local parsed = draft_parser.parse_email(email_lines)
  
  assert.truthy(parsed, "Should parse email")
  assert.equals(parsed.from, 'sender@test.com', "Should parse From header")
  assert.equals(parsed.to, 'recipient@test.com', "Should parse To header")
  assert.equals(parsed.subject, 'Test Email', "Should parse Subject header")
  assert.equals(parsed.body, 'This is the body.\nSecond line of body.', "Should parse body")
end))

table.insert(tests, framework.create_test('draft_parser_display_headers', function()
  local email_lines = {
    'From: sender@test.com',
    'To: recipient@test.com',
    'Subject: Test Email',
    'Date: 2025-01-01 12:00:00',
    '---',
    'From: sender@test.com',
    'To: recipient@test.com',
    'Subject: Test Email',
    '',
    'This is the body.'
  }
  
  local parsed = draft_parser.parse_email(email_lines)
  
  assert.truthy(parsed, "Should parse email with display headers")
  assert.equals(parsed.subject, 'Test Email', "Should use original headers")
  assert.equals(parsed.body, 'This is the body.', "Should parse body correctly")
end))

table.insert(tests, framework.create_test('draft_parser_multipart', function()
  local email_lines = {
    'From: sender@test.com',
    'To: recipient@test.com',
    'Subject: Test Email',
    '',
    '<#part type="text/plain">',
    'Plain text body',
    '<#/part>',
    '<#part type="text/html">',
    '<p>HTML body</p>',
    '<#/part>'
  }
  
  local parsed = draft_parser.parse_himalaya_draft(email_lines)
  
  assert.truthy(parsed, "Should parse multipart email")
  assert.equals(parsed.body, 'Plain text body', "Should extract plain text content")
  assert.falsy(parsed.body:match('<#part'), "Should remove multipart markers")
end))

table.insert(tests, framework.create_test('draft_parser_vim_nil_cleanup', function()
  local email_lines = {
    'From: sender@test.com',
    'To: ' .. tostring(vim.NIL),
    'Subject: Test Email',
    '',
    'Body content'
  }
  
  local parsed = draft_parser.parse_email(email_lines)
  
  assert.truthy(parsed, "Should parse email with vim.NIL")
  assert.equals(parsed.to, '', "Should clean vim.NIL to empty string")
end))

-- Phase 3 Tests: Draft Cache
table.insert(tests, framework.create_test('draft_cache_metadata', function()
  -- Clear cache
  draft_cache.metadata_cache = {}
  
  -- Cache metadata
  local metadata = {
    subject = 'Cached Subject',
    from = 'sender@test.com',
    to = 'recipient@test.com',
    date = os.date()
  }
  
  draft_cache.cache_draft_metadata('test@example.com', 'Drafts', '12345', metadata)
  
  -- Retrieve metadata
  local cached = draft_cache.get_draft_metadata('test@example.com', 'Drafts', '12345')
  assert.truthy(cached, "Should retrieve cached metadata")
  assert.equals(cached.subject, 'Cached Subject', "Should have correct subject")
  
  -- Test subject retrieval
  local subject = draft_cache.get_draft_subject('test@example.com', 'Drafts', '12345')
  assert.equals(subject, 'Cached Subject', "Should retrieve subject directly")
end))

table.insert(tests, framework.create_test('draft_cache_content', function()
  -- Clear cache
  draft_cache.content_cache = {}
  
  -- Cache content
  local content = {
    headers = { Subject = 'Test' },
    body = 'Test content'
  }
  
  draft_cache.cache_draft_content('test@example.com', 'Drafts', '12345', content)
  
  -- Retrieve content
  local cached = draft_cache.get_draft_content('test@example.com', 'Drafts', '12345')
  assert.truthy(cached, "Should retrieve cached content")
  assert.equals(cached.body, 'Test content', "Should have correct body")
end))

table.insert(tests, framework.create_test('draft_cache_persistence', function()
  -- Clear cache
  draft_cache.metadata_cache = {}
  
  -- Add metadata and persist
  draft_cache.cache_draft_metadata('test@example.com', 'Drafts', '12345', {
    subject = 'Persistent Subject'
  })
  
  -- Save to disk
  draft_cache.save_metadata()
  
  -- Clear memory cache
  draft_cache.metadata_cache = {}
  
  -- Load from disk
  draft_cache.load_metadata()
  
  -- Verify loaded
  local subject = draft_cache.get_draft_subject('test@example.com', 'Drafts', '12345')
  assert.equals(subject, 'Persistent Subject', "Should persist and load metadata")
end))

-- Phase 4 Tests: Retry Handler
table.insert(tests, framework.create_test('retry_handler_success', function()
  local attempts = 0
  
  local ok, result = retry_handler.retry(function()
    attempts = attempts + 1
    if attempts < 3 then
      error("Temporary failure")
    end
    return "Success"
  end, { max_retries = 5, name = "test operation" })
  
  assert.truthy(ok, "Should eventually succeed")
  assert.equals(result, "Success", "Should return success value")
  assert.equals(attempts, 3, "Should retry correct number of times")
end))

table.insert(tests, framework.create_test('retry_handler_non_retryable', function()
  local attempts = 0
  
  local ok, result = retry_handler.retry(function()
    attempts = attempts + 1
    error("Permission denied")
  end, { max_retries = 5, name = "test operation" })
  
  assert.falsy(ok, "Should fail on non-retryable error")
  assert.equals(attempts, 1, "Should not retry non-retryable errors")
end))

table.insert(tests, framework.create_test('retry_handler_himalaya', function()
  local attempts = 0
  
  local ok, result = retry_handler.retry_himalaya(function()
    attempts = attempts + 1
    if attempts < 2 then
      error("cannot open id mapper database")
    end
    return true
  end, "test himalaya operation")
  
  assert.truthy(ok, "Should retry himalaya lock errors")
  assert.equals(attempts, 2, "Should retry once for lock error")
end))

-- Integration Tests
table.insert(tests, framework.create_test('draft_integration_save_and_cache', function()
  -- Clear all state
  draft_manager.drafts = {}
  draft_cache.metadata_cache = {}
  draft_cache.content_cache = {}
  
  -- Register draft
  local buffer_id = 99
  local draft_state = draft_manager.register_draft(buffer_id, 'test@example.com', 'Drafts')
  
  -- Update with content
  local content = {
    from = 'sender@test.com',
    to = 'recipient@test.com',
    subject = 'Integration Test',
    body = 'Testing integration'
  }
  draft_manager.update_content(buffer_id, content)
  
  -- Simulate successful save with ID
  draft_manager.set_draft_id(buffer_id, '99999')
  
  -- Cache the metadata
  draft_cache.cache_draft_metadata('test@example.com', 'Drafts', '99999', {
    subject = content.subject,
    from = content.from,
    to = content.to
  })
  
  -- Verify everything is connected
  local draft = draft_manager.get_draft(buffer_id)
  assert.equals(draft.draft_id, '99999', "Should have draft ID")
  
  local cached_subject = draft_cache.get_draft_subject('test@example.com', 'Drafts', '99999')
  assert.equals(cached_subject, 'Integration Test', "Should cache subject")
  
  -- Find buffer by draft ID
  local found_buffer = draft_manager.find_buffer_for_draft('99999')
  assert.equals(found_buffer, buffer_id, "Should find buffer by draft ID")
end))

-- Performance Tests
table.insert(tests, framework.create_test('draft_parser_performance', function()
  -- Create a large email
  local lines = {
    'From: sender@test.com',
    'To: recipient@test.com',
    'Subject: Performance Test',
    ''
  }
  
  -- Add 1000 lines of body
  for i = 1, 1000 do
    table.insert(lines, 'This is line ' .. i .. ' of the email body.')
  end
  
  local start = vim.loop.hrtime()
  local parsed = draft_parser.parse_email(lines)
  local duration = (vim.loop.hrtime() - start) / 1e6
  
  assert.truthy(parsed, "Should parse large email")
  assert.truthy(duration < 100, "Should parse in under 100ms (actual: " .. duration .. "ms)")
end))

-- Export test suite
_G.himalaya_test = framework.create_suite('Draft System Refactor', tests)

return _G.himalaya_test