-- Force Refresh Module
-- Complete cache clear and refresh

local M = {}

local notify = require('neotex.util.notifications')

function M.force_refresh()
  notify.himalaya('=== FORCE REFRESH STARTED ===', notify.categories.USER_ACTION)
  
  -- 1. Clear all Himalaya databases
  notify.himalaya('1. Clearing Himalaya database...', notify.categories.STATUS)
  os.execute('rm -rf ~/.local/share/himalaya/.id-mappers 2>/dev/null')
  os.execute('rm -rf ~/.local/share/himalaya 2>/dev/null')
  
  -- 2. Clear any cache directories
  notify.himalaya('2. Clearing cache directories...', notify.categories.STATUS)
  os.execute('rm -rf ~/.cache/himalaya 2>/dev/null')
  
  -- 3. Clear in-memory cache
  notify.himalaya('3. Clearing in-memory cache...', notify.categories.STATUS)
  local utils = require('neotex.plugins.tools.himalaya.utils')
  local config = require('neotex.plugins.tools.himalaya.config')
  
  -- Use the more aggressive cache clear
  utils.force_clear_all_caches()
  
  -- 4. Reset pagination
  notify.himalaya('4. Resetting pagination...', notify.categories.STATUS)
  config.state.current_page = 1
  
  -- 5. Close and reopen sidebar
  notify.himalaya('5. Refreshing sidebar...', notify.categories.STATUS)
  local sidebar = require('neotex.plugins.tools.himalaya.sidebar')
  local ui = require('neotex.plugins.tools.himalaya.ui')
  
  if sidebar.is_open() then
    sidebar.close()
    vim.defer_fn(function()
      ui.show_email_list({})
    end, 100)
  end
  
  notify.himalaya('=== FORCE REFRESH COMPLETE ===', notify.categories.USER_ACTION)
  notify.himalaya('Sidebar will show fresh emails from disk', notify.categories.STATUS)
end

-- Test Himalaya directly
function M.test_himalaya()
  notify.himalaya('Testing Himalaya CLI directly...', notify.categories.USER_ACTION)
  
  local handle = io.popen('himalaya envelope list -f INBOX --page 1 --page-size 50 2>&1')
  if handle then
    local output = handle:read('*a')
    handle:close()
    
    -- Count unique email by subject + date
    local emails = {}
    local duplicate_count = 0
    local total_count = 0
    
    for line in output:gmatch('[^\n]+') do
      -- Parse the full email line to get subject and date
      -- Format: | ID | FLAGS | SUBJECT | FROM | DATE |
      local id, flags, subject, from, date = line:match('|%s*(%S+)%s*|%s*([^|]*)%s*|%s*([^|]+)%s*|%s*([^|]+)%s*|%s*([^|]+)%s*|')
      
      if subject and date and id ~= 'ID' then
        total_count = total_count + 1
        -- Create unique key from subject + date
        local key = vim.trim(subject) .. '|||' .. vim.trim(date)
        
        if emails[key] then
          duplicate_count = duplicate_count + 1
          notify.himalaya(string.format('  Duplicate: "%s" at %s', 
            vim.trim(subject):sub(1, 40), vim.trim(date)), notify.categories.DEBUG)
        else
          emails[key] = true
        end
      end
    end
    
    notify.himalaya(string.format('CLI shows %d total emails, %d unique (subject+time), %d duplicates', 
      total_count, vim.tbl_count(emails), duplicate_count), notify.categories.STATUS)
    
    if duplicate_count == 0 then
      notify.himalaya('✓ No duplicates in CLI output', notify.categories.STATUS)
    else
      notify.himalaya(string.format('⚠️  CLI showing %d duplicate entries', duplicate_count), notify.categories.WARNING)
    end
  end
end

-- Setup commands
function M.setup_commands()
  vim.api.nvim_create_user_command('HimalayaForceRefresh', M.force_refresh, {
    desc = 'Force complete refresh of Himalaya'
  })
  
  vim.api.nvim_create_user_command('HimalayaTestCLI', M.test_himalaya, {
    desc = 'Test Himalaya CLI directly'
  })
end

return M