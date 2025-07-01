-- Health check system for Himalaya email plugin
-- Detects and diagnoses common issues

local M = {}

-- Dependencies
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local config = require('neotex.plugins.tools.himalaya.core.config')
local state = require('neotex.plugins.tools.himalaya.core.state')

-- Health check functions
M.checks = {}

-- Check UIDVALIDITY files
function M.checks.uidvalidity()
  local account = config.get_current_account()
  local maildir = vim.fn.expand(account.maildir_path)
  
  local issues = {}
  local checked = 0
  
  -- Find all UIDVALIDITY files
  local handle = io.popen('find ' .. vim.fn.shellescape(maildir) .. ' -name ".uidvalidity" 2>/dev/null')
  if handle then
    local files = handle:read('*a')
    handle:close()
    
    for file in files:gmatch('[^\n]+') do
      checked = checked + 1
      
      -- Check file content
      local content_handle = io.open(file, 'r')
      if content_handle then
        local content = content_handle:read('*a')
        content_handle:close()
        
        -- Check for invalid formats
        if content:match('^%d+$') and #content < 5 then
          -- Single digit - our old format
          table.insert(issues, {
            file = file,
            issue = 'Contains timestamp instead of mbsync format',
            fix = 'Empty the file'
          })
        elseif content ~= '' and not content:match('^%d+\n%d+') then
          -- Non-empty but not mbsync format
          table.insert(issues, {
            file = file,
            issue = 'Invalid format',
            fix = 'Empty the file'
          })
        end
      end
    end
  end
  
  return {
    ok = #issues == 0,
    checked = checked,
    issues = issues,
    fix = #issues > 0 and ':HimalayaFixMaildir' or nil
  }
end

-- Check OAuth tokens
function M.checks.oauth()
  local oauth = require('neotex.plugins.tools.himalaya.sync.oauth')
  local account = config.get_current_account()
  
  local issues = {}
  local details = {}
  
  -- Check main account OAuth (for mbsync)
  local main_account = account.name or 'gmail'
  local main_status = oauth.get_status(main_account)
  
  table.insert(details, '━━ Main account (' .. main_account .. ') ━━')
  
  if not main_status.has_token then
    table.insert(issues, 'No OAuth token found for ' .. main_account)
  else
    table.insert(details, '  Token exists: Yes')
  end
  
  if main_status.token_info then
    if main_status.token_info.has_access_token then
      table.insert(details, '  Access token: Present')
    end
    if main_status.token_info.has_refresh_token then
      table.insert(details, '  Refresh token: Present')
    end
  end
  
  if main_status.last_refresh > 0 then
    local ago = os.time() - main_status.last_refresh
    local minutes = math.floor(ago / 60)
    table.insert(details, '  Last refresh: ' .. minutes .. ' minutes ago')
  end
  
  -- Check IMAP account OAuth (for fast check)
  local imap_account = main_account .. '-imap'
  local imap_status = oauth.get_status(imap_account)
  
  table.insert(details, '')
  table.insert(details, '━━ IMAP account (' .. imap_account .. ') ━━')
  
  if not imap_status.has_token then
    table.insert(issues, 'No OAuth token found for ' .. imap_account .. ' (needed for fast check)')
    table.insert(details, '  Token exists: No [!]')
  else
    table.insert(details, '  Token exists: Yes')
  end
  
  if imap_status.token_info then
    if imap_status.token_info.has_access_token then
      table.insert(details, '  Access token: Present')
    else
      table.insert(details, '  Access token: Missing [!]')
    end
    if imap_status.token_info.has_refresh_token then
      table.insert(details, '  Refresh token: Present')
    else
      table.insert(details, '  Refresh token: Missing [!]')
    end
  end
  
  -- Environment check (common for both)
  if not main_status.environment_loaded then
    table.insert(issues, 'OAuth environment variables not loaded')
  else
    table.insert(details, '')
    table.insert(details, 'Environment loaded: Yes')
  end
  
  -- Add fix suggestions
  local fix = nil
  if #issues > 0 then
    if not imap_status.has_token then
      fix = 'Run: himalaya account configure ' .. imap_account
    else
      fix = ':HimalayaOAuthRefresh or run "himalaya account configure" in terminal'
    end
  end
  
  return {
    ok = #issues == 0,
    main_status = main_status,
    imap_status = imap_status,
    issues = issues,
    details = details,
    fix = fix
  }
