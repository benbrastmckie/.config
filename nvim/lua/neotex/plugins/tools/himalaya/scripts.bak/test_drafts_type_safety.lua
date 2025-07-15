#!/usr/bin/env nvim -l
-- Test script to verify type safety in sidebar_v2 for draft emails

-- Add the config path to package.path
local config_dir = vim.fn.expand('~/.config/nvim')
package.path = package.path .. ';' .. config_dir .. '/lua/?.lua'

-- Load the sidebar_v2 module
local sidebar_v2 = require('neotex.plugins.tools.himalaya.ui.sidebar_v2')

-- Test email objects with different from field types
local test_emails = {
  -- Test 1: from as string
  {
    id = "test1",
    from = "user@example.com",
    subject = "Test email 1",
    date = "2024-01-15",
    account = "test"
  },
  -- Test 2: from as table with name and addr
  {
    id = "test2", 
    from = { name = "John Doe", addr = "john@example.com" },
    subject = "Test email 2",
    date = "2024-01-15",
    account = "test"
  },
  -- Test 3: from as table with only addr
  {
    id = "test3",
    from = { addr = "jane@example.com" },
    subject = "Test email 3", 
    date = "2024-01-15",
    account = "test"
  },
  -- Test 4: from as nil
  {
    id = "test4",
    from = nil,
    subject = "Test email 4",
    date = "2024-01-15",
    account = "test"
  },
  -- Test 5: from as number (edge case)
  {
    id = "test5",
    from = 12345,
    subject = "Test email 5",
    date = "2024-01-15",
    account = "test"
  },
  -- Test 6: from with angle brackets format
  {
    id = "test6",
    from = "John Doe <john@example.com>",
    subject = "Test email 6",
    date = "2024-01-15",
    account = "test"
  }
}

print("Testing type safety for email.from field in sidebar_v2...")
print("=========================================================")

-- Test format_draft_line with each email type
for i, email in ipairs(test_emails) do
  print("\nTest " .. i .. ":")
  print("  from type: " .. type(email.from))
  if type(email.from) == "table" then
    print("  from value: {name=" .. tostring(email.from.name) .. ", addr=" .. tostring(email.from.addr) .. "}")
  else
    print("  from value: " .. tostring(email.from))
  end
  
  -- Call format_draft_line
  local ok, result = pcall(sidebar_v2.format_draft_line, email, "[ ] ", 
    email.from or '', email.subject, email.date)
  
  if ok then
    print("  ✓ Success - formatted line: " .. result)
  else
    print("  ✗ Error: " .. result)
  end
end

-- Test the enhance_email_list_formatting function with metadata
print("\n\nTesting enhance_email_list_formatting...")
print("========================================")

-- Create a mock original format function
local function mock_format_fn(emails)
  local lines = {"=== Drafts ===", ""}
  local metadata = {}
  
  for i, email in ipairs(emails) do
    local line_num = i + 2
    lines[line_num] = string.format("[ ] %s | %s", 
      tostring(email.from), email.subject)
    metadata[line_num] = {
      is_draft = true,
      email_index = i,
      selected = false
    }
  end
  
  lines.email_start_line = 3
  lines.metadata = metadata
  return lines
end

-- Enhance the format function
local enhanced = sidebar_v2.enhance_email_list_formatting(mock_format_fn)

-- Mock state to simulate being in drafts folder
package.loaded['neotex.plugins.tools.himalaya.core.state'] = {
  get_current_folder = function() return "Drafts" end,
  get_current_account = function() return "test" end
}

package.loaded['neotex.plugins.tools.himalaya.utils'] = {
  find_draft_folder = function() return "Drafts" end,
  truncate_string = function(str, len) 
    if type(str) ~= "string" then str = tostring(str) end
    return string.len(str) > len and string.sub(str, 1, len-3) .. "..." or str
  end
}

-- Test with our test emails
local ok, result = pcall(enhanced, test_emails)
if ok then
  print("✓ Enhancement successful")
  if type(result) == "table" then
    print("\nFormatted lines:")
    for i, line in ipairs(result) do
      if type(line) == "string" and line ~= "" then
        print("  " .. i .. ": " .. line)
      end
    end
  end
else
  print("✗ Enhancement failed: " .. result)
end

print("\n\nType safety test complete!")