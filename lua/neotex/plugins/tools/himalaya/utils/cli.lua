-- CLI Utilities for Himalaya
-- Himalaya CLI execution and parsing utilities

local M = {}

local config = require('neotex.plugins.tools.himalaya.core.config')
local notify = require('neotex.util.notifications')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local state = require('neotex.plugins.tools.himalaya.core.state')
local string_utils = require('neotex.plugins.tools.himalaya.utils.string')

-- Execute himalaya command
function M.execute_himalaya(args, opts)
  opts = opts or {}
  
  -- Skip in test mode for certain commands
  if _G.HIMALAYA_TEST_MODE then
    -- Return mock data for folder list
    if args[1] == 'folder' and args[2] == 'list' then
      return {
        { name = "INBOX" },
        { name = "Sent" },
        { name = "Drafts" },
        { name = "Trash" }
      }
    end
    -- Return mock data for envelope list (used by fetch_folder_count)
    if args[1] == 'envelope' and args[2] == 'list' then
      -- Create mock emails based on requested size
      local size = 10 -- default
      for i, arg in ipairs(args) do
        if arg == '-s' and args[i+1] then
          size = tonumber(args[i+1]) or 10
        end
      end
      
      -- Return fewer emails than requested to simulate a folder with 5 emails
      local mock_count = math.min(5, size)
      local emails = {}
      for i = 1, mock_count do
        table.insert(emails, {
          id = tostring(i),
          subject = "Test Email " .. i,
          from = { email = "test@example.com" },
          date = os.time() - (i * 3600)
        })
      end
      return emails
    end
    -- For other commands in test mode, return nil without error
    return nil, 'Test mode: CLI calls disabled'
  end
  
  -- Get account name
  local account_name = opts.account or config.get_current_account_name()
  if not account_name then
    logger.error('No account configured')
    return nil, 'No account configured'
  end
  
  -- Build command
  local cmd = { 'himalaya' }
  
  -- Add subcommand arguments first
  for _, arg in ipairs(args) do
    table.insert(cmd, arg)
  end
  
  -- Add account and output format after subcommand
  table.insert(cmd, '-a')
  table.insert(cmd, account_name)
  table.insert(cmd, '-o')
  table.insert(cmd, 'json')
  
  -- Add options
  if opts.folder then
    table.insert(cmd, '-f')
    table.insert(cmd, opts.folder)
  end
  
  -- Log command for debugging
  local cmd_string_for_log = table.concat(cmd, ' ')
  logger.debug('Executing himalaya command', { 
    cmd = cmd_string_for_log,
    account = account_name,
    folder = opts.folder 
  })
  
  -- Also log to console if in debug mode
  if config.config and config.config.debug then
    print("HIMALAYA CMD: " .. cmd_string_for_log)
  end
  
  -- Show loading notification for long operations
  local show_loading = opts.show_loading
  local loading_msg = opts.loading_msg
  if show_loading and not loading_msg then
    -- Determine loading message based on command
    if vim.tbl_contains(args, 'envelope') and vim.tbl_contains(args, 'list') then
      loading_msg = 'Fetching email list...'
    elseif vim.tbl_contains(args, 'message') and vim.tbl_contains(args, 'read') then
      loading_msg = 'Loading email content...'
    elseif vim.tbl_contains(args, 'folder') and vim.tbl_contains(args, 'list') then
      loading_msg = 'Loading folders...'
    elseif vim.tbl_contains(args, 'send') then
      loading_msg = 'Sending email...'
    else
      loading_msg = 'Processing...'
    end
  end
  
  if show_loading then
    notify.himalaya(loading_msg or 'Processing...', notify.categories.STATUS)
  end
  
  -- Execute command (join table to string)
  local cmd_string = table.concat(cmd, ' ')
  local output = vim.fn.system(cmd_string)
  local exit_code = vim.v.shell_error
  
  -- Check for errors
  if exit_code ~= 0 then
    local error_msg = string_utils.trim(output)
    
    -- Debug logging for test failures
    if _G.HIMALAYA_TEST_MODE then
      logger.debug('Himalaya CLI error in test mode', {
        exit_code = exit_code,
        raw_output = output,
        trimmed_error = error_msg,
        cmd = cmd_string
      })
    end
    
    -- Special handling for authentication errors
    if error_msg:match('401') or error_msg:match('[Uu]nauthorized') or error_msg:match('[Aa]uthentication') then
      logger.error('Authentication failed', { error = error_msg, account = account_name })
      
      -- Check if we should trigger OAuth refresh
      local account = config.get_account(account_name)
      if account and account.oauth and config.get_config().sync.auto_refresh_oauth then
        -- Don't show error notification yet, try to refresh
        if show_loading then
          notify.himalaya('Authentication failed, refreshing token...', notify.categories.WARNING)
        end
        
        -- Trigger OAuth refresh via sync manager
        local sync_manager = require('neotex.plugins.tools.himalaya.sync.manager')
        local refresh_ok = sync_manager.refresh_oauth_if_needed(account_name)
        
        if refresh_ok then
          -- Retry the command
          output = vim.fn.system(cmd)
          exit_code = vim.v.shell_error
          
          if exit_code == 0 then
            -- Success after refresh
            logger.info('Command succeeded after OAuth refresh')
          else
            error_msg = string_utils.trim(output)
            if not _G.HIMALAYA_TEST_MODE then
              notify.himalaya('Command failed after OAuth refresh: ' .. error_msg, notify.categories.ERROR)
            end
            return nil, error_msg
          end
        else
          if not _G.HIMALAYA_TEST_MODE then
            notify.himalaya('OAuth refresh failed', notify.categories.ERROR)
          end
          return nil, 'OAuth refresh failed'
        end
      else
        -- No OAuth configured or auto-refresh disabled
        if not _G.HIMALAYA_TEST_MODE then
          notify.himalaya('Authentication failed: ' .. error_msg, notify.categories.ERROR)
        end
        return nil, error_msg
      end
    else
      -- Other errors
      if not _G.HIMALAYA_TEST_MODE then
        logger.error('Himalaya command failed', { 
          error = error_msg, 
          exit_code = exit_code,
          cmd = table.concat(cmd, ' ')
        })
      end
      
      -- User-friendly error messages
      if error_msg:match('no such file or directory') then
        error_msg = 'Himalaya not found. Please install himalaya CLI.'
      elseif error_msg:match('folder.*not found') then
        error_msg = 'Folder not found. Check your folder configuration.'
      elseif error_msg:match('network') or error_msg:match('connection') then
        error_msg = 'Network error. Check your internet connection.'
      elseif error_msg:match('timeout') then
        error_msg = 'Request timed out. Try again later.'
      end
      
      -- Only show error notification if not in test mode
      if show_loading and not _G.HIMALAYA_TEST_MODE then
        notify.himalaya(error_msg, notify.categories.ERROR)
      end
      
      return nil, error_msg
    end
  end
  
  -- Parse JSON output
  local ok, result = pcall(vim.json.decode, output)
  if not ok then
    -- Some commands don't return JSON
    if args[1] == 'send' or args[1] == 'move' or args[1] == 'delete' then
      -- These commands return plain text on success
      return string_utils.trim(output)
    end
    
    logger.error('Failed to parse himalaya output', { 
      error = result,
      output = output:sub(1, 200)  -- Log first 200 chars
    })
    
    if show_loading then
      notify.himalaya('Failed to parse response', notify.categories.ERROR)
    end
    
    return nil, 'Failed to parse response'
  end
  
  -- Cache successful results if appropriate
  if opts.cache_key then
    local cache = state.get('email_cache') or {}
    cache[opts.cache_key] = {
      data = result,
      timestamp = os.time()
    }
    state.set('email_cache', cache)
  end
  
  return result
