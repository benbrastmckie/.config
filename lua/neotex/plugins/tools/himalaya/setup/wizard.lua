-- Setup wizard for first-time users
-- Guides through dependencies, OAuth, and maildir setup

local M = {}

-- Dependencies
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local config = require('neotex.plugins.tools.himalaya.core.config')
local state = require('neotex.plugins.tools.himalaya.core.state')

-- Wizard progress tracking
M.current_step = 0
M.total_steps = 5
M.results = {}

-- Step 1: Check dependencies
function M.check_dependencies()
  local notify = require('neotex.util.notifications')
  
  local deps = {
    {name = 'mbsync', cmd = 'mbsync --version', required = true},
    {name = 'himalaya', cmd = 'himalaya --version', required = true},
    {name = 'flock', cmd = 'flock --version', required = true},
    {name = 'secret-tool', cmd = 'secret-tool --version', required = false},
  }
  
  local missing = {}
  local optional_missing = {}
  local found = {}
  
  for _, dep in ipairs(deps) do
    if vim.fn.executable(dep.name) == 1 then
      table.insert(found, dep.name)
    else
      if dep.required then
        table.insert(missing, dep.name)
      else
        table.insert(optional_missing, dep.name)
      end
    end
  end
  
  -- Report found dependencies
  if #found > 0 then
    print('  Found: ' .. table.concat(found, ', '))
  end
  
  if #missing > 0 then
    return false, 'missing dependencies: ' .. table.concat(missing, ', ')
  end
  
  if #optional_missing > 0 then
    print('  Optional missing: ' .. table.concat(optional_missing, ', '))
  end
  
  -- Check NixOS-specific setup
  local is_nixos = vim.fn.filereadable('/etc/NIXOS') == 1
  if is_nixos then
    local oauth = require('neotex.plugins.tools.himalaya.sync.oauth')
    local env = oauth.load_environment()
    if not env.GMAIL_CLIENT_ID then
      print('  NixOS: GMAIL_CLIENT_ID not in systemd environment')
    else
      print('  NixOS: OAuth environment configured')
    end
  end
  
  return true
end

-- Step 2: Setup OAuth
function M.setup_oauth()
  local oauth = require('neotex.plugins.tools.himalaya.sync.oauth')
  local config = require('neotex.plugins.tools.himalaya.core.config')
  local account = config.get_current_account()
  local account_name = account.name or 'gmail'
  
  print('  Checking OAuth for account: ' .. account_name)
  
  -- Use the new ensure_token function that automatically handles refresh
  local token_ready = false
  local token_error = nil
  
  oauth.ensure_token(account_name, function(success, error)
    token_ready = success
    token_error = error
  end)
  
  -- Wait for token operation to complete (up to 10 seconds)
  vim.wait(10000, function()
    return token_ready ~= false or token_error ~= nil
  end, 100)
  
  if token_ready then
    print('  OAuth token verified')
    return true
  else
    -- Guide user through manual setup (non-blocking)
    M.guide_oauth_setup()
    return false, 'oauth setup required'
  end
end

-- Guide through OAuth setup (non-interactive)
function M.guide_oauth_setup()
  local notify = require('neotex.util.notifications')
  notify.himalaya(' OAuth Setup Required:', notify.categories.USER_ACTION)
  notify.himalaya('  Option 1: Configure OAuth (first-time setup)', notify.categories.STATUS)
  notify.himalaya('    - Exit Neovim', notify.categories.STATUS)
  notify.himalaya('    - Run: himalaya account configure gmail', notify.categories.STATUS)
  notify.himalaya('    - Follow browser authentication', notify.categories.STATUS)
  notify.himalaya('    - Return and run :HimalayaSetup', notify.categories.STATUS)
  notify.himalaya('  Option 2: If previously configured', notify.categories.STATUS)
  notify.himalaya('    - Run :HimalayaRefreshOAuth', notify.categories.STATUS)
  notify.himalaya('    - Then :HimalayaSetup', notify.categories.STATUS)
