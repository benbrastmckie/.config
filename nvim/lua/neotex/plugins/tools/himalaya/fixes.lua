-- Himalaya UI Fixes
-- Patches for known issues in the email client

local M = {}

local config = require('neotex.plugins.tools.himalaya.config')
local utils = require('neotex.plugins.tools.himalaya.utils')

-- Fixed delete function that works from both sidebar cursor and email view
function M.delete_current_email_fixed()
  local buf = vim.api.nvim_get_current_buf()
  local email_id
  
  -- Try buffer variable first (for email reading view)
  email_id = vim.b[buf].himalaya_email_id
  
  -- If not found, try cursor-based extraction (for sidebar)
  if not email_id then
    email_id = require('neotex.plugins.tools.himalaya.ui').get_current_email_id()
  end
  
  if not email_id then
    vim.notify('No email to delete', vim.log.levels.WARN)
    return
  end
  
  local success, error_type, extra = utils.smart_delete_email(config.state.current_account, email_id)
  
  if success then
    vim.notify('Email deleted', vim.log.levels.INFO)
    local ui = require('neotex.plugins.tools.himalaya.ui')
    
    -- Close current view only if we're in email reading mode
    if vim.bo.filetype == 'himalaya-email' then
      ui.close_current_view()
    end
    
    ui.refresh_email_list()
  elseif error_type == 'missing_trash' then
    -- Trash folder doesn't exist, offer alternatives
    require('neotex.plugins.tools.himalaya.ui').handle_missing_trash_folder(email_id, extra)
  else
    vim.notify('Failed to delete email: ' .. (extra or 'Unknown error'), vim.log.levels.ERROR)
  end
end

-- Improved spam folder detection
function M.find_spam_folder(folders)
  -- Exact matches first (including Gmail specific folders)
  local exact_candidates = {
    '[Gmail]/Spam',
    'Spam',
    'Junk',
    '[Gmail].Spam',
    'SPAM',
    'JUNK'
  }
  
  for _, candidate in ipairs(exact_candidates) do
    for _, folder in ipairs(folders) do
      if folder == candidate then
        return folder
      end
    end
  end
  
  -- Case-insensitive exact matches
  for _, candidate in ipairs(exact_candidates) do
    for _, folder in ipairs(folders) do
      if folder:lower() == candidate:lower() then
        return folder
      end
    end
  end
  
  -- Partial matches as last resort (but more specific than current logic)
  local partial_candidates = {'spam', 'junk'}
  for _, candidate in ipairs(partial_candidates) do
    for _, folder in ipairs(folders) do
      if folder:lower():find(candidate, 1, true) then -- plain text search, no pattern matching
        return folder
      end
    end
  end
  
  return nil
end

-- Fixed spam function with better folder detection and error handling
function M.spam_current_email_fixed()
  local ui = require('neotex.plugins.tools.himalaya.ui')
  local email_id = ui.get_current_email_id()
  
  if not email_id then
    vim.notify('No email selected', vim.log.levels.WARN)
    return
  end
  
  local folders = utils.get_folders(config.state.current_account)
  if not folders then
    vim.notify('Could not get folder list', vim.log.levels.ERROR)
    return
  end
  
  local spam_folder = M.find_spam_folder(folders)
  
  if spam_folder then
    -- Found a spam folder, move email there
    local success = utils.move_email(email_id, spam_folder)
    if success then
      vim.notify('Email marked as spam and moved to ' .. spam_folder, vim.log.levels.INFO)
      ui.refresh_email_list()
    else
      vim.notify('Failed to move email to spam folder', vim.log.levels.ERROR)
    end
  else
    -- No spam folder found, show better options
    local folder_options = {}
    
    -- Add any folders that might be spam-related
    for _, folder in ipairs(folders) do
      table.insert(folder_options, folder)
    end
    
    -- Sort folders to put likely candidates first
    table.sort(folder_options, function(a, b)
      local a_score = 0
      local b_score = 0
      
      -- Score folders based on likelihood of being spam
      if a:lower():find('spam') or a:lower():find('junk') then a_score = a_score + 10 end
      if b:lower():find('spam') or b:lower():find('junk') then b_score = b_score + 10 end
      if a:lower():find('trash') or a:lower():find('bin') then a_score = a_score + 5 end
      if b:lower():find('trash') or b:lower():find('bin') then b_score = b_score + 5 end
      
      return a_score > b_score
    end)
    
    -- Add special options
    table.insert(folder_options, '--- Special Actions ---')
    table.insert(folder_options, 'Delete permanently')
    table.insert(folder_options, 'Cancel')
    
    vim.ui.select(folder_options, {
      prompt = 'No spam folder found. Select destination:',
      format_item = function(item)
        if item == '--- Special Actions ---' then
          return '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
        end
        return item
      end
    }, function(choice)
      if not choice or choice == 'Cancel' or choice == '--- Special Actions ---' then
        return
      elseif choice == 'Delete permanently' then
        M.delete_current_email_fixed()
      else
        -- Try to move to selected folder
        local success = utils.move_email(email_id, choice)
        if success then
          vim.notify('Email moved to ' .. choice, vim.log.levels.INFO)
          ui.refresh_email_list()
        else
          vim.notify('Failed to move email to ' .. choice, vim.log.levels.ERROR)
        end
      end
    end)
  end
end

-- Apply all fixes by overriding the original functions
function M.apply_fixes()
  local ui = require('neotex.plugins.tools.himalaya.ui')
  
  -- Override the problematic functions
  ui.delete_current_email = M.delete_current_email_fixed
  ui.spam_current_email = M.spam_current_email_fixed
  
  vim.notify('Himalaya fixes applied', vim.log.levels.INFO)
end

-- Create command to apply fixes
function M.setup_commands()
  vim.api.nvim_create_user_command('HimalayaApplyFixes', M.apply_fixes, {
    desc = 'Apply fixes for known Himalaya issues'
  })
  
  vim.api.nvim_create_user_command('HimalayaTestDelete', M.delete_current_email_fixed, {
    desc = 'Test fixed delete function'
  })
  
  vim.api.nvim_create_user_command('HimalayaTestSpam', M.spam_current_email_fixed, {
    desc = 'Test fixed spam function'
  })
end

return M