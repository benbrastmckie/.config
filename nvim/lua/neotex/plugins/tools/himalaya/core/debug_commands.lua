-- Debug Commands for Himalaya Draft System
-- Provides debugging utilities for troubleshooting draft issues

local M = {}

-- Dependencies
local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
local id_validator = require('neotex.plugins.tools.himalaya.core.id_validator')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local utils = require('neotex.plugins.tools.himalaya.utils')
local float = require('neotex.plugins.tools.himalaya.ui.float')

-- Setup debug commands
function M.setup()
  -- Main debug command
  vim.api.nvim_create_user_command('HimalayaDraftDebug', function(opts)
    local subcmd = opts.args
    if subcmd == 'state' then
      M.show_draft_state()
    elseif subcmd == 'cache' then
      M.show_cache_state()
    elseif subcmd == 'buffer' then
      M.show_buffer_info()
    elseif subcmd == 'validate' then
      M.validate_draft_system()
    elseif subcmd == 'parser' then
      M.test_parser()
    elseif subcmd == 'clear' then
      M.clear_all_state()
    elseif subcmd == 'maildir' then
      M.show_maildir_drafts()
    else
      M.show_debug_menu()
    end
  end, {
    nargs = '?',
    complete = function()
      return { 'state', 'cache', 'buffer', 'validate', 'parser', 'clear', 'maildir' }
    end,
    desc = 'Debug Himalaya draft system'
  })
  
  -- Log level command
  vim.api.nvim_create_user_command('HimalayaLogLevel', function(opts)
    local level = opts.args
    if level == 'debug' or level == 'info' or level == 'warn' or level == 'error' then
      logger.set_level(level)
      vim.notify('Himalaya log level set to: ' .. level)
    else
      vim.notify('Invalid log level. Use: debug, info, warn, or error', vim.log.levels.ERROR)
    end
  end, {
    nargs = 1,
    complete = function()
      return { 'debug', 'info', 'warn', 'error' }
    end,
    desc = 'Set Himalaya log level'
  })
end

-- Show debug menu
function M.show_debug_menu()
  local lines = {
    '# Himalaya Draft Debug Commands',
    '',
    '## Available Commands:',
    '',
    '1. **:HimalayaDraftDebug state**',
    '   Show current draft manager state',
    '',
    '2. **:HimalayaDraftDebug cache**',
    '   Show draft cache contents',
    '',
    '3. **:HimalayaDraftDebug buffer**',
    '   Show current buffer draft info',
    '',
    '4. **:HimalayaDraftDebug validate**',
    '   Validate draft system integrity',
    '',
    '5. **:HimalayaDraftDebug parser**',
    '   Test draft parser on current buffer',
    '',
    '6. **:HimalayaDraftDebug clear**',
    '   Clear all draft state (use with caution)',
    '',
    '7. **:HimalayaDraftDebug maildir**',
    '   Show drafts in maildir',
    '',
    '## Log Level:',
    '',
    '**:HimalayaLogLevel <level>**',
    '   Set log level to: debug, info, warn, or error',
    '',
    'Current log level: ' .. (logger.get_level and logger.get_level() or 'info')
  }
  
  float.show('Himalaya Draft Debug', lines)
end

