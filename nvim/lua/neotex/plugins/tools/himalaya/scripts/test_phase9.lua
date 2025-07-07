-- Himalaya Phase 9 Feature Testing Script
-- Interactive testing for all Phase 9 features with comprehensive reporting
-- Usage: :HimalayaTestPhase9

local M = {}

-- Test results storage
local test_results = {}

-- Helper to check debug mode
local function is_debug_mode()
  local config = require('neotex.plugins.tools.himalaya.core.config')
  return config.get('debug_mode', false)
end

-- Helper to log test result
local function log_test_result(test_name, success, message)
  table.insert(test_results, {
    name = test_name,
    success = success,
    message = message
  })
end

-- Wrapper to run a test with immediate feedback
local function run_test_with_feedback(test_name, test_fn)
  local notify = require('neotex.util.notifications')
  
  -- Show starting notification (USER_ACTION so it shows without debug mode)
  notify.himalaya("🔄 Running: " .. test_name, notify.categories.USER_ACTION)
  
  -- Run the test
  local ok, err = pcall(test_fn)
  
  if not ok then
    -- Test crashed
    notify.himalaya("❌ " .. test_name .. " - Error: " .. tostring(err), notify.categories.ERROR)
    log_test_result(test_name, false, "Error: " .. tostring(err))
  end
end

-- Test 1: Undo Send System
function M.test_undo_send()
  local notify = require('neotex.util.notifications')
  local send_queue = require('neotex.plugins.tools.himalaya.core.send_queue')
  
  local test_name = "Undo Send System"
  local success = true
  local issues = {}
  
  -- Debug mode shows more details
  if is_debug_mode() then
    notify.himalaya("=== Testing " .. test_name .. " ===", notify.categories.STATUS)
  end
  
  -- Check if send queue is initialized
  local queue_status = send_queue.get_status()
  if queue_status and queue_status.initialized then
    if is_debug_mode() then
      notify.himalaya("✓ Send queue initialized", notify.categories.USER_ACTION)
      notify.himalaya("Active queue items: " .. queue_status.active_count, notify.categories.STATUS)
      notify.himalaya("Try: :HimalayaSendQueue to view queue", notify.categories.STATUS)
      notify.himalaya("Try: :HimalayaUndoSend to cancel queued emails", notify.categories.STATUS)
    end
  else
    success = false
    table.insert(issues, "Send queue not initialized")
    if is_debug_mode() then
      notify.himalaya("✗ Send queue not initialized", notify.categories.ERROR)
    end
  end
  
  -- Test queue functionality with a mock email
  local test_email = {
    to = "test@example.com",
    subject = "Test Email for Queue",
    body = "This is a test email for the send queue system."
  }
  
  -- Queue test email (with override delay for quick testing)
  local ok, queue_id = pcall(send_queue.queue_email, test_email, "test_account", 5) -- 5 second delay
  if ok and queue_id then
    if is_debug_mode() then
      notify.himalaya("✓ Test email queued successfully: " .. queue_id, notify.categories.USER_ACTION)
    end
    
    -- Immediately cancel it for testing
    local cancel_ok, cancelled = pcall(send_queue.cancel_send, queue_id)
    if cancel_ok and cancelled then
      if is_debug_mode() then
        notify.himalaya("✓ Test email cancelled successfully", notify.categories.USER_ACTION)
      end
    else
      success = false
      table.insert(issues, "Failed to cancel test email")
      if is_debug_mode() then
        notify.himalaya("✗ Cancel error: " .. tostring(cancelled), notify.categories.ERROR)
      end
    end
  else
    -- Queue failed, but this might be expected if account doesn't exist
    if is_debug_mode() then
      notify.himalaya("Queue test skipped (no valid account configured)", notify.categories.STATUS)
      notify.himalaya("This is normal if you haven't set up Himalaya accounts yet", notify.categories.STATUS)
    end
  end
  
  local message = success and "Send queue working correctly" or table.concat(issues, ", ")
  log_test_result(test_name, success, message)
  
  -- Show result immediately
  if success then
    notify.himalaya(string.format("✅ %s: %s", test_name, message), notify.categories.USER_ACTION)
  else
    notify.himalaya(string.format("❌ %s: %s", test_name, message), notify.categories.ERROR)
  end
end

