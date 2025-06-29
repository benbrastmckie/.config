-- Setup wizard for first-time users
-- Guides through dependencies, OAuth, and maildir setup

local M = {}

-- Dependencies
local notify = require('neotex.util.notifications')

-- Wizard state
M.state = {
  current_step = 0,
  total_steps = 5,
  results = {},
}

-- Step 1: Check dependencies
function M.check_dependencies()
  notify.himalaya('🔍 Checking dependencies...', notify.categories.STATUS)
  
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
        notify.himalaya('✅ ' .. dep.name .. ' found', notify.categories.STATUS)
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
    notify.himalaya('❌ Missing required dependencies: ' .. table.concat(missing, ', '), notify.categories.ERROR)
    notify.himalaya('Install with: brew install isync himalaya', notify.categories.STATUS)
    return false, 'missing dependencies'
  end
  
  if #optional_missing > 0 then
    notify.himalaya('⚠️  Optional dependencies missing: ' .. table.concat(optional_missing, ', '), notify.categories.WARNING)
  end
  
  -- Check NixOS-specific setup
  local is_nixos = vim.fn.filereadable('/etc/NIXOS') == 1
  if is_nixos then
    notify.himalaya('📦 NixOS detected - checking systemd environment', notify.categories.STATUS)
    local oauth = require('neotex.plugins.tools.himalaya.sync.oauth')
    local env = oauth.load_environment()
    if not env.GMAIL_CLIENT_ID then
      notify.himalaya('⚠️  GMAIL_CLIENT_ID not found in systemd environment', notify.categories.WARNING)
      notify.himalaya('Add to home-manager: systemd.user.sessionVariables.GMAIL_CLIENT_ID', notify.categories.STATUS)
    end
  end
  
  return true
end

