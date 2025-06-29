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
  logger.info('🔍 Checking dependencies...')
  
  local deps = {
    {name = 'mbsync', cmd = 'mbsync --version', required = true},
    {name = 'himalaya', cmd = 'himalaya --version', required = true},
    {name = 'flock', cmd = 'flock --version', required = true},
    {name = 'secret-tool', cmd = 'secret-tool --version', required = false},
  }
  
  local missing = {}
  local optional_missing = {}
  
  for _, dep in ipairs(deps) do
    local handle = io.popen(dep.cmd .. ' 2>&1')
    if handle then
      local result = handle:read('*a')
      handle:close()
      
      if result == '' or result:match('not found') or result:match('No such file') then
        if dep.required then
          table.insert(missing, dep.name)
        else
          table.insert(optional_missing, dep.name)
        end
      else
        logger.info('✅ ' .. dep.name .. ' found')
      end
    else
      if dep.required then
        table.insert(missing, dep.name)
      else
        table.insert(optional_missing, dep.name)
      end
    end
  end
  
  if #missing > 0 then
    logger.error('❌ Missing required dependencies: ' .. table.concat(missing, ', '))
    logger.info('Install with: brew install isync himalaya')
    return false, 'missing dependencies'
  end
  
  if #optional_missing > 0 then
    logger.warn('⚠️  Optional dependencies missing: ' .. table.concat(optional_missing, ', ')')
  end
  
  -- Check NixOS-specific setup
  local is_nixos = vim.fn.filereadable('/etc/NIXOS') == 1
  if is_nixos then
    logger.info('📦 NixOS detected - checking systemd environment')
    local oauth = require('neotex.plugins.tools.himalaya.sync.oauth')
    local env = oauth.load_environment()
    if not env.GMAIL_CLIENT_ID then
      logger.warn('⚠️  GMAIL_CLIENT_ID not found in systemd environment')
      logger.info('Add to home-manager: systemd.user.sessionVariables.GMAIL_CLIENT_ID')
    end
  end
  
  return true
end

-- Step 2: Setup OAuth
function M.setup_oauth()
  logger.info('🔐 Checking OAuth setup...')
  
  local oauth = require('neotex.plugins.tools.himalaya.sync.oauth')
  local config = require('neotex.plugins.tools.himalaya.core.config')
  local account = config.get_current_account()
  
  -- Check if token exists
  if oauth.has_token(account.name or 'gmail') then
    logger.info('✅ OAuth token found')
    
    -- Try to validate it
    if oauth.is_valid(account.name or 'gmail') then
      logger.info('✅ OAuth token appears valid')
      return true
    else
      logger.warn('⚠️  OAuth token may be expired')
      
      -- Offer to refresh
      vim.ui.input({
        prompt = 'Try to refresh OAuth token? (y/n): '
      }, function(input)
        if input and input:lower() == 'y' then
          oauth.refresh(account.name or 'gmail', function(success)
            if success then
              logger.info('✅ OAuth token refreshed')
            else
              logger.error('❌ Failed to refresh token')
              M.guide_oauth_setup()
            end
          end)
        else
          M.guide_oauth_setup()
        end
      end)
      
      return false, 'oauth needs refresh'
    end
  else
    logger.warn('❌ No OAuth token found')
    M.guide_oauth_setup()
    return false, 'no oauth token'
  end
end

-- Guide through OAuth setup
function M.guide_oauth_setup()
  logger.info('📋 OAuth Setup Instructions:')
  logger.info('1. Exit Neovim')
  logger.info('2. Run in terminal: himalaya account configure gmail')
  logger.info('3. Follow the browser authentication flow')
  logger.info('4. Return to Neovim and run :HimalayaSetup again')
  
  vim.ui.input({
    prompt = 'Open terminal to configure OAuth? (y/n): '
  }, function(input)
    if input and input:lower() == 'y' then
      -- Open a terminal with the command
      vim.cmd('split | terminal himalaya account configure gmail')
      logger.info('Complete OAuth setup in the terminal below')
    end
  end)
end

-- Step 3: Create maildir structure
function M.create_maildir()
  logger.info('📁 Setting up maildir structure...')
  
  local config = require('neotex.plugins.tools.himalaya.core.config')
  local account = config.get_current_account()
  local maildir = vim.fn.expand(account.maildir_path)
  
  -- Check if maildir exists
  if vim.fn.isdirectory(maildir) == 1 then
    -- Check structure
    local has_cur = vim.fn.isdirectory(maildir .. 'cur') == 1
    local has_new = vim.fn.isdirectory(maildir .. 'new') == 1
    local has_tmp = vim.fn.isdirectory(maildir .. 'tmp') == 1
    
    if has_cur and has_new and has_tmp then
      logger.info('✅ Maildir structure exists')
      
      -- Fix UIDVALIDITY files
      M.fix_uidvalidity_files(maildir)
      return true
    end
  end
  
  -- Create structure
  logger.info('Creating maildir structure at: ' .. maildir)
  
  -- Create directories
  local dirs = {
    maildir,
    maildir .. 'cur',
    maildir .. 'new', 
    maildir .. 'tmp',
  }
  
  -- Add folder directories
  for imap_name, local_name in pairs(account.folder_map or {}) do
    if local_name ~= 'INBOX' then
      table.insert(dirs, maildir .. '.' .. local_name)
      table.insert(dirs, maildir .. '.' .. local_name .. '/cur')
      table.insert(dirs, maildir .. '.' .. local_name .. '/new')
      table.insert(dirs, maildir .. '.' .. local_name .. '/tmp')
    end
  end
  
  for _, dir in ipairs(dirs) do
    vim.fn.mkdir(dir, 'p')
  end
  
  -- Create empty UIDVALIDITY files (critical for mbsync)
  M.fix_uidvalidity_files(maildir)
  
  logger.info('✅ Maildir structure created')
  return true
end

-- Fix UIDVALIDITY files
function M.fix_uidvalidity_files(maildir)
  logger.info('🔧 Creating UIDVALIDITY files...')
  
  -- Create empty UIDVALIDITY files - mbsync will populate them
  local cmd = string.format('find %s -type d -name "cur" -exec sh -c \'touch "$(dirname "{}")"/.uidvalidity\' \\; 2>/dev/null', vim.fn.shellescape(maildir))
  os.execute(cmd)
  
  -- Empty any existing ones with wrong format
  cmd = string.format('find %s -name ".uidvalidity" -exec sh -c \'echo -n > "{}"\' \\; 2>/dev/null', vim.fn.shellescape(maildir))
  os.execute(cmd)
  
  logger.info('✅ UIDVALIDITY files prepared')
end

-- Step 4: Verify sync
function M.verify_sync()
  logger.info('🔄 Testing email sync...')
  
  local mbsync = require('neotex.plugins.tools.himalaya.sync.mbsync')
  local config = require('neotex.plugins.tools.himalaya.core.config')
  local account = config.get_current_account()
  
  -- Try to sync inbox
  local sync_worked = false
  local inbox_channel = account.mbsync and account.mbsync.inbox_channel or 'gmail-inbox'
  mbsync.sync(inbox_channel, {
    on_progress = function(progress)
      if progress.total then
        logger.info(string.format('Found %d messages', progress.total))
      end
    end,
    callback = function(success, error)
      if success then
        logger.info('✅ Sync test successful!')
        sync_worked = true
      else
        logger.error('❌ Sync failed: ' .. (error or 'unknown error'))
        
        if error:match('Authentication') or error:match('XOAUTH2') then
          logger.info('OAuth token may be invalid. Re-run OAuth setup.')
        elseif error:match('UIDVALIDITY') then
          logger.info('Maildir structure issue. Re-run setup.')
        end
      end
    end
  })
  
  -- Wait a bit for sync to complete
  vim.wait(5000, function() return sync_worked end, 100)
  
  return sync_worked
end

-- Step 5: Configure keymaps
function M.configure_keymaps()
  logger.info('⌨️  Setting up keymaps...')
  
  -- Check if which-key is available
  local has_which_key = pcall(require, 'which-key')
  
  if has_which_key then
    logger.info('✅ Keymaps configured in which-key')
    logger.info('Press <leader>m to see email commands')
  else
    -- Set up basic keymaps
    vim.keymap.set('n', '<leader>ml', ':Himalaya<CR>', {desc = 'Open email list'})
    vim.keymap.set('n', '<leader>ms', ':HimalayaSyncInbox<CR>', {desc = 'Sync inbox'})
    vim.keymap.set('n', '<leader>mc', ':HimalayaWrite<CR>', {desc = 'Compose email'})
    
    logger.info('✅ Basic keymaps configured')
    logger.info('<leader>ml - Open email')
    logger.info('<leader>ms - Sync inbox')
    logger.info('<leader>mc - Compose email')
  end
  
  return true
end

-- Main wizard runner
function M.run()
  logger.info('🧙 Starting Himalaya Setup Wizard')
  
  local steps = {
    {name = 'Check Dependencies', fn = M.check_dependencies},
    {name = 'Setup OAuth', fn = M.setup_oauth},
    {name = 'Create Maildir', fn = M.create_maildir},
    {name = 'Verify Sync', fn = M.verify_sync},
    {name = 'Configure Keymaps', fn = M.configure_keymaps},
  }
  
  M.total_steps = #steps
  
  for i, step in ipairs(steps) do
    M.current_step = i
    logger.info(string.format('\n📍 Step %d/%d: %s', i, #steps, step.name))
    
    local ok, err = step.fn()
    M.results[step.name] = {ok = ok, error = err}
    
    if not ok then
      logger.error(string.format('❌ Setup failed at step %d: %s', i, err or 'unknown error'))
      M.offer_fixes(step.name, err)
      return false
    end
  end
  
  logger.info('\n🎉 Himalaya setup complete!')
  logger.info('Press <leader>ml to open your email')
  
  -- Save setup completion
  state.set('setup.completed', true)
  state.set('setup.completed_at', os.time())
  
  return true
end

-- Offer fixes for common issues
function M.offer_fixes(step_name, error)
  local fixes = {
    ['Check Dependencies'] = {
      ['missing dependencies'] = 'Install missing dependencies and run :HimalayaSetup again'
    },
    ['Setup OAuth'] = {
      ['no oauth token'] = 'Complete OAuth setup in terminal, then run :HimalayaSetup',
      ['oauth needs refresh'] = 'Try :HimalayaOAuthRefresh or reconfigure in terminal'
    },
    ['Create Maildir'] = {
      ['permission denied'] = 'Check directory permissions or choose different location'
    },
    ['Verify Sync'] = {
      ['Authentication'] = 'OAuth token invalid - reconfigure with himalaya',
      ['UIDVALIDITY'] = 'Run :HimalayaFixMaildir to repair structure'
    }
  }
  
  if fixes[step_name] and fixes[step_name][error] then
    logger.info('💡 Suggested fix: ' .. fixes[step_name][error])
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
  return state.get('setup.completed', false)
end

return M