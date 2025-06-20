-- Himalaya Debug Tools
-- Diagnostic tools for debugging email operations

local M = {}

local config = require('neotex.plugins.tools.himalaya.config')
local utils = require('neotex.plugins.tools.himalaya.utils')
local ui = require('neotex.plugins.tools.himalaya.ui')

-- Test email ID extraction from sidebar
function M.test_email_id_extraction()
  local buftype = vim.bo.filetype
  local buf = vim.api.nvim_get_current_buf()
  
  print("=== Email ID Extraction Test ===")
  print("Buffer filetype:", buftype)
  print("Current buffer:", buf)
  
  if buftype == 'himalaya-list' then
    local line_num = vim.fn.line('.')
    local email_index = line_num - 4
    print("Current line:", line_num)
    print("Email index (line - 4):", email_index)
    
    -- Test buffer variable method (used by delete_current_email)
    local buf_email_id = vim.b[buf].himalaya_email_id
    print("vim.b.himalaya_email_id:", buf_email_id or "nil")
    
    -- Test get_current_email_id method
    local cursor_email_id = ui.get_current_email_id()
    print("get_current_email_id():", cursor_email_id or "nil")
    
    -- Test buffer emails data
    local emails = vim.b.himalaya_emails
    if emails then
      print("Total emails in buffer:", #emails)
      if emails[email_index] then
        print("Email at index", email_index, ":")
        print("  ID:", emails[email_index].id or "nil")
        print("  Subject:", emails[email_index].subject or "nil")
      else
        print("No email at index", email_index)
      end
    else
      print("No himalaya_emails buffer variable")
    end
  else
    print("Not in email list buffer")
    if buftype == 'himalaya-email' then
      print("In email reading buffer")
      local buf_email_id = vim.b[buf].himalaya_email_id
      print("vim.b.himalaya_email_id:", buf_email_id or "nil")
    end
  end
end

-- Test folder detection for spam operations
function M.test_spam_folder_detection()
  print("=== Spam Folder Detection Test ===")
  
  local folders = utils.get_folders(config.state.current_account)
  if not folders then
    print("ERROR: Could not get folders list")
    return
  end
  
  print("Available folders:")
  for i, folder in ipairs(folders) do
    print(string.format("  %d. %s", i, folder))
  end
  
  print("\nTesting spam folder detection:")
  
  local spam_candidates = {'Spam', 'Junk', '[Gmail].Spam', '[Gmail]/Spam', 'SPAM', 'JUNK'}
  local found_folders = {}
  
  -- Test current matching logic (flawed)
  print("\nCurrent matching logic (case-insensitive contains):")
  for _, folder in ipairs(folders) do
    for _, spam_name in ipairs(spam_candidates) do
      if folder:lower():match(spam_name:lower()) then
        print(string.format("  MATCH: '%s' matches '%s'", folder, spam_name))
        table.insert(found_folders, folder)
        break
      end
    end
  end
  
  if #found_folders == 0 then
    print("  No matches found")
  end
  
  -- Test improved exact matching logic
  print("\nImproved exact matching logic:")
  local exact_matches = {}
  for _, folder in ipairs(folders) do
    for _, spam_name in ipairs(spam_candidates) do
      if folder == spam_name then
        print(string.format("  EXACT MATCH: '%s'", folder))
        table.insert(exact_matches, folder)
        break
      end
    end
  end
  
  if #exact_matches == 0 then
    print("  No exact matches found")
  end
  
  -- Test case-insensitive exact matching
  print("\nCase-insensitive exact matching:")
  local case_matches = {}
  for _, folder in ipairs(folders) do
    for _, spam_name in ipairs(spam_candidates) do
      if folder:lower() == spam_name:lower() then
        print(string.format("  CASE MATCH: '%s' == '%s'", folder, spam_name))
        table.insert(case_matches, folder)
        break
      end
    end
  end
  
  if #case_matches == 0 then
    print("  No case-insensitive matches found")
  end
  
  return {
    available_folders = folders,
    current_logic_matches = found_folders,
    exact_matches = exact_matches,
    case_matches = case_matches
  }
end

-- Test move email operation
function M.test_move_email_operation(target_folder)
  print("=== Move Email Operation Test ===")
  
  local email_id = ui.get_current_email_id()
  if not email_id then
    print("ERROR: No email ID found from cursor position")
    return false
  end
  
  print("Email ID:", email_id)
  print("Target folder:", target_folder)
  print("Current account:", config.state.current_account)
  
  -- Check if target folder exists
  local folders = utils.get_folders(config.state.current_account)
  local folder_exists = false
  if folders then
    for _, folder in ipairs(folders) do
      if folder == target_folder then
        folder_exists = true
        break
      end
    end
  end
  
  print("Target folder exists:", folder_exists)
  
  if not folder_exists then
    print("ERROR: Target folder does not exist")
    return false
  end
  
  -- Test the move command construction
  local cmd = string.format('himalaya message move "%s" %s', target_folder, email_id)
  print("Command to execute:", cmd)
  
  -- Ask user if they want to actually execute
  local choice = vim.fn.input("Execute move command? (y/N): ")
  if choice:lower() == 'y' then
    local success = utils.move_email(email_id, target_folder)
    print("Move result:", success)
    return success
  else
    print("Move command not executed (dry run)")
    return true
  end
end

-- Show all debugging info
function M.debug_all()
  print("=============================================")
  print("           HIMALAYA DEBUG REPORT")
  print("=============================================")
  
  M.test_email_id_extraction()
  print()
  M.test_spam_folder_detection()
  print()
  
  print("=== Current State ===")
  print("Account:", config.state.current_account)
  print("Folder:", config.state.current_folder)
  print("Page:", config.state.current_page)
  print("Buffer filetype:", vim.bo.filetype)
  
  print("=============================================")
end

-- Create commands
function M.setup_commands()
  vim.api.nvim_create_user_command('HimalayaDebugEmailID', M.test_email_id_extraction, {
    desc = 'Test email ID extraction from cursor position'
  })
  
  vim.api.nvim_create_user_command('HimalayaDebugSpamFolders', M.test_spam_folder_detection, {
    desc = 'Test spam folder detection logic'
  })
  
  vim.api.nvim_create_user_command('HimalayaDebugMove', function(opts)
    local folder = opts.args
    if folder == '' then
      folder = vim.fn.input('Target folder: ')
    end
    M.test_move_email_operation(folder)
  end, {
    desc = 'Test move email operation',
    nargs = '?'
  })
  
  vim.api.nvim_create_user_command('HimalayaDebugAll', M.debug_all, {
    desc = 'Run all diagnostic tests'
  })
end

return M