-- Step 2: Setup OAuth
function M.setup_oauth()
  notify.himalaya('🔐 Checking OAuth setup...', notify.categories.STATUS)
  
  local oauth = require('neotex.plugins.tools.himalaya.sync.oauth')
  local config = require('neotex.plugins.tools.himalaya.core.config')
  local account = config.get_account()
  
  -- Check if token exists
  if oauth.has_token(account.name or 'gmail') then
    notify.himalaya('✅ OAuth token found', notify.categories.STATUS)
    
    -- Try to validate it
    if oauth.is_valid(account.name or 'gmail') then
      notify.himalaya('✅ OAuth token appears valid', notify.categories.STATUS)
      return true
    else
      notify.himalaya('⚠️  OAuth token may be expired', notify.categories.WARNING)
      
      -- Offer to refresh
      vim.ui.input({
        prompt = 'Try to refresh OAuth token? (y/n): '
      }, function(input)
        if input and input:lower() == 'y' then
          oauth.refresh(account.name or 'gmail', function(success)
            if success then
              notify.himalaya('✅ OAuth token refreshed', notify.categories.USER_ACTION)
            else
              notify.himalaya('❌ Failed to refresh token', notify.categories.ERROR)
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
    notify.himalaya('❌ No OAuth token found', notify.categories.WARNING)
    M.guide_oauth_setup()
    return false, 'no oauth token'
  end
end

-- Guide through OAuth setup
function M.guide_oauth_setup()
  notify.himalaya('📋 OAuth Setup Instructions:', notify.categories.USER_ACTION)
  notify.himalaya('1. Exit Neovim', notify.categories.STATUS)
  notify.himalaya('2. Run in terminal: himalaya account configure gmail', notify.categories.STATUS)
  notify.himalaya('3. Follow the browser authentication flow', notify.categories.STATUS)
  notify.himalaya('4. Return to Neovim and run :HimalayaSetup again', notify.categories.STATUS)
  
  vim.ui.input({
    prompt = 'Open terminal to configure OAuth? (y/n): '
  }, function(input)
    if input and input:lower() == 'y' then
      -- Open a terminal with the command
      vim.cmd('split | terminal himalaya account configure gmail')
      notify.himalaya('Complete OAuth setup in the terminal below', notify.categories.STATUS)
    end
  end)
end

-- Step 3: Create maildir structure
function M.create_maildir()
  notify.himalaya('📁 Setting up maildir structure...', notify.categories.STATUS)
  
  local config = require('neotex.plugins.tools.himalaya.core.config')
  local account = config.get_account()
  local maildir = vim.fn.expand(account.maildir_path)
  
  -- Check if maildir exists
  if vim.fn.isdirectory(maildir) == 1 then
    -- Check structure
    local has_cur = vim.fn.isdirectory(maildir .. 'cur') == 1
    local has_new = vim.fn.isdirectory(maildir .. 'new') == 1
    local has_tmp = vim.fn.isdirectory(maildir .. 'tmp') == 1
    
    if has_cur and has_new and has_tmp then
      notify.himalaya('✅ Maildir structure exists', notify.categories.STATUS)
      
      -- Fix UIDVALIDITY files
      M.fix_uidvalidity_files(maildir)
      return true
    end
  end
  
  -- Create structure
  notify.himalaya('Creating maildir structure at: ' .. maildir, notify.categories.STATUS)
  
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
  
  notify.himalaya('✅ Maildir structure created', notify.categories.USER_ACTION)
  return true
end

-- Fix UIDVALIDITY files
function M.fix_uidvalidity_files(maildir)
  notify.himalaya('🔧 Creating UIDVALIDITY files...', notify.categories.STATUS)
  
  -- Create empty UIDVALIDITY files - mbsync will populate them
  local cmd = string.format('find %s -type d -name "cur" -exec sh -c \'touch "$(dirname "{}")"/.uidvalidity\' \\; 2>/dev/null', vim.fn.shellescape(maildir))
  os.execute(cmd)
  
  -- Empty any existing ones with wrong format
  cmd = string.format('find %s -name ".uidvalidity" -exec sh -c \'echo -n > "{}"\' \\; 2>/dev/null', vim.fn.shellescape(maildir))
  os.execute(cmd)
  
  notify.himalaya('✅ UIDVALIDITY files prepared', notify.categories.STATUS)
end

-- Step 4: Verify sync
function M.verify_sync()
  notify.himalaya('🔄 Testing email sync...', notify.categories.STATUS)
  
  local mbsync = require('neotex.plugins.tools.himalaya.sync.mbsync')
  local config = require('neotex.plugins.tools.himalaya.core.config')
  local account = config.get_account()
  
  -- Try to sync inbox
  local sync_worked = false
  mbsync.sync_inbox({
    on_progress = function(progress)
      if progress.total then
        notify.himalaya(string.format('Found %d messages', progress.total), notify.categories.STATUS)
      end
    end,
    callback = function(success, error)
      if success then
        notify.himalaya('✅ Sync test successful!', notify.categories.USER_ACTION)
        sync_worked = true
      else
        notify.himalaya('❌ Sync failed: ' .. (error or 'unknown error'), notify.categories.ERROR)
        
        if error:match('Authentication') or error:match('XOAUTH2') then
          notify.himalaya('OAuth token may be invalid. Re-run OAuth setup.', notify.categories.STATUS)
        elseif error:match('UIDVALIDITY') then
          notify.himalaya('Maildir structure issue. Re-run setup.', notify.categories.STATUS)
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
  notify.himalaya('⌨️  Setting up keymaps...', notify.categories.STATUS)
  
  -- Check if which-key is available
  local has_which_key = pcall(require, 'which-key')
  
  if has_which_key then
    notify.himalaya('✅ Keymaps configured in which-key', notify.categories.STATUS)
    notify.himalaya('Press <leader>m to see email commands', notify.categories.USER_ACTION)
  else
    -- Set up basic keymaps
    vim.keymap.set('n', '<leader>ml', ':Himalaya<CR>', {desc = 'Open email list'})
    vim.keymap.set('n', '<leader>ms', ':HimalayaSyncInbox<CR>', {desc = 'Sync inbox'})
    vim.keymap.set('n', '<leader>mc', ':HimalayaWrite<CR>', {desc = 'Compose email'})
    
    notify.himalaya('✅ Basic keymaps configured', notify.categories.STATUS)
    notify.himalaya('<leader>ml - Open email', notify.categories.STATUS)
    notify.himalaya('<leader>ms - Sync inbox', notify.categories.STATUS)
    notify.himalaya('<leader>mc - Compose email', notify.categories.STATUS)
  end
  
  return true
end

-- Main wizard runner
function M.run()
  notify.himalaya('🧙 Starting Himalaya Setup Wizard', notify.categories.USER_ACTION)
  
  local steps = {
    {name = 'Check Dependencies', fn = M.check_dependencies},
    {name = 'Setup OAuth', fn = M.setup_oauth},
    {name = 'Create Maildir', fn = M.create_maildir},
    {name = 'Verify Sync', fn = M.verify_sync},
    {name = 'Configure Keymaps', fn = M.configure_keymaps},
  }
  
  M.state.total_steps = #steps
  
  for i, step in ipairs(steps) do
    M.state.current_step = i
    notify.himalaya(string.format('\n📍 Step %d/%d: %s', i, #steps, step.name), notify.categories.USER_ACTION)
    
    local ok, err = step.fn()
    M.state.results[step.name] = {ok = ok, error = err}
    
    if not ok then
      notify.himalaya(string.format('❌ Setup failed at step %d: %s', i, err or 'unknown error'), notify.categories.ERROR)
      M.offer_fixes(step.name, err)
      return false
    end
  end
  
  notify.himalaya('\n🎉 Himalaya setup complete!', notify.categories.USER_ACTION)
  notify.himalaya('Press <leader>ml to open your email', notify.categories.USER_ACTION)
  
  -- Save setup completion
  local state = require('neotex.plugins.tools.himalaya.state')
  state.set('setup_completed', true)
  state.save()
  
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
    notify.himalaya('💡 Suggested fix: ' .. fixes[step_name][error], notify.categories.STATUS)
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
  local state = require('neotex.plugins.tools.himalaya.state')
  return state.get('setup_completed') == true
end

return M