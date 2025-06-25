-- Seamless Email Experience Module
-- Provides automatic updates and streamlined mail sync for the best user experience

local M = {}

local config = require('neotex.plugins.tools.himalaya.config')
local utils = require('neotex.plugins.tools.himalaya.utils')
local sidebar = require('neotex.plugins.tools.himalaya.sidebar')
local ui = require('neotex.plugins.tools.himalaya.ui')
local native_sync = require('neotex.plugins.tools.himalaya.native_sync')
local notify = require('neotex.util.notifications')

-- Experience enhancement state
M.enhancements = {
  auto_refresh_enabled = true,
  smart_sync_enabled = true,
  seamless_navigation = true,
  background_updates = true
}

-- Auto-refresh interval in seconds (separate from sync interval)
M.auto_refresh_interval = 60 -- 1 minute for UI refresh

-- Timer for background email checks
M.background_timer = nil

-- Enhanced email list that auto-refreshes when stale
function M.show_email_list_enhanced(args)
  -- Call original function
  local result = ui.show_email_list(args)
  
  -- Setup background refresh if enabled
  if M.enhancements.background_updates and result then
    M.start_background_refresh()
  end
  
  return result
end

-- Start background refresh timer for open sidebar
function M.start_background_refresh()
  if M.background_timer then
    M.stop_background_refresh()
  end
  
  if not sidebar.is_open() then
    return
  end
  
  M.background_timer = vim.loop.new_timer()
  M.background_timer:start(
    M.auto_refresh_interval * 1000,
    M.auto_refresh_interval * 1000,
    vim.schedule_wrap(function()
      -- Only refresh if sidebar is still open and user isn't actively typing
      if sidebar.is_open() and vim.fn.mode() == 'n' then
        M.background_email_check()
      end
    end)
  )
end

function M.stop_background_refresh()
  if M.background_timer then
    M.background_timer:stop()
    M.background_timer:close()
    M.background_timer = nil
  end
end

-- Background check that only updates if there are changes
function M.background_email_check()
  local current_account = config.state.current_account
  local current_folder = config.state.current_folder or 'INBOX'
  
  -- Clear cache to get fresh data
  utils.clear_email_cache(current_account, current_folder)
  
  -- Get fresh email list
  local emails = utils.get_email_list(current_account, current_folder, 1, 30)
  
  if emails then
    local buf = sidebar.get_buf()
    if buf and vim.api.nvim_buf_is_valid(buf) then
      local cached_emails = vim.b[buf].himalaya_emails
      
      -- Compare email count and IDs to detect changes
      local has_changes = false
      if not cached_emails or #emails ~= #cached_emails then
        has_changes = true
      else
        -- Check if email IDs match (quick change detection)
        for i, email in ipairs(emails) do
          if not cached_emails[i] or email.id ~= cached_emails[i].id then
            has_changes = true
            break
          end
        end
      end
      
      -- Only update if there are actual changes
      if has_changes then
        local lines = ui.format_email_list(emails)
        sidebar.update_content(lines)
        
        -- Update buffer data
        vim.api.nvim_buf_set_var(buf, 'himalaya_emails', emails)
        
        notify.himalaya('Email list updated', notify.categories.BACKGROUND, { 
          new_count = #emails,
          folder = current_folder
        })
      end
    end
  end
end

-- Enhanced sync command that provides immediate feedback
function M.enhanced_sync(force)
  notify.himalaya('🔄 Syncing emails...', notify.categories.USER_ACTION)
  
  local success = native_sync.smart_native_sync(force)
  
  if success then
    -- Provide immediate visual feedback in sidebar
    if sidebar.is_open() then
      M.flash_sync_success()
    end
  end
  
  return success
end

-- Visual feedback for successful sync
function M.flash_sync_success()
  local buf = sidebar.get_buf()
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  
  -- Temporarily add sync indicator to header
  local lines = vim.api.nvim_buf_get_lines(buf, 0, 3, false)
  if #lines >= 2 then
    local original_line = lines[2]
    local sync_line = original_line .. ' ✓ Synced'
    
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 1, 2, false, {sync_line})
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    
    -- Restore original after 2 seconds
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_set_option(buf, 'modifiable', true)
        vim.api.nvim_buf_set_lines(buf, 1, 2, false, {original_line})
        vim.api.nvim_buf_set_option(buf, 'modifiable', false)
      end
    end, 2000)
  end
end

-- Enhanced folder switching with auto-refresh
function M.switch_folder_enhanced()
  local folders = utils.get_folders(config.state.current_account)
  if not folders then
    notify.himalaya('Could not get folder list', notify.categories.ERROR)
    return
  end
  
  vim.ui.select(folders, {
    prompt = 'Select folder:',
    format_item = function(folder)
      -- Show current folder with indicator
      if folder == config.state.current_folder then
        return '▶ ' .. folder .. ' (current)'
      end
      return '  ' .. folder
    end
  }, function(choice)
    if choice and choice ~= config.state.current_folder then
      -- Switch folder and auto-refresh
      config.state.current_folder = choice
      ui.reset_pagination()
      
      -- Show loading indicator
      notify.himalaya('Loading ' .. choice .. '...', notify.categories.STATUS)
      
      -- Load new folder with enhanced experience
      vim.defer_fn(function()
        M.show_email_list_enhanced({choice})
      end, 100)
    end
  end)