-- Show draft manager state
function M.show_draft_state()
  local lines = {
    '# Draft Manager State',
    '',
    'Total drafts tracked: ' .. vim.tbl_count(draft_manager.drafts),
    ''
  }
  
  for buffer_id, draft_state in pairs(draft_manager.drafts) do
    table.insert(lines, string.format('## Buffer %d', buffer_id))
    table.insert(lines, '```')
    table.insert(lines, 'Local ID: ' .. (draft_state.local_id or 'none'))
    table.insert(lines, 'Draft ID: ' .. (draft_state.draft_id or 'none'))
    table.insert(lines, 'Account: ' .. (draft_state.account or 'none'))
    table.insert(lines, 'Folder: ' .. (draft_state.folder or 'none'))
    table.insert(lines, 'State: ' .. (draft_state.state or 'unknown'))
    table.insert(lines, 'Last Saved: ' .. (draft_state.last_saved and os.date('%Y-%m-%d %H:%M:%S', draft_state.last_saved) or 'never'))
    table.insert(lines, 'Last Synced: ' .. (draft_state.last_synced and os.date('%Y-%m-%d %H:%M:%S', draft_state.last_synced) or 'never'))
    
    if draft_state.content then
      table.insert(lines, '')
      table.insert(lines, 'Content:')
      table.insert(lines, '  From: ' .. (draft_state.content.from or ''))
      table.insert(lines, '  To: ' .. (draft_state.content.to or ''))
      table.insert(lines, '  Subject: ' .. (draft_state.content.subject or ''))
      table.insert(lines, '  Body Length: ' .. (draft_state.content.body and #draft_state.content.body or 0))
    end
    
    table.insert(lines, '```')
    table.insert(lines, '')
  end
  
  float.show('Draft Manager State', lines)
end

-- Show cache state
function M.show_cache_state()
  local stats = draft_cache.get_stats()
  local lines = {
    '# Draft Cache State',
    '',
    '## Statistics:',
    '```',
    'Total Metadata Entries: ' .. stats.metadata_count,
    'Total Content Entries: ' .. stats.content_count,
    'Total Accounts: ' .. stats.account_count,
    'Total Size: ' .. string.format('%.2f KB', stats.total_size / 1024),
    '```',
    ''
  }
  
  -- Show metadata cache
  table.insert(lines, '## Metadata Cache:')
  table.insert(lines, '')
  
  for account, folders in pairs(draft_cache.metadata_cache) do
    table.insert(lines, '### Account: ' .. account)
    for folder, drafts in pairs(folders) do
      table.insert(lines, '#### Folder: ' .. folder)
      for draft_id, metadata in pairs(drafts) do
        table.insert(lines, string.format('- ID %s: "%s" (cached %s)',
          draft_id,
          metadata.subject or 'No subject',
          os.date('%Y-%m-%d %H:%M', metadata.cached_at or 0)
        ))
      end
      table.insert(lines, '')
    end
  end
  
  -- Show content cache
  table.insert(lines, '## Content Cache:')
  table.insert(lines, '')
  
  for account, folders in pairs(draft_cache.content_cache) do
    table.insert(lines, '### Account: ' .. account)
    for folder, drafts in pairs(folders) do
      table.insert(lines, '#### Folder: ' .. folder)
      for draft_id, content in pairs(drafts) do
        table.insert(lines, string.format('- ID %s: %d bytes (cached %s)',
          draft_id,
          content.size or 0,
          os.date('%Y-%m-%d %H:%M', content.cached_at or 0)
        ))
      end
      table.insert(lines, '')
    end
  end
  
  float.show('Draft Cache State', lines)
end

-- Show current buffer info
function M.show_buffer_info()
  local buf = vim.api.nvim_get_current_buf()
  local draft_state = draft_manager.get_by_buffer(buf)
  
  local lines = {
    '# Current Buffer Draft Info',
    '',
    'Buffer ID: ' .. buf,
    'Buffer Name: ' .. vim.api.nvim_buf_get_name(buf),
    'Modified: ' .. tostring(vim.api.nvim_buf_get_option(buf, 'modified')),
    ''
  }
  
  if draft_state then
    table.insert(lines, '## Draft State:')
    table.insert(lines, '```')
    table.insert(lines, vim.inspect(draft_state))
    table.insert(lines, '```')
  else
    table.insert(lines, '**Not tracked as a draft**')
  end
  
  -- Check if this looks like a compose buffer
  local buf_lines = vim.api.nvim_buf_get_lines(buf, 0, 10, false)
  local has_headers = false
  for _, line in ipairs(buf_lines) do
    if line:match('^From:') or line:match('^To:') or line:match('^Subject:') then
      has_headers = true
      break
    end
  end
  
  table.insert(lines, '')
  table.insert(lines, '## Buffer Analysis:')
  table.insert(lines, 'Appears to be email: ' .. tostring(has_headers))
  
  if has_headers then
    table.insert(lines, '')
    table.insert(lines, '## Parsed Content:')
    local draft_parser = require('neotex.plugins.tools.himalaya.core.draft_parser')
    local parsed = draft_parser.parse_email(buf_lines)
    table.insert(lines, '```')
    table.insert(lines, 'From: ' .. (parsed.from or ''))
    table.insert(lines, 'To: ' .. (parsed.to or ''))
    table.insert(lines, 'Subject: ' .. (parsed.subject or ''))
    table.insert(lines, 'Body Lines: ' .. (parsed.body and #vim.split(parsed.body, '\n') or 0))
    table.insert(lines, 'Parse Errors: ' .. #(parsed.errors or {}))
    table.insert(lines, '```')
  end
  
  float.show('Buffer Draft Info', lines)
end

-- Validate draft system
function M.validate_draft_system()
  local lines = {
    '# Draft System Validation',
    '',
    '## System Checks:',
    ''
  }
  
  local checks = {
    {
      name = 'Draft Manager',
      test = function()
        return type(draft_manager) == 'table' and type(draft_manager.register_draft) == 'function'
      end
    },
    {
      name = 'Draft Cache',
      test = function()
        return type(draft_cache) == 'table' and type(draft_cache.cache_draft_metadata) == 'function'
      end
    },
    {
      name = 'ID Validator',
      test = function()
        return id_validator.is_valid_id('12345') == true and id_validator.is_valid_id('Drafts') == false
      end
    },
    {
      name = 'Cache File',
      test = function()
        local cache_file = vim.fn.stdpath('cache') .. '/himalaya_draft_metadata.json'
        return vim.fn.filereadable(cache_file) == 1 or true -- OK if doesn't exist yet
      end
    },
    {
      name = 'Himalaya CLI',
      test = function()
        local result = vim.fn.system('himalaya --version')
        return vim.v.shell_error == 0
      end
    }
  }
  
  local all_pass = true
  for _, check in ipairs(checks) do
    local ok, result = pcall(check.test)
    local status = ok and result and '✅' or '❌'
    all_pass = all_pass and (ok and result)
    table.insert(lines, string.format('%s %s', status, check.name))
    if not (ok and result) then
      table.insert(lines, '  Error: ' .. tostring(ok and 'Test failed' or result))
    end
  end
  
  table.insert(lines, '')
  table.insert(lines, '## Integrity Checks:')
  table.insert(lines, '')
  
  -- Check for orphaned drafts
  local orphaned_count = 0
  for buffer_id, _ in pairs(draft_manager.drafts) do
    if not vim.api.nvim_buf_is_valid(buffer_id) then
      orphaned_count = orphaned_count + 1
    end
  end
  
  table.insert(lines, string.format('Orphaned drafts: %d', orphaned_count))
  
  -- Check cache consistency
  local cache_stats = draft_cache.get_stats()
  table.insert(lines, string.format('Cache metadata entries: %d', cache_stats.metadata_count))
  table.insert(lines, string.format('Cache content entries: %d', cache_stats.content_count))
  
  table.insert(lines, '')
  table.insert(lines, all_pass and '**✅ All systems operational**' or '**❌ Some issues detected**')
  
  float.show('Draft System Validation', lines)
end

-- Test parser on current buffer
function M.test_parser()
  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  
  local draft_parser = require('neotex.plugins.tools.himalaya.core.draft_parser')
  
  -- Test both parsers
  local email_result = draft_parser.parse_email(lines)
  local himalaya_result = draft_parser.parse_himalaya_draft(lines)
  
  local output = {
    '# Draft Parser Test',
    '',
    '## Input:',
    'Lines: ' .. #lines,
    '',
    '## parse_email() Result:',
    '```lua',
    vim.inspect(email_result),
    '```',
    '',
    '## parse_himalaya_draft() Result:',
    '```lua',
    vim.inspect(himalaya_result),
    '```'
  }
  
  float.show('Parser Test Results', output)
end

-- Clear all state (with confirmation)
function M.clear_all_state()
  local confirm = vim.fn.confirm('Clear all draft state? This cannot be undone.', '&Yes\n&No', 2)
  if confirm ~= 1 then
    return
  end
  
  -- Clear draft manager
  draft_manager.drafts = {}
  
  -- Clear cache
  draft_cache.metadata_cache = {}
  draft_cache.content_cache = {}
  
  -- Save empty cache
  draft_cache.save_metadata()
  
  vim.notify('All draft state cleared', vim.log.levels.INFO)
end

-- Show drafts in maildir
function M.show_maildir_drafts()
  local account = require('neotex.plugins.tools.himalaya.core.state').get_current_account()
  local draft_folder = utils.find_draft_folder(account)
  
  if not draft_folder then
    vim.notify('Could not find draft folder for account: ' .. account, vim.log.levels.ERROR)
    return
  end
  
  local lines = {
    '# Maildir Drafts',
    '',
    'Account: ' .. account,
    'Folder: ' .. draft_folder,
    '',
    '## Drafts in Maildir:',
    ''
  }
  
  -- List drafts using himalaya
  local ok, drafts = utils.execute_himalaya('envelope', {
    'list',
    '--account', account,
    '--folder', draft_folder,
    '--output', 'json'
  })
  
  if ok and drafts then
    table.insert(lines, 'Total drafts: ' .. #drafts)
    table.insert(lines, '')
    
    for i, draft in ipairs(drafts) do
      table.insert(lines, string.format('%d. ID %s: "%s"',
        i,
        draft.id or 'unknown',
        draft.subject or '(No subject)'
      ))
      table.insert(lines, string.format('   From: %s', draft.from or 'unknown'))
      table.insert(lines, string.format('   Date: %s', draft.date or 'unknown'))
      
      -- Check if this draft is tracked
      local tracked = draft_manager.get_by_remote_id(tostring(draft.id))
      if tracked then
        table.insert(lines, '   ✅ Tracked in draft manager')
      end
      
      -- Check if cached
      local cached_subject = draft_cache.get_draft_subject(account, draft_folder, draft.id)
      if cached_subject then
        table.insert(lines, '   ✅ Cached: "' .. cached_subject .. '"')
      end
      
      table.insert(lines, '')
    end
  else
    table.insert(lines, 'Error: Could not list drafts')
    table.insert(lines, tostring(drafts))
  end
  
  float.show('Maildir Drafts', lines)
end

return M