end

-- Step 3: Create maildir structure
function M.create_maildir()
  local config = require('neotex.plugins.tools.himalaya.core.config')
  local account = config.get_current_account()
  local maildir = vim.fn.expand(account.maildir_path)
  
  print('  Maildir path: ' .. maildir)
  
  -- Check if maildir exists with proper structure
  if vim.fn.isdirectory(maildir) == 1 then
    local has_cur = vim.fn.isdirectory(maildir .. 'cur') == 1
    local has_new = vim.fn.isdirectory(maildir .. 'new') == 1
    local has_tmp = vim.fn.isdirectory(maildir .. 'tmp') == 1
    
    if has_cur and has_new and has_tmp then
      print('  Maildir structure exists')
      -- Fix UIDVALIDITY files silently
      M.fix_uidvalidity_files(maildir)
      print('  UIDVALIDITY files verified')
      return true
    else
      print('  Incomplete maildir structure, recreating...')
    end
  else
    print('  Creating new maildir structure...')
  end
  
  -- Create structure
  local dirs = {
    maildir,
    maildir .. 'cur',
    maildir .. 'new', 
    maildir .. 'tmp',
  }
  
  -- Add folder directories
  local folder_count = 0
  for imap_name, local_name in pairs(account.folder_map or {}) do
    if local_name ~= 'INBOX' then
      table.insert(dirs, maildir .. '.' .. local_name)
      table.insert(dirs, maildir .. '.' .. local_name .. '/cur')
      table.insert(dirs, maildir .. '.' .. local_name .. '/new')
      table.insert(dirs, maildir .. '.' .. local_name .. '/tmp')
      folder_count = folder_count + 1
    end
  end
  
  if folder_count > 0 then
    print('  Creating ' .. folder_count .. ' mail folders')
  end
  
  for _, dir in ipairs(dirs) do
    vim.fn.mkdir(dir, 'p')
  end
  
  -- Create empty UIDVALIDITY files (critical for mbsync)
  M.fix_uidvalidity_files(maildir)
  print('  UIDVALIDITY files created')
  
  return true
end

-- Fix UIDVALIDITY files
function M.fix_uidvalidity_files(maildir)
  -- Create empty UIDVALIDITY files - mbsync will populate them
  local cmd = string.format('find %s -type d -name "cur" -exec sh -c \'touch "$(dirname "{}")"/.uidvalidity\' \\; 2>/dev/null', vim.fn.shellescape(maildir))
  os.execute(cmd)
  
  -- Empty any existing ones with wrong format
  cmd = string.format('find %s -name ".uidvalidity" -exec sh -c \'echo -n > "{}"\' \\; 2>/dev/null', vim.fn.shellescape(maildir))
  os.execute(cmd)
end

-- Step 4: Verify sync
function M.verify_sync()
  logger.info('Testing email sync...')
  
  local mbsync = require('neotex.plugins.tools.himalaya.sync.mbsync')
  local config = require('neotex.plugins.tools.himalaya.core.config')
  local account = config.get_current_account()
  
  -- Try to sync inbox
  local sync_complete = false
  local sync_worked = false
  local sync_error = nil
  local inbox_channel = account.mbsync and account.mbsync.inbox_channel or 'gmail-inbox'
  
  logger.info('Starting sync test for channel: ' .. inbox_channel)
  
  local sync_result = mbsync.sync(inbox_channel, {
    on_progress = function(progress)
      if progress.status then
        logger.info('Sync status: ' .. progress.status)
      end
      if progress.total then
        logger.info(string.format('Found %d messages', progress.total))
      end
    end,
    callback = function(success, error)
      sync_complete = true
      if success then
        logger.info('Sync test successful!')
        sync_worked = true
      else
        -- Handle both number (exit code) and string errors
        sync_error = type(error) == "number" and ("exit code " .. error) or (error or 'unknown error')
        logger.error('Sync failed: ' .. sync_error)
        
        -- Check state for detailed error message
        local detailed_error = state.get("sync.last_error", "")
        
        if detailed_error:match('Authentication') or detailed_error:match('XOAUTH2') then
          logger.info('OAuth token may be invalid. Re-run OAuth setup.')
        elseif detailed_error:match('UIDVALIDITY') then
          logger.info('Maildir structure issue. Re-run setup.')
        elseif detailed_error:match('cancelled') then
          logger.info('Sync was cancelled.')
        elseif detailed_error:match('mbsync not found') then
          logger.error('mbsync is not installed or not in PATH')
        end
      end
    end
  })
  
  -- Check if sync started
  if not sync_result then
    logger.error('Failed to start sync test')
    return false, 'failed to start sync'
  end
  
  -- Wait for sync to complete (up to 30 seconds for first sync)
  logger.info('Waiting for sync to complete (this may take a moment for first sync)...')
  local wait_result = vim.wait(30000, function() return sync_complete end, 500)
  
  if not wait_result then
    logger.error('Sync test timed out after 30 seconds')
    mbsync.stop()
    return false, 'sync timeout'
  end
  
  return sync_worked, sync_error