end

-- Check maildir structure
function M.checks.maildir()
  local account = config.get_current_account()
  local maildir = vim.fn.expand(account.maildir_path)
  
  local issues = {}
  
  -- Check trailing slash
  if not account.maildir_path:match('/$') then
    table.insert(issues, 'Maildir path missing trailing slash (required for Maildir++ format)')
  end
  
  -- Check base directories
  local required_dirs = {'cur', 'new', 'tmp'}
  for _, dir in ipairs(required_dirs) do
    if vim.fn.isdirectory(maildir .. dir) == 0 then
      table.insert(issues, 'Missing ' .. dir .. ' directory in INBOX')
    end
  end
  
  -- Check folder structure
  for imap_name, local_name in pairs(account.folder_map or {}) do
    if local_name ~= 'INBOX' then
      local folder_path = maildir .. '.' .. local_name
      if vim.fn.isdirectory(folder_path) == 1 then
        -- Check subdirectories
        for _, dir in ipairs(required_dirs) do
          if vim.fn.isdirectory(folder_path .. '/' .. dir) == 0 then
            table.insert(issues, 'Missing ' .. dir .. ' in folder ' .. local_name)
          end
        end
      end
    end
  end
  
  return {
    ok = #issues == 0,
    maildir = maildir,
    issues = issues,
    fix = #issues > 0 and 'Check trailing slash in config and run :HimalayaSetupMaildir' or nil
  }
end