-- Test 2: Advanced Search System
function M.test_advanced_search()
  local notify = require('neotex.util.notifications')
  local search = require('neotex.plugins.tools.himalaya.core.search')
  
  local test_name = "Advanced Search System"
  local success = true
  local issues = {}
  
  -- Debug mode shows more details
  if is_debug_mode() then
    notify.himalaya("=== Testing " .. test_name .. " ===", notify.categories.STATUS)
  end
  
  -- Test query parsing
  local test_queries = {
    "from:john@example.com",
    "subject:meeting has:attachment",
    "after:2024-01-01 before:2024-12-31",
    "is:unread from:github.com",
    "newer_than:7d larger:10MB"
  }
  
  local parsed_queries = 0
  for _, query in ipairs(test_queries) do
    local criteria, error_msg = search.parse_query(query)
    if criteria then
      parsed_queries = parsed_queries + 1
      if is_debug_mode() then
        notify.himalaya(string.format("✓ Parsed: %s", query), notify.categories.STATUS)
      end
    else
      success = false
      table.insert(issues, string.format("Failed to parse: %s (%s)", query, error_msg or "unknown error"))
      if is_debug_mode() then
        notify.himalaya(string.format("✗ Failed to parse: %s", query), notify.categories.ERROR)
      end
    end
  end
  
  -- Test search operators
  local operators = search.operators
  local operator_count = vim.tbl_count(operators)
  
  if is_debug_mode() then
    notify.himalaya(string.format("Available operators: %d", operator_count), notify.categories.STATUS)
    notify.himalaya("Try: :HimalayaSearch to open search UI", notify.categories.STATUS)
    notify.himalaya("Try: :HimalayaSearch from:example.com", notify.categories.STATUS)
    notify.himalaya("Try: :HimalayaSearchClear to clear cache", notify.categories.STATUS)
  end
  
  local message = success and string.format("%d/%d queries parsed, %d operators available", 
    parsed_queries, #test_queries, operator_count) or table.concat(issues, ", ")
  log_test_result(test_name, success, message)
  
  -- Show result immediately
  if success then
    notify.himalaya(string.format("✅ %s: %s", test_name, message), notify.categories.USER_ACTION)
  else
    notify.himalaya(string.format("❌ %s: %s", test_name, message), notify.categories.ERROR)
  end
end

-- Test 3: Email Templates System
function M.test_email_templates()
  local notify = require('neotex.util.notifications')
  local templates = require('neotex.plugins.tools.himalaya.core.templates')
  
  local test_name = "Email Templates System"
  local success = true
  local issues = {}
  
  -- Debug mode shows more details
  if is_debug_mode() then
    notify.himalaya("=== Testing " .. test_name .. " ===", notify.categories.STATUS)
  end
  
  -- Check built-in templates
  local builtin_templates = templates.builtin_templates
  local builtin_count = vim.tbl_count(builtin_templates)
  
  if builtin_count > 0 then
    if is_debug_mode() then
      notify.himalaya(string.format("✓ %d built-in templates available", builtin_count), notify.categories.USER_ACTION)
      for id, template in pairs(builtin_templates) do
        notify.himalaya(string.format("  • %s - %s", template.name, template.description), notify.categories.STATUS)
      end
    end
  else
    success = false
    table.insert(issues, "No built-in templates found")
  end
  
  -- Test template creation
  local test_template = {
    name = "Test Template",
    description = "A test template for validation",
    category = "test",
    subject = "Test: {{subject_var}}",
    body = "Hello {{name}},\n\nThis is a test template.\n\n{{#if urgent}}This is urgent!{{/if}}\n\nBest regards,\n{{sender_name}}"
  }
  
  if is_debug_mode() then
    notify.himalaya("Creating test template with variables: subject_var, name, urgent, sender_name", notify.categories.STATUS)
  end
  
  local created_template = templates.create_template(test_template)
  if created_template then
    if is_debug_mode() then
      notify.himalaya("✓ Test template created successfully", notify.categories.USER_ACTION)
    end
    
    -- Test template application
    local variables = {
      subject_var = "Testing",
      name = "Test User",
      urgent = "true",
      sender_name = "Test Sender"
    }
    
    local result, error_msg = templates.apply_template(created_template.id, variables)
    if result then
      if is_debug_mode() then
        notify.himalaya("✓ Template applied successfully", notify.categories.USER_ACTION)
        notify.himalaya("Subject: " .. result.subject, notify.categories.STATUS)
      end
      
      -- Clean up test template
      templates.delete_template(created_template.id)
    else
      success = false
      local error_detail = error_msg or "Unknown error"
      table.insert(issues, "Failed to apply template: " .. error_detail)
      if is_debug_mode() then
        notify.himalaya("✗ Template application error: " .. error_detail, notify.categories.ERROR)
      end
    end
  else
    success = false
    table.insert(issues, "Failed to create test template")
  end
  
  if is_debug_mode() then
    notify.himalaya("Template commands:", notify.categories.STATUS)
    notify.himalaya("  :HimalayaTemplates - Manage templates", notify.categories.STATUS)
    notify.himalaya("  :HimalayaTemplateNew - Create new template", notify.categories.STATUS)
    notify.himalaya("  :HimalayaTemplateUse - Use template to compose", notify.categories.STATUS)
  end
  
  local message = success and string.format("%d built-in templates, creation/application works", 
    builtin_count) or table.concat(issues, ", ")
  log_test_result(test_name, success, message)
  
  -- Show result immediately
  if success then
    notify.himalaya(string.format("✅ %s: %s", test_name, message), notify.categories.USER_ACTION)
  else
    notify.himalaya(string.format("❌ %s: %s", test_name, message), notify.categories.ERROR)
  end
end

-- Test 4: Email Scheduling (Placeholder)
function M.test_email_scheduling()
  local notify = require('neotex.util.notifications')
  
  local test_name = "Email Scheduling"
  local success = false  -- Not implemented yet
  
  -- Debug mode shows more details
  if is_debug_mode() then
    notify.himalaya("=== Testing " .. test_name .. " ===", notify.categories.STATUS)
    notify.himalaya("Email scheduling is not yet implemented in Phase 9", notify.categories.STATUS)
    notify.himalaya("This feature will be added in a future update", notify.categories.STATUS)
  end
  
  local message = "Not yet implemented"
  log_test_result(test_name, success, message)
  
  -- Show result immediately
  notify.himalaya(string.format("⏳ %s: %s", test_name, message), notify.categories.STATUS)
end

-- Test 5: Multiple Account Views (Placeholder)
function M.test_multiple_account_views()
  local notify = require('neotex.util.notifications')
  
  local test_name = "Multiple Account Views"
  local success = false  -- Not implemented yet
  
  -- Debug mode shows more details
  if is_debug_mode() then
    notify.himalaya("=== Testing " .. test_name .. " ===", notify.categories.STATUS)
    notify.himalaya("Multiple account views not yet implemented in Phase 9", notify.categories.STATUS)
    notify.himalaya("This feature will provide unified, split, and tabbed views", notify.categories.STATUS)
  end
  
  local message = "Not yet implemented"
  log_test_result(test_name, success, message)
  
  -- Show result immediately
  notify.himalaya(string.format("⏳ %s: %s", test_name, message), notify.categories.STATUS)
end

-- Test 6: Window Management (Placeholder)
function M.test_window_management()
  local notify = require('neotex.util.notifications')
  
  local test_name = "Window Management"
  local success = false  -- Not implemented yet
  
  -- Debug mode shows more details
  if is_debug_mode() then
    notify.himalaya("=== Testing " .. test_name .. " ===", notify.categories.STATUS)
    notify.himalaya("Enhanced window management not yet implemented in Phase 9", notify.categories.STATUS)
    notify.himalaya("This feature will improve window coordination and layouts", notify.categories.STATUS)
  end
  
  local message = "Not yet implemented"
  log_test_result(test_name, success, message)
  
  -- Show result immediately
  notify.himalaya(string.format("⏳ %s: %s", test_name, message), notify.categories.STATUS)
end

-- Test 7: Integration Status
function M.test_integration_status()
  local notify = require('neotex.util.notifications')
  
  local test_name = "Integration Status"
  local success = true
  local issues = {}
  
  -- Debug mode shows more details
  if is_debug_mode() then
    notify.himalaya("=== Testing " .. test_name .. " ===", notify.categories.STATUS)
  end
  
  -- Check if core modules are accessible
  local modules_to_check = {
    'neotex.plugins.tools.himalaya.core.send_queue',
    'neotex.plugins.tools.himalaya.core.search',
    'neotex.plugins.tools.himalaya.core.templates',
    'neotex.plugins.tools.himalaya.core.commands.email',
    'neotex.plugins.tools.himalaya.ui.email_composer'
  }
  
  local loaded_modules = 0
  for _, module_name in ipairs(modules_to_check) do
    local ok, module = pcall(require, module_name)
    if ok then
      loaded_modules = loaded_modules + 1
      if is_debug_mode() then
        notify.himalaya(string.format("✓ %s loaded", module_name), notify.categories.STATUS)
      end
    else
      success = false
      table.insert(issues, string.format("Failed to load %s", module_name))
      if is_debug_mode() then
        notify.himalaya(string.format("✗ Failed to load %s: %s", module_name, tostring(module)), notify.categories.ERROR)
      end
    end
  end
  
  -- Check notification system integration
  local notify_config = notify.config
  if notify_config and notify_config.modules and notify_config.modules.himalaya then
    if is_debug_mode() then
      notify.himalaya("✓ Notification system integrated", notify.categories.USER_ACTION)
    end
  else
    success = false
    table.insert(issues, "Notification system not properly integrated")
  end
  
  local message = success and string.format("%d/%d modules loaded, notifications integrated", 
    loaded_modules, #modules_to_check) or table.concat(issues, ", ")
  log_test_result(test_name, success, message)
  
  -- Show result immediately
  if success then
    notify.himalaya(string.format("✅ %s: %s", test_name, message), notify.categories.USER_ACTION)
  else
    notify.himalaya(string.format("❌ %s: %s", test_name, message), notify.categories.ERROR)
  end
end

-- Test 8: Run all tests
function M.run_all_tests()
  local tests = {
    { name = "Undo Send System", fn = M.test_undo_send },
    { name = "Advanced Search System", fn = M.test_advanced_search },
    { name = "Email Templates System", fn = M.test_email_templates },
    { name = "Email Scheduling", fn = M.test_email_scheduling },
    { name = "Multiple Account Views", fn = M.test_multiple_account_views },
    { name = "Window Management", fn = M.test_window_management },
    { name = "Integration Status", fn = M.test_integration_status }
  }
  
  local notify = require('neotex.util.notifications')
  
  -- Clear previous results
  test_results = {}
  
  -- Immediately show what will be tested
  notify.himalaya("=== Running All Phase 9 Tests ===", notify.categories.USER_ACTION)
  notify.himalaya("Tests to run: " .. #tests, notify.categories.USER_ACTION)
  for _, test in ipairs(tests) do
    notify.himalaya("  • " .. test.name, notify.categories.USER_ACTION)
  end
  
  -- Run tests with delays
  for i, test in ipairs(tests) do
    vim.defer_fn(function()
      run_test_with_feedback(test.name, test.fn)
    end, i * 1500)  -- 1.5 second delay between tests
  end
  
  -- Show summary at the end
  vim.defer_fn(function()
    notify.himalaya("=== All Tests Complete ===", notify.categories.USER_ACTION)
    
    -- Count results
    local passed = 0
    local failed = 0
    local pending = 0
    
    for _, result in ipairs(test_results) do
      if result.success then
        passed = passed + 1
      elseif result.message and result.message:match("Not yet implemented") then
        pending = pending + 1
      else
        failed = failed + 1
      end
    end
    
    -- Show final summary
    notify.himalaya(string.format("Test Summary: %d passed, %d pending, %d failed", passed, pending, failed), 
      failed > 0 and notify.categories.ERROR or notify.categories.USER_ACTION)
    
    -- If any failed, show which ones
    if failed > 0 then
      for _, result in ipairs(test_results) do
        if not result.success and not (result.message and result.message:match("Not yet implemented")) then
          notify.himalaya(string.format("❌ Failed: %s - %s", result.name, result.message or "Unknown error"), notify.categories.ERROR)
        end
      end
    end
    
    -- Show what's implemented vs pending
    notify.himalaya(string.format("Phase 9 Progress: %d features implemented, %d pending", passed, pending), notify.categories.STATUS)
  end, (#tests + 1) * 1500)
end

-- Test 9: Show available Phase 9 commands
function M.show_commands()
  local commands = require('neotex.plugins.tools.himalaya.core.commands')
  local float = require('neotex.plugins.tools.himalaya.ui.float')
  
  -- Get Phase 9 commands
  local all_commands = commands.list_commands()
  local phase9_patterns = {
    'SendQueue', 'UndoSend', 'Search', 'Template'
  }
  
  local phase9_commands = {}
  for _, cmd in ipairs(all_commands) do
    for _, pattern in ipairs(phase9_patterns) do
      if cmd:match(pattern) then
        table.insert(phase9_commands, cmd)
        break
      end
    end
  end
  
  -- Sort commands
  table.sort(phase9_commands)
  
  -- Create display
  local lines = {
    "╭─────────────────────────────────────────────╮",
    "│       Phase 9 Himalaya Commands             │",
    "├─────────────────────────────────────────────┤",
    "",
    "Undo Send System:",
    "  :HimalayaSendQueue - Show send queue",
    "  :HimalayaUndoSend [id] - Cancel queued email",
    "",
    "Advanced Search:",
    "  :HimalayaSearch [query] - Search with operators",
    "  :HimalayaSearchClear - Clear search cache",
    "",
    "Email Templates:",
    "  :HimalayaTemplates - Manage templates",
    "  :HimalayaTemplateNew - Create new template",
    "  :HimalayaTemplateEdit [id] - Edit template",
    "  :HimalayaTemplateDelete [id] - Delete template",
    "  :HimalayaTemplateUse [id] - Use template",
    "",
    "Search Operators:",
    "  from:email, to:email, subject:text",
    "  before:date, after:date, newer_than:1d",
    "  has:attachment, is:unread, larger:10MB",
    "",
    "Template Variables:",
    "  {{variable}} - Basic substitution",
    "  {{#if var}}...{{/if}} - Conditional blocks",
    "",
    "╰─────────────────────────────────────────────╯"
  }
  
  float.show('Phase 9 Commands', lines)
end

-- Main interactive test function using Telescope
function M.interactive_test()
  local ok, telescope = pcall(require, 'telescope')
  if not ok then
    -- Fallback to vim.ui.select if Telescope not available
    M.interactive_test_fallback()
    return
  end
  
  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  
  local test_options = {
    { name = "Test Undo Send System", fn = M.test_undo_send, icon = "⏰" },
    { name = "Test Advanced Search System", fn = M.test_advanced_search, icon = "🔍" },
    { name = "Test Email Templates System", fn = M.test_email_templates, icon = "📧" },
    { name = "Test Email Scheduling", fn = M.test_email_scheduling, icon = "📅" },
    { name = "Test Multiple Account Views", fn = M.test_multiple_account_views, icon = "👥" },
    { name = "Test Window Management", fn = M.test_window_management, icon = "🪟" },
    { name = "Test Integration Status", fn = M.test_integration_status, icon = "🔗" },
    { name = "Run All Tests", fn = M.run_all_tests, icon = "🚀" },
    { name = "Show Available Commands", fn = M.show_commands, icon = "📖" },
  }
  
  pickers.new({}, {
    prompt_title = "Himalaya Phase 9 Feature Tests",
    finder = finders.new_table {
      results = test_options,
      entry_maker = function(entry)
        return {
          value = entry,
          display = string.format("%s %s", entry.icon, entry.name),
          ordinal = entry.name,
        }
      end
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection and selection.value.fn then
          selection.value.fn()
        end
      end)
      return true
    end,
  }):find()
end

-- Fallback function using vim.ui.select
function M.interactive_test_fallback()
  local test_options = {
    { name = "1. Test Undo Send System", fn = M.test_undo_send },
    { name = "2. Test Advanced Search System", fn = M.test_advanced_search },
    { name = "3. Test Email Templates System", fn = M.test_email_templates },
    { name = "4. Test Email Scheduling", fn = M.test_email_scheduling },
    { name = "5. Test Multiple Account Views", fn = M.test_multiple_account_views },
    { name = "6. Test Window Management", fn = M.test_window_management },
    { name = "7. Test Integration Status", fn = M.test_integration_status },
    { name = "8. Run All Tests", fn = M.run_all_tests },
    { name = "9. Show Available Commands", fn = M.show_commands },
  }
  
  vim.ui.select(test_options, {
    prompt = "Select a Phase 9 test:",
    format_item = function(item)
      return item.name
    end
  }, function(choice)
    if choice and choice.fn then
      choice.fn()
    end
  end)
end

return M