-- Unit tests for data/templates.lua module
-- Tests email template system with variable substitution

local M = {}

-- Test metadata
M.test_metadata = {
  name = "Email Template Tests",
  description = "Tests email template system with variable substitution",
  count = 9,
  category = "unit",
  tags = {"templates", "email-composition", "variables"},
  estimated_duration_ms = 300
}

-- Load test framework
package.path = package.path .. ";/home/benjamin/.config/nvim/lua/?.lua"
local framework = require("neotex.plugins.tools.himalaya.test.utils.test_framework")
local test = framework.test
local assert = framework.assert

-- Module under test
local templates = require("neotex.plugins.tools.himalaya.data.templates")

-- Mock state module
local state = require("neotex.plugins.tools.himalaya.core.state")

-- Test setup
local function setup()
  -- Clear user templates
  state.set('email_templates', {})
end

-- Test suite
M.tests = {
  test_builtin_templates_exist = function()
    local all_templates = templates.get_templates()
    assert.is_table(all_templates, "Should return templates table")
    
    -- Check for specific builtin templates
    assert.is_table(all_templates.meeting_request, "Should have meeting_request template")
    assert.is_table(all_templates.follow_up, "Should have follow_up template")
    assert.is_table(all_templates.thank_you, "Should have thank_you template")
    assert.is_table(all_templates.out_of_office, "Should have out_of_office template")
  end,
  
  test_create_template = function()
    setup()
    
    local template_data = {
      name = "Test Template",
      description = "A test template",
      subject = "Hello {{recipient_name}}",
      body = "Dear {{recipient_name}},\n\nThis is a test.\n\nBest,\n{{sender_name}}"
    }
    
    local template = templates.create_template(template_data)
    assert.is_table(template, "Should create template")
    assert.equals(template.name, "Test Template", "Name should match")
    assert.equals(template.id, "test_template", "ID should be generated from name")
    
    -- Check variables were extracted
    assert.is_table(template.variables, "Should have variables")
    assert.equals(#template.variables, 2, "Should extract 2 variables")
  end,
  
  test_extract_variables = function()
    local subject = "Meeting with {{client_name}}"
    local body = "Hi {{client_name}},\n\n{{#if urgent}}This is urgent!{{/if}}\n\nFrom {{sender_name}}"
    
    local vars = templates.extract_variables(subject, body)
    assert.is_table(vars, "Should return variables")
    assert.equals(#vars, 3, "Should find 3 variables")
    
    local var_names = {}
    for _, var in ipairs(vars) do
      table.insert(var_names, var.name)
    end
    
    assert.truthy(vim.tbl_contains(var_names, "client_name"), "Should find client_name")
    assert.truthy(vim.tbl_contains(var_names, "sender_name"), "Should find sender_name")
    assert.truthy(vim.tbl_contains(var_names, "urgent"), "Should find urgent conditional")
  end,
  
  test_apply_template_simple = function()
    setup()
    
    local variables = {
      recipient_name = "John Doe",
      meeting_topic = "Q1 Planning",
      sender_name = "Jane Smith"
    }
    
    local result = templates.apply_template("meeting_request", variables)
    assert.is_table(result, "Should return result")
    assert.equals(type(result.subject), "string", "Should have subject")
    assert.equals(type(result.body), "string", "Should have body")
    
    -- Check substitutions
    assert.truthy(result.subject:match("Q1 Planning"), "Subject should contain topic")
    assert.truthy(result.body:match("John Doe"), "Body should contain recipient name")
    assert.truthy(result.body:match("Jane Smith"), "Body should contain sender name")
  end,
  
  test_process_conditionals = function()
    local text = "Start\n{{#if show_message}}This is shown{{/if}}\nEnd"
    
    -- Test with true condition
    local result1 = templates.process_conditionals(text, { show_message = "true" })
    assert.truthy(result1:match("This is shown"), "Should include conditional content")
    
    -- Test with false condition
    local result2 = templates.process_conditionals(text, { show_message = "false" })
    assert.falsy(result2:match("This is shown"), "Should exclude conditional content")
  end,
  
  test_variable_type_validation = function()
    -- Test email validation
    assert.truthy(templates.variable_types.email.validate("test@example.com"), "Should validate email")
    assert.falsy(templates.variable_types.email.validate("invalid"), "Should reject invalid email")
    
    -- Test date validation
    assert.truthy(templates.variable_types.date.validate("2025-01-17"), "Should validate date")
    assert.falsy(templates.variable_types.date.validate("invalid-date"), "Should reject invalid date")
    
    -- Test URL validation
    assert.truthy(templates.variable_types.url.validate("https://example.com"), "Should validate URL")
    assert.falsy(templates.variable_types.url.validate("not-a-url"), "Should reject invalid URL")
  end,
  
  test_update_template = function()
    setup()
    
    -- Create initial template
    local template = templates.create_template({
      name = "Original",
      subject = "Original Subject",
      body = "Original Body"
    })
    
    -- Update it
    local updated = templates.update_template(template.id, {
      subject = "Updated Subject {{new_var}}",
      body = "Updated Body"
    })
    
    assert.is_table(updated, "Should return updated template")
    assert.equals(updated.subject, "Updated Subject {{new_var}}", "Subject should be updated")
    
    -- Check variables were re-extracted
    local var_names = {}
    for _, var in ipairs(updated.variables) do
      table.insert(var_names, var.name)
    end
    assert.truthy(vim.tbl_contains(var_names, "new_var"), "Should extract new variable")
  end,
  
  test_delete_template = function()
    setup()
    
    -- Create template
    local template = templates.create_template({
      name = "To Delete",
      subject = "Test",
      body = "Test"
    })
    
    -- Delete it
    local success = templates.delete_template(template.id)
    assert.truthy(success, "Delete should succeed")
    
    -- Verify it's gone
    local retrieved = templates.get_template(template.id)
    assert.is_nil(retrieved, "Template should be deleted")
  end,
  
  test_system_variables = function()
    local sys_vars = templates.get_system_variables({})
    
    assert.is_table(sys_vars, "Should return system variables")
    assert.equals(type(sys_vars.current_date), "string", "Should have current_date")
    assert.equals(type(sys_vars.current_time), "string", "Should have current_time")
    assert.equals(type(sys_vars.day_of_week), "string", "Should have day_of_week")
    assert.equals(type(sys_vars.year), "string", "Should have year")
  end
}

-- Run all tests
function M.run()
  local test_results = {
    name = "test_templates",
    total = 0,
    passed = 0,
    failed = 0,
    errors = {}
  }
  
  for test_name, test_fn in pairs(M.tests) do
    test_results.total = test_results.total + 1
    
    -- Set test mode
    _G.HIMALAYA_TEST_MODE = true
    
    local ok, err = pcall(test_fn)
    
    if ok then
      test_results.passed = test_results.passed + 1
      -- Suppress print output when run from test runner
      if not _G.HIMALAYA_TEST_RUNNER_ACTIVE then
        print("✓ " .. test_name)
      end
    else
      test_results.failed = test_results.failed + 1
      table.insert(test_results.errors, {
        test = test_name,
        error = tostring(err)
      })
      -- Suppress print output when run from test runner
      if not _G.HIMALAYA_TEST_RUNNER_ACTIVE then
        print("✗ " .. test_name .. ": " .. tostring(err))
      end
    end
  end
  
  -- Print summary only when not run from test runner
  if not _G.HIMALAYA_TEST_RUNNER_ACTIVE then
    print(string.format("\n%s: %d/%d tests passed (%.1f%%)",
      test_results.name,
      test_results.passed,
      test_results.total,
      (test_results.passed / test_results.total) * 100
    ))
  end
  
  return test_results
end

-- Execute if running directly
if vim.fn.expand('%:t') == 'test_templates.lua' then
  M.run()
end

-- Add standardized interface
M.get_test_count = function() return M.test_metadata.count end
M.get_test_list = function()
  local names = {}
  for name, _ in pairs(M.tests) do
    table.insert(names, name:gsub("^test_", ""):gsub("_", " "))
  end
  return names
end

return M