end

-- Execute himalaya command asynchronously
function M.execute_himalaya_async(args, opts, callback)
  opts = opts or {}

  -- Get account name
  local account_name = opts.account or config.get_current_account_name()
  if not account_name then
    callback(nil, 'No account configured')
    return
  end

  -- Pass account and folder in opts to async_commands
  -- async_commands.build_command will construct the full command
  local async_opts = {
    account = account_name,
    folder = opts.folder,
    timeout = opts.timeout,
    priority = require('neotex.plugins.tools.himalaya.core.async_commands').priorities.user
  }

  -- Use async command execution
  local async_commands = require('neotex.plugins.tools.himalaya.core.async_commands')

  -- Build success callback
  local on_success = function(parsed_data)
    -- async_commands already parses JSON, so parsed_data is a Lua table
    -- Just pass it through to the callback
    vim.schedule(function()
      vim.notify('[DEBUG] cli_utils on_success - type: ' .. type(parsed_data) ..
        (type(parsed_data) == "table" and (' items: ' .. #parsed_data) or ''), vim.log.levels.INFO)
      callback(parsed_data)
    end)
  end

  -- Build error callback
  local on_error = function(error_msg)
    callback(nil, error_msg)
  end

  -- Execute async - pass just the subcommand args, not the full command
  async_commands.execute_async(args, async_opts, function(job_result, error_msg)
    -- async_commands returns (result, error_msg) signature
    -- - On success: (parsed_json_data, nil)
    -- - On error: (nil, error_message)
    if error_msg then
      on_error(error_msg)
    elseif job_result then
      on_success(job_result)
    else
      on_error('Unknown error')
    end
  end)
end

-- Parse CLI arguments
function M.parse_args(args_string)
  local args = {}
  local current_arg = ''
  local in_quotes = false
  local quote_char = nil
  
  for i = 1, #args_string do
    local char = args_string:sub(i, i)
    
    if in_quotes then
      if char == quote_char then
        in_quotes = false
        if current_arg ~= '' then
          table.insert(args, current_arg)
          current_arg = ''
        end
      else
        current_arg = current_arg .. char
      end
    else
      if char == '"' or char == "'" then
        in_quotes = true
        quote_char = char
      elseif char == ' ' then
        if current_arg ~= '' then
          table.insert(args, current_arg)
          current_arg = ''
        end
      else
        current_arg = current_arg .. char
      end
    end
  end
  
  -- Add final argument
  if current_arg ~= '' then
    table.insert(args, current_arg)
  end
  
  return args
end

-- Build CLI command string
function M.build_command(args, opts)
  opts = opts or {}
  
  local cmd_parts = { 'himalaya' }
  
  -- Add account
  if opts.account then
    table.insert(cmd_parts, '-a')
    table.insert(cmd_parts, string_utils.shell_escape(opts.account))
  end
  
  -- Add output format
  if opts.output then
    table.insert(cmd_parts, '-o')
    table.insert(cmd_parts, opts.output)
  else
    table.insert(cmd_parts, '-o')
    table.insert(cmd_parts, 'json')
  end
  
  -- Add folder
  if opts.folder then
    table.insert(cmd_parts, '-f')
    table.insert(cmd_parts, string_utils.shell_escape(opts.folder))
  end
  
  -- Add arguments
  for _, arg in ipairs(args) do
    table.insert(cmd_parts, string_utils.shell_escape(arg))
  end
  
  return table.concat(cmd_parts, ' ')
end

-- Check if himalaya CLI is available
function M.check_himalaya()
  local output = vim.fn.system({ 'which', 'himalaya' })
  return vim.v.shell_error == 0
end

-- Get himalaya version
function M.get_version()
  local output = vim.fn.system({ 'himalaya', '--version' })
  if vim.v.shell_error == 0 then
    return string_utils.trim(output)
  end
  return nil
end

return M