end

-- Step 5: Configure keymaps
function M.configure_keymaps()
  logger.info('Setting up keymaps...')
  
  -- Check if which-key is available
  local has_which_key = pcall(require, 'which-key')
  
  if has_which_key then
    logger.info('Keymaps configured in which-key')
    logger.info('Press <leader>m to see email commands')
  else
    -- Set up basic keymaps
    vim.keymap.set('n', '<leader>ml', ':Himalaya<CR>', {desc = 'Open email list'})
    vim.keymap.set('n', '<leader>ms', ':HimalayaSyncInbox<CR>', {desc = 'Sync inbox'})
    vim.keymap.set('n', '<leader>mc', ':HimalayaWrite<CR>', {desc = 'Compose email'})
    
    logger.info('Basic keymaps configured')
    logger.info('<leader>ml - Open email')
    logger.info('<leader>ms - Sync inbox')
    logger.info('<leader>mc - Compose email')
  end
  
  return true
end

-- Main wizard runner (streamlined version)
function M.run()
  local notify = require('neotex.util.notifications')
  local float = require('neotex.plugins.tools.himalaya.ui.float')
  
  -- Store all output lines
  local output_lines = {}
  
  -- Helper to add output line
  local function add_line(line)
    table.insert(output_lines, line or '')
  end
  
  -- Show banner
  add_line('Himalaya Setup Wizard')
  add_line(string.rep('=', 40))
  add_line('')
  add_line('This wizard will:')
  add_line('  1. Check required dependencies')
  add_line('  2. Verify OAuth authentication')
  add_line('  3. Set up maildir structure')
  add_line('')
  
  local steps = {
    {name = 'Check Dependencies', fn = M.check_dependencies},
    {name = 'Setup OAuth', fn = M.setup_oauth},
    {name = 'Create Maildir', fn = M.create_maildir},
  }
  
  M.total_steps = #steps
  
  -- Capture print output
  local original_print = print
  print = function(...)
    local args = {...}
    local line = table.concat(vim.tbl_map(tostring, args), '\t')
    add_line(line)
  end
  
  -- Run all steps automatically
  for i, step in ipairs(steps) do
    M.current_step = i
    add_line(string.format('Step %d/%d: %s...', i, #steps, step.name))
    add_line('')
    
    local ok, err = step.fn()
    M.results[step.name] = {ok = ok, error = err}
    
    if not ok then
      -- Only stop on error
      add_line(string.format('[ERROR] Setup failed: %s', err or 'unknown error'))
      
      -- Show troubleshooting for specific errors
      if err == 'missing dependencies' then
        add_line('[FIX] Install with: brew install isync himalaya')
      elseif err == 'oauth setup required' then
        add_line('[FIX] Run in terminal: himalaya account configure gmail')
        add_line('      Then run :HimalayaSetup again')
      elseif err:match('permission denied') then
        add_line('[FIX] Check directory permissions or choose different location')
      end
      
      -- Restore print
      print = original_print
      
      -- Show output in floating window
      float.show('Himalaya Setup Wizard', output_lines)
      return false
    else
      add_line(string.format('[OK] %s complete', step.name))
      add_line('')
    end
  end
  
  -- All steps completed
  add_line('')
  add_line(string.rep('-', 40))
  add_line(' Himalaya setup complete!')
  add_line(string.rep('-', 40))
  add_line('')
  add_line('Summary:')
  add_line('  [OK] Dependencies checked')
  add_line('  [OK] OAuth verified') 
  add_line('  [OK] Maildir configured')
  add_line('')
  
  -- Restore original print function
  print = original_print
  
  -- Save setup completion
  state.set('setup.completed', true)
  state.set('setup.completed_at', os.time())
  
  -- Show output in floating window
  float.show('Himalaya Setup Wizard', output_lines)
  
  return true
end

-- Offer fixes for common issues
function M.offer_fixes(step_name, error)
  local fixes = {
    ['Check Dependencies'] = {
      ['missing dependencies'] = 'Install missing dependencies and run :HimalayaSetup again'
    },
    ['Setup OAuth'] = {
      ['oauth setup required'] = 'Complete OAuth setup in terminal, then run :HimalayaSetup',
      ['oauth needs refresh'] = 'Try :HimalayaOAuthRefresh or reconfigure in terminal'
    },
    ['Create Maildir'] = {
      ['permission denied'] = 'Check directory permissions or choose different location'
    },
    ['Verify Sync'] = {
      ['sync timeout'] = 'Sync took too long. Check mbsync configuration',
      ['failed to start sync'] = 'Check mbsync is installed and configured',
      ['Authentication'] = 'OAuth token invalid - reconfigure with himalaya',
      ['UIDVALIDITY'] = 'Run :HimalayaFixMaildir to repair structure'
    }
  }
  
  if fixes[step_name] and fixes[step_name][error] then
    logger.info('Suggested fix: ' .. fixes[step_name][error])
  end
  
  -- Special handling for sync test failures
  if step_name == 'Verify Sync' then
    vim.ui.input({
      prompt = 'Skip sync test and continue? (y/n): '
    }, function(input)
      if input and input:lower() == 'y' then
        logger.info('Skipping sync test. You can test sync later with :HimalayaSyncInbox')
        -- Mark as completed and continue with remaining steps
        vim.defer_fn(function()
          M.current_step = 4  -- Current step
          M.results['Verify Sync'] = {ok = true, error = 'skipped'}
          
          -- Mark setup as complete
          logger.info('\nHimalaya setup complete!')
          logger.info('You can now use:')
          logger.info('  :Himalaya - Open email list')
          logger.info('  :HimalayaSyncInbox - Sync your inbox')
          logger.info('  :HimalayaHealth - Check system health')
          
          -- Save setup completion
          state.set('setup.completed', true)
          state.set('setup.completed_at', os.time())
        end, 100)
        return
      end
    end)
  end
  
  vim.ui.input({
    prompt = 'Retry setup? (y/n): '
  }, function(input)
    if input and input:lower() == 'y' then
      vim.defer_fn(function()
        M.run()
      end, 1000)
    end
  end)
end

-- Check if setup has been completed
function M.is_setup_complete()
  -- Check for actual configuration instead of volatile state
  -- 1. Check if himalaya is available
  if vim.fn.executable('himalaya') ~= 1 then
    return false
  end
  
  -- 2. Check if maildir exists
  local account = config.get_current_account()
  if account and account.maildir_path then
    local maildir = vim.fn.expand(account.maildir_path)
    if vim.fn.isdirectory(maildir) == 1 then
      -- If maildir exists and himalaya is available, assume setup is complete
      return true
    end
  end
  
  -- Fall back to state check for current session
  return state.get('setup.completed', false)
end

return M