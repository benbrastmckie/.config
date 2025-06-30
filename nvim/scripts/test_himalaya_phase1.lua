-- Test script for Himalaya Phase 1: Highlight Groups and Basic Color Coding

-- Test 1: Verify highlight groups are created
local function test_highlight_groups()
  print("Testing highlight groups...")
  
  -- Initialize sidebar
  local sidebar = require('neotex.plugins.tools.himalaya.ui.sidebar')
  sidebar.init()
  
  -- Check if highlight groups exist
  local groups = {'HimalayaUnread', 'HimalayaStarred', 'HimalayaSelected', 'HimalayaCheckbox', 'HimalayaCheckboxSelected'}
  
  for _, group in ipairs(groups) do
    local hl = vim.api.nvim_get_hl_by_name(group, true)
    if hl and (hl.foreground or hl.background or hl.bold) then
      print("✓ " .. group .. " highlight group created")
    else
      print("✗ " .. group .. " highlight group NOT created")
    end
  end
end

-- Test 2: Test email metadata parsing
local function test_email_metadata()
  print("\nTesting email metadata parsing...")
  
  -- Mock email data
  local emails = {
    {
      from = {name = "John Doe", addr = "john@example.com"},
      subject = "Unread email",
      date = "2025-06-30",
      flags = {} -- No flags = unread
    },
    {
      from = {name = "Jane Smith", addr = "jane@example.com"},
      subject = "Read email",
      date = "2025-06-30",
      flags = {"Seen"}
    },
    {
      from = {name = "Boss", addr = "boss@example.com"},
      subject = "Starred email",
      date = "2025-06-30",
      flags = {"Seen", "Flagged"}
    }
  }
  
  -- Format email list
  local main = require('neotex.plugins.tools.himalaya.ui.main')
  local lines = main.format_email_list(emails)
  
  -- Check metadata
  if lines.metadata then
    print("✓ Metadata structure created")
    
    local email_line_start = 5 -- After header lines
    for i, email in ipairs(emails) do
      local line_num = email_line_start + i
      local metadata = lines.metadata[line_num]
      
      if metadata then
        print(string.format("  Email %d: seen=%s, starred=%s", 
          i, tostring(metadata.seen), tostring(metadata.starred)))
      end
    end
  else
    print("✗ No metadata found")
  end
  
  return lines
end

-- Test 3: Test visual rendering (manual verification)
local function test_visual_rendering()
  print("\nManual visual test - opening Himalaya sidebar...")
  
  -- Close any existing Himalaya windows
  vim.cmd('silent! HimalayaToggle')
  vim.wait(100)
  
  -- Open Himalaya
  vim.cmd('Himalaya')
  
  print("\nCheck the sidebar for:")
  print("- Light blue highlighting on unread emails")
  print("- Light orange highlighting on starred emails")
  print("- Regular text color on read emails")
end

-- Run tests
print("=== Himalaya Phase 1 Testing ===\n")

test_highlight_groups()
local lines = test_email_metadata()

-- Ask if user wants visual test
vim.ui.input({prompt = "Run visual test? (y/n): "}, function(input)
  if input and input:lower() == 'y' then
    test_visual_rendering()
  else
    print("\nSkipping visual test.")
  end
end)

print("\n=== Phase 1 Testing Complete ===")