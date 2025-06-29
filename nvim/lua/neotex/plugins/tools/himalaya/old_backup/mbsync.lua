local M = {}

local notify = require('neotex.util.notifications')
local config = require('neotex.plugins.tools.himalaya.config')

local function get_mbsync_command(force_full)
  local account = config.get_current_account_name() or 'gmail'
  local flock_lock_file = '/tmp/mbsync-global.lock'
  
  -- Build flock-wrapped mbsync command to prevent race conditions
  local cmd = { 'flock', '-n', flock_lock_file }
  
  -- Add mbsync and its arguments as separate array elements
  table.insert(cmd, 'mbsync')
  table.insert(cmd, '-V')
  
  if force_full then
    table.insert(cmd, account)
  else
    table.insert(cmd, account .. '-inbox')
  end
  
  return cmd
end

local function clear_himalaya_cache()
  local utils = require('neotex.plugins.tools.himalaya.utils')
  if utils.clear_cache then
    utils.clear_cache()
  end
end

function M.sync(force_full, callback)
  local cmd = get_mbsync_command(force_full)
  
  notify.himalaya(
    force_full and '🔄 STARTING FULL SYNC (mbsync)' or '📧 STARTING INBOX SYNC (mbsync)',
    notify.categories.USER_ACTION
  )
  
  -- Set up environment for XOAUTH2
  -- Note: In a proper setup, SASL_PATH should be set in your shell environment
  -- This is a fallback to help mbsync find the XOAUTH2 plugin
  local env = vim.fn.environ()
  if not env.SASL_PATH or env.SASL_PATH == "" then
    -- Try to find SASL plugins in common locations
    local possible_paths = {
      "/usr/lib/sasl2",
      "/usr/lib64/sasl2",
      "/nix/store/*/lib/sasl2",
      vim.fn.expand("~/.nix-profile/lib/sasl2")
    }
    
    -- Note: This is a workaround. Properly set SASL_PATH in your shell config
    notify.himalaya('⚠️  SASL_PATH not set - XOAUTH2 auth may fail', notify.categories.WARNING)
    notify.himalaya('Set SASL_PATH in your shell config as documented', notify.categories.WARNING)
  end
  
  vim.fn.jobstart(cmd, {
    detach = false,  -- Ensure proper parent-child relationship to avoid zombies
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 then
        for _, line in ipairs(data) do
          if line ~= '' then
            vim.schedule(function()
              notify.himalaya('mbsync: ' .. line, notify.categories.STATUS)
            end)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        for _, line in ipairs(data) do
          if line ~= '' then
            vim.schedule(function()
              notify.himalaya('mbsync error: ' .. line, notify.categories.ERROR)
            end)
          end
        end
      end
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        if exit_code == 0 then
          notify.himalaya('✅ SYNC COMPLETED SUCCESSFULLY', notify.categories.USER_ACTION)
          clear_himalaya_cache()
          if callback then
            callback(true)
          end
        else
          -- Handle flock exit codes
          if exit_code == 1 then
            notify.himalaya('⚠️ Another sync is already running (flock denied)', notify.categories.WARNING)
            if callback then
              callback(false, 'Another sync is already running')
            end
          else
            notify.himalaya('❌ SYNC FAILED (exit code: ' .. exit_code .. ')', notify.categories.ERROR)
            if callback then
              callback(false, 'mbsync failed with exit code: ' .. exit_code)
            end
          end
        end
      end)
    end
  })
end

function M.is_available()
  local handle = io.popen('which mbsync 2>/dev/null')
  if handle then
    local result = handle:read('*a')
    handle:close()
    return result ~= ''
  end
  return false
end

function M.check_config()
  local home = os.getenv('HOME')
  if not home then
    return false, 'HOME environment variable not set'
  end
  
  local mbsyncrc = home .. '/.mbsyncrc'
  local file = io.open(mbsyncrc, 'r')
  if file then
    file:close()
    return true
  else
    return false, '.mbsyncrc not found in home directory'
  end
end

function M.health_check()
  local available, msg = M.is_available()
  if not available then
    return false, 'mbsync binary not found in PATH'
  end
  
  local config_ok, config_msg = M.check_config()
  if not config_ok then
    return false, config_msg
  end
  
  return true
end

return M