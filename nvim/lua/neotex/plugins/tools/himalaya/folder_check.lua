-- Check available folders and debug trash folder issues

local M = {}

local config = require('neotex.plugins.tools.himalaya.config')
local utils = require('neotex.plugins.tools.himalaya.utils')

-- List all available folders in the account
function M.list_folders()
  print("=== Checking Himalaya Folders ===")
  print("Current account:", config.state.current_account)
  
  local folders = utils.get_folders(config.state.current_account)
  
  if not folders then
    print("ERROR: Could not get folder list")
    return
  end
  
  print("\nAvailable folders:")
  for i, folder in ipairs(folders) do
    print(string.format("%2d. %s", i, folder))
    
    -- Check if it might be a trash folder
    local lower_folder = folder:lower()
    if lower_folder:match("trash") or lower_folder:match("bin") or lower_folder:match("deleted") then
      print("    ^ Possible trash folder")
    end
  end
  
  print("\nLooking for Gmail-specific folders:")
  local gmail_folders = {
    "[Gmail]/Trash",
    "[Gmail]/Bin", 
    "[Gmail]/All Mail",
    "[Gmail]/Spam",
    "[Gmail]/Sent Mail",
    "[Gmail]/Drafts"
  }
  
  for _, gmail_folder in ipairs(gmail_folders) do
    local found = false
    for _, folder in ipairs(folders) do
      if folder == gmail_folder then
        found = true
        break
      end
    end
    print(string.format("  %s: %s", gmail_folder, found and "FOUND" or "NOT FOUND"))
  end
  
  return folders
end

-- Test the actual delete command
function M.test_delete_command(email_id)
  if not email_id then
    print("ERROR: No email ID provided")
    return
  end
  
  print("\n=== Testing Delete Command ===")
  print("Email ID:", email_id)
  print("Account:", config.state.current_account)
  
  -- Build the command
  local cmd = {
    'himalaya',
    'message', 'delete',
    tostring(email_id),
    '-a', config.state.current_account,
    '-o', 'json'
  }
  
  print("\nCommand:", table.concat(cmd, ' '))
  
  -- Execute and capture result
  local cmd_str = table.concat(cmd, ' ')
  local result = vim.fn.system(cmd_str)
  local exit_code = vim.v.shell_error
  
  print("\nExit code:", exit_code)
  print("Result:", result)
  
  if result:match('cannot find maildir matching name') then
    local missing_folder = result:match('cannot find maildir matching name ([^%s]+)')
    print("\nMISSING FOLDER:", missing_folder or "Unknown")
    print("\nThis means Himalaya is looking for a folder named '" .. (missing_folder or "Trash") .. "' but it doesn't exist.")
  end
end

-- Smart delete with Gmail folder detection
function M.smart_delete_gmail(email_id)
  local folders = utils.get_folders(config.state.current_account)
  if not folders then
    print("ERROR: Could not get folders")
    return false
  end
  
  -- Try to find Gmail trash folder
  local trash_folder = nil
  local possible_trash = {
    "[Gmail]/Trash",
    "[Gmail]/Bin",
    "Trash",
    "TRASH",
    "Deleted",
    "Bin"
  }
  
  for _, candidate in ipairs(possible_trash) do
    for _, folder in ipairs(folders) do
      if folder == candidate then
        trash_folder = folder
        break
      end
    end
    if trash_folder then break end
  end
  
  if trash_folder then
    print("Found trash folder:", trash_folder)
    -- Move to trash folder instead of using delete command
    local success = utils.move_email(email_id, trash_folder)
    if success then
      print("Successfully moved email to", trash_folder)
      return true
    else
      print("Failed to move email to", trash_folder)
      return false
    end
  else
    print("No trash folder found!")
    print("Available folders:", table.concat(folders, ", "))
    return false
  end
end

-- Override the problematic delete function
function M.fix_delete_for_gmail()
  -- Check if local trash is enabled - if so, don't apply this fix
  local trash_manager = require('neotex.plugins.tools.himalaya.trash_manager')
  if trash_manager.is_enabled() then
    -- Local trash is enabled, no need for folder-specific fix
    return
  end
  
  local original_smart_delete = utils.smart_delete_email
  
  utils.smart_delete_email = function(account, email_id)
    -- Get folders first
    local folders = utils.get_folders(account)
    if not folders then
      return false, 'delete_failed', 'Could not get folder list'
    end
    
    -- Look for trash folder
    local trash_folder = nil
    local trash_candidates = {
      "[Gmail]/Trash",
      "[Gmail].Trash",     -- Added dot notation
      "[Gmail]/Bin",
      "[Gmail].Bin",       -- Added dot notation
      "[Gmail]/Deleted",
      "[Gmail].Deleted",   -- Added dot notation
      "Trash",
      "TRASH",
      "Bin",
      "Deleted",
      "INBOX.Trash",       -- Some IMAP servers use this
      "INBOX.Bin"
    }
    
    for _, candidate in ipairs(trash_candidates) do
      for _, folder in ipairs(folders) do
        if folder == candidate then
          trash_folder = folder
          break
        end
      end
      if trash_folder then break end
    end
    
    if trash_folder then
      -- Move to trash instead of delete
      local success = utils.move_email(email_id, trash_folder)
      if success then
        return true, 'moved_to_trash', trash_folder
      else
        return false, 'move_failed', 'Could not move to ' .. trash_folder
      end
    else
      -- No trash folder found, return with folder list
      return false, 'missing_trash', folders
    end
  end
  
  print("Gmail delete fix applied!")
end

-- Commands
function M.setup_commands()
  vim.api.nvim_create_user_command('HimalayaListFolders', M.list_folders, {
    desc = 'List all available folders in current account'
  })
  
  vim.api.nvim_create_user_command('HimalayaTestDelete', function(opts)
    local email_id = opts.args
    if email_id == '' then
      local ui = require('neotex.plugins.tools.himalaya.ui')
      email_id = ui.get_current_email_id()
    end
    M.test_delete_command(email_id)
  end, {
    desc = 'Test delete command with current or specified email',
    nargs = '?'
  })
  
  vim.api.nvim_create_user_command('HimalayaFixGmailDelete', M.fix_delete_for_gmail, {
    desc = 'Apply Gmail-specific delete fix'
  })
end

return M