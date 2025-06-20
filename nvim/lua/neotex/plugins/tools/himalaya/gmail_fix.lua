-- Gmail-specific fixes for missing trash folder

local M = {}

local config = require('neotex.plugins.tools.himalaya.config')
local utils = require('neotex.plugins.tools.himalaya.utils')
local notifications = require('neotex.plugins.tools.himalaya.notifications')

-- Check if Gmail trash folder exists and create if needed
function M.ensure_trash_folder()
  local folders = utils.get_folders(config.state.current_account)
  if not folders then
    return nil
  end
  
  -- Check for any trash-like folder
  local trash_candidates = {
    "[Gmail].Trash",
    "[Gmail]/Trash",
    "[Gmail].Bin",
    "[Gmail]/Bin",
    "Trash",
    "Bin",
    "Deleted"
  }
  
  for _, candidate in ipairs(trash_candidates) do
    for _, folder in ipairs(folders) do
      if folder == candidate then
        return folder -- Found existing trash folder
      end
    end
  end
  
  -- No trash folder found
  return nil
end

-- Use All Mail as fallback for deletion (Gmail's archive)
function M.delete_to_all_mail(email_id)
  local folders = utils.get_folders(config.state.current_account)
  if not folders then
    return false, "Could not get folder list"
  end
  
  -- Find All Mail folder
  local all_mail = nil
  for _, folder in ipairs(folders) do
    if folder == "[Gmail].All Mail" or folder == "[Gmail]/All Mail" then
      all_mail = folder
      break
    end
  end
  
  if all_mail then
    -- Move to All Mail and mark with a label or flag
    local success = utils.move_email(email_id, all_mail)
    if success then
      -- Try to add a "Deleted" label or flag
      -- Note: This might require additional Himalaya commands
      return true, "Moved to " .. all_mail .. " (Gmail archive)"
    else
      return false, "Failed to move to " .. all_mail
    end
  else
    return false, "No All Mail folder found"
  end
end

-- Override smart delete for Gmail accounts without trash
function M.apply_gmail_delete_fix()
  local original_smart_delete = utils.smart_delete_email
  
  utils.smart_delete_email = function(account, email_id)
    -- First check if local trash is enabled - if so, let it handle deletion
    local trash_manager = require('neotex.plugins.tools.himalaya.trash_manager')
    if trash_manager.is_enabled() then
      -- Call the original function which now includes local trash support
      return original_smart_delete(account, email_id)
    end
    
    -- Local trash not enabled, use Gmail-specific logic
    -- First check if we have a trash folder
    local trash_folder = M.ensure_trash_folder()
    
    if trash_folder then
      -- We have a trash folder, use it
      local success = utils.move_email(email_id, trash_folder)
      if success then
        return true, 'moved_to_trash', trash_folder
      else
        return false, 'move_failed', 'Could not move to ' .. trash_folder
      end
    else
      -- No trash folder - for Gmail, we have options:
      -- 1. Move to All Mail (archive)
      -- 2. Create a custom Deleted folder
      -- 3. Show folder picker
      
      local folders = utils.get_folders(account)
      if not folders then
        return false, 'delete_failed', 'Could not get folder list'
      end
      
      -- Option 1: Try to use All Mail as a soft delete
      local all_mail = nil
      for _, folder in ipairs(folders) do
        if folder == "[Gmail].All Mail" or folder == "[Gmail]/All Mail" then
          all_mail = folder
          break
        end
      end
      
      if all_mail then
        -- Offer choice: Archive to All Mail or select custom folder
        local choices = {
          "Archive to " .. all_mail,
          "Select custom folder",
          "Cancel"
        }
        
        vim.ui.select(choices, {
          prompt = "No Trash folder found. How would you like to handle deletion?",
        }, function(choice)
          if choice == choices[1] then
            -- Archive to All Mail
            local success = utils.move_email(email_id, all_mail)
            if success then
              notifications.notify('Email archived to ' .. all_mail, vim.log.levels.INFO)
              -- Update UI
              local performance = require('neotex.plugins.tools.himalaya.performance')
              performance.remove_email_locally(email_id)
              performance.schedule_refresh(1000)
            else
              notifications.notify('Failed to archive email', vim.log.levels.ERROR)
            end
          elseif choice == choices[2] then
            -- Return to show folder picker
            return false, 'missing_trash', folders
          else
            -- Cancelled
            notifications.notify('Delete operation cancelled', vim.log.levels.INFO)
          end
        end)
        
        -- Return special status to prevent default handling
        return false, 'handled_by_dialog', nil
      else
        -- No All Mail folder either, show all folders
        return false, 'missing_trash', folders
      end
    end
  end
  
  notifications.notify_force('Gmail delete fix applied', vim.log.levels.INFO)
end

-- Check Gmail folder structure and suggest fixes
function M.diagnose_gmail_folders()
  print("=== Gmail Folder Diagnosis ===")
  
  local folders = utils.get_folders(config.state.current_account)
  if not folders then
    print("ERROR: Could not get folder list")
    return
  end
  
  print("\nCurrent folders:")
  for _, folder in ipairs(folders) do
    print("  - " .. folder)
  end
  
  local has_trash = M.ensure_trash_folder() ~= nil
  local has_spam = false
  local has_all_mail = false
  
  for _, folder in ipairs(folders) do
    if folder:match("Spam") or folder:match("Junk") then
      has_spam = true
    end
    if folder:match("All Mail") then
      has_all_mail = true
    end
  end
  
  print("\nFolder Status:")
  print("  Trash folder: " .. (has_trash and "✓ Found" or "✗ MISSING"))
  print("  Spam folder: " .. (has_spam and "✓ Found" or "✗ MISSING"))
  print("  All Mail folder: " .. (has_all_mail and "✓ Found" or "○ Available for archive"))
  
  if not has_trash then
    print("\n⚠️  WARNING: No Trash folder found!")
    print("Gmail usually creates these folders automatically.")
    print("Possible solutions:")
    print("1. Log into Gmail web interface and check if Trash folder is hidden")
    print("2. Try sending an email to trash in Gmail web to create the folder")
    print("3. Check your Gmail settings for 'Show in IMAP' options")
    print("4. Use 'Archive to All Mail' as an alternative")
  end
end

-- Setup commands
function M.setup_commands()
  vim.api.nvim_create_user_command('HimalayaDiagnoseGmail', M.diagnose_gmail_folders, {
    desc = 'Diagnose Gmail folder structure'
  })
  
  vim.api.nvim_create_user_command('HimalayaApplyGmailFix', M.apply_gmail_delete_fix, {
    desc = 'Apply Gmail-specific delete handling'
  })
end

return M