-- Check for stuck sync processes and recent errors
function M.checks.sync_status()
  local issues = {}
  local processes = {}
  local details = {}
  
  -- Check for mbsync processes
  local handle = io.popen('ps aux | grep "[m]bsync" 2>/dev/null')
  if handle then
    local output = handle:read('*a')
    handle:close()
    
    for line in output:gmatch('[^\n]+') do
      local pid = line:match('^%S+%s+(%d+)')
      if pid then
        table.insert(processes, {pid = pid, cmd = line})
      end
    end
  end
  
  -- Check lock files
  local lock = require('neotex.plugins.tools.himalaya.sync.lock')
  local active_locks = lock.get_active_locks()
  
  -- Only consider it problematic if there are truly excessive processes (3+)
  -- Single external sync from another nvim instance is normal
  if #processes > 2 then
    table.insert(issues, 'Too many mbsync processes detected (' .. #processes .. ')')
  end
  
  if #active_locks > 0 and #processes == 0 then
    table.insert(issues, 'Stale lock files detected')
  end
  
  -- Check last sync error
  local last_error = state.get("sync.last_error")
  if last_error then
    table.insert(details, 'Last sync error: ' .. last_error)
  end
  
  -- Check last sync time
  local last_sync = state.get("sync.last_sync")
  if last_sync then
    local ago = os.time() - last_sync
    local minutes = math.floor(ago / 60)
    table.insert(details, 'Last sync: ' .. minutes .. ' minutes ago')
  end
  
  -- Add process count
  if #processes > 0 then
    table.insert(details, 'Active mbsync processes: ' .. #processes)
  end
  
  return {
    ok = #issues == 0,
    processes = processes,
    locks = active_locks,
    issues = issues,
    details = details,
    fix = #issues > 0 and ':HimalayaCleanup' or nil
  }
end

-- Check binaries
function M.checks.binaries()
  local issues = {}
  
  for name, path in pairs(config.config.binaries) do
    if vim.fn.executable(path) == 0 then
      table.insert(issues, name .. ' not found at: ' .. path)
    end
  end
  
  return {
    ok = #issues == 0,
    issues = issues,
    fix = #issues > 0 and 'Install missing binaries or update config paths' or nil
  }
end

-- Check folder mappings
function M.checks.folder_mappings()
  local account = config.get_current_account()
  local maildir = vim.fn.expand(account.maildir_path)
  
  local issues = {}
  local mappings = {}
  
  -- Check consistency between folder_map and local_to_imap
  for imap, local_name in pairs(account.folder_map or {}) do
    mappings[imap] = local_name
    
    -- Check reverse mapping
    if account.local_to_imap and account.local_to_imap[local_name] ~= imap then
      table.insert(issues, 'Inconsistent mapping for ' .. imap)
    end
    
    -- Check if local folder exists
    if local_name ~= 'INBOX' then
      local folder_path = maildir .. '.' .. local_name
      if vim.fn.isdirectory(folder_path) == 0 then
        -- This is ok, folder will be created on sync
        mappings[imap] = mappings[imap] .. ' (not synced yet)'
      end
    end
  end
  
  return {
    ok = #issues == 0,
    mappings = mappings,
    issues = issues,
    fix = #issues > 0 and 'Check folder configuration in config' or nil
  }
end

-- Run all health checks
function M.check()
  local checks = {
    {name = 'Binaries', test = M.checks.binaries},
    {name = 'Maildir Structure', test = M.checks.maildir},
    {name = 'UIDVALIDITY Files', test = M.checks.uidvalidity},
    {name = 'OAuth Status', test = M.checks.oauth},
    {name = 'Folder Mappings', test = M.checks.folder_mappings},
    {name = 'Sync Status', test = M.checks.sync_status},
  }
  
  local report = {}
  local all_ok = true
  
  for _, check in ipairs(checks) do
    local result = check.test()
    result.name = check.name
    table.insert(report, result)
    
    if not result.ok then
      all_ok = false
    end
  end
  
  return {
    ok = all_ok,
    report = report
  }
end

-- Display health check results
function M.show_report(silent)
  local result = M.check()
  local float = require('neotex.plugins.tools.himalaya.ui.float')
  
  -- Build output lines
  local lines = {}
  
  if not silent then
    table.insert(lines, 'Himalaya Health Check')
    table.insert(lines, string.rep('=', 40))
    table.insert(lines, '')
  end
  
  for _, check in ipairs(result.report) do
    local icon = check.ok and '✓' or '✗'
    local status = check.ok and 'OK' or 'ISSUES'
    
    if not silent then
      local line = string.format('%s %s: %s', icon, check.name, status)
      table.insert(lines, line)
    end
    
    -- Show details if available (when debug mode is on or if there are issues)
    local notify = require('neotex.util.notifications')
    local show_details = notify.config.modules.himalaya.debug_mode or not check.ok
    
    if show_details and check.details and #check.details > 0 and not silent then
      for _, detail in ipairs(check.details) do
        table.insert(lines, '   ' .. detail)
      end
    end
    
    if not check.ok and check.issues and not silent then
      for _, issue in ipairs(check.issues) do
        if type(issue) == 'table' then
          table.insert(lines, '   ' .. issue.issue .. ' (' .. issue.file .. ')')
        else
          table.insert(lines, '   ' .. issue)
        end
      end
      
      if check.fix then
        table.insert(lines, '   Fix: ' .. check.fix)
      end
    end
  end
  
  if not silent then
    table.insert(lines, '')
    table.insert(lines, string.rep('-', 40))
    
    if result.ok then
      table.insert(lines, 'All checks passed!')
    else
      table.insert(lines, 'Some issues detected. Run suggested fixes.')
    end
    
    -- Show in floating window
    float.show('Himalaya Health Check', lines)
  end
  
  return result
end

-- Fix common issues automatically
function M.fix_common_issues()
  print(' Attempting to fix common issues...')
  
  local fixes_applied = {}
  
  -- Fix UIDVALIDITY files
  local uidvalidity_check = M.checks.uidvalidity()
  if not uidvalidity_check.ok then
    local wizard = require('neotex.plugins.tools.himalaya.setup.wizard')
    local account = config.get_current_account()
    wizard.fix_uidvalidity_files(vim.fn.expand(account.maildir_path))
    table.insert(fixes_applied, 'Fixed UIDVALIDITY files')
  end
  
  -- Clean up stale locks
  local sync_check = M.checks.sync_status()
  if not sync_check.ok and #sync_check.locks > 0 and #sync_check.processes == 0 then
    local lock = require('neotex.plugins.tools.himalaya.sync.lock')
    local cleaned = lock.cleanup_locks()
    if cleaned > 0 then
      table.insert(fixes_applied, 'Cleaned ' .. cleaned .. ' stale lock files')
    end
  end
  
  if #fixes_applied > 0 then
    print(' Applied fixes:')
    for _, fix in ipairs(fixes_applied) do
      print('  - ' .. fix)
    end
  else
    print('No automatic fixes available')
  end
  
  -- Show report again
  vim.defer_fn(function()
    M.show_report()
  end, 1000)
end

return M