end

-- Enhanced account switching
function M.switch_account_enhanced()
  local accounts = vim.tbl_keys(config.config.accounts)
  
  vim.ui.select(accounts, {
    prompt = 'Select account:',
    format_item = function(account)
      local account_info = config.config.accounts[account]
      local display = account
      if account_info and account_info.email then
        display = display .. ' (' .. account_info.email .. ')'
      end
      
      if account == config.state.current_account then
        return '▶ ' .. display .. ' (current)'
      end
      return '  ' .. display
    end
  }, function(choice)
    if choice and choice ~= config.state.current_account then
      if config.switch_account(choice) then
        ui.reset_pagination()
        
        notify.himalaya('Switched to ' .. choice, notify.categories.USER_ACTION)
        
        -- Auto-load email list for new account
        vim.defer_fn(function()
          M.show_email_list_enhanced({})
        end, 200)
      end
    end
  end)
end

-- Setup enhanced keybindings for seamless experience
function M.setup_enhanced_keybinds()
  local group = vim.api.nvim_create_augroup('HimalayaSeamlessExperience', { clear = true })
  
  -- Enhanced buffer-specific keybinds
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'himalaya-list',
    group = group,
    callback = function(args)
      local buf = args.buf
      
      -- Enhanced folder switching
      vim.keymap.set('n', 'gm', M.switch_folder_enhanced, { 
        buffer = buf, 
        desc = 'Switch folder (enhanced)' 
      })
      
      -- Enhanced account switching
      vim.keymap.set('n', 'ga', M.switch_account_enhanced, { 
        buffer = buf, 
        desc = 'Switch account (enhanced)' 
      })
      
      -- Quick sync
      vim.keymap.set('n', 'gs', function()
        M.enhanced_sync(false)
      end, { 
        buffer = buf, 
        desc = 'Quick sync' 
      })
      
      -- Force sync
      vim.keymap.set('n', 'gS', function()
        M.enhanced_sync(true)
      end, { 
        buffer = buf, 
        desc = 'Force sync' 
      })
      
      -- Auto-refresh toggle
      vim.keymap.set('n', 'gA', function()
        M.toggle_auto_refresh()
      end, { 
        buffer = buf, 
        desc = 'Toggle auto-refresh' 
      })
    end
  })
end

-- Toggle auto-refresh feature
function M.toggle_auto_refresh()
  M.enhancements.background_updates = not M.enhancements.background_updates
  
  if M.enhancements.background_updates then
    M.start_background_refresh()
    notify.himalaya('Auto-refresh enabled', notify.categories.USER_ACTION)
  else
    M.stop_background_refresh()
    notify.himalaya('Auto-refresh disabled', notify.categories.USER_ACTION)
  end
end

-- Apply seamless experience enhancements
function M.apply_enhancements()
  -- Override UI functions with enhanced versions
  ui.show_email_list_original = ui.show_email_list
  ui.show_email_list = M.show_email_list_enhanced
  
  -- Setup enhanced keybindings
  M.setup_enhanced_keybinds()
  
  -- Setup automatic cleanup when sidebar closes
  local original_close = sidebar.close
  sidebar.close = function()
    M.stop_background_refresh()
    return original_close()
  end
  
  notify.himalaya('Seamless email experience activated', notify.categories.BACKGROUND)
end

-- Create commands
function M.setup_commands()
  vim.api.nvim_create_user_command('HimalayaSeamlessToggle', function()
    if M.enhancements.background_updates then
      M.enhancements.background_updates = false
      M.stop_background_refresh()
      notify.himalaya('Seamless experience disabled', notify.categories.USER_ACTION)
    else
      M.apply_enhancements()
      notify.himalaya('Seamless experience enabled', notify.categories.USER_ACTION)
    end
  end, {
    desc = 'Toggle seamless email experience'
  })
  
  -- REMOVED: Duplicate HimalayaEnhancedSync command - use the one in commands.lua instead
  -- vim.api.nvim_create_user_command('HimalayaEnhancedSync', function(opts)
  --   M.enhanced_sync(opts.bang)
  -- end, {
  --   bang = true,
  --   desc = 'Enhanced sync with visual feedback'
  -- })
  
  vim.api.nvim_create_user_command('HimalayaAutoRefreshToggle', M.toggle_auto_refresh, {
    desc = 'Toggle automatic email refresh'
  })
end

-- Initialize seamless experience
function M.init()
  M.apply_enhancements()
end

-- Cleanup
function M.cleanup()
  M.stop_background_refresh()
end

return M